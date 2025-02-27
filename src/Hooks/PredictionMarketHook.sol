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

contract PredictionMarketHook is BaseHook, Ownable {
    using CurrencyLibrary for Currency;
    using SafeERC20 for IERC20;

    address public immutable usdc;
    address public immutable yesToken;
    address public immutable noToken;
    uint256 public immutable startTime;
    uint256 public immutable endTime;

    PoolKey public yesPoolKey;
    PoolKey public noPoolKey;

    bool public resolved;
    bool public outcomeIsYes;
    uint256 public totalUSDC;
    uint256 public hookYesBalance;
    uint256 public hookNoBalance;

    event OutcomeResolved(bool outcomeIsYes);
    event Claimed(address indexed user, uint256 amount);

    constructor(
        IPoolManager _poolManager,
        address _usdc,
        address _yesToken,
        address _noToken,
        uint256 _startTime,
        uint256 _endTime
    ) BaseHook(IPoolManager(_poolManager)) Ownable(msg.sender) {
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
            afterSwap: false,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    function _beforeAddLiquidity(
        address sender,
        PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata params,
        bytes calldata
    ) internal override returns (bytes4) {
        require(_isValidPool(key), "Invalid pool");
        require(block.timestamp >= startTime && block.timestamp <= endTime, "Betting closed");
        return IHooks.beforeAddLiquidity.selector;
    }

    function _beforeRemoveLiquidity(
        address sender,
        PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata params,
        bytes calldata
    ) internal override returns (bytes4) {
        require(_isValidPool(key), "Invalid pool");
        require(block.timestamp >= startTime && block.timestamp <= endTime, "Betting closed");
        return IHooks.beforeRemoveLiquidity.selector;
    }

    function _beforeSwap(
        address sender,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        bytes calldata
    ) internal override returns (bytes4, BeforeSwapDelta, uint24) {
        require(_isValidPool(key), "Invalid pool");
        require(block.timestamp >= startTime && block.timestamp <= endTime, "Betting closed");
        return (IHooks.beforeSwap.selector, BeforeSwapDelta.wrap(0), 0);
    }
    
    function initializePools() external onlyOwner {
        yesPoolKey = PoolKey({
            currency0: Currency.wrap(usdc),
            currency1: Currency.wrap(yesToken),
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(address(this))
        });
        poolManager.initialize(yesPoolKey, TickMath.getSqrtPriceAtTick(0));
        _mintLiquidity(yesPoolKey, 50_000e6, 50_000e18);

        noPoolKey = PoolKey({
            currency0: Currency.wrap(usdc),
            currency1: Currency.wrap(noToken),
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(address(this))
        });
        poolManager.initialize(noPoolKey, TickMath.getSqrtPriceAtTick(0));
        _mintLiquidity(noPoolKey, 50_000e6, 50_000e18);
    }

    function _mintLiquidity(PoolKey memory key, uint256 amount0, uint256 amount1) internal {
        Currency currency0 = key.currency0;
        Currency currency1 = key.currency1;
        
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

        IPoolManager.ModifyLiquidityParams memory params = IPoolManager.ModifyLiquidityParams({
            tickLower: -887272,
            tickUpper: 887272,
            liquidityDelta: int128(liquidity),
            salt: keccak256("prediction_market")
        });
        
        (BalanceDelta callerDelta, ) = poolManager.modifyLiquidity(key, params, "");
    }

    function _isValidPool(PoolKey calldata key) internal view returns (bool) {
        return (Currency.unwrap(key.currency0) == usdc && Currency.unwrap(key.currency1) == yesToken) ||
               (Currency.unwrap(key.currency0) == usdc && Currency.unwrap(key.currency1) == noToken);
    }

    function resolveOutcome(bool _outcomeIsYes) external onlyOwner {
        require(block.timestamp > endTime, "Betting ongoing");
        require(!resolved, "Already resolved");

        (uint256 usdcYes, uint256 yesTokens) = _withdrawLiquidity(yesPoolKey);
        (uint256 usdcNo, uint256 noTokens) = _withdrawLiquidity(noPoolKey);

        totalUSDC = usdcYes + usdcNo;
        hookYesBalance = yesTokens;
        hookNoBalance = noTokens;
        outcomeIsYes = _outcomeIsYes;
        resolved = true;
    }

    function _withdrawLiquidity(PoolKey memory key) internal returns (uint256 usdcAmount, uint256 tokenAmount) {
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
    }

    function claim() external {
        require(resolved, "Outcome not resolved");

        address token = outcomeIsYes ? yesToken : noToken;
        uint256 userBalance = IERC20(token).balanceOf(msg.sender);
        uint256 totalWinningSupply = IERC20(token).totalSupply() - (outcomeIsYes ? hookYesBalance : hookNoBalance);

        require(totalWinningSupply > 0, "No winners");
        uint256 usdcShare = (userBalance * totalUSDC) / totalWinningSupply;

        IERC20(usdc).transfer(msg.sender, usdcShare);
    }
}