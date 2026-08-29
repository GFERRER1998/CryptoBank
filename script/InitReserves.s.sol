// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/lending/LendingPool.sol";
import "../src/infrastructure/PriceFeed.sol";

contract InitReservesScript is Script {
    // Sepolia token addresses
    address constant WETH = 0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9;
    address constant USDC = 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238;
    address constant WBTC = 0x29f2D40B0605204364af54EC677bD022dA425d03;
    address constant LINK = 0x779877A7B0D9E8603169DdbD7836e478b4624789;

    // Chainlink Price Feed addresses on Sepolia
    address constant ETH_USD_FEED = 0x694AA1769357215DE4FAC081bf1f309aDC325306;
    address constant BTC_USD_FEED = 0x1B44f3514812D8357c87870A117E0b0747BE81Fb;
    address constant LINK_USD_FEED = 0x425fEc615c2d0d5202e621CFfFE005a5b0B18e43;
    // USDC doesn't have a Chainlink feed on Sepolia - use mock or 0

    // LendingPool address (already deployed)
    address constant LENDING_POOL = 0x2C1BAe355B41926a310B649B962faE85Fb8E57D1;

    // Liquidation thresholds (80% = 0.8e27 in RAY)
    uint256 constant LIQUIDATION_THRESHOLD = 0.8e27;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        // InterestRateStrategy address - SET AFTER DEPLOY
        address interestRateStrategy = vm.envAddress("IR_STRATEGY_ADDRESS");

        // PriceFeed address - SET AFTER DEPLOY
        address priceFeed = vm.envAddress("PRICE_FEED_ADDRESS");

        console.log("Initializing Reserves in LendingPool...");
        console.log("Deployer:", deployer);
        console.log("LendingPool:", LENDING_POOL);
        console.log("InterestRateStrategy:", interestRateStrategy);
        console.log("PriceFeed:", priceFeed);

        vm.startBroadcast(deployerPrivateKey);

        LendingPool lendingPool = LendingPool(LENDING_POOL);

        // Initialize WETH reserve
        console.log("Initializing WETH reserve...");
        lendingPool.initReserve(WETH, interestRateStrategy, LIQUIDATION_THRESHOLD, ETH_USD_FEED);
        address aWETH = lendingPool.getReserveData(WETH).aTokenAddress;
        console.log("aWETH created at:", aWETH);

        // Initialize USDC reserve (no Chainlink feed on Sepolia, use PriceFeed address)
        console.log("Initializing USDC reserve...");
        lendingPool.initReserve(USDC, interestRateStrategy, LIQUIDATION_THRESHOLD, priceFeed);
        address aUSDC = lendingPool.getReserveData(USDC).aTokenAddress;
        console.log("aUSDC created at:", aUSDC);

        // Initialize WBTC reserve
        console.log("Initializing WBTC reserve...");
        lendingPool.initReserve(WBTC, interestRateStrategy, LIQUIDATION_THRESHOLD, BTC_USD_FEED);
        address aWBTC = lendingPool.getReserveData(WBTC).aTokenAddress;
        console.log("aWBTC created at:", aWBTC);

        // Initialize LINK reserve
        console.log("Initializing LINK reserve...");
        lendingPool.initReserve(LINK, interestRateStrategy, LIQUIDATION_THRESHOLD, LINK_USD_FEED);
        address aLINK = lendingPool.getReserveData(LINK).aTokenAddress;
        console.log("aLINK created at:", aLINK);

        vm.stopBroadcast();

        console.log("\n=== Reserves Initialized ===");
        console.log("WETH -> aWETH:", aWETH);
        console.log("USDC -> aUSDC:", aUSDC);
        console.log("WBTC -> aWBTC:", aWBTC);
        console.log("LINK -> aLINK:", aLINK);
        console.log("\nUpdate frontend/lib/contracts.ts with these AToken addresses!");
    }
}