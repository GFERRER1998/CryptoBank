// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title CryptoBankGovernor
 * @notice Contrato de gobernanza DAO para el protocolo CryptoBank
 * @dev Implementa un sistema de gobernanza on-chain basado en OpenZeppelin Governor
 *      Los holders de CBToken pueden crear propuestas, votar y ejecutar cambios
 *
 * @dev INSPIRACIÓN: Compound Governor + OpenZeppelin Governor
 *
 * @dev FLUJO DE GOBERNANZA:
 *      ┌─────────────────────────────────────────────────────────────┐
 *      │                                                             │
 *      │  1. CREACIÓN DE PROPUESTA                                  │
 *      │     - Usuario con ≥10,000 CB crea propuesta                 │
 *      │     - Propuesta entra en "Pending"                          │
 *      │                                                             │
 *      │  2. PERÍODO DE VOTACIÓN (7 días)                           │
 *      │     - Holders votan For/Against/Abstain                     │
 *      │     - Se necesita quorum del 4%                             │
 *      │                                                             │
 *      │  3. QUEUING (Timelock)                                     │
 *      │     - Si pasa, entra en timelock de 48 horas                │
 *      │     - Permite a usuarios salir si no están de acuerdo       │
 *      │                                                             │
 *      │  4. EJECUCIÓN                                              │
 *      │     - Después del timelock, se ejecuta automáticamente     │
 *      │     - Los cambios se aplican al protocolo                  │
 *      │                                                             │
 *      └─────────────────────────────────────────────────────────────┘
 *
 * @dev HERENCIA (OpenZeppelin modular):
 *      Governor → Lógica base de propuestas y votación
 *      GovernorCountingSimple → Conteo simple de votos (For/Against/Abstain)
 *      GovernorVotes → Poder de voto basado en tokens ERC20Votes
 *      GovernorVotesQuorumFraction → Quorum como fracción del supply
 *      GovernorTimelockControl → Ejecución con delay de seguridad
 */
import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorTimelockControl.sol";
import "@openzeppelin/contracts/governance/TimelockController.sol";

