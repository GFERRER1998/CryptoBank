// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title IAggregatorV3Interface
 * @notice Interfaz del oráculo Chainlink Price Feed
 * @dev Define las funciones para obtener precios de Chainlink
 */
interface IAggregatorV3Interface {
    /**
     * @notice Obtiene el número de decimales del precio
     * @return Decimales (típicamente 8 para precios USD)
     */
    function decimals() external view returns (uint8);

    /**
     * @notice Obtiene la descripción del feed
     * @return Nombre del feed (ej: "ETH / USD")
     */
    function description() external view returns (string memory);

    /**
     * @notice Obtiene los datos de la última ronda
     * @return roundId ID de la ronda
     * @return answer Precio actual
     * @return startedAt Timestamp de inicio
     * @return updatedAt Timestamp de última actualización
     * @return answeredInRound Ronda en la que se respondió
     */
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

/**
 * @title PriceFeed
 * @notice Oráculo de precios que integra Chainlink Price Feeds
 * @dev Proporciona precios on-chain para el protocolo CryptoBank
 *      Usa Chainlink como fuente de verdad para precios de activos
 *
 * @dev FLUJO DE FUNCIONAMIENTO:
 *      1. Admin agrega feeds de precios para activos
 *      2. LendingPool u otros contratos solicitan precios
 *      3. PriceFeed consulta Chainlink
 *      4. Verifica que el precio sea válido y actualizado
 *      5. Retorna el precio al solicitante
 *
 * @dev SEGURIDAD:
 *      - Solo admins pueden agregar/modificar feeds
 *      - Verificación de precios stale (antiguos)
 *      - Rangos mínimos/máximos para prevenir manipulación
 *      - Pausable en caso de emergencia
 *
 * @dev HERENCIA:
 *      Ownable → Control de acceso al deployer
 *      AccessControl → Roles granulares
 *      Pausable → Pausa de emergencia
 */
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

contract PriceFeed is Ownable, AccessControl, Pausable {

    // ========================================================================
    //                         ESTRUCTURAS
    // ========================================================================

    /**
     * @notice Datos de un feed de precios
     * @dev Almacena configuración de cada feed Chainlink
     *
     * @param feedAddress Dirección del contrato Chainlink (address(0) para mock)
     * @param priceDecimals Número de decimales del precio
     * @param isPaused Si el feed está pausado
     * @param minPrice Precio mínimo aceptable (prevenr manipulación)
     * @param maxPrice Precio máximo aceptable (prevenir manipulación)
     * @param maxStalePeriod Tiempo máximo sin actualizar (segundos)
     * @param mockPrice Precio simulado para stablecoins sin feed Chainlink (0 = usar Chainlink)
     */
    struct FeedData {
        address feedAddress;
        uint256 priceDecimals;
        bool isPaused;
        uint256 minPrice;
        uint256 maxPrice;
        uint256 maxStalePeriod;
        uint256 mockPrice;
    }

    // ========================================================================
    //                         ESTADO DEL CONTRATO
    // ========================================================================

    /**
     * @notice Mapping de feeds por dirección de activo
     * @dev Key: dirección del token ERC20
     *      Value: datos del feed Chainlink
     */
    mapping(address => FeedData) public feeds;

    /**
     * @notice Array de direcciones de activos con feed configurado
     * @dev Usado para iterar sobre todos los feeds
     */
    address[] public feedAssets;

    // ========================================================================
    //                         CONSTANTES
    // ========================================================================

    /**
     * @notice Desviación máxima permitida del precio (5%)
     * @dev 500 = 5.00% (con 2 decimales implícitos)
     *      Usado para detectar manipulación de precios
     */
    uint256 public constant MAX_PRICE_DEVIATION = 500;

    /**
     * @notice Segundos en una hora
     * @dev 3600 segundos = 1 hora
     *      Usado para cálculos de stale period
     */
    uint256 public constant SECONDS_PER_HOUR = 3600;

    // ========================================================================
    //                         EVENTOS
    // ========================================================================

    /**
     * @notice Emitido cuando se agrega un nuevo feed
     * @param asset Dirección del activo
     * @param feedAddress Dirección del feed Chainlink
     */
    event FeedAdded(address indexed asset, address indexed feedAddress);

    /**
     * @notice Emitido cuando se actualiza un feed
     * @param asset Dirección del activo
     * @param feedAddress Nueva dirección del feed
     */
    event FeedUpdated(address indexed asset, address indexed feedAddress);

    /**
     * @notice Emitido cuando se consulta un precio
     * @param asset Dirección del activo
     * @param price Precio obtenido
     */
    event PriceUpdated(address indexed asset, uint256 price);

    // ========================================================================
    //                         MODIFICADORES
    // ========================================================================

    /**
     * @notice Modificador que restringe a administradores de feeds
     * @dev Verifica que msg.sender tenga DEFAULT_ADMIN_ROLE
     */
    modifier onlyFeedAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller must be feed admin");
        _;
    }

