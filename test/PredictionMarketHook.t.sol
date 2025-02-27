// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console2} from "forge-std/Test.sol";
import {PredictionMarketHook} from "../src/Hooks/PredictionMarketHook.sol";
import {IPoolManager} from "@v4-core/interfaces/IPoolManager.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {PoolKey, Currency} from "@v4-core/types/PoolKey.sol";
import {TickMath} from "@v4-core/libraries/TickMath.sol";
import {IHooks} from "@v4-core/interfaces/IHooks.sol";
import {BalanceDelta} from "@v4-core/types/BalanceDelta.sol";
import {LiquidityAmounts} from "@v4-periphery/libraries/LiquidityAmounts.sol";
import {Hooks} from "@v4-core/libraries/Hooks.sol";
import {MockContract} from "@v4-core/test/MockContract.sol";
import {MockHooks} from "@v4-core/test/MockHooks.sol";
import {HookMiner} from "@v4-periphery/utils/HookMiner.sol";
import {Pool} from "@v4-core/libraries/Pool.sol";
import {SwapMath} from "@v4-core/libraries/SwapMath.sol";

contract PredictionMarketHookTest is Test {
    PredictionMarketHook public hook;
    PoolManagerHandler public poolManager;
    ERC20Mock public usdc;
    ERC20Mock public yesToken;
    ERC20Mock public noToken;
    uint256 public startTime;
    uint256 public endTime;

    function setUp() public {
        // Deploy mock tokens
        usdc = new ERC20Mock();
        yesToken = new ERC20Mock();
        noToken = new ERC20Mock();

        // Deploy pool manager mock
        poolManager = new PoolManagerHandler();

        // Set up timestamps
        startTime = block.timestamp;
        endTime = startTime + 7 days;

        // Calculate hook address with required flags
        uint160 flags = uint160(
            Hooks.BEFORE_ADD_LIQUIDITY_FLAG |
            Hooks.BEFORE_REMOVE_LIQUIDITY_FLAG |
            Hooks.BEFORE_SWAP_FLAG |
            Hooks.AFTER_SWAP_FLAG
        );

        // Deploy the hook
        (address hookAddress,) = HookMiner.find(
            address(this), 
            flags, 
            type(PredictionMarketHook).creationCode,
            abi.encode(
                address(poolManager),
                address(usdc),
                address(yesToken),
                address(noToken),
                startTime,
                endTime
            )
        );

        // Deploy hook with CREATE2
        hook = new PredictionMarketHook{salt: bytes32(0)}(
            IPoolManager(address(poolManager)),
            address(usdc),
            address(yesToken),
            address(noToken),
            startTime,
            endTime
        );

        // Mint initial tokens
        usdc.mint(address(this), 1_000_000e6);
        yesToken.mint(address(this), 1_000_000e18);
        noToken.mint(address(this), 1_000_000e18);

        // Approve tokens
        usdc.approve(address(hook), type(uint256).max);
        yesToken.approve(address(hook), type(uint256).max);
        noToken.approve(address(hook), type(uint256).max);
    }

    function test_InitializePools() public {
        hook.initializePools();
        
        // Check initial state
        assertEq(hook.usdcInYesPool(), 50_000e6, "Incorrect USDC amount in YES pool");
        assertEq(hook.usdcInNoPool(), 50_000e6, "Incorrect USDC amount in NO pool");
        assertEq(hook.yesTokensInPool(), 50_000e18, "Incorrect YES tokens in pool");
        assertEq(hook.noTokensInPool(), 50_000e18, "Incorrect NO tokens in pool");
    }

    function test_GetOdds() public {
        hook.initializePools();
        
        (uint256 yesOdds, uint256 noOdds) = hook.getOdds();
        assertEq(yesOdds, 50, "Initial YES odds should be 50");
        assertEq(noOdds, 50, "Initial NO odds should be 50");
    }

    function test_RevertWhenBettingClosed() public {
        // Move time past end time
        vm.warp(endTime + 1);
        
        vm.expectRevert("Betting closed");
        hook.initializePools();
    }
}

