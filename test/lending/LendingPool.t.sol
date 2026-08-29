// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title LendingPoolTest
 * @notice Tests unitarios para el contrato LendingPool
 * @dev Verifica el funcionamiento del pool de lending/borrowing
 *
 * @dev COBERTURA:
 *      - Inicialización de reservas
 *      - Depósitos (supply)
 *      - Préstamos (borrow)
 *      - Pagos (repay)
 *      - Pausa/despausa
 *      - Errores y require statements
 *
 * @dev NOTA: Estos tests usan una implementación simplificada de AToken.
 *      En producción, se necesitarían tests más completos con AToken completo.
 */
import "forge-std/Test.sol";
import "../../src/lending/LendingPool.sol";
import "../../src/tokens/AToken.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title MockERC20
 * @notice Token ERC20 mock para testing
 * @dev Permite mintear tokens sin restricciones para tests
 */
contract MockERC20 is ERC20 {
    /** @notice Decimales del token */
    uint8 private _decimals;

    /**
     * @notice Constructor del mock
     * @param name Nombre del token
     * @param symbol Símbolo del token
     * @param decimals_ Número de decimales
     */
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals_
    ) ERC20(name, symbol) {
        _decimals = decimals_;
    }

    /**
     * @notice Retorna los decimales del token
     * @return Decimales configurados
     */
    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    /**
     * @notice Acuña tokens a una dirección
     * @dev Sin restricciones - solo para testing
     * @param to Dirección receptora
     * @param amount Cantidad a acuñar
     */
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract LendingPoolTest is Test {
    // ========================================================================
    //                         VARIABLES DE TEST
    // ========================================================================

    /** @notice Instancia del LendingPool */
    LendingPool public lendingPool;

    /** @notice Token mock para testing */
    MockERC20 public mockToken;

    /** @notice Dirección del deployer (owner/admin) */
    address public owner = address(this);

    /** @notice Usuario de prueba 1 */
    address public user1 = makeAddr("user1");

    /** @notice Usuario de prueba 2 */
    address public user2 = makeAddr("user2");

    /** @notice Cantidad inicial para mintear a cada usuario */
    uint256 public constant INITIAL_MINT = 1000 * 1e18;

    // ========================================================================
    //                         SETUP
    // ========================================================================

    /**
     * @notice Configuración inicial antes de cada test
     * @dev Crea el pool y token mock, y mintea tokens a los usuarios
     */
    function setUp() public {
        // Crear instancia del pool
        lendingPool = new LendingPool();

        // Crear token mock
        mockToken = new MockERC20("Mock Token", "MOCK", 18);

        // Mintear tokens a cada usuario
        mockToken.mint(owner, INITIAL_MINT);
        mockToken.mint(user1, INITIAL_MINT);
        mockToken.mint(user2, INITIAL_MINT);
    }

    // ========================================================================
    //                         TESTS DE INICIALIZACIÓN
    // ========================================================================

    /**
     * @notice Verifica inicialización correcta de reserva
     * @dev La reserva debe estar activa y tener un aToken válido
     */
    function test_InitReserve() public {
        // Inicializar reserva para el token mock
        lendingPool.initReserve(address(mockToken), address(0), 0.8e27, address(0));

        // Obtener datos de la reserva
        LendingPool.ReserveData memory reserve = lendingPool.getReserveData(address(mockToken));

        // Verificar que esté activa
        assertTrue(reserve.isActive);
        // Verificar que tenga un aToken válido
        assertEq(reserve.aTokenAddress != address(0), true);
    }

    // ========================================================================
    //                         TESTS DE SUPPLY (DEPÓSITO)
    // ========================================================================

    /**
     * @notice Verifica que supply transfiere tokens al pool
     * @dev Los tokens del usuario deben moverse al pool
     */
    function test_Supply_TransfersTokens() public {
        // Inicializar reserva
        lendingPool.initReserve(address(mockToken), address(0), 0.8e27, address(0));

        // Aprobar tokens al pool
        mockToken.approve(address(lendingPool), INITIAL_MINT);

        uint256 supplyAmount = 100 * 1e18;
        uint256 poolBalanceBefore = mockToken.balanceOf(address(lendingPool));

        // Ejecutar supply
        lendingPool.supply(address(mockToken), supplyAmount, owner);

        // Verificar que el pool recibió los tokens
        uint256 poolBalanceAfter = mockToken.balanceOf(address(lendingPool));
        assertEq(poolBalanceAfter, poolBalanceBefore + supplyAmount);
    }

    /**
     * @notice Verifica que supply emite el evento correcto
     * @dev El evento Supply debe emitirse con los parámetros correctos
     */
    function test_Supply_EmitsEvent() public {
        // Inicializar reserva
        lendingPool.initReserve(address(mockToken), address(0), 0.8e27, address(0));

        // Aprobar tokens
        mockToken.approve(address(lendingPool), INITIAL_MINT);

        uint256 supplyAmount = 100 * 1e18;

        // Verificar que se emite el evento
        vm.expectEmit(true, true, true, true);
        emit LendingPool.Supply(address(mockToken), owner, supplyAmount);
        lendingPool.supply(address(mockToken), supplyAmount, owner);
    }

    // ========================================================================
    //                         TESTS DE BORROW (PRÉSTAMO)
    // ========================================================================

    /**
     * @notice Verifica que borrow transfiere tokens al usuario
     * @dev El usuario recibe los tokens prestados
     */
    function test_Borrow_TransfersTokensToUser() public {
        // Inicializar y depositar
        lendingPool.initReserve(address(mockToken), address(0), 0.8e27, address(0));
        mockToken.approve(address(lendingPool), INITIAL_MINT);

        uint256 supplyAmount = 100 * 1e18;
        lendingPool.supply(address(mockToken), supplyAmount, owner);

        // Pedir préstamo
        uint256 borrowAmount = supplyAmount / 2;
        uint256 user1BalanceBefore = mockToken.balanceOf(user1);

        lendingPool.borrow(address(mockToken), borrowAmount, user1);

        // Verificar que user1 recibió los tokens
        uint256 user1BalanceAfter = mockToken.balanceOf(user1);
        assertEq(user1BalanceAfter, user1BalanceBefore + borrowAmount);
    }

    // ========================================================================
    //                         TESTS DE REPAY (PAGO)
    // ========================================================================

    /**
     * @notice Verifica que repay quita tokens del pagador
     * @dev El pagador transfiere tokens al pool para cubrir su deuda
     */
    function test_Repay_TransfersTokensFromUser() public {
        // Inicializar y depositar
        lendingPool.initReserve(address(mockToken), address(0), 0.8e27, address(0));
        mockToken.approve(address(lendingPool), INITIAL_MINT);

        uint256 supplyAmount = 100 * 1e18;
        lendingPool.supply(address(mockToken), supplyAmount, owner);

        // Pedir préstamo
        uint256 borrowAmount = supplyAmount / 2;
        lendingPool.borrow(address(mockToken), borrowAmount, user1);

        // Aprobar tokens para pago
        vm.prank(user1);
        mockToken.approve(address(lendingPool), borrowAmount);

        // Pagar deuda
        uint256 user1BalanceBefore = mockToken.balanceOf(user1);
        vm.prank(user1);
        lendingPool.repay(address(mockToken), borrowAmount, user1);
        uint256 user1BalanceAfter = mockToken.balanceOf(user1);

        // Verificar que se descontaron los tokens
        assertEq(user1BalanceAfter, user1BalanceBefore - borrowAmount);
    }

    // ========================================================================
    //                         TESTS DE ERRORES
    // ========================================================================

    /**
     * @notice Verifica que supply falla con reserva inactiva
     * @dev No se puede depositar en una reserva no inicializada
     */
    function test_Supply_RevertWhen_ReserveNotActive() public {
        // Intentar supply sin inicializar reserva
        vm.expectRevert("Reserve not active");
        lendingPool.supply(address(mockToken), INITIAL_MINT, owner);
    }

    // ========================================================================
    //                         TESTS DE CONSULTA
    // ========================================================================

    /**
     * @notice Verifica que getReserves retorna todas las reservas
     * @dev Después de inicializar, debe haber 1 reserva
     */
    function test_GetReserves() public {
        // Inicializar reserva
        lendingPool.initReserve(address(mockToken), address(0), 0.8e27, address(0));

        // Obtener reservas
        address[] memory reserves = lendingPool.getReserves();

        // Verificar cantidad y dirección
        assertEq(reserves.length, 1);
        assertEq(reserves[0], address(mockToken));
    }

    // ========================================================================
    //                         TESTS DE PAUSA
    // ========================================================================

    /**
     * @notice Verifica que supply falla cuando el pool está pausado
     * @dev El pausable debe bloquear operaciones
     */
    function test_Pause_RevertsSupply() public {
        // Inicializar reserva
        lendingPool.initReserve(address(mockToken), address(0), 0.8e27, address(0));

        // Aprobar tokens
        mockToken.approve(address(lendingPool), INITIAL_MINT);

        // Pausar pool
        lendingPool.pause();

        // Intentar supply - debe fallar
        vm.expectRevert();
        lendingPool.supply(address(mockToken), 100 * 1e18, owner);
    }

    /**
     * @notice Verifica que unpause restaura operaciones
     * @dev Después de despausar, supply debe funcionar
     */
    function test_Unpause_AllowsSupply() public {
        // Inicializar reserva
        lendingPool.initReserve(address(mockToken), address(0), 0.8e27, address(0));

        // Aprobar tokens
        mockToken.approve(address(lendingPool), INITIAL_MINT);

        // Pausar y despausar
        lendingPool.pause();
        lendingPool.unpause();

        // Supply debe funcionar ahora
        uint256 supplyAmount = 100 * 1e18;
        uint256 poolBalanceBefore = mockToken.balanceOf(address(lendingPool));

        lendingPool.supply(address(mockToken), supplyAmount, owner);

        // Verificar que se transfirieron tokens
        uint256 poolBalanceAfter = mockToken.balanceOf(address(lendingPool));
        assertEq(poolBalanceAfter, poolBalanceBefore + supplyAmount);
    }
}
