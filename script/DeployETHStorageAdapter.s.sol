// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {ETHStorageAdapter} from "../src/ethstorage/ETHStorageAdapter.sol";
import {ETHStorageMarketData} from "../src/ethstorage/ETHStorageMarketData.sol";

/**
 * @title DeployETHStorageAdapterScript
 * @dev Deployment script for ETH Storage integration components
 */
contract DeployETHStorageAdapterScript is Script {
    // Mock ETH Storage contract address - replace with actual address for mainnet/testnet
    address constant ETH_STORAGE_CONTRACT = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D;
    
    function run() public {
        console.log("Starting deployment of ETH Storage integration components...");
        
        // Retrieve private key and address for deployment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);
        
        console.log("Deployer address:", deployerAddress);
        
        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy ETH Storage adapter
        ETHStorageAdapter adapter = new ETHStorageAdapter(ETH_STORAGE_CONTRACT);
        console.log("ETHStorageAdapter deployed at:", address(adapter));
        
        // Deploy ETH Storage market data service
        ETHStorageMarketData marketData = new ETHStorageMarketData(ETH_STORAGE_CONTRACT);
        console.log("ETHStorageMarketData deployed at:", address(marketData));
        
        // Stop broadcasting transactions
        vm.stopBroadcast();
        
        console.log("ETH Storage integration components deployment completed");
    }
} 