// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console2} from "lib/v4-core/lib/forge-std/src/Script.sol";
import {PredictionMarketHook} from "../src/Hooks/PredictionMarketHook.sol";
import {IPoolManager} from "lib/v4-core/src/interfaces/IPoolManager.sol";
import {ERC20Mock} from "lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";
import {HookMiner} from "@v4-periphery/utils/HookMiner.sol";
import {Hooks} from "@v4-core/libraries/Hooks.sol";

contract DeployPredictionMarket is Script {
    // Pre-compute the hook address with required flags embedded
    function getHookAddress(uint160 flags) public view returns (address) {
        // Compute the init code hash of the hook
        bytes memory creationCode = type(PredictionMarketHook).creationCode;
        
        // Deploy a dummy PoolManager for testing, we'll replace this with the real address later
        address dummyPoolManager = address(0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408);
        address dummyUsdc = address(0x1);
        address dummyYesToken = address(0x2);
        address dummyNoToken = address(0x3);
        uint256 dummyStartTime = 1000;
        uint256 dummyEndTime = 2000;
        
        bytes memory constructorArgs = abi.encode(
            dummyPoolManager,
            dummyUsdc,
            dummyYesToken,
            dummyNoToken,
            dummyStartTime,
            dummyEndTime
        );
        
        bytes memory bytecode = abi.encodePacked(creationCode, constructorArgs);
        bytes32 initCodeHash = keccak256(bytecode);
        
        console2.log("Init code hash:");
        console2.logBytes32(initCodeHash);
        
        // Try many salt values to find one that produces an address with the right flags
        for (uint256 i = 0; i < 1000000; i++) {
            bytes32 salt = bytes32(i);
            address hookAddress = _computeCreate2AddressWithDeployer(salt, initCodeHash, address(this));
            
            // Check if the address has the required flags
            if (uint160(hookAddress) & flags == flags) {
                console2.log("Found valid hook address:", hookAddress);
                console2.log("With salt:", uint256(salt));
                return hookAddress;
            }
        }
        
        revert("Couldn't find a valid hook address");
    }
    
    function _computeCreate2AddressWithDeployer(bytes32 salt, bytes32 initCodeHash, address deployer) internal pure returns (address) {
        return address(uint160(uint256(keccak256(abi.encodePacked(
            bytes1(0xff),
            deployer,
            salt,
            initCodeHash
        )))));
    }

    function computeCreate2Address(bytes32 salt, bytes32 initCodeHash) internal pure override returns (address) {
        // Using a constant address for CREATE2 computation
        address deployer = address(0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84);
        return address(uint160(uint256(keccak256(abi.encodePacked(
            bytes1(0xff),
            deployer,
            salt,
            initCodeHash
        )))));
    }

    function run() external {
        // Add console logs for debugging
        console2.log("Starting deployment script");
        
        // Load private key from .env
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        console2.log("Deployer address:", deployer);
        
        // Calculate the hook flags based on the hook's permissions
        uint160 hookFlags = uint160(
            Hooks.BEFORE_ADD_LIQUIDITY_FLAG | 
            Hooks.BEFORE_REMOVE_LIQUIDITY_FLAG | 
            Hooks.BEFORE_SWAP_FLAG
        );
        console2.log("Hook flags:", uint256(hookFlags));
        
        // Find a valid hook address
        address validHookAddress = getHookAddress(hookFlags);
        console2.log("Valid hook address found:", validHookAddress);
        
        vm.startBroadcast(deployerPrivateKey);

        // Deploy mock tokens
        console2.log("Deploying mock tokens...");
        ERC20Mock usdc = new ERC20Mock();
        ERC20Mock yesToken = new ERC20Mock();
        ERC20Mock noToken = new ERC20Mock();
        
        console2.log("USDC address:", address(usdc));
        console2.log("YES token address:", address(yesToken));
        console2.log("NO token address:", address(noToken));

        // Mint initial tokens to the deployer
        console2.log("Minting tokens to deployer...");
        usdc.mint(deployer, 100_000_000e6); // 100M USDC
        yesToken.mint(deployer, 100_000_000e18); // 100M YesToken
        noToken.mint(deployer, 100_000_000e18); // 100M NoToken

        // Deploy PoolManager (use actual address on Base testnet)
        address poolManagerAddr = 0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408;
        console2.log("Using PoolManager at:", poolManagerAddr);
        IPoolManager poolManager = IPoolManager(poolManagerAddr);

        // Calculate timestamps (1 day from now -> 7 day duration)
        uint256 startTime = block.timestamp + 1 days;
        uint256 endTime = startTime + 7 days;
        console2.log("Start time:", startTime);
        console2.log("End time:", endTime);

        // Direct approach using the HookMiner.find function from the test file
        console2.log("Trying direct hook mining...");
        (address hookAddress, bytes32 salt) = HookMiner.find(
            address(this),
            hookFlags,
            type(PredictionMarketHook).creationCode,
            abi.encode(
                poolManager,
                address(usdc),
                address(yesToken),
                address(noToken),
                startTime,
                endTime
            )
        );
        
        console2.log("HookMiner found address:", hookAddress);
        console2.log("Using salt:", vm.toString(salt));
        
        // Deploy the hook using CREATE2 with the calculated salt
        console2.log("Deploying PredictionMarketHook...");
        
        // ===== THE CRITICAL CHANGE =====
        // Instead of using 'new PredictionMarketHook{salt: salt}(...)', use vm.broadcast
        // with the exact salt and bytecode to ensure the correct address
        bytes memory creationCode = type(PredictionMarketHook).creationCode;
        bytes memory constructorArgs = abi.encode(
            poolManager,
            address(usdc),
            address(yesToken),
            address(noToken),
            startTime,
            endTime
        );
        bytes memory bytecode = abi.encodePacked(creationCode, constructorArgs);
        
        // Use assembly to deploy with CREATE2
        address deployedHook;
        assembly {
            deployedHook := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            if iszero(deployedHook) {
                revert(0, 0)
            }
        }
        
        console2.log("Hook deployed at:", deployedHook);
        
        // Check that the deployed address matches the expected hook address
        require(deployedHook == hookAddress, "Hook address mismatch");
        
        PredictionMarketHook hook = PredictionMarketHook(deployedHook);
        
        // Initialize pools
        console2.log("Initializing pools...");
        hook.initializePools();
        console2.log("Pools initialized");
        
        vm.stopBroadcast();
        console2.log("Deployment completed successfully");
    }
}