    // ========================================================================
    //                         CONSTRUCTOR
    // ========================================================================

    /**
     * @notice Constructor del PriceFeed
     * @dev Inicializa el oráculo con el deployer como admin
     *
     * @dev PASOS:
     *      1. Inicializa Ownable con msg.sender
     *      2. Otorga DEFAULT_ADMIN_ROLE a msg.sender
     */
    constructor() Ownable(msg.sender) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // ========================================================================
    //                    FUNCIONES ADMINISTRATIVAS
    // ========================================================================

    /**
     * @notice Agrega un nuevo feed de precios
     * @dev Registra un feed Chainlink o mock para un activo
     *
     * @param asset Dirección del token ERC20
     * @param feedAddress Dirección del contrato Chainlink (address(0) para mock)
     * @param priceDecimals Decimales del precio (típicamente 8)
     * @param minPrice Precio mínimo aceptable
     * @param maxPrice Precio máximo aceptable
     * @param maxStalePeriod Tiempo máximo sin actualizar (segundos)
     * @param mockPrice Precio simulado para stablecoins (0 = usar Chainlink)
     *
     * @dev PASOS:
     *      1. Verificar que no exista feed para este activo
     *      2. Verificar dirección válida o mockPrice > 0
     *      3. Guardar datos del feed
     *      4. Agregar activo al array
     *      5. Emitir evento FeedAdded
     *
     * @dev RESTRICCIÓN: Solo DEFAULT_ADMIN_ROLE
     *
     * @dev EJEMPLO (Chainlink):
     *      addFeed(
     *        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, // WETH
     *        0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419, // Chainlink ETH/USD
     *        8,                                            // 8 decimales
     *        100e8,                                        // $100 mínimo
     *        100000e8,                                     // $100,000 máximo
     *        3600,                                         // 1 hora stale
     *        0                                             // sin mock
     *      )
     *
     * @dev EJEMPLO (Mock para USDC):
     *      addFeed(
     *        0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238, // USDC
     *        address(0),                                   // Sin Chainlink
     *        8,                                            // 8 decimales
     *        99e8,                                         // $0.99 mínimo
     *        101e8,                                        // $1.01 máximo
     *        0,                                            // Sin stale check
     *        100000000                                     // $1.00 mock price (8 decimales)
     *      )
     */
    function addFeed(
        address asset,
        address feedAddress,
        uint256 priceDecimals,
        uint256 minPrice,
        uint256 maxPrice,
        uint256 maxStalePeriod,
        uint256 mockPrice
    ) external onlyFeedAdmin {
        // Verificar que no exista feed
        require(feeds[asset].feedAddress == address(0), "Feed already exists");
        // Verificar dirección válida o mock price
        require(feedAddress != address(0) || mockPrice > 0, "Invalid feed address or mock price");

        // Guardar datos del feed
        feeds[asset] = FeedData({
            feedAddress: feedAddress,
            priceDecimals: priceDecimals,
            isPaused: false,
            minPrice: minPrice,
            maxPrice: maxPrice,
            maxStalePeriod: maxStalePeriod,
            mockPrice: mockPrice
        });

        // Agregar activo al array
        feedAssets.push(asset);

        // Emitir evento
        emit FeedAdded(asset, feedAddress);
    }

    /**
     * @notice Actualiza la dirección de un feed existente
     * @dev Cambia el feed Chainlink para un activo
     *
     * @param asset Dirección del activo
     * @param newFeedAddress Nueva dirección del feed
     *
     * @dev PASOS:
     *      1. Verificar que exista feed para este activo
     *      2. Verificar nueva dirección válida
     *      3. Actualizar dirección
     *      4. Emitir evento FeedUpdated
     *
     * @dev RESTRICCIÓN: Solo DEFAULT_ADMIN_ROLE
     */
    function updateFeed(
        address asset,
        address newFeedAddress
    ) external onlyFeedAdmin {
        require(feeds[asset].feedAddress != address(0), "Feed not found");
        require(newFeedAddress != address(0), "Invalid feed address");

        feeds[asset].feedAddress = newFeedAddress;

        emit FeedUpdated(asset, newFeedAddress);
    }

    /**
     * @notice Pausa un feed específico
     * @dev Detiene las consultas de precio para un activo
     *
     * @param asset Dirección del activo a pausar
     *
     * @dev USO: En caso de emergencia o mantenimiento
     */
    function pauseFeed(address asset) external onlyFeedAdmin {
        feeds[asset].isPaused = true;
    }

