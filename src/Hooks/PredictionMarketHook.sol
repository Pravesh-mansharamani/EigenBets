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
import {IUnlockCallback} from "@v4-core/interfaces/callback/IUnlockCallback.sol";
import {PoolIdLibrary} from "@v4-core/types/PoolId.sol";

contract PredictionMarketHook is BaseHook, Ownable, IUnlockCallback {
    using CurrencyLibrary for Currency;
    using SafeERC20 for IERC20;
    using PoolIdLibrary for PoolKey;

    // Market states
    bool public marketOpen;
    bool public marketClosed;
    bool public resolved;
    bool public outcomeIsYes;
    uint256 public startTime;
    uint256 public endTime;

    // Operation types for unlock callback handling
    enum OperationType {
        None,
        AddLiquidityYes,
        AddLiquidityNo,
        RemoveLiquidityYes,
        RemoveLiquidityNo,
        Swap
    }

    // Operation context for unlock callback
    struct OperationContext {
        OperationType operationType;
        PoolKey poolKey;
        IPoolManager.ModifyLiquidityParams modifyParams;
        IPoolManager.SwapParams swapParams;
        address recipient;
    }

    // Current operation context
    OperationContext public currentOperation;

    address public immutable usdc;
    address public immutable yesToken;
    address public immutable noToken;

    // State variables to track pool balances
    uint256 public usdcInYesPool = 0;
    uint256 public usdcInNoPool = 0;
    uint256 public yesTokensInPool = 0;
    uint256 public noTokensInPool = 0;

    PoolKey public yesPoolKey;
    PoolKey public noPoolKey;

    uint256 public totalUSDCCollected;
    uint256 public hookYesBalance;
    uint256 public hookNoBalance;
    
    // Track users who have already claimed
    mapping(address => bool) public hasClaimed;

    // Store token positions in pools for easier access
    bool public isUSDCToken0InYesPool;
    bool public isUSDCToken0InNoPool;

    event MarketOpened();
    event MarketClosed();
    event OutcomeResolved(bool outcomeIsYes);
    event Claimed(address indexed user, uint256 amount);
    event PoolsInitialized(address yesPool, address noPool);
    event LiquidityAdded(address pool, uint256 amount0, uint256 amount1);
    event SwapExecuted(address user, address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut);
    event MarketReset();

    constructor(
        IPoolManager _poolManager,
        address _usdc,
        address _yesToken,
        address _noToken
    ) BaseHook(IPoolManager(_poolManager)) Ownable(tx.origin) {
        usdc = _usdc;
        yesToken = _yesToken;
        noToken = _noToken;
        
        marketOpen = false;
        marketClosed = false;
        resolved = false;
    }

    /**
     * @notice Opens the market for betting
     * @dev Only the owner can open the market
     */
    function openMarket() external onlyOwner {
        require(!marketOpen, "Market already open");
        require(!marketClosed, "Market already closed");
        require(!resolved, "Market already resolved");
        
        marketOpen = true;
        startTime = block.timestamp;
        endTime = block.timestamp + 7 days;
        emit MarketOpened();
    }
    
    /**
     * @notice Closes the market for betting
     * @dev Only the owner can close the market
     */
    function closeMarket() external onlyOwner {
        require(marketOpen, "Market not open");
        require(!marketClosed, "Market already closed");
        
        marketClosed = true;
        endTime = block.timestamp;
        emit MarketClosed();
    }
    
    /**
     * @notice Reset the market to create a new prediction round
     * @dev Only the owner can reset the market, and only after it's been resolved
     */
    function resetMarket() external onlyOwner {
        require(resolved, "Current market not resolved yet");
        
        // Reset market state
        marketOpen = false;
        marketClosed = false;
        resolved = false;
        outcomeIsYes = false;
        
        // Reset pool tracking variables
        usdcInYesPool = 0;
        usdcInNoPool = 0;
        yesTokensInPool = 0;
        noTokensInPool = 0;
        
        totalUSDCCollected = 0;
        hookYesBalance = 0;
        hookNoBalance = 0;
        
        // Reset pool keys
        yesPoolKey = PoolKey({
            currency0: Currency.wrap(address(0)),
            currency1: Currency.wrap(address(0)),
            fee: 0,
            tickSpacing: 0,
            hooks: IHooks(address(0))
        });
        
        noPoolKey = PoolKey({
            currency0: Currency.wrap(address(0)),
            currency1: Currency.wrap(address(0)),
            fee: 0,
            tickSpacing: 0,
            hooks: IHooks(address(0))
        });
        
        emit MarketReset();
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
            afterSwap: true,
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
        require(!marketClosed, "Market closed");
        require(_isValidPool(key), "Invalid pool");
        return IHooks.beforeAddLiquidity.selector;
    }

    function _beforeRemoveLiquidity(
        address /* sender */,
        PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata /* params */,
        bytes calldata
    ) internal view override returns (bytes4) {
        require(_isValidPool(key), "Invalid pool");
        require(marketOpen && !marketClosed, "Market not active");
        return IHooks.beforeRemoveLiquidity.selector;
    }

    function _beforeSwap(
        address /* sender */,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata /* params */,
        bytes calldata
    ) internal view override returns (bytes4, BeforeSwapDelta, uint24) {
        require(_isValidPool(key), "Invalid pool");
        require(marketOpen && !marketClosed, "Market not active");
        return (IHooks.beforeSwap.selector, BeforeSwapDelta.wrap(0), 0);
    }
    
    function _afterSwap(
        address /* sender */,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata,
        BalanceDelta delta,
        bytes calldata
    ) internal override returns (bytes4, int128) {
        bool isYesPool = _isYesPool(key);
        
        int256 usdcDelta;
        int256 tokenDelta;
        
        if (isYesPool) {
            // For YES pool
            usdcDelta = isUSDCToken0InYesPool ? delta.amount0() : delta.amount1();
            tokenDelta = isUSDCToken0InYesPool ? delta.amount1() : delta.amount0();
            
            if (usdcDelta < 0) {
                usdcInYesPool += uint256(-usdcDelta);
            } else {
                require(usdcInYesPool >= uint256(usdcDelta), "Insufficient USDC in YES pool");
                usdcInYesPool -= uint256(usdcDelta);
            }
            
            if (tokenDelta < 0) {
                yesTokensInPool += uint256(-tokenDelta);
            } else {
                require(yesTokensInPool >= uint256(tokenDelta), "Insufficient YES tokens in pool");
                yesTokensInPool -= uint256(tokenDelta);
            }
            
            if (usdcDelta < 0 || tokenDelta < 0) {
                emit LiquidityAdded(
                    yesToken, 
                    usdcDelta < 0 ? uint256(-usdcDelta) : 0, 
                    tokenDelta < 0 ? uint256(-tokenDelta) : 0
                );
            }
        } else {
            // For NO pool
            usdcDelta = isUSDCToken0InNoPool ? delta.amount0() : delta.amount1();
            tokenDelta = isUSDCToken0InNoPool ? delta.amount1() : delta.amount0();
            
            if (usdcDelta < 0) {
                usdcInNoPool += uint256(-usdcDelta);
            } else {
                require(usdcInNoPool >= uint256(usdcDelta), "Insufficient USDC in NO pool");
                usdcInNoPool -= uint256(usdcDelta);
            }
            
            if (tokenDelta < 0) {
                noTokensInPool += uint256(-tokenDelta);
            } else {
                require(noTokensInPool >= uint256(tokenDelta), "Insufficient NO tokens in pool");
                noTokensInPool -= uint256(tokenDelta);
            }
            
            if (usdcDelta < 0 || tokenDelta < 0) {
                emit LiquidityAdded(
                    noToken, 
                    usdcDelta < 0 ? uint256(-usdcDelta) : 0, 
                    tokenDelta < 0 ? uint256(-tokenDelta) : 0
                );
            }
        }
        
        return (IHooks.afterSwap.selector, 0);
    }

    function checkOwner() public view returns (address) {
        return owner();
    }
    
    function initializePools() external onlyOwner {
        require(!marketOpen && !marketClosed && !resolved, "Cannot initialize active market");
        
        // Create YES pool with correct token ordering
        isUSDCToken0InYesPool = uint160(usdc) < uint160(yesToken);
        
        yesPoolKey = PoolKey({
            currency0: Currency.wrap(isUSDCToken0InYesPool ? usdc : yesToken),
            currency1: Currency.wrap(isUSDCToken0InYesPool ? yesToken : usdc),
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(address(this))
        });
        
        IPoolManager(address(poolManager)).initialize(yesPoolKey, TickMath.getSqrtPriceAtTick(0));
        
        _addLiquidity(yesPoolKey, 50_000e6, 50_000e18);
        
        // Initialize the state tracking variables
        usdcInYesPool = 50_000e6;
        yesTokensInPool = 50_000e18;

        // Determine correct token ordering for NO pool
        isUSDCToken0InNoPool = uint160(usdc) < uint160(noToken);
        
        noPoolKey = PoolKey({
            currency0: Currency.wrap(isUSDCToken0InNoPool ? usdc : noToken),
            currency1: Currency.wrap(isUSDCToken0InNoPool ? noToken : usdc),
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(address(this))
        });
        
        IPoolManager(address(poolManager)).initialize(noPoolKey, TickMath.getSqrtPriceAtTick(0));
        
        _addLiquidity(noPoolKey, 50_000e6, 50_000e18);
        
        // Initialize the state tracking variables
        usdcInNoPool = 50_000e6;
        noTokensInPool = 50_000e18;
        
        emit PoolsInitialized(yesToken, noToken);
    }

    function _addLiquidity(PoolKey memory key, uint256 usdcAmount, uint256 tokenAmount) internal {
        bool isYes = _isYesPool(key);
        bool isUSDCToken0 = isYes ? isUSDCToken0InYesPool : isUSDCToken0InNoPool;
        address token = isYes ? yesToken : noToken;
        
        uint256 amount0 = isUSDCToken0 ? usdcAmount : tokenAmount;
        uint256 amount1 = isUSDCToken0 ? tokenAmount : usdcAmount;
        
        IERC20(Currency.unwrap(key.currency0)).approve(address(poolManager), 0);
        IERC20(Currency.unwrap(key.currency0)).approve(address(poolManager), amount0);
        
        IERC20(Currency.unwrap(key.currency1)).approve(address(poolManager), 0);
        IERC20(Currency.unwrap(key.currency1)).approve(address(poolManager), amount1);

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
            tickLower: -887220,
            tickUpper: 887220,
            liquidityDelta: int128(liquidity),
            salt: keccak256("prediction_market")
        });

        // Set operation context for the callback
        currentOperation = OperationContext({
            operationType: isYes ? OperationType.AddLiquidityYes : OperationType.AddLiquidityNo,
            poolKey: key,
            modifyParams: params,
            swapParams: IPoolManager.SwapParams({
                zeroForOne: false,
                amountSpecified: 0,
                sqrtPriceLimitX96: 0
            }),
            recipient: address(0)
        });

        // The actual operation will be performed in the unlockCallback
        poolManager.unlock(new bytes(0));
        
        // Reset operation context
        currentOperation = OperationContext({
            operationType: OperationType.None,
            poolKey: PoolKey({
                currency0: Currency.wrap(address(0)),
                currency1: Currency.wrap(address(0)),
                fee: 0,
                tickSpacing: 0,
                hooks: IHooks(address(0))
            }),
            modifyParams: IPoolManager.ModifyLiquidityParams({
                tickLower: 0,
                tickUpper: 0,
                liquidityDelta: 0,
                salt: bytes32(0)
            }),
            swapParams: IPoolManager.SwapParams({
                zeroForOne: false,
                amountSpecified: 0,
                sqrtPriceLimitX96: 0
            }),
            recipient: address(0)
        });
    }

    /**
     * @notice Swap USDC for YES tokens
     * @param usdcAmount Amount of USDC to spend
     * @return tokenAmount Amount of YES tokens received
     */
    function swapUSDCForYesTokens(uint256 usdcAmount) external returns (uint256 tokenAmount) {
        return _swapExactInput(usdc, yesToken, usdcAmount, msg.sender);
    }
    
    /**
     * @notice Swap USDC for NO tokens
     * @param usdcAmount Amount of USDC to spend
     * @return tokenAmount Amount of NO tokens received
     */
    function swapUSDCForNoTokens(uint256 usdcAmount) external returns (uint256 tokenAmount) {
        return _swapExactInput(usdc, noToken, usdcAmount, msg.sender);
    }
    
    /**
     * @notice Swap YES tokens for USDC
     * @param tokenAmount Amount of YES tokens to sell
     * @return usdcAmount Amount of USDC received
     */
    function swapYesTokensForUSDC(uint256 tokenAmount) external returns (uint256 usdcAmount) {
        return _swapExactInput(yesToken, usdc, tokenAmount, msg.sender);
    }
    
    /**
     * @notice Swap NO tokens for USDC
     * @param tokenAmount Amount of NO tokens to sell
     * @return usdcAmount Amount of USDC received
     */
    function swapNoTokensForUSDC(uint256 tokenAmount) external returns (uint256 usdcAmount) {
        return _swapExactInput(noToken, usdc, tokenAmount, msg.sender);
    }
    
    /**
     * @notice Swap YES tokens for NO tokens
     * @param yesAmount Amount of YES tokens to swap
     * @return noAmount Amount of NO tokens received
     */
    function swapYesForNoTokens(uint256 yesAmount) external returns (uint256 noAmount) {
        // First swap YES to USDC
        uint256 usdcReceived = _swapExactInput(yesToken, usdc, yesAmount, address(this));
        
        // Then swap USDC to NO
        noAmount = _swapExactInput(usdc, noToken, usdcReceived, msg.sender);
        
        return noAmount;
    }
    
    /**
     * @notice Swap NO tokens for YES tokens
     * @param noAmount Amount of NO tokens to swap
     * @return yesAmount Amount of YES tokens received
     */
    function swapNoForYesTokens(uint256 noAmount) external returns (uint256 yesAmount) {
        // First swap NO to USDC
        uint256 usdcReceived = _swapExactInput(noToken, usdc, noAmount, address(this));
        
        // Then swap USDC to YES
        yesAmount = _swapExactInput(usdc, yesToken, usdcReceived, msg.sender);
        
        return yesAmount;
    }
    
    /**
     * @notice Generic swap function that handles any token pair
     * @param tokenIn Address of input token
     * @param tokenOut Address of output token
     * @param amountIn Exact amount of input tokens to swap
     * @param amountOutMinimum Minimum amount of output tokens to receive
     * @return amountOut Actual amount of output tokens received
     */
    function swap(
        address tokenIn, 
        address tokenOut, 
        uint256 amountIn, 
        uint256 amountOutMinimum
    ) external returns (uint256 amountOut) {
        require(marketOpen && !marketClosed, "Market not active");
        require(!resolved, "Market resolved");
        
        // Verify valid token pairs
        require(
            (tokenIn == usdc && (tokenOut == yesToken || tokenOut == noToken)) ||
            ((tokenIn == yesToken || tokenIn == noToken) && tokenOut == usdc) ||
            (tokenIn == yesToken && tokenOut == noToken) ||
            (tokenIn == noToken && tokenOut == yesToken),
            "Invalid token pair"
        );
        
        // If direct swap is possible (USDC<->YES or USDC<->NO)
        if ((tokenIn == usdc && (tokenOut == yesToken || tokenOut == noToken)) ||
            ((tokenIn == yesToken || tokenIn == noToken) && tokenOut == usdc)) {
            amountOut = _swapExactInput(tokenIn, tokenOut, amountIn, msg.sender);
        } 
        // For YES<->NO, do a 2-step swap through USDC
        else {
            // First swap to USDC
            uint256 usdcReceived = _swapExactInput(tokenIn, usdc, amountIn, address(this));
            
            // Then swap USDC to destination token
            amountOut = _swapExactInput(usdc, tokenOut, usdcReceived, msg.sender);
        }
        
        require(amountOut >= amountOutMinimum, "Slippage: insufficient output amount");
        return amountOut;
    }
    
    /**
     * @dev Internal function to perform an exact input swap
     * @param tokenIn Address of input token
     * @param tokenOut Address of output token
     * @param amountIn Exact amount of input tokens
     * @param recipient Address to receive output tokens
     * @return amountOut Amount of output tokens received
     */
    function _swapExactInput(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        address recipient
    ) internal returns (uint256 amountOut) {
        require(marketOpen && !marketClosed, "Market not active");
        require(!resolved, "Market resolved");
        
        // Determine which pool to use
        PoolKey memory poolKey;
        bool zeroForOne;
        
        if ((tokenIn == usdc && tokenOut == yesToken) || (tokenIn == yesToken && tokenOut == usdc)) {
            poolKey = yesPoolKey;
            
            // Determine swap direction based on token positions
            if (tokenIn == Currency.unwrap(poolKey.currency0)) {
                zeroForOne = true;
            } else {
                zeroForOne = false;
            }
        } else if ((tokenIn == usdc && tokenOut == noToken) || (tokenIn == noToken && tokenOut == usdc)) {
            poolKey = noPoolKey;
            
            // Determine swap direction based on token positions
            if (tokenIn == Currency.unwrap(poolKey.currency0)) {
                zeroForOne = true;
            } else {
                zeroForOne = false;
            }
        } else {
            revert("Unsupported token pair");
        }
        
        // Approve token transfers
        if (tokenIn != address(this)) {
            // Only approve if the caller is not the contract itself
            IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        }
        IERC20(tokenIn).approve(address(poolManager), amountIn);
        
        // Set up swap params
        IPoolManager.SwapParams memory params = IPoolManager.SwapParams({
            zeroForOne: zeroForOne,
            amountSpecified: int256(amountIn), // Positive = exact input
            sqrtPriceLimitX96: zeroForOne ? TickMath.MIN_SQRT_PRICE + 1 : TickMath.MAX_SQRT_PRICE - 1
        });
        
        // Set operation context for the callback
        currentOperation = OperationContext({
            operationType: OperationType.Swap,
            poolKey: poolKey,
            modifyParams: IPoolManager.ModifyLiquidityParams({
                tickLower: 0,
                tickUpper: 0,
                liquidityDelta: 0,
                salt: bytes32(0)
            }),
            swapParams: params,
            recipient: recipient
        });
        
        // Execute the swap in the callback
        bytes memory swapResult = poolManager.unlock(new bytes(0));
        
        // Process outputAmount
        amountOut = abi.decode(swapResult, (uint256));
        
        // Reset operation context
        currentOperation = OperationContext({
            operationType: OperationType.None,
            poolKey: PoolKey({
                currency0: Currency.wrap(address(0)),
                currency1: Currency.wrap(address(0)),
                fee: 0,
                tickSpacing: 0,
                hooks: IHooks(address(0))
            }),
            modifyParams: IPoolManager.ModifyLiquidityParams({
                tickLower: 0,
                tickUpper: 0,
                liquidityDelta: 0,
                salt: bytes32(0)
            }),
            swapParams: IPoolManager.SwapParams({
                zeroForOne: false,
                amountSpecified: 0,
                sqrtPriceLimitX96: 0
            }),
            recipient: address(0)
        });
        
        return amountOut;
    }

    // Helper function to check if a pool is the YES pool
    function _isYesPool(PoolKey memory key) internal view returns (bool) {
        return (
            (Currency.unwrap(key.currency0) == usdc && Currency.unwrap(key.currency1) == yesToken) ||
            (Currency.unwrap(key.currency0) == yesToken && Currency.unwrap(key.currency1) == usdc)
        );
    }

    function _isValidPool(PoolKey calldata key) internal view returns (bool) {
        return (
            (Currency.unwrap(key.currency0) == usdc && Currency.unwrap(key.currency1) == yesToken) ||
            (Currency.unwrap(key.currency0) == yesToken && Currency.unwrap(key.currency1) == usdc) ||
            (Currency.unwrap(key.currency0) == usdc && Currency.unwrap(key.currency1) == noToken) ||
            (Currency.unwrap(key.currency0) == noToken && Currency.unwrap(key.currency1) == usdc)
        );
    }

    function resolveOutcome(bool _outcomeIsYes) external onlyOwner {
        require(marketClosed, "Market not closed");
        require(!resolved, "Already resolved");
        
        // Set operation context for yes pool withdrawal
        currentOperation = OperationContext({
            operationType: OperationType.RemoveLiquidityYes,
            poolKey: yesPoolKey,
            modifyParams: IPoolManager.ModifyLiquidityParams({
                tickLower: -887220,
                tickUpper: 887220,
                liquidityDelta: type(int128).min,
                salt: keccak256("prediction_market")
            }),
            swapParams: IPoolManager.SwapParams({
                zeroForOne: false,
                amountSpecified: 0,
                sqrtPriceLimitX96: 0
            }),
            recipient: address(0)
        });
        
        // Withdraw from YES pool
        bytes memory resultYes = poolManager.unlock(new bytes(0));
        uint256 usdcYes = usdcInYesPool;
        uint256 yesTokens = yesTokensInPool;
        
        // Set operation context for no pool withdrawal
        currentOperation = OperationContext({
            operationType: OperationType.RemoveLiquidityNo,
            poolKey: noPoolKey,
            modifyParams: IPoolManager.ModifyLiquidityParams({
                tickLower: -887220,
                tickUpper: 887220,
                liquidityDelta: type(int128).min,
                salt: keccak256("prediction_market")
            }),
            swapParams: IPoolManager.SwapParams({
                zeroForOne: false,
                amountSpecified: 0,
                sqrtPriceLimitX96: 0
            }),
            recipient: address(0)
        });
        
        // Withdraw from NO pool
        bytes memory resultNo = poolManager.unlock(new bytes(0));
        uint256 usdcNo = usdcInNoPool;
        uint256 noTokens = noTokensInPool;
        
        // Reset operation context
        currentOperation = OperationContext({
            operationType: OperationType.None,
            poolKey: PoolKey({
                currency0: Currency.wrap(address(0)),
                currency1: Currency.wrap(address(0)),
                fee: 0,
                tickSpacing: 0,
                hooks: IHooks(address(0))
            }),
            modifyParams: IPoolManager.ModifyLiquidityParams({
                tickLower: 0,
                tickUpper: 0,
                liquidityDelta: 0,
                salt: bytes32(0)
            }),
            swapParams: IPoolManager.SwapParams({
                zeroForOne: false,
                amountSpecified: 0,
                sqrtPriceLimitX96: 0
            }),
            recipient: address(0)
        });

        // Update state variables - use actual USDC balance instead of reported values
        totalUSDCCollected = IERC20(usdc).balanceOf(address(this));
        
        // Save token balances to use in claim calculation
        hookYesBalance = IERC20(yesToken).balanceOf(address(this));
        hookNoBalance = IERC20(noToken).balanceOf(address(this));
        
        // Mark as resolved
        outcomeIsYes = _outcomeIsYes;
        resolved = true;
        
        emit OutcomeResolved(_outcomeIsYes);
    }
    
    // Implement the unlockCallback function required by IUnlockCallback
    function unlockCallback(bytes calldata data) external override returns (bytes memory) {
        // Check that the caller is the PoolManager
        require(msg.sender == address(poolManager), "Unauthorized callback");
        
        // No operation to perform
        if (currentOperation.operationType == OperationType.None) {
            return "";
        }
        
        uint256 outputAmount = 0;
        
        // Handle liquidity operations
        if (currentOperation.operationType == OperationType.AddLiquidityYes || 
            currentOperation.operationType == OperationType.AddLiquidityNo) {
            return _handleAddLiquidity();
        } 
        else if (currentOperation.operationType == OperationType.RemoveLiquidityYes || 
                 currentOperation.operationType == OperationType.RemoveLiquidityNo) {
            return _handleRemoveLiquidity();
        }
        else if (currentOperation.operationType == OperationType.Swap) {
            outputAmount = _handleSwap(data);
            return abi.encode(outputAmount); // Return the output amount
        }
        
        return "";
    }
    
    // Handle adding liquidity in the callback
    function _handleAddLiquidity() internal returns (bytes memory) {
        (BalanceDelta delta, ) = poolManager.modifyLiquidity(
            currentOperation.poolKey,
            currentOperation.modifyParams,
            ""
        );
        
        // Process token transfers
        _processBalanceDelta(delta, currentOperation.poolKey);
        
        // Safely convert for event emission
        uint256 safeAmount0 = delta.amount0() < 0 ? uint256(uint128(-delta.amount0())) : 0;
        uint256 safeAmount1 = delta.amount1() < 0 ? uint256(uint128(-delta.amount1())) : 0;
        
        emit LiquidityAdded(
            _isYesPool(currentOperation.poolKey) ? yesToken : noToken,
            safeAmount0,
            safeAmount1
        );
        
        return "";
    }
    
    // Handle removing liquidity in the callback
    function _handleRemoveLiquidity() internal returns (bytes memory) {
        (BalanceDelta delta, ) = poolManager.modifyLiquidity(
            currentOperation.poolKey,
            currentOperation.modifyParams,
            ""
        );
        
        // Process token transfers
        _processBalanceDelta(delta, currentOperation.poolKey);
        
        // Zero out pool balance for the relevant pool
        if (currentOperation.operationType == OperationType.RemoveLiquidityYes) {
            usdcInYesPool = 0;
            yesTokensInPool = 0;
        } else {
            usdcInNoPool = 0;
            noTokensInPool = 0;
        }
        
        return "";
    }
    
    // Handle swap operation in the callback
    function _handleSwap(bytes calldata data) internal returns (uint256 outputAmount) {
        // Execute the swap
        BalanceDelta delta = poolManager.swap(
            currentOperation.poolKey,
            currentOperation.swapParams,
            data
        );
        
        // Determine which tokens are being swapped
        Currency tokenIn;
        Currency tokenOut;
        uint256 amountIn;
        uint256 amountOut;
        
        if (currentOperation.swapParams.zeroForOne) {
            tokenIn = currentOperation.poolKey.currency0;
            tokenOut = currentOperation.poolKey.currency1;
            amountIn = uint256(uint128(-delta.amount0()));
            amountOut = uint256(uint128(delta.amount1()));
        } else {
            tokenIn = currentOperation.poolKey.currency1;
            tokenOut = currentOperation.poolKey.currency0;
            amountIn = uint256(uint128(-delta.amount1()));
            amountOut = uint256(uint128(delta.amount0()));
        }
        
        // Transfer token in to pool
        IERC20(Currency.unwrap(tokenIn)).transfer(
            address(poolManager),
            amountIn
        );
        
        // Settle with the pool
        poolManager.settle();
        
        // Take token out from pool to recipient
        address recipient = currentOperation.recipient == address(0) ? msg.sender : currentOperation.recipient;
        poolManager.take(tokenOut, recipient, amountOut);
        
        emit SwapExecuted(
            recipient,
            Currency.unwrap(tokenIn),
            Currency.unwrap(tokenOut),
            amountIn,
            amountOut
        );
        
        return amountOut;
    }
    
    // Helper function to process balance delta and handle token transfers
    function _processBalanceDelta(BalanceDelta delta, PoolKey memory key) internal {
        // For negative delta amounts, transfer tokens TO the PoolManager
        if (delta.amount0() < 0) {
            int128 absAmount0 = -delta.amount0();
            uint256 transferAmount0 = uint256(uint128(absAmount0));
            Currency currency0 = key.currency0;
            
            poolManager.sync(currency0);
            IERC20(Currency.unwrap(currency0)).safeTransfer(
                address(poolManager), 
                transferAmount0
            );
            poolManager.settle();
        }
        
        if (delta.amount1() < 0) {
            int128 absAmount1 = -delta.amount1();
            uint256 transferAmount1 = uint256(uint128(absAmount1));
            Currency currency1 = key.currency1;
            
            poolManager.sync(currency1);
            IERC20(Currency.unwrap(currency1)).safeTransfer(
                address(poolManager), 
                transferAmount1
            );
            poolManager.settle();
        }
        
        // For positive delta amounts, take tokens FROM the PoolManager
        if (delta.amount0() > 0) {
            Currency currency0 = key.currency0;
            uint256 amount0 = uint256(uint128(delta.amount0()));
            poolManager.take(currency0, address(this), amount0);
        }
        
        if (delta.amount1() > 0) {
            Currency currency1 = key.currency1;
            uint256 amount1 = uint256(uint128(delta.amount1()));
            poolManager.take(currency1, address(this), amount1);
        }
    }

    function claim() external {
        require(resolved, "Outcome not resolved");
        require(!hasClaimed[msg.sender], "Already claimed");
        
        address winningToken = outcomeIsYes ? yesToken : noToken;
        uint256 userBalance = IERC20(winningToken).balanceOf(msg.sender);
        
        require(userBalance > 0, "No winning tokens");
        
        // Calculate total supply of winning tokens held by users (excluding hook balance)
        uint256 totalWinningTokens = IERC20(winningToken).totalSupply() - (outcomeIsYes ? hookYesBalance : hookNoBalance);
        
        // Sanity check
        require(totalWinningTokens > 0, "No winners");
        
        // Calculate user's share of the USDC proportional to their token holdings
        uint256 usdcShare = (userBalance * totalUSDCCollected) / totalWinningTokens;
        
        // Mark as claimed before external calls to prevent reentrancy
        hasClaimed[msg.sender] = true;
        
        // Transfer USDC to the user
        IERC20(usdc).transfer(msg.sender, usdcShare);
        emit Claimed(msg.sender, usdcShare);
    }
    
    // Function to get odds of YES/NO outcomes
    function getOdds() external view returns (uint256 yesOdds, uint256 noOdds) {
        require(marketOpen, "Market not started");
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
    
    // Helper function to properly expose pool key components
    function getYesPoolKeyComponents() public view returns (Currency, Currency, uint24, int24, IHooks) {
        return (
            yesPoolKey.currency0,
            yesPoolKey.currency1,
            yesPoolKey.fee,
            yesPoolKey.tickSpacing,
            yesPoolKey.hooks
        );
    }
    
    // Helper function to properly expose pool key components
    function getNoPoolKeyComponents() public view returns (Currency, Currency, uint24, int24, IHooks) {
        return (
            noPoolKey.currency0,
            noPoolKey.currency1,
            noPoolKey.fee,
            noPoolKey.tickSpacing,
            noPoolKey.hooks
        );
    }

    /**
     * @notice Returns the current state of the market
     * @return isOpen Whether the market is open for trading
     * @return isClosed Whether the market is closed for trading
     * @return isResolved Whether the market outcome has been resolved
     * @return outcome The resolved outcome (only valid if isResolved is true)
     */
    function getMarketState() external view returns (
        bool isOpen,
        bool isClosed,
        bool isResolved,
        bool outcome
    ) {
        return (marketOpen, marketClosed, resolved, outcomeIsYes);
    }
}