contract CryptoBankGovernor is
    Governor,
    GovernorCountingSimple,
    GovernorVotes,
    GovernorVotesQuorumFraction,
    GovernorTimelockControl
{
    // ========================================================================
    //                         CONSTANTES
    // ========================================================================

    /**
     * @notice Retraso antes de que una propuesta entre en votación
     * @dev 1 bloque = ~12 segundos en Ethereum
     *      Permite que el snapshot de votos se tome después de la propuesta
     */
    uint256 public constant VOTING_DELAY = 1;

    /**
     * @notice Duración del período de votación
     * @dev 50400 bloques ≈ 7 días (50400 * 12s = 604800s = 7 días)
     *      Tiempo suficiente para que los holders voten
     */
    uint256 public constant VOTING_PERIOD = 50400;

    /**
     * @notice Umbral mínimo de tokens para crear una propuesta
     * @dev 10,000 CB tokens (10000 * 1e18)
     *      Previene spam de propuestas
     */
    uint256 public constant PROPOSAL_THRESHOLD = 10000 * 1e18;

    // ========================================================================
    //                         CONSTRUCTOR
    // ========================================================================

    /**
     * @notice Constructor del gobernante
     * @dev Inicializa el sistema de gobernanza con token y timelock
     *
     * @param _token Token de gobernanza (CBToken)
     * @param _timelock Controlador de timelock para ejecución retardada
     *
     * @dev PASOS:
     *      1. Inicializa Governor con nombre "CryptoBank Governor"
     *      2. Inicializa GovernorVotes con el token de votación
     *      3. Inicializa GovernorVotesQuorumFraction con 4% de quorum
     *      4. Inicializa GovernorTimelockControl con el timelock
     *
     * @dev CONFIGURACIÓN QUORUM:
     *      4% del supply total debe votar para que una propuesta pase
     *      Con 100M tokens = 4M tokens necesarios para quorum
     */
    constructor(IVotes _token, TimelockController _timelock)
        Governor("CryptoBank Governor")
        GovernorVotes(_token)
        GovernorVotesQuorumFraction(4)
        GovernorTimelockControl(_timelock)
    {}

    // ========================================================================
    //                    FUNCIONES DE GOBERNANZA (OVERRIDES)
    // ========================================================================

    /**
     * @notice Obtiene el retraso antes de la votación
     * @dev 1 bloque = ~12 segundos
     *
     * @return Número de bloques de retraso
     *
     * @dev PROPÓSITO: Dar tiempo para que el snapshot de votos se tome
     */
    function votingDelay() public pure override returns (uint256) {
        return VOTING_DELAY;
    }

    /**
     * @notice Obtiene la duración del período de votación
     * @dev 50400 bloques ≈ 7 días
     *
     * @return Número de bloques de votación
     *
     * @dev PROPÓSITO: Tiempo suficiente para que todos los holders voten
     */
    function votingPeriod() public pure override returns (uint256) {
        return VOTING_PERIOD;
    }

    /**
     * @notice Calcula el quorum para un bloque específico
     * @dev 4% del supply total en ese bloque
     *
     * @param blockNumber Número de bloque para calcular quorum
     * @return Cantidad mínima de votos necesarios
     *
     * @dev FÓRMULA: (totalSupply(blockNumber) * 4) / 100
     * @dev EJEMPLO: Con 100M tokens → 4M tokens necesarios
     */
    function quorum(uint256 blockNumber) public view override(Governor, GovernorVotesQuorumFraction) returns (uint256) {
        return super.quorum(blockNumber);
    }

    /**
     * @notice Obtiene el estado actual de una propuesta
     * @dev Los estados posibles son:
     *      - Pending: Esperando período de votación
     *      - Active: En período de votación
     *      - Canceled: Cancelada por el creator
     *      - Defeated: No alcanzó quorum o más votos en contra
     *      - Succeeded: Pasó votación, esperando timelock
     *      - Queued: En timelock
     *      - Expired: Timelock expiró sin ejecutar
     *      - Executed: Ejecutada exitosamente
     *
     * @param proposalId ID de la propuesta
     * @return Estado actual de la propuesta
     */
    function state(uint256 proposalId)
        public
        view
        override(Governor, GovernorTimelockControl)
        returns (ProposalState)
    {
        return super.state(proposalId);
    }

    /**
     * @notice Determina si una propuesta necesita ser encolada en el timelock
     * @dev Todas las propuestas exitosas necesitan pasar por el timelock
     *
     * @param proposalId ID de la propuesta
     * @return true si necesita ser encolada
     */
    function proposalNeedsQueuing(uint256 proposalId)
        public
        view
        override(Governor, GovernorTimelockControl)
        returns (bool)
    {
        return super.proposalNeedsQueuing(proposalId);
    }

    /**
     * @notice Obtiene el umbral mínimo para crear propuestas
     * @dev 10,000 CB tokens
     *
     * @return Cantidad mínima de tokens (en wei)
     *
     * @dev PROPÓSITO: Prevenir spam de propuestas
     */
    function proposalThreshold() public view override returns (uint256) {
        return PROPOSAL_THRESHOLD;
    }

    // ========================================================================
    //                    FUNCIONES INTERNAS (OVERRIDES)
    // ========================================================================

    /**
     * @notice Encola operaciones en el timelock
     * @dev Llamado cuando una propuesta pasa la votación
     *
     * @param proposalId ID de la propuesta
     * @param targets Direcciones de contratos a interactuar
     * @param values Cantidades de ETH a enviar
     * @param calldatas Datos de las transacciones
     * @param descriptionHash Hash de la descripción
     * @return Timestamp de ejecución
     */
    function _queueOperations(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) returns (uint48) {
        return super._queueOperations(
            proposalId,
            targets,
            values,
            calldatas,
            descriptionHash
        );
    }

    /**
     * @notice Ejecuta las operaciones de una propuesta
     * @dev Llamado después del período de timelock
     *
     * @param proposalId ID de la propuesta
     * @param targets Direcciones de contratos
     * @param values Cantidades de ETH
     * @param calldatas Datos de las transacciones
     * @param descriptionHash Hash de la descripción
     */
    function _executeOperations(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) {
        super._executeOperations(
            proposalId,
            targets,
            values,
            calldatas,
            descriptionHash
        );
    }

    /**
     * @notice Cancela una propuesta
     * @dev Solo el creator puede cancelar antes de que pase
     *
     * @param targets Direcciones de contratos
     * @param values Cantidades de ETH
     * @param calldatas Datos de las transacciones
     * @param descriptionHash Hash de la descripción
     * @return ID de la propuesta cancelada
     */
    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) returns (uint256) {
        return super._cancel(
            targets,
            values,
            calldatas,
            descriptionHash
        );
    }

    /**
     * @notice Obtiene la dirección del ejecutor
     * @dev Retorna la dirección del timelock
     *
     * @return Dirección del timelock controller
     */
    function _executor()
        internal
        view
        override(Governor, GovernorTimelockControl)
        returns (address)
    {
        return super._executor();
    }
}
