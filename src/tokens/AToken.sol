// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @title RayMath
 * @notice Biblioteca de matemáticas en formato RAY (27 decimales)
 * @dev Utilizada por AToken y LendingPool para cálculos de precisión
 *      en operaciones de lending/borrowing
 *
 * @dev CONCEPTOS CLAVE:
 *      - WAD: 1e18 (18 decimales) - para cantidades normales
 *      - RAY: 1e27 (27 decimales) - para cálculos internos de precisión
 *      - HALF_RAY: 1e27 / 2 - para redondeo
 *      - WAD_RAY_RATIO: 1e9 - factor de conversión entre WAD y RAY
 *
 * @dev FORMULAS:
 *      - rayMul(a, b) = (a * b + HALF_RAY) / RAY
 *      - rayDiv(a, b) = (a * RAY + HALF_RAY) / b
 *      - rayToWad(a) = a / WAD_RAY_RATIO
 *      - wadToRay(a) = a * WAD_RAY_RATIO
 */
library RayMath {
    // Constante para redondeo: mitad de RAY
    uint256 internal constant HALF_RAY = 1e27 / 2;

    // Constante WAD: 18 decimales para cantidades
    uint256 internal constant WAD = 1e18;

    // Constante RAY: 27 decimales para precisión interna
    uint256 internal constant RAY = 1e27;

    // Ratio de conversión WAD a RAY
    uint256 internal constant WAD_RAY_RATIO = 1e9;

    /**
     * @notice Multiplica dos números en formato RAY
     * @dev Implementa (a * b) / RAY con redondeo
     *      Previene overflow verificando límites antes de la multiplicación
     *
     * @param a Primer operando en formato RAY
     * @param b Segundo operando en formato RAY
     * @return Resultado de la multiplicación en formato RAY
     *
     * @dev FÓRMULA: (a * b + HALF_RAY) / RAY
     * @dev VALIDACIÓN: b <= (type(uint256).max - HALF_RAY) / a
     */
    function rayMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) return 0;
        require(b <= (type(uint256).max - HALF_RAY) / a, "RayMath: multiplication overflow");
        return (a * b + HALF_RAY) / RAY;
    }

    /**
     * @notice Divide dos números en formato RAY
     * @dev Implementa (a * RAY) / b con redondeo
     *      Previene división por cero y overflow
     *
     * @param a Dividendo en formato RAY
     * @param b Divisor en formato RAY
     * @return Resultado de la división en formato RAY
     *
     * @dev FÓRMULA: (a * RAY + HALF_RAY) / b
     * @dev VALIDACIÓN: b != 0 Y a <= (type(uint256).max - HALF_RAY) / b
     */
    function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "RayMath: division by zero");
        require(a <= (type(uint256).max - HALF_RAY) / b, "RayMath: division overflow");
        return (a * RAY + HALF_RAY) / b;
    }

    /**
     * @notice Convierte de RAY a WAD
     * @dev Divide por WAD_RAY_RATIO con redondeo
     *
     * @param a Valor en formato RAY
     * @return Valor convertido a formato WAD
     *
     * @dev USO: Cuando necesitamos mostrar valores al usuario
     */
    function rayToWad(uint256 a) internal pure returns (uint256) {
        return a / WAD_RAY_RATIO + (a % WAD_RAY_RATIO >= WAD_RAY_RATIO / 2 ? 1 : 0);
    }

    /**
     * @notice Convierte de WAD a RAY
     * @dev Multiplica por WAD_RAY_RATIO
     *
     * @param a Valor en formato WAD
     * @return Valor convertido a formato RAY
     *
     * @dev USO: Cuando necesitamos mayor precisión en cálculos
     */
    function wadToRay(uint256 a) internal pure returns (uint256) {
        return a * WAD_RAY_RATIO;
    }
}

/**
 * @title IAToken
 * @notice Interfaz del token de yield (aToken)
 * @dev Define las funciones que debe implementar un token de yield
 *      similar a los aTokens de Aave
 */
interface IAToken {
    /**
     * @notice Obtiene el balance escalado de un usuario
     * @dev El balance escalado se usa para cálculos internos
     *      No representa el balance real del usuario
     */
    function scaledBalanceOf(address user) external view returns (uint256);

    /**
     * @notice Obtiene el supply total escalado
     * @dev Suma de todos los balances escalados
     */
    function scaledTotalSupply() external view returns (uint256);

    /**
     * @notice Obtiene el balance subyacente de un usuario
     * @dev Balance real en tokens subyacentes (no escalado)
     */
    function getUnderlyingBalance(address user) external view returns (uint256);

    /**
     * @notice Acuña tokens aTokens por depósito
     * @dev Solo el pool puede llamar esta función
     */
    function mint(address user, uint256 amount, uint256 index) external returns (bool);

    /**
     * @notice Quema tokens aTokens por retiro
     * @dev Solo el pool puede llamar esta función
     */
    function burn(address user, uint256 amount, uint256 index) external returns (bool);
}

