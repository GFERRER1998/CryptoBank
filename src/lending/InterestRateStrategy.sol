// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../tokens/AToken.sol";

/**
 * @title IInterestRateStrategy
 * @notice Interfaz para estrategias de tasas de interés
 * @dev Define el contrato que calcula tasas basadas en utilización
 */
interface IInterestRateStrategy {
    /**
     * @notice Calcula las tasas de interés actuales
     * @param totalDeposits Total de depósitos en el pool
     * @param totalBorrowed Total de préstamos activos
     * @param reserveFactor Factor de reserva para el tesoro
     * @param excessLiquidity Liquidez excesiva (no usado en simplificación)
     * @return liquidityRate Tasa que ganan los depositantes
     * @return variableBorrowRate Tasa que pagan los borrowers
     */
    function calculateInterestRates(
        uint256 totalDeposits,
        uint256 totalBorrowed,
        uint256 reserveFactor,
        uint256 excessLiquidity
    ) external view returns (uint256 liquidityRate, uint256 variableBorrowRate);
}

/**
 * @title InterestRateStrategy
 * @notice Estrategia de tasas de interés basada en utilización
 * @dev Implementa un modelo de dos pendientes similar a Aave
 *
 * @dev MODELO DE TASAS:
 *      ┌─────────────────────────────────────────────────────┐
 *      │  Tasa                                              │
 *      │    │                                                │
 *      │    │                    ╱ Pendiente 2               │
 *      │    │                  ╱                             │
 *      │    │                ╱                               │
 *      │    │    Pendiente 1╱                                │
 *      │    │            ╱                                   │
 *      │    │          ╱                                     │
 *      │    │        ╱                                       │
 *      │    │      ╱                                         │
 *      │    │    ╱                                           │
 *      │    │  ╱                                             │
 *      │    │╱                                               │
 *      │    └──────────────────────────────── Utilización    │
 *      │    0%              Óptima                    100%   │
 *      └─────────────────────────────────────────────────────┘
 *
 * @dev FÓRMULAS:
 *      Si utilización <= optimal:
 *        variableBorrowRate = base + (utilización * slope1) / optimal
 *
 *      Si utilización > optimal:
 *        variableBorrowRate = base + slope1 + (exceso * slope2) / (1 - optimal)
 *
 *      liquidityRate = variableBorrowRate * (1 - reserveFactor) * borrowed / deposits
 *
 * @dev HERENCIA:
 *      Ownable → Solo el owner puede cambiar parámetros
 */
