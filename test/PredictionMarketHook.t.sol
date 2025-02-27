// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
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


contract PoolManagerHandler {
    function initialize(PoolKey calldata, uint160) external pure returns (int24 tick) {
        return 0; // Return initial tick of 0
    }

    function modifyLiquidity(PoolKey calldata, IPoolManager.ModifyLiquidityParams calldata, bytes calldata)
        external
        pure
        returns (BalanceDelta delta, BalanceDelta fees)
    {
        // Return empty balance deltas
        return (BalanceDelta.wrap(0), BalanceDelta.wrap(0));
    }

    function swap(PoolKey calldata, IPoolManager.SwapParams calldata, bytes calldata)
        external
        pure
        returns (BalanceDelta delta)
    {
        // Return empty balance delta
        return BalanceDelta.wrap(0);
    }
}

contract PredictionMarketHookTest is Test {
    PredictionMarketHook hook;
    ERC20Mock usdc;
    ERC20Mock yesToken;
    ERC20Mock noToken;
    IPoolManager poolManager;
    
    
    uint256 startTime;
    uint256 endTime;
    address user = makeAddr("user");
    address owner = makeAddr("owner");

    function setUp() public {
    vm.startPrank(owner);
    
    // Deploy tokens
    usdc = new ERC20Mock();
    yesToken = new ERC20Mock();
    noToken = new ERC20Mock();
    
    // Setup timestamps
    startTime = block.timestamp + 1 days;
    endTime = startTime + 7 days;

    // Deploy PoolManager mock
    MockContract mockPoolManager = new MockContract();
    poolManager = IPoolManager(address(mockPoolManager));

    // Setup mock responses
    MockContract(payable(address(poolManager))).setImplementation(address(new PoolManagerHandler()));

    // Find valid hook address with the correct flags
    (address hookAddress, bytes32 salt) = HookMiner.find(
        address(this),
        uint160(Hooks.BEFORE_ADD_LIQUIDITY_FLAG | Hooks.BEFORE_REMOVE_LIQUIDITY_FLAG | Hooks.BEFORE_SWAP_FLAG),
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

    hook = new PredictionMarketHook{salt: salt}(
        poolManager,
        address(usdc),
        address(yesToken),
        address(noToken),
        startTime,
        endTime
    );

    require(address(hook) == hookAddress, "Hook address mismatch");
    
    hook.initializePools();
    
    vm.stopPrank();
    }

    // Helper function to get pool components
    function getPoolComponents(bool isYesPool) internal view returns (
        Currency currency0,
        Currency currency1,
        uint24 fee,
        int24 tickSpacing,
        IHooks hooks
    ) {
        return isYesPool ? hook.yesPoolKey() : hook.noPoolKey();
    }

    // Test 1: Verify pool initialization parameters
    function test_PoolInitialization() public {
        // Yes pool
        (
            Currency yesCurrency0,
            Currency yesCurrency1,
            uint24 yesFee,
            int24 yesTickSpacing,
            IHooks yesHooks
        ) = getPoolComponents(true);
        
        assertEq(Currency.unwrap(yesCurrency0), address(usdc));
        assertEq(Currency.unwrap(yesCurrency1), address(yesToken));
        assertEq(yesFee, 3000);
        assertEq(yesTickSpacing, 60);
        assertEq(address(yesHooks), address(hook));

        // No pool
        (
            Currency noCurrency0,
            Currency noCurrency1,
            uint24 noFee,
            int24 noTickSpacing,
            IHooks noHooks
        ) = getPoolComponents(false);
        
        assertEq(Currency.unwrap(noCurrency0), address(usdc));
        assertEq(Currency.unwrap(noCurrency1), address(noToken));
        assertEq(noFee, 3000);
        assertEq(noTickSpacing, 60);
        assertEq(address(noHooks), address(hook));
    }

    // Test 2: Verify betting window enforcement
    function test_BettingWindowEnforcement() public {
        // Get valid pool key
        (
            Currency currency0,
            Currency currency1,
            uint24 fee,
            int24 tickSpacing,
            IHooks hooks
        ) = getPoolComponents(true);
        PoolKey memory poolKey = PoolKey(currency0, currency1, fee, tickSpacing, hooks);

        IPoolManager.SwapParams memory params = IPoolManager.SwapParams({
            zeroForOne: true,
            amountSpecified: 100e6,
            sqrtPriceLimitX96: TickMath.MAX_SQRT_PRICE - 1
        });

        // Before start
        vm.expectRevert("Betting closed");
        hook.beforeSwap(user, poolKey, params, "");

        // During window
        vm.warp(startTime + 1);
        (bytes4 selector,,) = hook.beforeSwap(user, poolKey, params, "");
        assertEq(selector, IHooks.beforeSwap.selector);

        // After end
        vm.warp(endTime + 1);
        vm.expectRevert("Betting closed");
        hook.beforeSwap(user, poolKey, params, "");
    }

    // Test 3: Verify liquidity management restrictions
    function test_LiquidityManagementRestrictions() public {
        (
            Currency currency0,
            Currency currency1,
            uint24 fee,
            int24 tickSpacing,
            IHooks hooks
        ) = getPoolComponents(true);
        PoolKey memory poolKey = PoolKey(currency0, currency1, fee, tickSpacing, hooks);

        IPoolManager.ModifyLiquidityParams memory params = IPoolManager.ModifyLiquidityParams({
            tickLower: -887272,
            tickUpper: 887272,
            liquidityDelta: 1e18,
            salt: keccak256("test")
        });

        // Before start
        vm.expectRevert("Betting closed");
        hook.beforeAddLiquidity(user, poolKey, params, "");

        // During window
        vm.warp(startTime + 1);
        bytes4 selector = hook.beforeAddLiquidity(user, poolKey, params, "");
        assertEq(selector, IHooks.beforeAddLiquidity.selector);

        // After end
        vm.warp(endTime + 1);
        vm.expectRevert("Betting closed");
        hook.beforeAddLiquidity(user, poolKey, params, "");
    }

    // Test 4: Verify outcome resolution and payout
    function test_OutcomeResolutionAndPayout() public {
        // Initial balances
        uint256 initialUSDC = usdc.balanceOf(owner);
        uint256 initialYes = yesToken.balanceOf(owner);
        uint256 initialNo = noToken.balanceOf(owner);

        // Resolve outcome
        vm.warp(endTime + 1);
        vm.prank(owner);
        hook.resolveOutcome(true);

        // Verify resolution
        assertTrue(hook.resolved());
        assertTrue(hook.outcomeIsYes());

        // Verify balances
        assertEq(hook.totalUSDC() > 0, true);

        // Test claim
        uint256 userBalance = 100e18;
        yesToken.mint(user, userBalance);
        
        vm.prank(user);
        hook.claim();
        
        uint256 expectedShare = (userBalance * hook.totalUSDC()) / 
            (yesToken.totalSupply() - hook.hookYesBalance());
        assertEq(usdc.balanceOf(user), expectedShare);
    }

    // Test 5: Verify access control
    function test_AccessControl() public {
        vm.warp(endTime + 1);
        
        // Non-owner resolution
        vm.expectRevert("Ownable: caller is not the owner");
        hook.resolveOutcome(true);

        // Unauthorized pool initialization
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(user);
        hook.initializePools();
    }

    // Test 6: Verify invalid pool detection
    function test_InvalidPoolDetection() public {
        // Create invalid pool
        PoolKey memory invalidPool = PoolKey({
            currency0: Currency.wrap(address(usdc)),
            currency1: Currency.wrap(address(0xDead)),
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(address(hook))
        });

        IPoolManager.SwapParams memory params = IPoolManager.SwapParams({
            zeroForOne: true,
            amountSpecified: 100e6,
            sqrtPriceLimitX96: TickMath.MAX_SQRT_PRICE - 1
        });

        vm.expectRevert("Invalid pool");
        hook.beforeSwap(user, invalidPool, params, "");
    }

    // Test 7: Verify liquidity calculations
    function test_LiquidityCalculations() public {
        (
            Currency currency0,
            Currency currency1,
            uint24 fee,
            int24 tickSpacing,
            IHooks hooks
        ) = getPoolComponents(true);
        PoolKey memory poolKey = PoolKey(currency0, currency1, fee, tickSpacing, hooks);

        uint256 amount0 = 50_000e6;
        uint256 amount1 = 50_000e18;
        
        uint160 sqrtPriceX96 = TickMath.getSqrtPriceAtTick(0);
        uint160 sqrtPriceAX96 = TickMath.getSqrtPriceAtTick(-887272);
        uint160 sqrtPriceBX96 = TickMath.getSqrtPriceAtTick(887272);

        uint128 liquidity = LiquidityAmounts.getLiquidityForAmounts(
            sqrtPriceX96,
            sqrtPriceAX96,
            sqrtPriceBX96,
            amount0,
            amount1
        );

        assertGt(liquidity, 0, "Liquidity should be positive");
    }
}