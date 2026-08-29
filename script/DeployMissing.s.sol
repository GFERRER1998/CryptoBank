// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/lending/InterestRateStrategy.sol";
import "../src/infrastructure/PriceFeed.sol";

contract DeployMissingScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying Missing Contracts...");
        console.log("Deployer:", deployer);

        vm.startBroadcast(deployerPrivateKey);

        // ====================================================================
        // DEPLOY InterestRateStrategy
        // ====================================================================
        // Valores Aave-típicos (RAY = 1e27)
        uint256 optimalUtilization = 0.8e27;        // 80%
        uint256 baseVariableBorrowRate = 0.02e27;   // 2% base
        uint256 variableRateSlope1 = 0.04e27;       // 4% slope 1
        uint256 variableRateSlope2 = 0.75e27;       // 75% slope 2

        InterestRateStrategy interestRateStrategy = new InterestRateStrategy(
            optimalUtilization,
            baseVariableBorrowRate,
            variableRateSlope1,
            variableRateSlope2
        );
        console.log("InterestRateStrategy deployed at:", address(interestRateStrategy));

        // ====================================================================
        // DEPLOY PriceFeed
        // ====================================================================
        PriceFeed priceFeed = new PriceFeed();
        console.log("PriceFeed deployed at:", address(priceFeed));

        vm.stopBroadcast();

        console.log("\n=== Deployment Summary ===");
        console.log("InterestRateStrategy:", address(interestRateStrategy));
        console.log("PriceFeed:", address(priceFeed));
        console.log("\nNext steps:");
        console.log("1. Run InitReserves.s.sol to initialize reserves in LendingPool");
        console.log("2. Run ConfigurePriceFeed.s.sol to add Chainlink feeds");
    }
}