// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title LendingPool
 * @notice Pool principal de lending/borrowing del protocolo CryptoBank
 * @dev Implementa un pool de liquidez donde los usuarios pueden:
 *      - Depositar activos para earn yield
 *      - Pedir préstamos colateralizados
 *      - Retirar sus depósitos
 *      - Pagar sus deudas
 *      - Liquidar posiciones unhealthy
 *
 * @dev INSPIRACIÓN: Aave V3 (versión simplificada)
 *
 * @dev ARQUITECTURA:
 *      ┌─────────────────────────────────────────────────┐
 *      │                  LendingPool                     │
 *      │  ┌──────────┐  ┌──────────┐  ┌──────────┐     │
 *      │  │ Reserves │  │  Users   │  │  Tokens  │     │
 *      │  │  (map)   │  │  (map)   │  │ (aTokens)│     │
 *      │  └──────────┘  └──────────┘  └──────────┘     │
 *      └─────────────────────────────────────────────────┘
 *
 * @dev FLUJO DE DEPÓSITO:
 *      1. Usuario aprueba tokens al pool
 *      2. Llama a supply(asset, amount, onBehalfOf)
 *      3. Pool actualiza estado (índices, tasas)
 *      4. Pool transfiere tokens del usuario
 *      5. Pool acuña aTokens al depositante
 *      6. Emite evento Supply
 *
 * @dev FLUJO DE PRÉSTAMO:
 *      1. Usuario tiene aTokens como colateral
 *      2. Llama a borrow(asset, amount, onBehalfOf)
 *      3. Pool verifica liquidez disponible
 *      4. Pool transfiere tokens al borrower
 *      5. Registra deuda del usuario
 *      6. Emite evento Borrow
 *
 * @dev SEGURIDAD:
 *      - ReentrancyGuard previene ataques de reentrancy
 *      - Pausable permite pausar el pool en emergencias
 *      - AccessControl para funciones administrativas
 *      - Checks-Effects-Interactions pattern
 */
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "../tokens/AToken.sol";
import "./InterestRateStrategy.sol";

/**
 * @title IPriceFeed
 * @notice Interfaz mínima para PriceFeed
 */
interface IPriceFeed {
    function getAssetPrice(address asset) external view returns (uint256);
}

