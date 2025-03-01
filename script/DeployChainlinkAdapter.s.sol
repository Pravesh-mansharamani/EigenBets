// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console, console2} from "forge-std/Script.sol";
import {ChainlinkPredictionMarketAdapter} from "../src/chainlink/ChainlinkPredictionMarketAdapter.sol";

contract DeployChainlinkAdapterScript is Script {
    function run() external {
        console.log("Starting ChainlinkPredictionMarketAdapter deployment script");

        // Load deployer private key and address
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        console.log("Deployer:", deployer);

        // Get existing prediction market hook address
        address predictionMarketHook = vm.envOr("PREDICTION_MARKET_HOOK", address(0x5a1df3b6FAcBBe873a26737d7b1027Ad47834AC0));
        console.log("Using PredictionMarketHook at:", predictionMarketHook);

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy the ChainlinkPredictionMarketAdapter contract
        ChainlinkPredictionMarketAdapter adapter = new ChainlinkPredictionMarketAdapter(predictionMarketHook);
        console.log("ChainlinkPredictionMarketAdapter deployed at:", address(adapter));

        vm.stopBroadcast();
        console.log("Deployment script completed successfully.");
    }
} 