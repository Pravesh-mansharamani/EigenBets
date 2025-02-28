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
import {console2} from "forge-std/console2.sol";
import {PoolIdLibrary} from "@v4-core/types/PoolId.sol";

contract PredictionMarketHook is BaseHook, Ownable, IUnlockCallback {
    using CurrencyLibrary for Currency;
    using SafeERC20 for IERC20;
    using PoolIdLibrary for PoolKey;

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
    uint256 public totalUSDCCollected;
    uint256 public hookYesBalance;
    uint256 public hookNoBalance;
    
    // Track users who have already claimed
    mapping(address => bool) public hasClaimed;

    event OutcomeResolved(bool outcomeIsYes);
    event Claimed(address indexed user, uint256 amount);
    event PoolsInitialized(address yesPool, address noPool);
    event LiquidityAdded(address pool, uint256 amount0, uint256 amount1);
    event SwapExecuted(address user, address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut);

    constructor(
        IPoolManager _poolManager,
        address _usdc,
        address _yesToken,
        address _noToken,
        uint256 _startTime,
        uint256 _endTime
    ) BaseHook(IPoolManager(_poolManager)) Ownable(tx.origin) {
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
        require(block.timestamp <= endTime, "Betting closed");
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
        require(
            block.timestamp >= startTime && 
            block.timestamp <= endTime, 
            "Betting closed"
        );
        return (IHooks.beforeSwap.selector, BeforeSwapDelta.wrap(0), 0);
    }
    
    function _afterSwap(
        address /* sender */,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata,
        BalanceDelta delta,
        bytes calldata
    ) internal override returns (bytes4, int128) {
        bool isYesPool = Currency.unwrap(key.currency1) == yesToken;
        
        int256 usdcDelta = Currency.unwrap(key.currency0) == usdc ? delta.amount0() : delta.amount1();
        int256 tokenDelta = Currency.unwrap(key.currency0) == usdc ? delta.amount1() : delta.amount0();
        
        uint256 usdcAdded = usdcDelta < 0 ? uint256(-usdcDelta) : 0;
        uint256 tokenAdded = tokenDelta < 0 ? uint256(-tokenDelta) : 0;
        
        if (isYesPool) {
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
            
            if (usdcAdded > 0 || tokenAdded > 0) {
                emit LiquidityAdded(yesToken, usdcAdded, tokenAdded);
            }
        } else {
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
            
            if (usdcAdded > 0 || tokenAdded > 0) {
                emit LiquidityAdded(noToken, usdcAdded, tokenAdded);
            }
        }
        
        return (IHooks.afterSwap.selector, 0);
    }

    function checkOwner() public view returns (address) {
        return owner();
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
        _addLiquidity(yesPoolKey, 50_000e6, 50_000e18);
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
        _addLiquidity(noPoolKey, 50_000e6, 50_000e18);
        console2.log("Added liquidity to NO pool");
        
        // Initialize the state tracking variables
        usdcInNoPool = 50_000e6;
        noTokensInPool = 50_000e18;
        
        emit PoolsInitialized(Currency.unwrap(yesPoolKey.currency1), Currency.unwrap(noPoolKey.currency1));
    }

    function _addLiquidity(PoolKey memory key, uint256 amount0, uint256 amount1) internal {
        Currency currency0 = key.currency0;
        Currency currency1 = key.currency1;
        
        console2.log("Approving tokens for liquidity provisioning");
        if (!currency0.isAddressZero()) {
            // Reset approvals to ensure proper approval amounts
            IERC20(Currency.unwrap(currency0)).approve(address(poolManager), 0);
            IERC20(Currency.unwrap(currency0)).approve(address(poolManager), amount0);
        }
        if (!currency1.isAddressZero()) {
            // Reset approvals to ensure proper approval amounts
            IERC20(Currency.unwrap(currency1)).approve(address(poolManager), 0);
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
            tickLower: -887220,
            tickUpper: 887220,
            liquidityDelta: int128(liquidity),
            salt: keccak256("prediction_market")
        });

        // Set operation context for the callback
        if (Currency.unwrap(key.currency1) == yesToken) {
            currentOperation = OperationContext({
                operationType: OperationType.AddLiquidityYes,
                poolKey: key,
                modifyParams: params,
                swapParams: IPoolManager.SwapParams({
                    zeroForOne: false,
                    amountSpecified: 0,
                    sqrtPriceLimitX96: 0
                }),
                recipient: address(0)
            });
        } else {
            currentOperation = OperationContext({
                operationType: OperationType.AddLiquidityNo,
                poolKey: key,
                modifyParams: params,
                swapParams: IPoolManager.SwapParams({
                    zeroForOne: false,
                    amountSpecified: 0,
                    sqrtPriceLimitX96: 0
                }),
                recipient: address(0)
            });
        }

        // The actual operation will be performed in the unlockCallback
        console2.log("Unlocking pool manager to execute liquidity operation");
        bytes memory result = poolManager.unlock(new bytes(0));
        
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
        require(block.timestamp >= startTime && block.timestamp <= endTime, "Market not active");
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
        require(block.timestamp >= startTime && block.timestamp <= endTime, "Market not active");
        require(!resolved, "Market resolved");
        
        // Determine which pool to use
        PoolKey memory poolKey;
        if ((tokenIn == usdc && tokenOut == yesToken) || (tokenIn == yesToken && tokenOut == usdc)) {
            poolKey = yesPoolKey;
        } else if ((tokenIn == usdc && tokenOut == noToken) || (tokenIn == noToken && tokenOut == usdc)) {
            poolKey = noPoolKey;
        } else {
            revert("Unsupported token pair");
        }
        
        // Determine swap direction
        bool zeroForOne;
        if (tokenIn == Currency.unwrap(poolKey.currency0)) {
            zeroForOne = true;
        } else {
            zeroForOne = false;
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

    function _isValidPool(PoolKey calldata key) internal view returns (bool) {
        return (Currency.unwrap(key.currency0) == usdc && Currency.unwrap(key.currency1) == yesToken) ||
               (Currency.unwrap(key.currency0) == usdc && Currency.unwrap(key.currency1) == noToken);
    }

    function resolveOutcome(bool _outcomeIsYes) external onlyOwner {
        require(block.timestamp > endTime, "Betting ongoing");
        require(!resolved, "Already resolved");
        console2.log("Resolving outcome as:", _outcomeIsYes ? "YES" : "NO");

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
        console2.log("Withdrawing from YES pool");
        bytes memory resultYes = poolManager.unlock(new bytes(0));
        uint256 usdcYes = usdcInYesPool;
        uint256 yesTokens = yesTokensInPool;
        console2.log("Withdrawn from YES pool - USDC:", usdcYes, "YES tokens:", yesTokens);
        
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
        console2.log("Withdrawing from NO pool");
        bytes memory resultNo = poolManager.unlock(new bytes(0));
        uint256 usdcNo = usdcInNoPool;
        uint256 noTokens = noTokensInPool;
        console2.log("Withdrawn from NO pool - USDC:", usdcNo, "NO tokens:", noTokens);
        
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
        console2.log("Total USDC collected:", totalUSDCCollected);
        
        // Save token balances to use in claim calculation
        hookYesBalance = IERC20(yesToken).balanceOf(address(this));
        hookNoBalance = IERC20(noToken).balanceOf(address(this));
        console2.log("Hook YES token balance:", hookYesBalance);
        console2.log("Hook NO token balance:", hookNoBalance);
        
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
        console2.log("Executing add liquidity operation in callback");
        
        (BalanceDelta delta, ) = poolManager.modifyLiquidity(
            currentOperation.poolKey,
            currentOperation.modifyParams,
            ""
        );
        
        console2.log("Added liquidity successfully");
        console2.log("Delta amount0:", int256(delta.amount0()));
        console2.log("Delta amount1:", int256(delta.amount1()));
        
        // Process token transfers
        _processBalanceDelta(delta, currentOperation.poolKey);
        
        // Safely convert for event emission
        uint256 safeAmount0 = delta.amount0() < 0 ? uint256(uint128(-delta.amount0())) : 0;
        uint256 safeAmount1 = delta.amount1() < 0 ? uint256(uint128(-delta.amount1())) : 0;
        
        emit LiquidityAdded(
            Currency.unwrap(currentOperation.poolKey.currency1),
            safeAmount0,
            safeAmount1
        );
        
        return "";
    }
    
    // Handle removing liquidity in the callback
    function _handleRemoveLiquidity() internal returns (bytes memory) {
        console2.log("Executing remove liquidity operation in callback");
        
        (BalanceDelta delta, ) = poolManager.modifyLiquidity(
            currentOperation.poolKey,
            currentOperation.modifyParams,
            ""
        );
        
        console2.log("Removed liquidity successfully");
        console2.log("Delta amount0:", int256(delta.amount0()));
        console2.log("Delta amount1:", int256(delta.amount1()));
        
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
        console2.log("Executing swap operation in callback");
        
        // Execute the swap
        BalanceDelta delta = poolManager.swap(
            currentOperation.poolKey,
            currentOperation.swapParams,
            data
        );
        
        console2.log("Swap executed successfully");
        console2.log("Delta amount0:", int256(delta.amount0()));
        console2.log("Delta amount1:", int256(delta.amount1()));
        
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
        console2.log("User claiming rewards:", msg.sender);

        address token = outcomeIsYes ? yesToken : noToken;
        uint256 userBalance = IERC20(token).balanceOf(msg.sender);
        console2.log("User balance of winning token:", userBalance);
        
        require(userBalance > 0, "No winning tokens");
        
        // Calculate total supply of winning tokens held by users (excluding hook balance)
        uint256 totalWinningTokens = IERC20(token).totalSupply() - (outcomeIsYes ? hookYesBalance : hookNoBalance);
        console2.log("Total winning tokens in circulation:", totalWinningTokens);
        
        // Sanity check
        require(totalWinningTokens > 0, "No winners");
        
        // Calculate user's share of the USDC proportional to their token holdings
        uint256 usdcShare = (userBalance * totalUSDCCollected) / totalWinningTokens;
        console2.log("User's USDC share:", usdcShare);

        // Mark as claimed before external calls to prevent reentrancy
        hasClaimed[msg.sender] = true;
        
        // Transfer USDC to the user
        IERC20(usdc).transfer(msg.sender, usdcShare);
        emit Claimed(msg.sender, usdcShare);
    }
    
    // Function to get odds of YES/NO outcomes
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
}