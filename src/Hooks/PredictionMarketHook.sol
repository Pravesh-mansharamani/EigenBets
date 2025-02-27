// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {BaseHook} from "@v4-periphery/utils/BaseHook.sol";
import {IPoolManager} from "@v4-core/interfaces/IPoolManager.sol";
import {Hooks} from "@v4-core/libraries/Hooks.sol";
import {PoolKey} from "@v4-core/types/PoolKey.sol";
import {Currency, CurrencyLibrary} from "@v4-core/types/Currency.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Pool} from "@v4-core/libraries/Pool.sol";
import {TickMath} from "@v4-core/libraries/TickMath.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {BalanceDelta, toBalanceDelta, BalanceDeltaLibrary} from "@v4-core/types/BalanceDelta.sol";
import {IHooks} from "@v4-core/interfaces/IHooks.sol";
import {BeforeSwapDelta} from "@v4-core/types/BeforeSwapDelta.sol";
import {LiquidityAmounts} from "@v4-periphery/libraries/LiquidityAmounts.sol";
import {console2} from "forge-std/console2.sol";
import {PoolIdLibrary} from "@v4-core/types/PoolId.sol";

contract PredictionMarketHook is BaseHook, Ownable {
    using CurrencyLibrary for Currency;
    using SafeERC20 for IERC20;
    using PoolIdLibrary for PoolKey;

    address public immutable usdc;
    address public immutable yesToken;
    address public immutable noToken;
    uint256 public immutable startTime;
    uint256 public immutable endTime;

    // State variables to track pool balances
    uint256 public usdcInYesPool = 0;
    uint256 public usdcInNoPool = 0;
    uint256 public yesTokensInPool = 0;
    uint256 public noTokensInPool = 0;

    PoolKey public yesPoolKey;
    PoolKey public noPoolKey;

    bool public resolved;
    bool public outcomeIsYes;
    uint256 public totalUSDCCollected;  // Renamed to avoid shadowing
    uint256 public hookYesBalance;
    uint256 public hookNoBalance;
    
    // Track users who have already claimed
    mapping(address => bool) public hasClaimed;

    event OutcomeResolved(bool outcomeIsYes);
    event Claimed(address indexed user, uint256 amount);
    event PoolsInitialized(address yesPool, address noPool);
    event LiquidityAdded(address pool, uint256 amount0, uint256 amount1);

    constructor(
        IPoolManager _poolManager,
        address _usdc,
        address _yesToken,
        address _noToken,
        uint256 _startTime,
        uint256 _endTime
    ) BaseHook(IPoolManager(_poolManager)) Ownable(msg.sender) {
        console2.log("Initializing PredictionMarketHook");
        console2.log("USDC:", _usdc);
        console2.log("YES token:", _yesToken);
        console2.log("NO token:", _noToken);
        console2.log("Start time:", _startTime);
        console2.log("End time:", _endTime);
        
        usdc = _usdc;
        yesToken = _yesToken;
        noToken = _noToken;
        startTime = _startTime;
        endTime = _endTime;
    }

    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: true,
            afterAddLiquidity: false,
            beforeRemoveLiquidity: true,
            afterRemoveLiquidity: false,
            beforeSwap: true,
            afterSwap: true,   // Enable afterSwap to track balances
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    function _beforeAddLiquidity(
        address /* sender */,
        PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata /* params */,
        bytes calldata
    ) internal view override returns (bytes4) {
        require(_isValidPool(key), "Invalid pool");
        require(block.timestamp >= startTime && block.timestamp <= endTime, "Betting closed");
        return IHooks.beforeAddLiquidity.selector;
    }

    function _beforeRemoveLiquidity(
        address /* sender */,
        PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata /* params */,
        bytes calldata
    ) internal view override returns (bytes4) {
        require(_isValidPool(key), "Invalid pool");
        require(block.timestamp >= startTime && block.timestamp <= endTime, "Betting closed");
        return IHooks.beforeRemoveLiquidity.selector;
    }

    function _beforeSwap(
        address /* sender */,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata /* params */,
        bytes calldata
    ) internal view override returns (bytes4, BeforeSwapDelta, uint24) {
        require(_isValidPool(key), "Invalid pool");
        require(block.timestamp >= startTime && block.timestamp <= endTime, "Betting closed");
        return (IHooks.beforeSwap.selector, BeforeSwapDelta.wrap(0), 0);
    }
    
    // Implementation of afterSwap to track pool balances
    function _afterSwap(
        address /* sender */,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata /* params */,
        BalanceDelta delta,
        bytes calldata
    ) internal override returns (bytes4, int128) {
        // Determine which pool was affected
        bool isYesPool = Currency.unwrap(key.currency1) == yesToken;
        
        // Calculate USDC change (delta.amount0 if USDC is token0, delta.amount1 otherwise)
        int256 usdcDelta = Currency.unwrap(key.currency0) == usdc ? delta.amount0() : delta.amount1();
        int256 tokenDelta = Currency.unwrap(key.currency0) == usdc ? delta.amount1() : delta.amount0();
        
        // Update state variables
        if (isYesPool) {
            // negating because of how deltas work (negative means tokens came into the pool)
            if (usdcDelta < 0) {
                usdcInYesPool += uint256(-usdcDelta);
            } else {
                usdcInYesPool = usdcInYesPool > uint256(usdcDelta) ? usdcInYesPool - uint256(usdcDelta) : 0;
            }
            
            if (tokenDelta < 0) {
                yesTokensInPool += uint256(-tokenDelta);
            } else {
                yesTokensInPool = yesTokensInPool > uint256(tokenDelta) ? yesTokensInPool - uint256(tokenDelta) : 0;
            }
        } else {
            // negating because of how deltas work (negative means tokens came into the pool)
            if (usdcDelta < 0) {
                usdcInNoPool += uint256(-usdcDelta);
            } else {
                usdcInNoPool = usdcInNoPool > uint256(usdcDelta) ? usdcInNoPool - uint256(usdcDelta) : 0;
            }
            
            if (tokenDelta < 0) {
                noTokensInPool += uint256(-tokenDelta);
            } else {
                noTokensInPool = noTokensInPool > uint256(tokenDelta) ? noTokensInPool - uint256(tokenDelta) : 0;
            }
        }
        
        return (IHooks.afterSwap.selector, 0);
    }
    
    function initializePools() external onlyOwner {
        console2.log("Initializing YES pool");
        yesPoolKey = PoolKey({
            currency0: Currency.wrap(usdc),
            currency1: Currency.wrap(yesToken),
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(address(this))
        });
        
        try IPoolManager(address(poolManager)).initialize(yesPoolKey, TickMath.getSqrtPriceAtTick(0)) {
            console2.log("YES pool initialized successfully");
        } catch Error(string memory reason) {
            console2.log("Failed to initialize YES pool:", reason);
            revert(reason);
        }
        
        console2.log("Adding liquidity to YES pool");
        _mintLiquidity(yesPoolKey, 50_000e6, 50_000e18);
        console2.log("Added liquidity to YES pool");
        
        // Initialize the state tracking variables
        usdcInYesPool = 50_000e6;
        yesTokensInPool = 50_000e18;

        console2.log("Initializing NO pool");
        noPoolKey = PoolKey({
            currency0: Currency.wrap(usdc),
            currency1: Currency.wrap(noToken),
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(address(this))
        });
        
        try IPoolManager(address(poolManager)).initialize(noPoolKey, TickMath.getSqrtPriceAtTick(0)) {
            console2.log("NO pool initialized successfully");
        } catch Error(string memory reason) {
            console2.log("Failed to initialize NO pool:", reason);
            revert(reason);
        }
        
        console2.log("Adding liquidity to NO pool");
        _mintLiquidity(noPoolKey, 50_000e6, 50_000e18);
        console2.log("Added liquidity to NO pool");
        
        // Initialize the state tracking variables
        usdcInNoPool = 50_000e6;
        noTokensInPool = 50_000e18;
        
        emit PoolsInitialized(Currency.unwrap(yesPoolKey.currency1), Currency.unwrap(noPoolKey.currency1));
    }

    function _mintLiquidity(PoolKey memory key, uint256 amount0, uint256 amount1) internal {
        Currency currency0 = key.currency0;
        Currency currency1 = key.currency1;
        
        console2.log("Approving tokens for liquidity provisioning");
        if (!currency0.isAddressZero()) {
            IERC20(Currency.unwrap(currency0)).approve(address(poolManager), amount0);
        }
        if (!currency1.isAddressZero()) {
            IERC20(Currency.unwrap(currency1)).approve(address(poolManager), amount1);
        }

        uint160 sqrtPriceAX96 = TickMath.getSqrtPriceAtTick(-887272);
        uint160 sqrtPriceBX96 = TickMath.getSqrtPriceAtTick(887272);
        uint160 sqrtPriceX96 = TickMath.getSqrtPriceAtTick(0);

        uint128 liquidity = LiquidityAmounts.getLiquidityForAmounts(
            sqrtPriceX96,
            sqrtPriceAX96,
            sqrtPriceBX96,
            amount0,
            amount1
        );
        console2.log("Calculated liquidity amount:", uint256(liquidity));

        IPoolManager.ModifyLiquidityParams memory params = IPoolManager.ModifyLiquidityParams({
            tickLower: -887272,
            tickUpper: 887272,
            liquidityDelta: int128(liquidity),
            salt: keccak256("prediction_market")
        });
        
        console2.log("Calling modifyLiquidity");
        try IPoolManager(address(poolManager)).modifyLiquidity(key, params, "") returns (BalanceDelta callerDelta, BalanceDelta) {
            console2.log("Added liquidity successfully");
            // Log deltas for debugging
            console2.log("Delta amount0:", int256(callerDelta.amount0()));
            console2.log("Delta amount1:", int256(callerDelta.amount1()));
            
            emit LiquidityAdded(
                Currency.unwrap(key.currency1), 
                uint256(int256(-callerDelta.amount0())), // Negate because negative delta means tokens going to pool
                uint256(int256(-callerDelta.amount1()))  // Negate because negative delta means tokens going to pool
            );
        } catch Error(string memory reason) {
            console2.log("Failed to add liquidity:", reason);
            revert(reason);
        }
    }

    function _isValidPool(PoolKey calldata key) internal view returns (bool) {
        return (Currency.unwrap(key.currency0) == usdc && Currency.unwrap(key.currency1) == yesToken) ||
               (Currency.unwrap(key.currency0) == usdc && Currency.unwrap(key.currency1) == noToken);
    }

    function resolveOutcome(bool _outcomeIsYes) external onlyOwner {
        require(block.timestamp > endTime, "Betting ongoing");
        require(!resolved, "Already resolved");
        console2.log("Resolving outcome as:", _outcomeIsYes ? "YES" : "NO");

        (uint256 usdcYes, uint256 yesTokens) = _withdrawLiquidity(yesPoolKey);
        console2.log("Withdrawn from YES pool - USDC:", usdcYes, "YES tokens:", yesTokens);
        
        (uint256 usdcNo, uint256 noTokens) = _withdrawLiquidity(noPoolKey);
        console2.log("Withdrawn from NO pool - USDC:", usdcNo, "NO tokens:", noTokens);

        totalUSDCCollected = usdcYes + usdcNo;
        hookYesBalance = yesTokens;
        hookNoBalance = noTokens;
        outcomeIsYes = _outcomeIsYes;
        resolved = true;
        
        console2.log("Total USDC:", totalUSDCCollected);
        emit OutcomeResolved(_outcomeIsYes);
    }

    function _withdrawLiquidity(PoolKey memory key) internal returns (uint256 usdcAmount, uint256 tokenAmount) {
        console2.log("Withdrawing liquidity from pool");
        IPoolManager.ModifyLiquidityParams memory params = IPoolManager.ModifyLiquidityParams({
            tickLower: -887272,
            tickUpper: 887272,
            liquidityDelta: type(int128).min,
            salt: keccak256("prediction_market")
        });
        
        (BalanceDelta delta, ) = poolManager.modifyLiquidity(key, params, "");

        (usdcAmount, tokenAmount) = Currency.unwrap(key.currency0) == usdc
            ? (uint256(int256(delta.amount0())), uint256(int256(delta.amount1())))
            : (uint256(int256(delta.amount1())), uint256(int256(delta.amount0())));
            
        console2.log("Withdrawn amounts - USDC:", usdcAmount, "Token:", tokenAmount);
        return (usdcAmount, tokenAmount);
    }

    function claim() external {
        require(resolved, "Outcome not resolved");
        require(!hasClaimed[msg.sender], "Already claimed");
        console2.log("User claiming rewards:", msg.sender);

        address token = outcomeIsYes ? yesToken : noToken;
        uint256 userBalance = IERC20(token).balanceOf(msg.sender);
        console2.log("User balance of winning token:", userBalance);
        
        require(userBalance > 0, "No winning tokens");
        
        uint256 totalWinningSupply = IERC20(token).totalSupply() - (outcomeIsYes ? hookYesBalance : hookNoBalance);
        console2.log("Total winning supply:", totalWinningSupply);

        require(totalWinningSupply > 0, "No winners");
        uint256 usdcShare = (userBalance * totalUSDCCollected) / totalWinningSupply;
        console2.log("User's USDC share:", usdcShare);

        // Mark as claimed
        hasClaimed[msg.sender] = true;
        
        // Transfer USDC to the user
        IERC20(usdc).transfer(msg.sender, usdcShare);
        emit Claimed(msg.sender, usdcShare);
    }
    
    // Fixed getOdds function that uses tracked state variables
    function getOdds() external view returns (uint256 yesOdds, uint256 noOdds) {
        require(block.timestamp >= startTime, "Market not started");
        require(!resolved, "Market resolved");
        
        // Calculate total USDC in both pools
        uint256 totalPoolUSDC = usdcInYesPool + usdcInNoPool;
        
        if (totalPoolUSDC == 0) {
            return (50, 50); // Default to 50/50 if no liquidity
        }
        
        // Higher USDC in YES pool means higher probability for NO (and vice versa)
        // This is because USDC flows to the side people are betting against
        noOdds = (usdcInYesPool * 100) / totalPoolUSDC;
        yesOdds = (usdcInNoPool * 100) / totalPoolUSDC;
    
        return (yesOdds, noOdds);
    }

    // Helper to calculate price from sqrtPriceX96
    function _calculatePrice(uint160 sqrtPriceX96) internal pure returns (uint256) {
        // Simplified price calculation from sqrtPriceX96
        uint256 price = uint256(sqrtPriceX96) * uint256(sqrtPriceX96);
        price = price >> 192; // Divide by 2^192 (since sqrtPriceX96 is Q64.96)
        return price;
    }

    // Function to get token prices using tracked pool state
    function getTokenPrices() external view returns (uint256 yesPrice, uint256 noPrice) {
        // Calculate token prices based on the USDC amounts and token amounts
        // Price = USDC amount / token amount
        
        if (yesTokensInPool > 0) {
            yesPrice = (usdcInYesPool * 1e18) / yesTokensInPool;
        } else {
            yesPrice = 0;
        }
        
        if (noTokensInPool > 0) {
            noPrice = (usdcInNoPool * 1e18) / noTokensInPool;
        } else {
            noPrice = 0;
        }
        
        return (yesPrice, noPrice);
    }
}