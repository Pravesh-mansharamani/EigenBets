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
import {IUnlockCallback} from "@v4-core/interfaces/callback/IUnlockCallback.sol";

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

        (address hookAddress, bytes32 salt) = HookMiner.find(
            address(this), // Deployer address
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

        // Deploy the hook with the correct salt
        hook = new PredictionMarketHook{salt: salt}(
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

    function test_SwapForYesToken() public {
        hook.initializePools();
        uint256 usdcAmount = 100e6;
        
        // Track initial balances
        uint256 initialYesPoolUSDC = hook.usdcInYesPool();
        uint256 initialYesTokens = hook.yesTokensInPool();
            
        // Get the pool key components from the hook's getter
        (Currency currency0, Currency currency1, uint24 fee, int24 tickSpacing, IHooks hooks) = hook.getYesPoolKeyComponents();
        
        // Construct the PoolKey
        PoolKey memory poolKey = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: fee,
            tickSpacing: tickSpacing,
            hooks: hooks
        });

        IPoolManager.SwapParams memory params = IPoolManager.SwapParams({
            zeroForOne: true,
            amountSpecified: int256(usdcAmount),
            sqrtPriceLimitX96: TickMath.MAX_SQRT_PRICE - 1
        });

        // Execute swap
        poolManager.swap(poolKey, params, "");
        
        // Verify balances updated correctly
        assertGt(hook.usdcInYesPool(), initialYesPoolUSDC, "USDC in YES pool should increase");
        assertLt(hook.yesTokensInPool(), initialYesTokens, "YES tokens in pool should decrease");
        
        // Verify the magnitude of changes
        assertEq(hook.usdcInYesPool() - initialYesPoolUSDC, usdcAmount, "USDC amount added should match input");
        assertGt(initialYesTokens - hook.yesTokensInPool(), 0, "Should have received YES tokens");
    }

    function test_SwapForNoToken() public {
        hook.initializePools();
        uint256 usdcAmount = 100e6;
        
        // Track initial balances
        uint256 initialNoPoolUSDC = hook.usdcInNoPool();
        uint256 initialNoTokens = hook.noTokensInPool();
            
        // Get the pool key components from the hook's getter
        (Currency currency0, Currency currency1, uint24 fee, int24 tickSpacing, IHooks hooks) = hook.getNoPoolKeyComponents();
        
        // Construct the PoolKey
        PoolKey memory poolKey = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: fee,
            tickSpacing: tickSpacing,
            hooks: hooks
        });

        IPoolManager.SwapParams memory params = IPoolManager.SwapParams({
            zeroForOne: true,
            amountSpecified: int256(usdcAmount),
            sqrtPriceLimitX96: TickMath.MAX_SQRT_PRICE - 1
        });

        // Execute swap
        poolManager.swap(poolKey, params, "");
        
        // Verify balances updated correctly
        assertGt(hook.usdcInNoPool(), initialNoPoolUSDC, "USDC in NO pool should increase");
        assertLt(hook.noTokensInPool(), initialNoTokens, "NO tokens in pool should decrease");
        
        // Verify the magnitude of changes
        assertEq(hook.usdcInNoPool() - initialNoPoolUSDC, usdcAmount, "USDC amount added should match input");
        assertGt(initialNoTokens - hook.noTokensInPool(), 0, "Should have received NO tokens");
    }

    // Test claim functionality
    function test_ClaimWinnings() public {
        // Setup: place bet and resolve
        hook.initializePools();
        
        // Make a swap to get Yes tokens
        uint256 usdcAmount = 100e6;
        
        // Get the pool key components
        (Currency currency0, Currency currency1, uint24 fee, int24 tickSpacing, IHooks hooks) = hook.getYesPoolKeyComponents();
        
        // Construct the PoolKey
        PoolKey memory poolKey = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: fee,
            tickSpacing: tickSpacing,
            hooks: hooks
        });

        // Execute swap to get Yes tokens
        IPoolManager.SwapParams memory params = IPoolManager.SwapParams({
            zeroForOne: true,
            amountSpecified: int256(usdcAmount),
            sqrtPriceLimitX96: TickMath.MAX_SQRT_PRICE - 1
        });
        
        // Execute swap to get Yes tokens
        poolManager.swap(poolKey, params, "");
        
        // Move time past end time
        vm.warp(hook.endTime() + 1);
        
        // The key insight: In a real environment, the hook would receive USDC back from the pools
        // But in our test, we need to simulate this by minting USDC to the hook
        uint256 totalPayout = 100_000e6; // A reasonable amount that should cover the claim
        usdc.mint(address(hook), totalPayout);
        
        // Now resolve the outcome
        hook.resolveOutcome(true);
        
        // Get initial USDC balance
        uint256 initialUSDCBalance = usdc.balanceOf(address(this));
        
        // Claim winnings
        hook.claim();
        
        // Verify that USDC balance increased
        assertGt(usdc.balanceOf(address(this)), initialUSDCBalance, "USDC balance should increase after claim");
    }

    // Fixed betting closed test
    function test_RevertWhenBettingClosed_Swap() public {
        // Initialize pools first
        hook.initializePools();
        
        // Move time past end time
        vm.warp(hook.endTime() + 1);
        
        // Get the pool key components from the hook's getter
        (Currency currency0, Currency currency1, uint24 fee, int24 tickSpacing, IHooks hooks) = hook.getYesPoolKeyComponents();
        
        // Construct the PoolKey
        PoolKey memory poolKey = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: fee,
            tickSpacing: tickSpacing,
            hooks: hooks
        });

        IPoolManager.SwapParams memory params = IPoolManager.SwapParams({
            zeroForOne: true,
            amountSpecified: int256(100e6),
            sqrtPriceLimitX96: TickMath.MAX_SQRT_PRICE - 1
        });

        // This should revert with "Betting closed"
        vm.expectRevert(bytes("Betting closed"));
        poolManager.swap(poolKey, params, "");
    }

    // function test_RevertWhenBettingClosed() public {
    //     // Move time past end time
    //     vm.warp(endTime + 1);
        
    //     vm.expectRevert("Betting closed");
    //     hook.initializePools();
    // }
}