contract InterestRateStrategy is IInterestRateStrategy, Ownable {
    // Usamos RayMath para cálculos de precisión
    using RayMath for uint256;

    // ========================================================================
    //                         CONSTANTES
    // ========================================================================

    /**
     * @notice Formato RAY: 27 decimales
     */
    uint256 public constant RAY = 1e27;

    // ========================================================================
    //                         VARIABLES DE ESTADO
    // ========================================================================

    /**
     * @notice Utilización óptima del pool
     * @dev Punto donde la tasa cambia de pendiente
     *      Valor en RAY (ej: 0.8e27 = 80%)
     */
    uint256 public optimalUtilization;

    /**
     * @notice Tasa base para préstamos variables
     * @dev Tasa mínima cuando la utilización es 0%
     *      Valor en RAY
     */
    uint256 public baseVariableBorrowRate;

    /**
     * @notice Pendiente 1 de la curva de tasas
     * @dev Aumento de tasa desde 0% hasta utilización óptima
     *      Valor en RAY
     */
    uint256 public variableRateSlope1;

    /**
     * @notice Pendiente 2 de la curva de tasas
     * @dev Aumento de tasa después de utilización óptima
     *      Generalmente más pronunciada para incentivar repagos
     *      Valor en RAY
     */
    uint256 public variableRateSlope2;

    // ========================================================================
    //                         CONSTRUCTOR
    // ========================================================================

    /**
     * @notice Constructor de la estrategia de tasas
     * @dev Inicializa los parámetros de la curva de tasas
     *
     * @param _optimalUtilization Utilización óptima (en RAY)
     * @param _baseVariableBorrowRate Tasa base (en RAY)
     * @param _variableRateSlope1 Pendiente 1 (en RAY)
     * @param _variableRateSlope2 Pendiente 2 (en RAY)
     *
     * @dev EJEMPLO (valores típicos):
     *      - optimalUtilization: 0.8e27 (80%)
     *      - baseVariableBorrowRate: 0.02e27 (2%)
     *      - variableRateSlope1: 0.04e27 (4%)
     *      - variableRateSlope2: 0.75e27 (75%)
     */
    constructor(
        uint256 _optimalUtilization,
        uint256 _baseVariableBorrowRate,
        uint256 _variableRateSlope1,
        uint256 _variableRateSlope2
    ) Ownable(msg.sender) {
        optimalUtilization = _optimalUtilization;
        baseVariableBorrowRate = _baseVariableBorrowRate;
        variableRateSlope1 = _variableRateSlope1;
        variableRateSlope2 = _variableRateSlope2;
    }

    // ========================================================================
    //                    FUNCIONES PRINCIPALES
    // ========================================================================

    /**
     * @notice Calcula las tasas de interés actuales
     * @dev Implementa el modelo de dos pendientes
     *
     * @param totalDeposits Total de depósitos en el pool
     * @param totalBorrowed Total de préstamos activos
     * @param reserveFactor Factor de reserva para el tesoro
     * @return liquidityRate Tasa que ganan los depositantes
     * @return variableBorrowRate Tasa que pagan los borrowers
     *
     * @dev PASOS:
     *      1. Calcular utilización = borrowed / deposits
     *      2. Si utilización <= óptima:
     *         - variableBorrowRate = base + (util * slope1) / optimal
     *      3. Si utilización > óptima:
     *         - exceso = utilización - óptima
     *         - variableBorrowRate = base + slope1 + (exceso * slope2) / (1 - optimal)
     *      4. liquidityRate = variableBorrowRate * (1 - reserveFactor) * borrowed / deposits
     *
     * @dev EJEMPLO:
     *      - Depósitos: 1000 ETH
     *      - Préstamos: 800 ETH (80% utilización = óptima)
     *      - base: 2%, slope1: 4%
     *      - variableBorrowRate = 2% + (80% * 4%) / 80% = 2% + 4% = 6%
     *      - liquidityRate = 6% * (1 - 0) * 800 / 1000 = 4.8%
     */
    function calculateInterestRates(
        uint256 totalDeposits,
        uint256 totalBorrowed,
        uint256 reserveFactor,
        uint256
    ) external view override returns (uint256 liquidityRate, uint256 variableBorrowRate) {
        // Calcular utilización actual
        uint256 utilization = 0;
        if (totalDeposits > 0) {
            utilization = (totalBorrowed * RAY) / totalDeposits;
        }

        // Calcular tasa variable según utilización
        if (utilization <= optimalUtilization) {
            // Utilización por debajo de la óptima: pendiente 1
            variableBorrowRate =
                baseVariableBorrowRate +
                (utilization * variableRateSlope1) / optimalUtilization;
        } else {
            // Utilización por encima de la óptima: pendiente 2
            uint256 excessUtilization = utilization - optimalUtilization;
            variableBorrowRate =
                baseVariableBorrowRate +
                variableRateSlope1 +
                (excessUtilization * variableRateSlope2) / (RAY - optimalUtilization);
        }

        // Calcular tasa de liquidez (lo que ganan los depositantes)
        liquidityRate = 0;
        if (totalDeposits > 0) {
            liquidityRate =
                (variableBorrowRate * (RAY - reserveFactor) * (totalBorrowed)) /
                (RAY * RAY * totalDeposits);
        }
    }

    // ========================================================================
    //                    FUNCIONES ADMINISTRATIVAS
    // ========================================================================

    /**
     * @notice Cambia la utilización óptima
     * @dev Solo el owner puede cambiar este parámetro
     *
     * @param _optimalUtilization Nueva utilización óptima (en RAY)
     *
     * @dev VALIDACIÓN: Debe estar entre 0 y RAY (0% - 100%)
     *
     * @dev EFECTO: Cambia el punto donde la curva de tasas cambia de pendiente
     */
    function setOptimalUtilization(uint256 _optimalUtilization) external onlyOwner {
        require(_optimalUtilization > 0 && _optimalUtilization <= RAY, "Invalid optimal utilization");
        optimalUtilization = _optimalUtilization;
    }

    /**
     * @notice Cambia las pendientes de la curva de tasas
     * @dev Solo el owner puede cambiar estos parámetros
     *
     * @param _slope1 Nueva pendiente 1 (en RAY)
     * @param _slope2 Nueva pendiente 2 (en RAY)
     *
     * @dev VALIDACIÓN: Ambas deben estar entre 0 y RAY
     *
     * @dev EFECTO:
     *      - slope1: Afecta tasas cuando utilización < óptima
     *      - slope2: Afecta tasas cuando utilización > óptima
     */
    function setVariableRateSlopes(
        uint256 _slope1,
        uint256 _slope2
    ) external onlyOwner {
        require(_slope1 <= RAY && _slope2 <= RAY, "Invalid slope values");
        variableRateSlope1 = _slope1;
        variableRateSlope2 = _slope2;
    }
}