contract PoolManagerHandler {
    // Mock values for token holdings
    mapping(address => mapping(address => uint256)) public tokenBalances;

    function initialize(PoolKey calldata, uint160) external pure returns (int24 tick) {
        return 0; // Return initial tick of 0
    }

    function modifyLiquidity(PoolKey calldata key, IPoolManager.ModifyLiquidityParams calldata params, bytes calldata)
        external
        returns (BalanceDelta delta, BalanceDelta fees)
    {
        // Simulate modifyLiquidity behavior
        address token0 = Currency.unwrap(key.currency0);
        address token1 = Currency.unwrap(key.currency1);

        // For adding liquidity
        if (params.liquidityDelta > 0) {
            // Calculate amounts based on provided liquidity
            uint256 amount0 = uint256(uint128(uint256(params.liquidityDelta))) * 1e6; // Fixed conversion
            uint256 amount1 = uint256(uint128(uint256(params.liquidityDelta))) * 1e18; // Fixed conversion
            
            // Track the token amounts
            tokenBalances[msg.sender][token0] += amount0;
            tokenBalances[msg.sender][token1] += amount1;
            
            // Return the simulated delta (negative means tokens taken from user)
            delta = BalanceDelta.wrap(-(int256(amount0) << 128 | int256(amount1)));
        } 
        // For removing liquidity
        else if (params.liquidityDelta < 0) {
            // Calculate amounts based on provided liquidity - fixed conversion
            int256 absDelta = -params.liquidityDelta;
            uint256 amount0 = uint256(uint128(uint256(absDelta))) * 1e6;
            uint256 amount1 = uint256(uint128(uint256(absDelta))) * 1e18;
            
            // Return the simulated delta (positive means tokens given to user)
            delta = BalanceDelta.wrap(int256(amount0) << 128 | int256(amount1));
        }
        
        return (delta, BalanceDelta.wrap(0));
    }

    function swap(PoolKey calldata key, IPoolManager.SwapParams calldata params, bytes calldata)
        external
        returns (BalanceDelta delta)
    {
        // Simulate swap behavior
        address token0 = Currency.unwrap(key.currency0);
        address token1 = Currency.unwrap(key.currency1);

        // Simplified swap logic
        if (params.zeroForOne) {
            // User provides token0, receives token1
            uint256 token0In = uint256(int256(params.amountSpecified));
            uint256 token1Out = token0In * 95 / 100; // 5% slippage for simplicity
            
            // Track the token changes
            tokenBalances[msg.sender][token0] += token0In;
            
            // Return the simulated delta (negative for token0 in, positive for token1 out)
            delta = BalanceDelta.wrap(-(int256(token0In) << 128) | int256(token1Out));
        } else {
            // User provides token1, receives token0
            uint256 token1In = uint256(int256(params.amountSpecified));
            uint256 token0Out = token1In * 95 / 100; // 5% slippage for simplicity
            
            // Track the token changes
            tokenBalances[msg.sender][token1] += token1In;
            
            // Return the simulated delta (positive for token0 out, negative for token1 in)
            delta = BalanceDelta.wrap(int256(token0Out) << 128 | -(int256(token1In)));
        }
        
        return delta;
    }

    // Helper function to simulate getInternalPrice (for getOdds)
    function sqrtPriceX96ToPrice(uint160 sqrtPriceX96, uint8 decimals0, uint8 decimals1) external pure returns (uint256) {
        uint256 price = uint256(sqrtPriceX96) * uint256(sqrtPriceX96);
        // Scale by 2^192 / 10^decimals0 / 10^decimals1
        uint256 scale = uint256(1) << 192;
        uint256 decimalAdjustment = 10**(decimals0 + decimals1);
        return price * scale / decimalAdjustment;
    }
}