contract LendingPool is Ownable, AccessControl, ReentrancyGuard, Pausable {
    // Usamos SafeERC20 para transferencias seguras
    using SafeERC20 for IERC20;

    // Usamos RayMath para cálculos de precisión
    using RayMath for uint256;

    // ========================================================================
    //                         ROLES Y PERMISOS
    // ========================================================================

    /**
     * @notice Rol para administradores del pool
     * @dev Permite inicializar reservas, pausar/despausar, etc.
     *      Solo el deployer inicializa con este rol
     */
    bytes32 public constant POOL_ADMIN_ROLE = keccak256("POOL_ADMIN_ROLE");

    // ========================================================================
    //                         CONSTANTES
    // ========================================================================

    /**
     * @notice Formato RAY: 27 decimales para cálculos internos
     */
    uint256 public constant RAY = 1e27;

    /**
     * @notice Factor de porcentaje: 10000 = 100%
     * @dev Usado para health factor y liquidaciones
     */
    uint256 public constant PERCENTAGE_FACTOR = 1e4;

    /**
     * @notice Factor de cierre para liquidaciones: 50%
     * @dev El liquidador puede cubrir hasta el 50% de la deuda
     */
    uint256 public constant LIQUIDATION_CLOSE_FACTOR = 5000;

    /**
     * @notice Bonus para liquidadores: 5%
     * @dev El liquidador recibe un 5% extra como incentivo
     */
    uint256 public constant LIQUIDATION_BONUS = 500;

    // ========================================================================
    //                         ESTRUCTURAS DE DATOS
    // ========================================================================

    /**
     * @notice Datos de una reserva (mercado de un activo)
     * @dev Cada activo soportado tiene su propia reserva
     *
     * @param isActive Si la reserva está activa para operaciones
     * @param isFrozen Si la reserva está congelada (sin nuevas operaciones)
     * @param isPaused Si la reserva está pausada
     * @param liquidityIndex Índice acumulado de liquidez (RAY)
     * @param currentLiquidityRate Tasa actual de liquidez (RAY)
     * @param variableBorrowIndex Índice acumulado de deuda variable (RAY)
     * @param currentVariableBorrowRate Tasa actual de deuda variable (RAY)
     * @param lastUpdateTimestamp Timestamp de última actualización
     * @param liquidityCap Límite máximo de liquidez
     * @param borrowCap Límite máximo de préstamos
     * @param aTokenAddress Dirección del aToken correspondiente
     * @param interestRateStrategyAddress Dirección de la estrategia de tasas
     * @param reserveFactor Porcentaje de intereses para el tesoro (RAY)
     * @param liquidationThreshold Umbral de liquidación (en RAY, ej: 0.8e27 = 80%)
     * @param priceFeedAddress Dirección del PriceFeed para este activo
     * @param totalScaledVariableDebt Deuda variable total escalada (RAY)
     */
    struct ReserveData {
        bool isActive;
        bool isFrozen;
        bool isPaused;
        uint128 liquidityIndex;
        uint128 currentLiquidityRate;
        uint128 variableBorrowIndex;
        uint128 currentVariableBorrowRate;
        uint40 lastUpdateTimestamp;
        uint256 liquidityCap;
        uint256 borrowCap;
        address aTokenAddress;
        address interestRateStrategyAddress;
        uint256 reserveFactor;
        uint256 liquidationThreshold;
        address priceFeedAddress;
        uint256 totalScaledVariableDebt;
    }

    /**
     * @notice Datos de un usuario para una reserva específica
     * @dev Trackea balances y deudas del usuario en un activo
     *
     * @param currentATokenBalance Balance actual de aTokens (escalado)
     * @param currentStableDebt Deuda estable actual
     * @param currentVariableDebt Deuda variable actual (escalada)
     * @param principalStableDebt Deuda estable principal
     * @param stableBorrowRate Tasa de la deuda estable
     * @param stableRateLastUpdated Timestamp de última actualización de tasa estable
     * @param usageAsCollateralEnabled Si el usuario usa este activo como colateral
     */
    struct UserReserveData {
        uint256 currentATokenBalance;
        uint256 currentStableDebt;
        uint256 currentVariableDebt;
        uint256 principalStableDebt;
        uint256 stableBorrowRate;
        uint40 stableRateLastUpdated;
        bool usageAsCollateralEnabled;
    }

    // ========================================================================
    //                         ESTADO DEL CONTRATO
    // ========================================================================

    /**
     * @notice Mapping de reservas por dirección de activo
     * @dev Key: dirección del token ERC20
     *      Value: datos de la reserva
     */
    mapping(address => ReserveData) public reserves;

    /**
     * @notice Mapping de datos de usuario por reserva
     * @dev Key1: dirección del usuario
     *      Key2: dirección del activo
     *      Value: datos del usuario en esa reserva
     */
    mapping(address => mapping(address => UserReserveData)) public userReserves;

    /**
     * @notice Array de direcciones de activos con reserva activa
     * @dev Usado para iterar sobre todas las reservas
     */
    address[] public reserveAssets;

    // ========================================================================
    //                         EVENTOS
    // ========================================================================

    /**
     * @notice Emitido cuando un usuario deposita activos
     * @param reserve Dirección del activo depositado
     * @param user Dirección del depositante
     * @param amount Cantidad depositada
     */
    event Supply(address indexed reserve, address indexed user, uint256 amount);

    /**
     * @notice Emitido cuando un usuario retira activos
     * @param reserve Dirección del activo retirado
     * @param user Dirección del usuario
     * @param amount Cantidad retirada
     */
    event Withdraw(address indexed reserve, address indexed user, uint256 amount);

    /**
     * @notice Emitido cuando un usuario pide un préstamo
     * @param reserve Dirección del activo prestado
     * @param user Dirección del borrower
     * @param amount Cantidad prestada
     */
    event Borrow(address indexed reserve, address indexed user, uint256 amount);

    /**
     * @notice Emitido cuando un usuario paga su deuda
     * @param reserve Dirección del activo pagado
     * @param user Dirección del pagador
     * @param amount Cantidad pagada
     */
    event Repay(address indexed reserve, address indexed user, uint256 amount);

    /**
     * @notice Emitido cuando se liquid una posición
     * @param collateralAsset Dirección del colateral liquidado
     * @param debtAsset Dirección de la deuda pagada
     * @param user Dirección del usuario liquidado
     * @param amount Cantidad de deuda liquidada
     */
    event Liquidation(address indexed collateralAsset, address indexed debtAsset, address indexed user, uint256 amount);

    // ========================================================================
    //                         MODIFICADORES
    // ========================================================================

    /**
     * @notice Modificador que restringe funciones a administradores del pool
     * @dev Verifica que msg.sender tenga el POOL_ADMIN_ROLE
     */
    modifier onlyPoolAdmin() {
        require(hasRole(POOL_ADMIN_ROLE, msg.sender), "Caller must be pool admin");
        _;
    }

    // ========================================================================
    //                         CONSTRUCTOR
    // ========================================================================

    /**
     * @notice Constructor del LendingPool
     * @dev Inicializa el pool con el deployer como admin
     *
     * @dev PASOS:
     *      1. Inicializa Ownable con msg.sender
     *      2. Otorga DEFAULT_ADMIN_ROLE a msg.sender
     *      3. Otorga POOL_ADMIN_ROLE a msg.sender
     */
    constructor() Ownable(msg.sender) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(POOL_ADMIN_ROLE, msg.sender);
    }

    // ========================================================================
    //                    FUNCIONES ADMINISTRATIVAS
    // ========================================================================