    /**
     * @notice Despausa un feed específico
     * @dev Restaura las consultas de precio para un activo
     *
     * @param asset Dirección del activo a despausar
     */
    function unpauseFeed(address asset) external onlyFeedAdmin {
        feeds[asset].isPaused = false;
    }

    /**
     * @notice Establece el estado de pausa de un feed
     * @dev Función alternativa para pausar/despausar
     *
     * @param asset Dirección del activo
     * @param paused true para pausar, false para despausar
     */
    function setFeedPaused(address asset, bool paused) external onlyFeedAdmin {
        feeds[asset].isPaused = paused;
    }

    /**
     * @notice Actualiza el precio mock de un activo
     * @dev Solo para feeds con mockPrice > 0 (stablecoins)
     *
     * @param asset Dirección del activo
     * @param newMockPrice Nuevo precio mock (8 decimales)
     *
     * @dev RESTRICCIÓN: Solo DEFAULT_ADMIN_ROLE
     */
    function setMockPrice(address asset, uint256 newMockPrice) external onlyFeedAdmin {
        require(feeds[asset].mockPrice > 0, "Not a mock feed");
        require(newMockPrice > 0, "Invalid mock price");
        feeds[asset].mockPrice = newMockPrice;
    }

    // ========================================================================
    //                    FUNCIONES DE CONSULTA
    // ========================================================================

    /**
     * @notice Obtiene el precio actual de un activo
     * @dev Consulta Chainlink y valida el precio
     *
     * @param asset Dirección del activo
     * @return Precio actual en formato Chainlink
     *
     * @dev PASOS:
     *      1. Verificar que exista feed
     *      2. Verificar que no esté pausado
     *      3. Obtener datos de Chainlink
     *      4. Verificar precio válido (> 0)
     *      5. Verificar que no esté stale
     *      6. Verificar rango válido
     *      7. Retornar precio
     *
     * @dev ERRORES:
     *      - "Feed not found": No hay feed configurado
     *      - "Feed is paused": Feed está pausado
     *      - "Invalid price": Precio <= 0
     *      - "Stale price": Precio demasiado antiguo
     *      - "Price out of range": Fuera de rango min/max
     *
     * @dev EJEMPLO:
     *      getAssetPrice(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2)
     *      Retorna: 200000000000 (2000.00 USD con 8 decimales)
     */
    function getAssetPrice(address asset) external view returns (uint256) {
        // Obtener datos del feed
        FeedData storage feedData = feeds[asset];
        require(feedData.feedAddress != address(0) || feedData.mockPrice > 0, "Feed not found");
        require(!feedData.isPaused, "Feed is paused");

        uint256 priceUint;

        // Si hay mock price, usarlo (para stablecoins sin Chainlink feed)
        if (feedData.mockPrice > 0) {
            priceUint = feedData.mockPrice;
        } else {
            // Consultar Chainlink
            (
                ,
                int256 price,
                ,
                uint256 updatedAt,
            ) = IAggregatorV3Interface(feedData.feedAddress).latestRoundData();

            // Verificar precio válido
            require(price > 0, "Invalid price");
            // Verificar que no esté stale
            require(
                block.timestamp - updatedAt <= feedData.maxStalePeriod,
                "Stale price"
            );

            // Convertir a uint256
            priceUint = uint256(price);
        }

        // Verificar rango
        require(
            priceUint >= feedData.minPrice && priceUint <= feedData.maxPrice,
            "Price out of range"
        );

        return priceUint;
    }

    /**
     * @notice Obtiene precios de múltiples activos
     * @dev Función batch para optimizar gas
     *
     * @param assets Array de direcciones de activos
     * @return prices Array de precios correspondientes
     *
     * @dev USO: Para dashboards y interfaces que muestran múltiples precios
     */
    function getAssetsPrices(address[] calldata assets)
        external
        view
        returns (uint256[] memory prices)
    {
        prices = new uint256[](assets.length);
        for (uint256 i = 0; i < assets.length; i++) {
            prices[i] = this.getAssetPrice(assets[i]);
        }
    }

    // ========================================================================
    //                    FUNCIONES DE CONSULTA (VIEW)
    // ========================================================================

    /**
     * @notice Obtiene los datos completos de un feed
     * @param asset Dirección del activo
     * @return Datos del feed
     */
    function getFeedData(address asset) external view returns (FeedData memory) {
        return feeds[asset];
    }

    /**
     * @notice Obtiene todas las direcciones de activos con feed
     * @return Array de direcciones de activos
     */
    function getFeedAssets() external view returns (address[] memory) {
        return feedAssets;
    }
}