/**
 * @title AToken
 * @notice Token de yield que representa depósitos en el pool de lending
 * @dev Similar a los aTokens de Aave, representa una reclamación sobre
 *      los activos depositados en el pool. El balance aumenta con el tiempo
 *      debido a los intereses generados por los borrowers.
 *
 * @dev FLUJO DE FUNCIONAMIENTO:
 *      1. Usuario deposita activos en LendingPool
 *      2. LendingPool llama a AToken.mint()
 *      3. AToken acuña tokens al usuario
 *      4. El balance crece con los intereses
 *      5. Usuario retira y LendingPool llama a AToken.burn()
 *
 * @dev HERENCIA:
 *      ERC20 → Token estándar con balances y transferencias
 *      IAToken → Interfaz específica para tokens de yield
 *      Ownable → Control de acceso al pool
 */
contract AToken is ERC20, IAToken, Ownable {
    // Usamos la biblioteca RayMath para cálculos de precisión
    using RayMath for uint256;

    // ========================================================================
    //                        VARIABLES INMUTABLES
    // ========================================================================

    /**
     * @notice Dirección del activo subyacente (ej: WETH, USDC)
     * @dev Es inmutable porque no cambia después del deploy
     *      Permite saber qué token representa este aToken
     */
    address public immutable UNDERLYING_ASSET_ADDRESS;

    /**
     * @notice Dirección del contrato LendingPool
     * @dev Solo el pool puede mintear y quemar tokens
     *      Es inmutable porque el pool no cambia
     */
    address public immutable POOL;

    // ========================================================================
    //                         CONSTRUCTOR
    // ========================================================================

    /**
     * @notice Constructor del AToken
     * @dev Inicializa el token de yield con sus parámetros
     *
     * @param name Nombre del token (ej: "A Wrapped Ether")
     * @param symbol Símbolo del token (ej: "aWETH")
     * @param underlyingAsset Dirección del token subyacente
     * @param pool Dirección del LendingPool que controlará este token
     *
     * @dev PASOS:
     *      1. Inicializa ERC20 con nombre y símbolo
     *      2. Inicializa Ownable con msg.sender
     *      3. Guarda dirección del activo subyacente (inmutable)
     *      4. Guarda dirección del pool (inmutable)
     */
    constructor(
        string memory name,
        string memory symbol,
        address underlyingAsset,
        address pool
    ) ERC20(name, symbol) Ownable(msg.sender) {
        UNDERLYING_ASSET_ADDRESS = underlyingAsset;
        POOL = pool;
    }

    // ========================================================================
    //                         MODIFICADORES
    // ========================================================================

    /**
     * @notice Modificador que restringe funciones al pool
     * @dev Solo el LendingPool puede mintear/burnear tokens
     *
     * @dev USO: modifier onlyPool() en mint() y burn()
     */
    modifier onlyPool() {
        require(msg.sender == POOL, "AToken: caller must be pool");
        _;
    }

    // ========================================================================
    //                    FUNCIONES DE CONSULTA (VIEW)
    // ========================================================================

    /**
     * @notice Obtiene el balance escalado de un usuario
     * @dev Retorna 0 como implementación simplificada
     *      En producción, trackearía balances por usuario con precisión RAY
     *
     * @param user Dirección del usuario
     * @return Balance escalado del usuario (siempre 0 en versión simplificada)
     */
    function scaledBalanceOf(address user) public view override returns (uint256) {
        return 0;
    }

    /**
     * @notice Obtiene el supply total escalado
     * @dev Retorna el supply total del ERC20
     *      En producción, mantendría un tracking separado de scaled balances
     *
     * @return Supply total escalado
     */
    function scaledTotalSupply() public view override returns (uint256) {
        return totalSupply();
    }

    /**
     * @notice Obtiene el balance subyacente de un usuario
     * @dev Retorna el balance ERC20 estándar del usuario
     *
     * @param user Dirección del usuario
     * @return Balance en tokens subyacentes
     */
    function getUnderlyingBalance(address user) external view override returns (uint256) {
        return super.balanceOf(user);
    }

    // ========================================================================
    //                    FUNCIONES DE MUTACIÓN
    // ========================================================================

    /**
     * @notice Acuña nuevos aTokens para un usuario
     * @dev Solo el LendingPool puede llamar esta función
     *      Se llama cuando un usuario deposita activos
     *
     * @param user Dirección que recibirá los aTokens
     * @param amount Cantidad de tokens a acuñar
     * @return true si la operación fue exitosa
     *
     * @dev PASOS:
     *      1. Verifica que msg.sender es el pool (onlyPool)
     *      2. Acuña 'amount' tokens al usuario
     *      3. Retorna true
     *
     * @dev NOTA: En producción, se usaría el index para calcular
     *           scaled amounts y trackear yield
     */
    function mint(
        address user,
        uint256 amount,
        uint256
    ) external override onlyPool returns (bool) {
        _mint(user, amount);
        return true;
    }

    /**
     * @notice Quema aTokens de un usuario
     * @dev Solo el LendingPool puede llamar esta función
     *      Se llama cuando un usuario retira activos
     *
     * @param user Dirección cuyos tokens serán quemados
     * @param amount Cantidad de tokens a quemar
     * @return true si la operación fue exitosa
     *
     * @dev PASOS:
     *      1. Verifica que msg.sender es el pool (onlyPool)
     *      2. Verifica que 'user' tenga suficiente balance
     *      3. Quema los tokens
     *      4. Retorna true
     */
    function burn(
        address user,
        uint256 amount,
        uint256
    ) external override onlyPool returns (bool) {
        _burn(user, amount);
        return true;
    }
}
