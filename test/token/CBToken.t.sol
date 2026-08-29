// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title CBTokenTest
 * @notice Tests unitarios para el contrato CBToken
 * @dev Verifica el funcionamiento del token de gobernanza
 *
 * @dev COBERTURA:
 *      - Constructor y supply inicial
 *      - Transferencias
 *      - Aprobaciones (approve/transferFrom)
 *      - Acuñación (mint) con límites
 *      - Quemado (burn)
 *      - Casos límite
 */
import "forge-std/Test.sol";
import "../../src/tokens/CBToken.sol";

contract CBTokenTest is Test {
    // ========================================================================
    //                         VARIABLES DE TEST
    // ========================================================================

    /** @notice Instancia del token CB */
    CBToken public cbToken;

    /** @notice Dirección del deployer (owner) */
    address public owner = address(this);

    /** @notice Dirección de usuario de prueba 1 */
    address public user1 = makeAddr("user1");

    /** @notice Dirección de usuario de prueba 2 */
    address public user2 = makeAddr("user2");

    // ========================================================================
    //                         SETUP
    // ========================================================================

    /**
     * @notice Configuración inicial antes de cada test
     * @dev Despliega una nueva instancia del token
     */
    function setUp() public {
        cbToken = new CBToken();
    }

    // ========================================================================
    //                         TESTS DE CONSTRUCTOR
    // ========================================================================

    /**
     * @notice Verifica el supply inicial correcto
     * @dev Debe haber 100M tokens en total y todos en el owner
     */
    function test_InitialSupply() public {
        // Verificar supply total
        assertEq(cbToken.totalSupply(), 100_000_000 * 1e18);
        // Verificar balance del owner
        assertEq(cbToken.balanceOf(owner), 100_000_000 * 1e18);
    }

    // ========================================================================
    //                         TESTS DE TRANSFERENCIA
    // ========================================================================

    /**
     * @notice Verifica transferencias básicas
     * @dev Token estándar: transfer reduce sender, incrementa receiver
     */
    function test_Transfer() public {
        uint256 amount = 1000 * 1e18;

        // Transferir de owner a user1
        cbToken.transfer(user1, amount);

        // Verificar balances
        assertEq(cbToken.balanceOf(user1), amount);
        assertEq(cbToken.balanceOf(owner), 100_000_000 * 1e18 - amount);
    }

    // ========================================================================
    //                         TESTS DE APROBACIÓN
    // ========================================================================

    /**
     * @notice Verifica approve y allowances
     * @dev Permite a un spender transferir en nombre del holder
     */
    function test_Approve() public {
        uint256 amount = 1000 * 1e18;

        // Aprobar a user1 para gastar amount
        cbToken.approve(user1, amount);

        // Verificar allowance
        assertEq(cbToken.allowance(owner, user1), amount);
    }

    /**
     * @notice Verifica transferFrom con aprobación previa
     * @dev Flujo completo: approve → transferFrom
     */
    function test_TransferFrom() public {
        uint256 amount = 1000 * 1e18;

        // Aprobar a user1
        cbToken.approve(user1, amount);

        // user1 transfiere de owner a user2
        vm.prank(user1);
        cbToken.transferFrom(owner, user2, amount);

        // Verificar balance de user2
        assertEq(cbToken.balanceOf(user2), amount);
    }

    // ========================================================================
    //                         TESTS DE MINT
    // ========================================================================

    /**
     * @notice Verifica acuñación de tokens
     * @dev Solo owner puede mintear
     */
    function test_Mint() public {
        // Primero quemar para crear espacio
        uint256 burnAmount = 1000 * 1e18;
        cbToken.burn(owner, burnAmount);

        // Mintear nuevos tokens
        uint256 mintAmount = 500 * 1e18;
        cbToken.mint(user1, mintAmount);

        // Verificar balance
        assertEq(cbToken.balanceOf(user1), mintAmount);
    }

    /**
     * @notice Verifica que no se puede exceder MAX_SUPPLY
     * @dev El mint debe fallar si excede el máximo
     */
    function test_MintExceedsMaxSupply() public {
        uint256 maxSupply = cbToken.MAX_SUPPLY();

        // Intentar mintear más del máximo
        vm.expectRevert("CBToken: exceeds max supply");
        cbToken.mint(user1, maxSupply + 1);
    }

    // ========================================================================
    //                         TESTS DE BURN
    // ========================================================================

    /**
     * @notice Verifica quemado de tokens
     * @dev Reduce el balance y supply total
     */
    function test_Burn() public {
        uint256 burnAmount = 1000 * 1e18;

        // Quemar tokens
        cbToken.burn(owner, burnAmount);

        // Verificar balance reducido
        assertEq(cbToken.balanceOf(owner), 100_000_000 * 1e18 - burnAmount);
    }

    // ========================================================================
    //                         TESTS DE CASOS LÍMITE
    // ========================================================================

    /**
     * @notice Verifica que no se puede transferir más del balance
     * @dev Debe revertir con insufficient balance
     */
    function test_TransferExceedsBalance() public {
        uint256 amount = 100_000_001 * 1e18;

        // Intentar transferir más de lo que se tiene
        vm.expectRevert();
        cbToken.transfer(user1, amount);
    }

    /**
     * @notice Verifica transferencia de cero tokens
     * @dev Operación válida pero sin efecto
     */
    function test_TransferZero() public {
        // Transferir 0 tokens
        cbToken.transfer(user1, 0);

        // Verificar balance
        assertEq(cbToken.balanceOf(user1), 0);
    }
}
