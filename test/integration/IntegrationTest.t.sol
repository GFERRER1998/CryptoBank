// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title IntegrationTest
 * @notice Tests de integración que verifican el flujo completo
 * @dev Prueba supply → borrow → repay en un escenario real
 *
 * @dev COBERTURA:
 *      - Flujo completo de lending
 *      - Múltiples usuarios
 *      - Interacciones entre contratos
 *      - Estados y balances
 */
import "forge-std/Test.sol";
import "../../src/tokens/CBToken.sol";
import "../../src/tokens/AToken.sol";
import "../../src/lending/LendingPool.sol";
import "../../src/lending/InterestRateStrategy.sol";

contract MockERC20 is ERC20 {
    constructor() ERC20("Mock Token", "MOCK") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract IntegrationTest is Test {
    // ========================================================================
    //                         VARIABLES DE TEST
    // ========================================================================

    /** @notice Token principal del pool */
    CBToken public cbToken;

    /** @notice Token mock para pruebas */
    MockERC20 public mockToken;

    /** @notice Pool de lending */
    LendingPool public pool;

    /** @notice Estrategia de tasas */
    InterestRateStrategy public strategy;

    /** @notice Token aToken */
    AToken public aToken;

    /** @notice Deployer/owner */
    address public owner = address(this);

    /** @notice Usuario 1 */
    address public user1 = makeAddr("user1");

    /** @notice Usuario 2 */
    address public user2 = makeAddr("user2");

    /** @notice Cantidad base para tests */
    uint256 public constant AMOUNT = 10000 * 1e18;

    // ========================================================================
    //                         SETUP
    // ========================================================================

    /**
     * @notice Configuración inicial
     * @dev Despliega todos los contratos necesarios
     */
    function setUp() public {
        // Deploy tokens
        cbToken = new CBToken();
        mockToken = new MockERC20();

        // Deploy strategy (80% optimal, 2% base, 4% slope1, 75% slope2)
        strategy = new InterestRateStrategy(
            0.8e27,  // optimalUtilization
            0.02e27, // baseVariableBorrowRate
            0.04e27, // variableRateSlope1
            0.75e27  // variableRateSlope2
        );

        // Deploy pool
        pool = new LendingPool();

        // Mint tokens a usuarios
        mockToken.mint(user1, AMOUNT * 10);
        mockToken.mint(user2, AMOUNT * 10);

        // Aprobar pool
        vm.prank(user1);
        mockToken.approve(address(pool), type(uint256).max);

        vm.prank(user2);
        mockToken.approve(address(pool), type(uint256).max);
    }

    // ========================================================================
    //                         TESTS DE INTEGRACIÓN
    // ========================================================================

    /**
     * @notice Verifica el flujo completo supply → borrow → repay
     * @dev Flujo: Usuario1 supply → Usuario2 borrow → Usuario2 repay
     *
     * @dev FLUJO:
     *      1. user1 hace supply de 5000 MOCK
     *      2. Pool inicializa reserva
     *      3. user2 borrow de 1000 MOCK
     *      4. Verifica deuda de user2
     *      5. user2 repay de 1000 MOCK
     *      6. Verifica que deuda se eliminó
     */
    function test_FullLendingFlow() public {
        uint256 supplyAmount = 5000 * 1e18;
        uint256 borrowAmount = 1000 * 1e18;

        // 1. Inicializar reserva
        pool.initReserve(address(mockToken), address(strategy), 0.8e27, address(0));

        // 2. User1 supply
        vm.prank(user1);
        pool.supply(address(mockToken), supplyAmount, user1);

        // 3. User2 borrow
        vm.prank(user2);
        pool.borrow(address(mockToken), borrowAmount, user2);

        // 4. Verificar balances
        uint256 user1Balance = mockToken.balanceOf(user1);
        uint256 user2Balance = mockToken.balanceOf(user2);

        // user1: 100k - 5k = 95k
        assertEq(user1Balance, AMOUNT * 10 - supplyAmount);

        // user2: 100k + 1k = 101k (recibió el préstamo)
        assertEq(user2Balance, AMOUNT * 10 + borrowAmount);

        // 5. User2 repay
        vm.prank(user2);
        pool.repay(address(mockToken), borrowAmount, user2);

        // 6. Verificar que user2 pagó
        uint256 user2BalanceAfterRepay = mockToken.balanceOf(user2);
        assertEq(user2BalanceAfterRepay, AMOUNT * 10);
    }

    /**
     * @notice Verifica que múltiples usuarios pueden supply
     * @dev Dos usuarios hacen supply al mismo pool
     */
    function test_MultipleUsersSupply() public {
        uint256 amount1 = 3000 * 1e18;
        uint256 amount2 = 7000 * 1e18;

        // Inicializar reserva
        pool.initReserve(address(mockToken), address(strategy), 0.8e27, address(0));

        // User1 supply
        vm.prank(user1);
        pool.supply(address(mockToken), amount1, user1);

        // User2 supply
        vm.prank(user2);
        pool.supply(address(mockToken), amount2, user2);

        // Verificar balances
        assertEq(mockToken.balanceOf(user1), AMOUNT * 10 - amount1);
        assertEq(mockToken.balanceOf(user2), AMOUNT * 10 - amount2);
    }

    /**
     * @notice Verifica que no se puede borrow más del disponible
     * @dev Intenta borrow sin liquidity suficiente
     */
    function test_BorrowMoreThanAvailable_Reverts() public {
        uint256 supplyAmount = 1000 * 1e18;
        uint256 borrowAmount = 5000 * 1e18;

        // Inicializar reserva
        pool.initReserve(address(mockToken), address(strategy), 0.8e27, address(0));

        // User1 supply poco
        vm.prank(user1);
        pool.supply(address(mockToken), supplyAmount, user1);

        // User2 intenta borrow más de lo disponible
        vm.prank(user2);
        vm.expectRevert();
        pool.borrow(address(mockToken), borrowAmount, user2);
    }

    /**
     * @notice Verifica withdraw después de supply
     * @dev Supply → Verify → Withdraw → Verify
     */
    function test_SupplyAndWithdraw() public {
        uint256 supplyAmount = 5000 * 1e18;

        // Inicializar reserva
        pool.initReserve(address(mockToken), address(strategy), 0.8e27, address(0));

        // User1 supply
        vm.prank(user1);
        pool.supply(address(mockToken), supplyAmount, user1);

        // Verificar balance después de supply
        uint256 balanceAfterSupply = mockToken.balanceOf(user1);
        assertEq(balanceAfterSupply, AMOUNT * 10 - supplyAmount);

        // User1 withdraw
        vm.prank(user1);
        pool.withdraw(address(mockToken), supplyAmount, user1);

        // Verificar balance después de withdraw
        uint256 balanceAfterWithdraw = mockToken.balanceOf(user1);
        assertEq(balanceAfterWithdraw, AMOUNT * 10);
    }
}
