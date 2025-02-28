// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console, console2} from "forge-std/Script.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";
import {YesToken} from "../src/YesToken.sol";
import {NoToken} from "../src/NoToken.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {PredictionMarketHook} from "../src/Hooks/PredictionMarketHook.sol";
import {HookMiner} from "lib/v4-periphery/src/utils/HookMiner.sol";
import {IPoolManager} from "@v4-core/interfaces/IPoolManager.sol";

contract DeployPredictionMarketScript is Script {
    function run() external {
        console.log("Starting PredictionMarketHook deployment script");

        // Load deployer private key and address
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        console.log("Deployer:", deployer);

        // // Calculate hook flags (using a 16-bit mask shifted to the highest 16 bits)
        // uint16 mask = 0;
        // mask |= 1 << 13; // BEFORE_ADD_LIQUIDITY_FLAG
        // mask |= 1 << 11; // BEFORE_REMOVE_LIQUIDITY_FLAG
        // mask |= 1 << 9;  // BEFORE_SWAP_FLAG
        // mask |= 1 << 8;  // AFTER_SWAP_FLAG
        // uint160 flags = uint160(mask) << 144;
        // console.log("Hook flags:", uint256(flags));

        uint160 flags = uint160(
            Hooks.BEFORE_ADD_LIQUIDITY_FLAG |
            Hooks.BEFORE_REMOVE_LIQUIDITY_FLAG |
            Hooks.BEFORE_SWAP_FLAG |
            Hooks.AFTER_SWAP_FLAG
        );

        address poolManagerAddress = vm.envOr("POOL_MANAGER_ADDRESS", address(0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408));
        console.log("PoolManager:", poolManagerAddress);

        address create2Deployer = vm.envOr("CREATE2_DEPLOYER_ADDRESS", address(0x4e59b44847b379578588920cA78FbF26c0B4956C));
        console.log("Using CREATE2 deployer:", create2Deployer);

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy tokens:
        console.log("Deploying token contracts...");
        ERC20Mock usdc = new ERC20Mock();
        usdc.mint(deployer, 1_000_000_000_000); // Mint 1e12 USDC units
        YesToken yesToken = new YesToken();
        NoToken noToken = new NoToken();
        console.log("USDC address:", address(usdc));
        console.log("YES token address:", address(yesToken));
        console.log("NO token address:", address(noToken));

        console.log("Mining for valid hook address...");
        // Mine a salt that produces a hook address with the required flags.
        (address predictedHook, bytes32 salt) = HookMiner.find(
            create2Deployer,
            flags,
            type(PredictionMarketHook).creationCode,
            abi.encode(
                IPoolManager(poolManagerAddress),
                address(usdc),
                address(yesToken),
                address(noToken)
            )
        );
        console.log("Predicted hook address:", predictedHook);
        console.log("Salt used:", vm.toString(salt));

        // Deploy the hook contract using CREATE2 with the found salt.
        PredictionMarketHook hook = new PredictionMarketHook{salt: salt}(
            IPoolManager(poolManagerAddress),
            address(usdc),
            address(yesToken),
            address(noToken)
        );
        console.log("Deployed hook at:", address(hook));
        require(address(hook) == predictedHook, "Deployed address mismatch");

        // Initialize liquidity pools:
        console.log("Initializing pools...");
        // Approve tokens for the hook
        usdc.approve(address(hook), type(uint256).max);
        yesToken.approve(address(hook), type(uint256).max);
        noToken.approve(address(hook), type(uint256).max);

        console.log("Transferring initial liquidity to the hook...");

        // Transfer initial liquidity to the hook (for example, 100k USDC and 100k tokens each)
        usdc.transfer(address(hook), 100_000e6);    // USDC (assuming 6 decimals)
        yesToken.transfer(address(hook), 100_000e18); // YES token (18 decimals)
        noToken.transfer(address(hook), 100_000e18);  // NO token (18 decimals)

        console.log("Calling initializePools() on the hook...");

        address ownerAddr = hook.checkOwner();
        console.log("Owner of the hook:", ownerAddr);

        hook.initializePools();
        console.log("Pools initialized.");

        vm.stopBroadcast();
        console.log("Deployment script completed successfully.");
    }


}
