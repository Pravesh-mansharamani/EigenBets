// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {YesToken} from "../src/YesToken.sol";
import {NoToken} from "../src/NoToken.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

/**
 * @title DeployTokens
 * @dev Script to deploy only the YES, NO tokens and a USDC token for testing
 * This can be used separately from the full PredictionMarketHook deployment
 */
contract DeployTokens is Script {
    function run() external {
        console2.log("Starting token deployment script");
        
        // Load private key from .env
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        console2.log("Deployer address:", deployer);
        
        vm.startBroadcast(deployerPrivateKey);

        // Deploy tokens
        console2.log("Deploying tokens...");
        
        // Deploy mock USDC token
        ERC20Mock usdc = new ERC20Mock();
        usdc.mint(deployer, 1_000_000e6);
        
        // Deploy YES and NO tokens (automatically mint to deployer in constructor)
        YesToken yesToken = new YesToken();
        NoToken noToken = new NoToken();
        
        // Display contract addresses for easy reference
        console2.log("\nToken Deployment Summary:");
        console2.log("====================");
        console2.log("USDC Token:", address(usdc));
        console2.log("YES Token:", address(yesToken));
        console2.log("NO Token:", address(noToken));
        
        vm.stopBroadcast();
        console2.log("Token deployment completed successfully");
    }
} 