// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/infrastructure/PriceFeed.sol";

contract ConfigurePriceFeedScript is Script {
    // Sepolia token addresses
    address constant WETH = 0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9;
    address constant USDC = 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238;
    address constant WBTC = 0x29f2D40B0605204364af54EC677bD022dA425d03;
    address constant LINK = 0x779877A7B0D9E8603169DdbD7836e478b4624789;

    // Chainlink Price Feed addresses on Sepolia
    address constant ETH_USD_FEED = 0x694AA1769357215DE4FAC081bf1f309aDC325306;
    address constant BTC_USD_FEED = 0x1B44f3514812D8357c87870A117E0b0747BE81Fb;
    address constant LINK_USD_FEED = 0x425fEc615c2d0d5202e621CFfFE005a5b0B18e43;

    // PriceFeed address (already deployed)
    address constant PRICE_FEED = 0xDf612D3422a748f00Fee370f60Cd3C54A161AA63;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Configuring PriceFeed...");
        console.log("Deployer:", deployer);
        console.log("PriceFeed:", PRICE_FEED);

        vm.startBroadcast(deployerPrivateKey);

        PriceFeed priceFeed = PriceFeed(PRICE_FEED);

        // Add WETH feed (Chainlink)
        console.log("Adding WETH feed...");
        priceFeed.addFeed(
            WETH,
            ETH_USD_FEED,
            8,
            100e8,        // $100 min
            100000e8,     // $100,000 max
            3600,         // 1 hour stale
            0             // no mock
        );

        // Add USDC feed (Mock - $1.00)
        console.log("Adding USDC feed (mock)...");
        priceFeed.addFeed(
            USDC,
            address(0),       // No Chainlink feed
            8,
            99e8,             // $0.99 min
            101e8,            // $1.01 max
            0,                // No stale check for mock
            100000000         // $1.00 mock price (8 decimals)
        );

        // Add WBTC feed (Chainlink)
        console.log("Adding WBTC feed...");
        priceFeed.addFeed(
            WBTC,
            BTC_USD_FEED,
            8,
            1000e8,       // $1,000 min
            100000e8,     // $100,000 max
            3600,         // 1 hour stale
            0             // no mock
        );

        // Add LINK feed (Chainlink)
        console.log("Adding LINK feed...");
        priceFeed.addFeed(
            LINK,
            LINK_USD_FEED,
            8,
            1e8,           // $1 min
            1000e8,        // $1,000 max
            3600,          // 1 hour stale
            0              // no mock
        );

        vm.stopBroadcast();

        console.log("\n=== PriceFeed Configured ===");
        console.log("WETH: Chainlink ETH/USD");
        console.log("USDC: Mock $1.00");
        console.log("WBTC: Chainlink BTC/USD");
        console.log("LINK: Chainlink LINK/USD");
    }
}