contract PoolManagerHandler {
    // Mock values for token holdings
    mapping(address => mapping(address => uint256)) public tokenBalances;
    
    // Track pool balances
    mapping(address => uint256) public poolBalances;

    // Common variables stored as state variables to reduce stack usage
    uint256 internal constant FEE_NUMERATOR = 3000; // 0.3%
    uint256 internal constant FEE_DENOMINATOR = 1_000_000;

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
            poolBalances[token0] += amount0;
            poolBalances[token1] += amount1;
            
            // Return the simulated delta (negative means tokens taken from user)
            delta = BalanceDelta.wrap(-(int256(amount0) << 128 | int256(amount1)));
        } 
        // For removing liquidity
        else if (params.liquidityDelta < 0) {
            // For withdrawing all liquidity (type(int128).min), use the pool balances directly
            // This avoids overflow issues when converting the large negative number
            if (params.liquidityDelta == type(int128).min) {
                uint256 amount0 = poolBalances[token0];
                uint256 amount1 = poolBalances[token1];
                
                // Reset pool balances to zero
                poolBalances[token0] = 0;
                poolBalances[token1] = 0;
                
                // Return the simulated delta (positive means tokens given to user)
                delta = BalanceDelta.wrap(int256(amount0) << 128 | int256(amount1));
            } else {
                // Normal liquidity removal
                int256 absDelta = -params.liquidityDelta;
                uint256 amount0 = uint256(uint128(uint256(absDelta))) * 1e6;
                uint256 amount1 = uint256(uint128(uint256(absDelta))) * 1e18;
                
                // Ensure we don't remove more than exists
                amount0 = amount0 > poolBalances[token0] ? poolBalances[token0] : amount0;
                amount1 = amount1 > poolBalances[token1] ? poolBalances[token1] : amount1;
                
                // Track the token amounts
                poolBalances[token0] -= amount0;
                poolBalances[token1] -= amount1;
                
                // Return the simulated delta (positive means tokens given to user)
                delta = BalanceDelta.wrap(int256(amount0) << 128 | int256(amount1));
            }
        }
        
        return (delta, BalanceDelta.wrap(0));
    }

    function unlock(bytes calldata data) external returns (bytes memory) {
        // Call the unlockCallback on the caller, which should be the hook contract
        bytes memory result = IUnlockCallback(msg.sender).unlockCallback(data);
        return result;
    }

    function swap(PoolKey calldata key, IPoolManager.SwapParams calldata params, bytes calldata)
        external
        returns (BalanceDelta delta)
    {
        // First check with the hook's beforeSwap function
        // This will revert if betting is closed or the pool is invalid
        _checkBeforeSwap(key, params);
        
        // Proceed with swap only if beforeSwap didn't revert
        // Simulate swap behavior
        address token0 = Currency.unwrap(key.currency0);
        address token1 = Currency.unwrap(key.currency1);

        // Calculate swap amounts
        if (params.zeroForOne) {
            // Calculate for token0 -> token1 direction
            delta = _swapZeroForOne(token0, token1, params.amountSpecified);
        } else {
            // Calculate for token1 -> token0 direction
            delta = _swapOneForZero(token0, token1, params.amountSpecified);
        }
        
        // Call the hook's afterSwap to update its state
        _callAfterSwap(key, params, delta);

        return delta;
    }
    
    function _checkBeforeSwap(PoolKey calldata key, IPoolManager.SwapParams calldata params) internal {
        (bytes4 beforeSelector, , ) = IHooks(address(key.hooks)).beforeSwap(
            msg.sender,
            key,
            params,
            ""
        );
        
        require(beforeSelector == IHooks.beforeSwap.selector, "Invalid beforeSwap selector");
    }
    
    function _swapZeroForOne(address token0, address token1, int256 amountSpecified) internal returns (BalanceDelta delta) {
        uint256 token0In = uint256(amountSpecified);
        uint256 feeAmount = (token0In * FEE_NUMERATOR) / FEE_DENOMINATOR;
        uint256 token0InAfterFee = token0In - feeAmount;
        uint256 token1Out = (token0InAfterFee * poolBalances[token1]) / (poolBalances[token0] + token0InAfterFee);
        
        // Update pool balances
        poolBalances[token0] += token0In;
        poolBalances[token1] -= token1Out;
        
        // Return the simulated delta (negative for token0 in, positive for token1 out)
        return BalanceDelta.wrap(-(int256(token0In) << 128) | int256(token1Out));
    }
    
    function _swapOneForZero(address token0, address token1, int256 amountSpecified) internal returns (BalanceDelta delta) {
        uint256 token1In = uint256(amountSpecified);
        uint256 feeAmount = (token1In * FEE_NUMERATOR) / FEE_DENOMINATOR;
        uint256 token1InAfterFee = token1In - feeAmount;
        uint256 token0Out = (token1InAfterFee * poolBalances[token0]) / (poolBalances[token1] + token1InAfterFee);
        
        // Update pool balances
        poolBalances[token1] += token1In;
        poolBalances[token0] -= token0Out;
        
        // Return the simulated delta (positive for token0 out, negative for token1 in)
        return BalanceDelta.wrap(int256(token0Out) << 128 | -(int256(token1In)));
    }
    
    function _callAfterSwap(PoolKey calldata key, IPoolManager.SwapParams calldata params, BalanceDelta delta) internal {
        (bytes4 selector,) = IHooks(address(key.hooks)).afterSwap(
            msg.sender,
            key,
            params,
            delta,
            ""
        );
        require(selector == IHooks.afterSwap.selector, "Invalid afterSwap selector");
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