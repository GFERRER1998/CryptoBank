// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title DeployScript
 * @notice Script de deploy para el protocolo CryptoBank
 * @dev Despliega todos los contratos principales en orden correcto
 *
 * @dev ORDEN DE DEPLOY:
 *      1. CBToken (Token de gobernanza)
 *      2. TimelockController (Delay de seguridad)
 *      3. CryptoBankGovernor (DAO)
 *      4. LendingPool (Pool de préstamos)
 *      5. Transferir ownership del token al Governor
 *
 * @dev USO:
 *      forge script script/Deploy.s.sol \
 *        --rpc-url <RPC_URL> \
 *        --private-key <PRIVATE_KEY> \
 *        --broadcast \
 *        --verify
 */
import "forge-std/Script.sol";
import "../src/tokens/CBToken.sol";
import "../src/lending/LendingPool.sol";
import "../src/governance/CryptoBankGovernor.sol";
import "@openzeppelin/contracts/governance/TimelockController.sol";

contract DeployScript is Script {

    /**
     * @notice Función principal de deploy
     * @dev Despliega todos los contratos en el orden correcto
     *
     * @dev PASOS:
     *      1. Obtener private key del deployer
     *      2. Calcular dirección del deployer
     *      3. Iniciar broadcast de transacciones
     *      4. Deploy CBToken → 100M tokens al deployer
     *      5. Deploy TimelockController → 2 días de delay
     *      6. Deploy CryptoBankGovernor → Conecta token y timelock
     *      7. Deploy LendingPool → Pool de préstamos
     *      8. Transferir ownership del token al Governor
     *      9. Detener broadcast
     *      10. Imprimir resumen de deploy
     *
     * @dev VARIABLES DE ENTORNO REQUERIDAS:
     *      - PRIVATE_KEY: Clave privada del deployer
     *
     * @dev NOTA: En producción, usar CREATE2 para direcciones determinísticas
     */
    function run() external {
        // Obtener private key del entorno
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        // Calcular dirección del deployer
        address deployer = vm.addr(deployerPrivateKey);

        // Imprimir información de deploy
        console.log("Deploying CryptoBank Protocol...");
        console.log("Deployer:", deployer);

        // Iniciar broadcast de transacciones
        vm.startBroadcast(deployerPrivateKey);

        // ====================================================================
        // PASO 1: Deploy CBToken
        // ====================================================================
        // El token de gobernanza con 100M supply
        CBToken cbToken = new CBToken();
        console.log("CBToken deployed at:", address(cbToken));

        // ====================================================================
        // PASO 2: Deploy TimelockController
        // ====================================================================
        // Delay de 2 días para ejecución de propuestas
        uint256 minDelay = 2 days;
        // El deployer será el único propositor inicialmente
        address[] memory proposers = new address[](1);
        proposers[0] = deployer;
        // El deployer será el único ejecutor inicialmente
        address[] memory executors = new address[](1);
        executors[0] = deployer;

        TimelockController timelock = new TimelockController(
            minDelay,
            proposers,
            executors,
            address(0)  // Sin admin adicional
        );
        console.log("TimelockController deployed at:", address(timelock));

        // ====================================================================
        // PASO 3: Deploy CryptoBankGovernor
        // ====================================================================
        // Conecta el token de votación y el timelock
        CryptoBankGovernor governor = new CryptoBankGovernor(
            IVotes(address(cbToken)),
            timelock
        );
        console.log("CryptoBankGovernor deployed at:", address(governor));

        // ====================================================================
        // PASO 4: Deploy LendingPool
        // ====================================================================
        // Pool de préstamos principal
        LendingPool lendingPool = new LendingPool();
        console.log("LendingPool deployed at:", address(lendingPool));

        // ====================================================================
        // PASO 5: Transferir ownership del token al Governor
        // ====================================================================
        // Esto permite que el Governor controle el supply del token
        cbToken.transferOwnership(address(governor));
        console.log("CBToken ownership transferred to Governor");

        // Detener broadcast
        vm.stopBroadcast();

        // Imprimir resumen
        console.log("\n=== Deployment Summary ===");
        console.log("CBToken:", address(cbToken));
        console.log("TimelockController:", address(timelock));
        console.log("CryptoBankGovernor:", address(governor));
        console.log("LendingPool:", address(lendingPool));
    }
}
