// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "lib/v4-core/lib/forge-std/src/Script.sol";
import {PredictionMarketHook} from "../src/Hooks/PredictionMarketHook.sol";
import {IPoolManager} from "lib/v4-core/src/interfaces/IPoolManager.sol";
import {ERC20Mock} from "lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";

contract DeployPredictionMarket is Script {
    function run() external {
        // Load private key from .env
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);

        // Deploy mock tokens
        ERC20Mock usdc = new ERC20Mock();
        ERC20Mock yesToken = new ERC20Mock();
        ERC20Mock noToken = new ERC20Mock();

        // Mint initial tokens to the deployer
        usdc.mint(msg.sender, 100_000_000e6); // 100M USDC
        yesToken.mint(msg.sender, 100_000_000e18); // 100M YesToken
        noToken.mint(msg.sender, 100_000_000e18); // 100M NoToken

        // Deploy PoolManager (use actual address on Base testnet)
        IPoolManager poolManager = IPoolManager(0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408);

        // Calculate timestamps (1 day from now -> 7 day duration)
        uint256 startTime = block.timestamp + 1 days;
        uint256 endTime = startTime + 7 days;

        // Deploy prediction market hook
        PredictionMarketHook hook = new PredictionMarketHook(
            poolManager,
            address(usdc),
            address(yesToken),
            address(noToken),
            startTime,
            endTime
        );

        // Initialize pools
        hook.initializePools();

        vm.stopBroadcast();
    }
}