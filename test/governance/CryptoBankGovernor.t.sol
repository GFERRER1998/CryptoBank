// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title GovernanceTest
 * @notice Tests unitarios para el sistema de gobernanza CryptoBank
 * @dev Verifica el funcionamiento del Governor y sus componentes
 *
 * @dev COBERTURA:
 *      - Creación de propuestas
 *      - Umbral de propuestas
 *      - Períodos de votación
 *      - Configuración del Governor
 *
 * @dev NOTA: Estos tests verifican la configuración básica.
 *      Tests completos de votación requieren avanzar bloques
 *      y simular votos de múltiples usuarios.
 */
import "forge-std/Test.sol";
import "../../src/tokens/CBToken.sol";
import "../../src/governance/CryptoBankGovernor.sol";
import "@openzeppelin/contracts/governance/TimelockController.sol";
import "@openzeppelin/contracts/governance/utils/IVotes.sol";

contract GovernanceTest is Test {
    // ========================================================================
    //                         VARIABLES DE TEST
    // ========================================================================

    /** @notice Token de gobernanza */
    CBToken public cbToken;

    /** @notice Controlador de timelock */
    TimelockController public timelock;

    /** @notice Governor principal */
    CryptoBankGovernor public governor;

    /** @notice Dirección del deployer */
    address public owner = address(this);

    /** @notice Votante 1 con poder de voto alto */
    address public voter1 = makeAddr("voter1");

    /** @notice Votante 2 con poder de voto medio */
    address public voter2 = makeAddr("voter2");

    /** @notice Cantidad de tokens para votación */
    uint256 public constant VOTE_AMOUNT = 50000 * 1e18;

    // ========================================================================
    //                         SETUP
    // ========================================================================

    /**
     * @notice Configuración inicial antes de cada test
     * @dev Despliega todos los componentes de gobernanza
     *
     * @dev PASOS:
     *      1. Deploy CBToken
     *      2. Deploy TimelockController
     *      3. Deploy CryptoBankGovernor
     *      4. Transferir tokens a votantes
     *      5. Delegar poder de voto
     *      6. Avanzar bloque para que los votos cuenten
     */
    function setUp() public {
        // 1. Deploy CBToken
        cbToken = new CBToken();

        // 2. Deploy TimelockController (1 día de delay)
        uint256 minDelay = 1 days;
        address[] memory proposers = new address[](0);
        address[] memory executors = new address[](0);

        timelock = new TimelockController(
            minDelay,
            proposers,
            executors,
            address(0)
        );

        // 3. Deploy Governor
        governor = new CryptoBankGovernor(
            IVotes(address(cbToken)),
            timelock
        );

        // 4. Transferir tokens a votantes
        cbToken.transfer(voter1, VOTE_AMOUNT * 2);  // 100k CB
        cbToken.transfer(voter2, VOTE_AMOUNT);       // 50k CB

        // 5. Delegar poder de voto (necesario para que cuenten los votos)
        vm.prank(voter1);
        cbToken.delegate(voter1);

        vm.prank(voter2);
        cbToken.delegate(voter2);

        // 6. Avanzar bloque para que los checkpoints de voto se registren
        vm.roll(block.number + 1);
    }

    // ========================================================================
    //                         TESTS DE CREACIÓN DE PROPUESTAS
    // ========================================================================

    /**
     * @notice Verifica que se puede crear una propuesta
     * @dev Un usuario con suficientes tokens debe poder proponer
     *
     * @dev REQUISITOS:
     *      - Tener ≥10,000 CB tokens
     *      - Haber delegado voto
     *      - Haber avanzado al menos 1 bloque
     */
    function test_ProposalCreation() public {
        // voter1 tiene 100k CB, suficiente para proponer
        vm.prank(voter1);

        // Crear propuesta (objetivos vacíos para simplificar)
        uint256 proposalId = governor.propose(
            new address[](1),   // targets
            new uint256[](1),   // values
            new bytes[](1),     // calldatas
            ""                  // descripción
        );

        // Verificar que se creó (ID > 0)
        assertGt(proposalId, 0);
    }

    /**
     * @notice Verifica que se requiere umbral para proponer
     * @dev Un usuario con menos de 10,000 CB no puede proponer
     */
    function test_ProposalThreshold() public {
        // Crear usuario con pocos tokens
        address smallVoter = makeAddr("smallVoter");
        cbToken.transfer(smallVoter, 1000 * 1e18);  // Solo 1,000 CB

        // Intentar proponer - debe fallar
        vm.prank(smallVoter);
        vm.expectRevert();
        governor.propose(
            new address[](1),
            new uint256[](1),
            new bytes[](1),
            ""
        );
    }

    // ========================================================================
    //                         TESTS DE CONFIGURACIÓN
    // ========================================================================

    /**
     * @notice Verifica el voting delay
     * @dev Debe ser 1 bloque (~12 segundos)
     */
    function test_VotingDelay() public {
        assertEq(governor.votingDelay(), 1);
    }

    /**
     * @notice Verifica el voting period
     * @dev Debe ser 50,400 bloques (~7 días)
     */
    function test_VotingPeriod() public {
        assertEq(governor.votingPeriod(), 50400);
    }

    /**
     * @notice Verifica el umbral de propuestas
     * @dev Debe ser 10,000 CB tokens
     */
    function test_ProposalThresholdValue() public {
        assertEq(governor.proposalThreshold(), 10000 * 1e18);
    }
}