/**
     * @notice Inicializa una nueva reserva para un activo
     * @dev Crea el aToken correspondiente y configura la reserva
     *
     * @param asset Dirección del token ERC20 a soportar
     * @param interestRateStrategyAddress Dirección de la estrategia de tasas
     * @param liquidationThreshold Umbral de liquidación en RAY (ej: 0.8e27 = 80%)
     * @param priceFeedAddress Dirección del PriceFeed para este activo
     *
     * @dev PASOS:
     *      1. Verificar que no exista una reserva para este activo
     *      2. Aprueba que el pool pueda manejar los tokens
     *      3. Crea un nuevo AToken para este activo
     *      4. Inicializa la reserva con valores por defecto
     *      5. Agrega el activo al array de reservas
     *
     * @dev RESTRICCIÓN: Solo POOL_ADMIN_ROLE
     */
    function initReserve(
        address asset,
        address interestRateStrategyAddress,
        uint256 liquidationThreshold,
        address priceFeedAddress
    ) external onlyPoolAdmin {
        // Verificar que la reserva no exista
        require(!reserves[asset].isActive, "Reserve already initialized");

        // Aprobar que el pool pueda manejar tokens (ilimitado para simplificar)
        IERC20(asset).forceApprove(address(this), type(uint256).max);

        // Crear el aToken para este activo
        AToken aToken = new AToken(
            string(abi.encodePacked("A", IERC20Metadata(asset).name())),
            string(abi.encodePacked("A", IERC20Metadata(asset).symbol())),
            asset,
            address(this)
        );

        // Inicializar la reserva con valores por defecto
        reserves[asset] = ReserveData({
            isActive: true,
            isFrozen: false,
            isPaused: false,
            liquidityIndex: uint128(RAY),           // Índice inicial = 1.0 en RAY
            currentLiquidityRate: 0,
            variableBorrowIndex: uint128(RAY),      // Índice inicial = 1.0 en RAY
            currentVariableBorrowRate: 0,
            lastUpdateTimestamp: uint40(block.timestamp),
            liquidityCap: 0,
            borrowCap: 0,
            aTokenAddress: address(aToken),
            interestRateStrategyAddress: interestRateStrategyAddress,
            reserveFactor: 0,
            liquidationThreshold: liquidationThreshold,
            priceFeedAddress: priceFeedAddress,
            totalScaledVariableDebt: 0
        });

        // Agregar el activo al array de reservas
        reserveAssets.push(asset);
    }

    // ========================================================================
    //                    FUNCIONES PRINCIPALES
    // ========================================================================

    /**
     * @notice Deposita activos en el pool para earn yield
     * @dev El usuario recibe aTokens que representan su depósito
     *
     * @param asset Dirección del token a depositar
     * @param amount Cantidad a depositar
     * @param onBehalfOf Dirección que recibirá los aTokens
     * @return amount Cantidad depositada
     *
     * @dev PASOS:
     *      1. Verificar que la reserva esté activa y no congelada
     *      2. Actualizar el estado de la reserva (índices, tasas)
     *      3. Verificar liquidity cap
     *      4. Acuñar aTokens al depositante
     *      5. Transferir tokens del usuario al pool
     *      6. Emitir evento Supply
     *
     * @dev RESTRICCIÓN: noReentrant, whenNotPaused
     */
    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf
    ) external nonReentrant whenNotPaused returns (uint256) {
        // Verificar que la reserva esté activa
        require(reserves[asset].isActive, "Reserve not active");
        // Verificar que la reserva no esté congelada
        require(!reserves[asset].isFrozen, "Reserve is frozen");

        // Actualizar estado de la reserva
        _updateState(asset);

        // Obtener referencia a la reserva
        ReserveData storage reserve = reserves[asset];

        // Verificar liquidity cap
        if (reserve.liquidityCap > 0) {
            uint256 currentDeposits = _getTotalDeposits(asset);
            require(currentDeposits + amount <= reserve.liquidityCap, "Liquidity cap exceeded");
        }

        // Acuñar aTokens al depositante
        AToken(reserve.aTokenAddress).mint(onBehalfOf, amount, uint256(reserve.liquidityIndex));

        // Actualizar balance del usuario
        UserReserveData storage userReserve = userReserves[onBehalfOf][asset];
        userReserve.currentATokenBalance += amount.rayDiv(uint256(reserve.liquidityIndex));

        // Transferir tokens del usuario al pool
        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);

        // Emitir evento
        emit Supply(asset, onBehalfOf, amount);
        return amount;
    }

    /**
     * @notice Retira activos del pool
     * @dev Quema aTokens y devuelve los activos subyacentes
     *
     * @param asset Dirección del token a retirar
     * @param amount Cantidad a retirar (type(uint256).max para todo)
     * @param to Dirección que recibirá los tokens
     * @return amount Cantidad retirada
     *
     * @dev PASOS:
     *      1. Verificar que la reserva esté activa
     *      2. Actualizar estado de la reserva
     *      3. Calcular cantidad a retirar
     *      4. Verificar balance suficiente
     *      5. Quemar aTokens
     *      6. Transferir tokens al usuario
     *      7. Emitir evento Withdraw
     *
     * @dev RESTRICCIÓN: noReentrant, whenNotPaused
     */
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external nonReentrant whenNotPaused returns (uint256) {
        // Verificar que la reserva esté activa
        require(reserves[asset].isActive, "Reserve not active");

        // Actualizar estado
        _updateState(asset);

        // Obtener datos del usuario y reserva
        UserReserveData storage userReserve = userReserves[msg.sender][asset];
        ReserveData storage reserve = reserves[asset];

        // Calcular cantidad a retirar
        uint256 amountToWithdraw = amount;
        if (amount == type(uint256).max) {
            // Si amount es max, retirar todo el balance del usuario
            amountToWithdraw = userReserve.currentATokenBalance.rayMul(uint256(reserve.liquidityIndex));
        }

        // Verificar que el usuario tenga suficiente balance
        uint256 userBalance = userReserve.currentATokenBalance.rayMul(uint256(reserve.liquidityIndex));
        require(amountToWithdraw <= userBalance, "Insufficient balance");

        // Actualizar balance del usuario
        userReserve.currentATokenBalance -= amountToWithdraw.rayDiv(uint256(reserve.liquidityIndex));

        // Quemar aTokens
        AToken(reserve.aTokenAddress).burn(msg.sender, amountToWithdraw, uint256(reserve.liquidityIndex));

        // Transferir tokens al usuario
        IERC20(asset).safeTransfer(to, amountToWithdraw);

        // Emitir evento
        emit Withdraw(asset, msg.sender, amountToWithdraw);
        return amountToWithdraw;
    }

    /**
     * @notice Pide un préstamo del pool
     * @dev Requiere colateral suficiente (no implementado completamente)
     *
     * @param asset Dirección del token a pedir prestado
     * @param amount Cantidad a pedir prestado
     * @param onBehalfOf Dirección que recibirá los tokens
     * @return amount Cantidad prestada
     *
     * @dev PASOS:
     *      1. Verificar que la reserva esté activa y no congelada
     *      2. Actualizar estado
     *      3. Verificar liquidez disponible
     *      4. Registrar deuda del usuario
     *      5. Transferir tokens al borrower
     *      6. Emitir evento Borrow
     *
     * @dev RESTRICCIÓN: noReentrant, whenNotPaused
     */
    function borrow(
        address asset,
        uint256 amount,
        address onBehalfOf
    ) external nonReentrant whenNotPaused returns (uint256) {
        // Verificar reserva activa
        require(reserves[asset].isActive, "Reserve not active");
        // Verificar reserva no congelada
        require(!reserves[asset].isFrozen, "Reserve is frozen");

        // Actualizar estado
        _updateState(asset);

        // Obtener referencia a la reserva
        ReserveData storage reserve = reserves[asset];

        // Verificar liquidez disponible
        uint256 totalDeposits = _getTotalDeposits(asset);
        uint256 totalBorrows = _getTotalBorrows(asset);

        require(totalDeposits - totalBorrows >= amount, "Insufficient liquidity");

        // Verificar borrow cap
        if (reserve.borrowCap > 0) {
            uint256 currentTotalBorrows = reserve.totalScaledVariableDebt.rayMul(uint256(reserve.variableBorrowIndex));
            require(currentTotalBorrows + amount <= reserve.borrowCap, "Borrow cap exceeded");
        }

        // Registrar deuda del usuario
        UserReserveData storage userReserve = userReserves[onBehalfOf][asset];
        uint256 scaledAmount = amount.rayDiv(uint256(reserve.variableBorrowIndex));
        userReserve.currentVariableDebt += scaledAmount;

        // Actualizar deuda total escalada de la reserva
        reserve.totalScaledVariableDebt += scaledAmount;

        // Transferir tokens al borrower
        IERC20(asset).safeTransfer(onBehalfOf, amount);

        // Emitir evento
        emit Borrow(asset, onBehalfOf, amount);
        return amount;
    }

    /**
     * @notice Paga una deuda existente
     * @dev Reduce la deuda del usuario y quita tokens del pagador
     *
     * @param asset Dirección del token con el que se paga
     * @param amount Cantidad a pagar (type(uint256).max para toda la deuda)
     * @param onBehalfOf Dirección cuya deuda se pagará
     * @return amount Cantidad pagada
     *
     * @dev PASOS:
     *      1. Verificar que la reserva esté activa
     *      2. Actualizar estado
     *      3. Calcular deuda actual del usuario
     *      4. Determinar cantidad a pagar
     *      5. Reducir deuda del usuario
     *      6. Transferir tokens del pagador al pool
     *      7. Emitir evento Repay
     *
     * @dev RESTRICCIÓN: noReentrant, whenNotPaused
     */
    function repay(
        address asset,
        uint256 amount,
        address onBehalfOf
    ) external nonReentrant whenNotPaused returns (uint256) {
        // Verificar reserva activa
        require(reserves[asset].isActive, "Reserve not active");

        // Actualizar estado
        _updateState(asset);

        // Obtener datos
        UserReserveData storage userReserve = userReserves[onBehalfOf][asset];
        ReserveData storage reserve = reserves[asset];

        // Calcular deuda actual
        uint256 userDebt = userReserve.currentVariableDebt.rayMul(uint256(reserve.variableBorrowIndex));

        // Determinar cantidad a pagar
        uint256 amountToRepay = amount;
        if (amount == type(uint256).max) {
            amountToRepay = userDebt;
        }

        // Verificar que no se pague más de lo adeudado
        require(amountToRepay <= userDebt, "Repay amount exceeds debt");

        // Reducir deuda del usuario
        uint256 scaledRepay = amountToRepay.rayDiv(uint256(reserve.variableBorrowIndex));
        userReserve.currentVariableDebt -= scaledRepay;

        // Actualizar deuda total escalada de la reserva
        reserve.totalScaledVariableDebt -= scaledRepay;

        // Transferir tokens del pagador al pool
        IERC20(asset).safeTransferFrom(msg.sender, address(this), amountToRepay);

        // Emitir evento
        emit Repay(asset, onBehalfOf, amountToRepay);
        return amountToRepay;
    }

    /**
     * @notice Liquida una posición unhealthy
     * @dev Permite a liquidadores cerrar posiciones con health factor < 1
     *
     * @param collateralAsset Dirección del colateral a liquidar
     * @param debtAsset Dirección de la deuda a cubrir
     * @param user Dirección del usuario a liquidar
     * @param debtToCover Cantidad de deuda a cubrir
     * @return amount Cantidad de deuda liquidada
     *
     * @dev PASOS:
     *      1. Verificar reserva activa
     *      2. Actualizar estado de ambas reservas
     *      3. Calcular deuda del usuario
     *      4. Verificar health factor < 1
     *      5. Calcular colateral a transferir (deuda + 5% bonus)
     *      6. Reducir deuda del usuario
     *      7. Reducir colateral del usuario
     *      8. Transferir colateral al liquidador
     *      9. Transferir deuda del liquidador al pool
     *      10. Emitir evento Liquidation
     *
     * @dev RESTRICCIÓN: noReentrant, whenNotPaused
     */
    function liquidate(
        address collateralAsset,
        address debtAsset,
        address user,
        uint256 debtToCover
    ) external nonReentrant whenNotPaused returns (uint256) {
        // Verificar reserva activa
        require(reserves[debtAsset].isActive, "Reserve not active");

        // Actualizar estado de ambas reservas
        _updateState(debtAsset);
        _updateState(collateralAsset);

        // Obtener datos del usuario
        UserReserveData storage userDebtReserve = userReserves[user][debtAsset];
        ReserveData storage debtReserve = reserves[debtAsset];

        // Calcular deuda actual del usuario
        uint256 userDebt = userDebtReserve.currentVariableDebt.rayMul(uint256(debtReserve.variableBorrowIndex));

        // Verificar que la posición sea liquidable (health factor < 1)
        uint256 healthFactor = _calculateHealthFactor(user);
        require(healthFactor < PERCENTAGE_FACTOR, "Position is not liquidatable");

        // Determinar cantidad de deuda a cubrir
        uint256 debtAmountCovered = debtToCover;
        if (debtAmountCovered > userDebt) {
            debtAmountCovered = userDebt;
        }

        // Calcular colateral a transferir (deuda + 5% bonus)
        uint256 collateralAmount = (debtAmountCovered * (PERCENTAGE_FACTOR + LIQUIDATION_BONUS)) / PERCENTAGE_FACTOR;

        // Reducir deuda del usuario
        uint256 scaledDebtCovered = debtAmountCovered.rayDiv(uint256(debtReserve.variableBorrowIndex));
        userDebtReserve.currentVariableDebt -= scaledDebtCovered;

        // Actualizar deuda total escalada de la reserva
        debtReserve.totalScaledVariableDebt -= scaledDebtCovered;

        // Obtener datos del colateral
        UserReserveData storage userCollateralReserve = userReserves[user][collateralAsset];
        ReserveData storage collateralReserve = reserves[collateralAsset];

        // Reducir colateral del usuario
        userCollateralReserve.currentATokenBalance -= collateralAmount.rayDiv(uint256(collateralReserve.liquidityIndex));

        // Quemar aTokens del usuario
        AToken(collateralReserve.aTokenAddress).burn(user, collateralAmount, uint256(collateralReserve.liquidityIndex));

        // Transferir colateral al liquidador
        IERC20(collateralAsset).safeTransfer(msg.sender, collateralAmount);

        // Transferir deuda del liquidador al pool
        IERC20(debtAsset).safeTransferFrom(msg.sender, address(this), debtAmountCovered);

        // Emitir evento
        emit Liquidation(collateralAsset, debtAsset, user, debtAmountCovered);
        return debtAmountCovered;
    }

    // ========================================================================
    //                    FUNCIONES INTERNAS
    // ========================================================================

    /**
     * @notice Actualiza el estado de una reserva
     * @dev Recalcula tasas de interés y actualiza índices
     *
     * @param asset Dirección del activo a actualizar
     *
     * @dev PASOS:
     *      1. Obtener timestamp actual
     *      2. Si hay estrategia de tasas, calcular nuevas tasas
     *      3. Actualizar timestamp y tasas en la reserva
     */
    function _updateState(address asset) internal {
        ReserveData storage reserve = reserves[asset];

        uint40 timestamp = uint40(block.timestamp);
        uint256 liquidityRate = 0;
        uint256 variableBorrowRate = 0;

        // Si hay estrategia de tasas, calcular tasas actuales
        if (reserve.interestRateStrategyAddress != address(0)) {
            (liquidityRate, variableBorrowRate) = IInterestRateStrategy(reserve.interestRateStrategyAddress)
                .calculateInterestRates(
                    _getTotalDeposits(asset),
                    _getTotalBorrows(asset),
                    reserve.reserveFactor,
                    0
                );
        }

        // Actualizar reserva con nuevos valores
        reserve.lastUpdateTimestamp = timestamp;
        reserve.currentLiquidityRate = uint128(liquidityRate);
        reserve.currentVariableBorrowRate = uint128(variableBorrowRate);
    }

    /**
     * @notice Obtiene el total de depósitos de un activo
     * @dev Retorna el supply total escalado del aToken
     *
     * @param asset Dirección del activo
     * @return Total de depósitos
     */
    function _getTotalDeposits(address asset) internal view returns (uint256) {
        return AToken(reserves[asset].aTokenAddress).scaledTotalSupply();
    }

    /**
     * @notice Obtiene el total de préstamos de un activo
     * @dev Retorna la deuda variable total escalada * variableBorrowIndex
     *
     * @param asset Dirección del activo
     * @return Total de préstamos
     */
    function _getTotalBorrows(address asset) internal view returns (uint256) {
        ReserveData storage reserve = reserves[asset];
        return reserve.totalScaledVariableDebt.rayMul(uint256(reserve.variableBorrowIndex));
    }

    /**
     * @notice Obtiene el precio de un activo desde PriceFeed
     * @param asset Dirección del activo
     * @return Precio en USD (8 decimales) o 0 si no hay feed
     */
    function _getAssetPrice(address asset) internal view returns (uint256) {
        ReserveData storage reserve = reserves[asset];
        if (reserve.priceFeedAddress == address(0)) {
            return 0;
        }
        try IPriceFeed(reserve.priceFeedAddress).getAssetPrice(asset) returns (uint256 price) {
            return price;
        } catch {
            return 0;
        }
    }

    /**
     * @notice Calcula el health factor de un usuario
     * @dev Health Factor = (Sum(collateral * price * liquidationThreshold)) / Sum(debt * price)
     *      Si no hay deuda, retorna type(uint256).max (infinito)
     *
     * @param user Dirección del usuario
     * @return Health factor en RAY (1e27 = 100%)
     */
    function _calculateHealthFactor(address user) internal view returns (uint256) {
        uint256 totalCollateral = 0;
        uint256 totalDebt = 0;

        for (uint256 i = 0; i < reserveAssets.length; i++) {
            address asset = reserveAssets[i];
            ReserveData storage reserve = reserves[asset];
            UserReserveData storage userReserve = userReserves[user][asset];

            uint256 price = _getAssetPrice(asset);
            if (price == 0) continue;

            // Collateral value
            if (userReserve.currentATokenBalance > 0 && reserve.liquidationThreshold > 0) {
                uint256 collateralAmt = userReserve.currentATokenBalance.rayMul(uint256(reserve.liquidityIndex));
                uint256 weighted = (collateralAmt * price) / 1e8;
                weighted = (weighted * reserve.liquidationThreshold) / RAY;
                totalCollateral += weighted;
            }

            // Debt value
            if (userReserve.currentVariableDebt > 0) {
                uint256 debtAmt = userReserve.currentVariableDebt.rayMul(uint256(reserve.variableBorrowIndex));
                totalDebt += (debtAmt * price) / 1e8;
            }
        }

        if (totalDebt == 0) {
            return type(uint256).max;
        }

        return (totalCollateral * RAY) / totalDebt;
    }

    // ========================================================================
    //                    FUNCIONES DE CONSULTA (VIEW)
    // ========================================================================

    /**
     * @notice Obtiene los datos de una reserva
     * @param asset Dirección del activo
     * @return Datos de la reserva
     */
    function getReserveData(address asset) external view returns (ReserveData memory) {
        return reserves[asset];
    }

    /**
     * @notice Obtiene los datos de un usuario para una reserva
     * @param asset Dirección del activo
     * @param user Dirección del usuario
     * @return Datos del usuario en esa reserva
     */
    function getUserReserveData(address asset, address user) external view returns (UserReserveData memory) {
        return userReserves[user][asset];
    }

    /**
     * @notice Obtiene todas las direcciones de reservas activas
     * @return Array de direcciones de activos
     */
    function getReserves() external view returns (address[] memory) {
        return reserveAssets;
    }

    // ========================================================================
    //                    FUNCIONES ADMINISTRATIVAS (CAPS)
    // ========================================================================

    /**
     * @notice Establece el límite máximo de liquidez para una reserva
     * @dev Solo POOL_ADMIN_ROLE puede llamar esta función
     *
     * @param asset Dirección del activo
     * @param cap Límite máximo (0 = sin límite)
     */
    function setLiquidityCap(address asset, uint256 cap) external onlyPoolAdmin {
        require(reserves[asset].isActive, "Reserve not active");
        reserves[asset].liquidityCap = cap;
    }

    /**
     * @notice Establece el límite máximo de préstamos para una reserva
     * @dev Solo POOL_ADMIN_ROLE puede llamar esta función
     *
     * @param asset Dirección del activo
     * @param cap Límite máximo (0 = sin límite)
     */
    function setBorrowCap(address asset, uint256 cap) external onlyPoolAdmin {
        require(reserves[asset].isActive, "Reserve not active");
        reserves[asset].borrowCap = cap;
    }

    // ========================================================================
    //                    FUNCIONES DE EMERGENCIA
    // ========================================================================

    /**
     * @notice Pausa el pool - bloquea todas las operaciones
     * @dev Solo POOL_ADMIN_ROLE puede pausar
     *
     * @dev USO: En caso de exploit o emergencia de seguridad
     */
    function pause() external onlyPoolAdmin {
        _pause();
    }

    /**
     * @notice Despausa el pool - restaura operaciones
     * @dev Solo POOL_ADMIN_ROLE puede despausar
     *
     * @dev USO: Después de resolver una emergencia
     */
    function unpause() external onlyPoolAdmin {
        _unpause();
    }
}
