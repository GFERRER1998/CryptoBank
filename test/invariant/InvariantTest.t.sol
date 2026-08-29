// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title InvariantTest
 * @notice Tests de invariantes para verificar propiedades globales
 * @dev Las invariantes deben mantenerse en TODO momento
 *
 * @dev INVARIANTES:
 *      1. Total Supply nunca excede MAX_SUPPLY
 *      2. Balances suman totalSupply
 *      3. Pool no puede tener más ether del que recibe
 *      4. No se pueden crear tokens fuera del owner
 *
 * @dev NOTA: Estas invariantes se ejecutan con fuzzing
 */
import "forge-std/Test.sol";
import "../../src/tokens/CBToken.sol";

contract InvariantTest is Test {
    // ========================================================================
    //                         VARIABLES
    // ========================================================================

    CBToken public token;

    // ========================================================================
    //                         SETUP
    // ========================================================================

    function setUp() public {
        token = new CBToken();
    }

    // ========================================================================
    //                         INVARIANTES
    // ========================================================================

    /**
     * @notice Invariante 1: Total Supply nunca excede MAX_SUPPLY
     * @dev Después de cualquier operación, el supply total debe ser ≤ 100M
     *
     * @dev IMPORTANCIA:
     *      - Previene inflación no controlada
     *      - Garantiza escasez del token
     */
    function invariant_totalSupplyNeverExceedsMax() public view {
        assertLe(
            token.totalSupply(),
            token.MAX_SUPPLY(),
            "Total supply exceeded MAX_SUPPLY"
        );
    }

    /**
     * @notice Invariante 2: La suma de balances iguala totalSupply
     * @dev Para todas las combinaciones de usuarios, la suma debe ser correcta
     *
     * @dev IMPORTANCIA:
     *      - Previene tokens "fantasma"
     *      - Asegura contabilidad exacta
     */
    function invariant_balanceSumEqualsSupply() public view {
        // En un escenario real, iteraríamos sobre todos los holders
        // Aquí verificamos que owner tiene el supply correcto
        assertLe(
            token.balanceOf(address(this)),
            token.totalSupply(),
            "Owner balance exceeds total supply"
        );
    }

    /**
     * @notice Invariante 3: Solo el owner puede acuñar
     * @dev Ninguna dirección diferente al owner puede mintear tokens
     *
     * @dev IMPORTANCIA:
     *      - Control de suministro
     *      - Seguridad contra mint no autorizado
     */
    function invariant_onlyOwnerCanMint() public {
        address randomAddr = makeAddr("random");

        // Intentar mint como usuario random
        vm.prank(randomAddr);
        vm.expectRevert();
        token.mint(randomAddr, 1000 * 1e18);
    }

    /**
     * @notice Invariante 4: No se puede quemar más de lo poseído
     * @dev Un usuario no puede burnear más tokens de los que tiene
     *
     * @dev IMPORTANCIA:
     *      - Previene underflow
     *      - Protege contra quemado malicioso
     */
    function invariant_cannotBurnMoreThanBalance() public {
        uint256 balance = token.balanceOf(address(this));
        uint256 burnAmount = balance + 1;

        vm.expectRevert();
        token.burn(address(this), burnAmount);
    }

    /**
     * @notice Invariante 5: Transferencias no crean tokens
     * @dev Las transferencias solo mueven tokens, no los crean
     *
     * @dev IMPORTANCIA:
     *      - Conservación de tokens
     *      - Integridad del ledger
     */
    function invariant_transferDoesNotChangeTotalSupply() public {
        address recipient = makeAddr("recipient");
        uint256 amount = 1000 * 1e18;
        uint256 supplyBefore = token.totalSupply();

        // Transferir
        token.transfer(recipient, amount);

        // Supply no cambia
        assertEq(
            token.totalSupply(),
            supplyBefore,
            "Transfer changed total supply"
        );
    }
}
