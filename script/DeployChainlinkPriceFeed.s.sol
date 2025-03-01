// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console, console2} from "forge-std/Script.sol";
import {ChainlinkPriceFeed} from "../src/chainlink/ChainlinkPriceFeed.sol";

contract DeployChainlinkPriceFeedScript is Script {
    function run() external {
        console.log("Starting ChainlinkPriceFeed deployment script");

        // Load deployer private key and address
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        console.log("Deployer:", deployer);

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy the ChainlinkPriceFeed contract
        ChainlinkPriceFeed priceFeed = new ChainlinkPriceFeed();
        console.log("ChainlinkPriceFeed deployed at:", address(priceFeed));

        vm.stopBroadcast();
        console.log("Deployment script completed successfully.");
    }
} 