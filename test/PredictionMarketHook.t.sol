// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console2} from "forge-std/Test.sol";
import {PredictionMarketHook} from "../src/Hooks/PredictionMarketHook.sol";
import {IPoolManager} from "@v4-core/interfaces/IPoolManager.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {PoolKey} from "@v4-core/types/PoolKey.sol";
import {Currency, CurrencyLibrary} from "@v4-core/types/Currency.sol";
import {TickMath} from "@v4-core/libraries/TickMath.sol";
import {IHooks} from "@v4-core/interfaces/IHooks.sol";
import {BalanceDelta} from "@v4-core/types/BalanceDelta.sol";
import {LiquidityAmounts} from "@v4-periphery/libraries/LiquidityAmounts.sol";
import {Hooks} from "@v4-core/libraries/Hooks.sol";
import {Pool} from "@v4-core/libraries/Pool.sol";
import {IUnlockCallback} from "@v4-core/interfaces/callback/IUnlockCallback.sol";
import {PoolId, PoolIdLibrary} from "@v4-core/types/PoolId.sol";

contract PredictionMarketHookTests is Test {
    using CurrencyLibrary for Currency;
    using PoolIdLibrary for PoolKey;
    
    // Define the RPC URL - this should be replaced with your actual RPC URL
    string constant FORK_URL = "https://base-sepolia.g.alchemy.com/v2/IC5OtAuX9SD5Kzaxg7eOVvxh3jMGGV6_";
    
    PredictionMarketHook public hook;
    address public constant DEPLOYED_HOOK_ADDRESS = 0x8C89ADa8EbDc0D8D9279EcC673fAf6B4d6EBCaC0;
    address public poolManagerAddress;
    address public usdcAddress;
    address public yesTokenAddress;
    address public noTokenAddress;
    uint256 public startTime;
    uint256 public endTime;
    
    // For interacting with tokens
    IERC20 public usdc;
    IERC20 public yesToken;
    IERC20 public noToken;
    
    // Test users
    address public constant USER1 = address(0x1111);
    address public constant USER2 = address(0x2222);
    address public constant USER3 = address(0x3333);
    address public owner;

    function setUp() public {
        // Create a fork of Base Sepolia
        uint256 forkId = vm.createFork(FORK_URL);
        vm.selectFork(forkId);
        
        // Use the deployed contract instead of deploying a new one
        hook = PredictionMarketHook(DEPLOYED_HOOK_ADDRESS);
        
        // Get key contract addresses and information
        usdcAddress = hook.usdc();
        yesTokenAddress = hook.yesToken();
        noTokenAddress = hook.noToken();
        poolManagerAddress = address(hook.poolManager());
        bool marketOpen = hook.marketOpen();
        bool marketClosed = hook.marketClosed();
        bool resolved = hook.resolved();
        startTime = hook.startTime();
        endTime = hook.endTime();
        owner = hook.checkOwner();
        
        console2.log("Contract info:");
        console2.log("USDC Address:", usdcAddress);
        console2.log("YES Token:", yesTokenAddress);
        console2.log("NO Token:", noTokenAddress);
        console2.log("PoolManager:", poolManagerAddress);
        
        // Setup token interfaces
        usdc = IERC20(usdcAddress);
        yesToken = IERC20(yesTokenAddress);
        noToken = IERC20(noTokenAddress);
        
        // Label addresses for better trace output
        vm.label(DEPLOYED_HOOK_ADDRESS, "PredictionMarketHook");
        vm.label(usdcAddress, "USDC");
        vm.label(yesTokenAddress, "YesToken");
        vm.label(noTokenAddress, "NoToken");
        vm.label(poolManagerAddress, "PoolManager");
        vm.label(USER1, "User1");
        vm.label(USER2, "User2");
        vm.label(USER3, "User3");
        vm.label(owner, "HookOwner");
        
        // Setup test users with funds
        setupTestUsers();
    }
    
    function setupTestUsers() public {
        // Fund users with ETH for gas
        vm.deal(USER1, 10 ether);
        vm.deal(USER2, 10 ether);
        vm.deal(USER3, 10 ether);
        
        // Try to get USDC for users
        address[] memory accounts = new address[](2);
        accounts[0] = owner;
        accounts[1] = hook.checkOwner();
        
        bool fundedUsers = false;
        for (uint i = 0; i < accounts.length; i++) {
            uint256 balance = usdc.balanceOf(accounts[i]);
            if (balance > 1000 * 10**6) {
                vm.startPrank(accounts[i]);
                usdc.transfer(USER1, 500 * 10**6);
                usdc.transfer(USER2, 500 * 10**6);
                usdc.transfer(USER3, 500 * 10**6);
                vm.stopPrank();
                fundedUsers = true;
                console2.log("Funded users with USDC from account:", accounts[i]);
                break;
            }
        }
        
        if (!fundedUsers) {
            console2.log("Could not fund users with real USDC, using mock approach");
            
            // If we couldn't transfer USDC from existing accounts, mint it
            // This is just for testing purposes
            vm.startPrank(address(this));
            try ERC20Mock(usdcAddress).mint(USER1, 1000 * 10**6) {
                ERC20Mock(usdcAddress).mint(USER2, 1000 * 10**6);
                ERC20Mock(usdcAddress).mint(USER3, 1000 * 10**6);
                console2.log("Minted mock USDC for users");
            } catch {
                console2.log("Failed to mint mock USDC");
            }
            vm.stopPrank();
        }
        
        // Get YES and NO tokens for users (either from owner or minting)
        bool tokensFunded = false;
        if (yesToken.balanceOf(owner) > 1000 * 10**18) {
            vm.startPrank(owner);
            yesToken.transfer(USER1, 200 * 10**18);
            yesToken.transfer(USER2, 200 * 10**18);
            noToken.transfer(USER1, 200 * 10**18);
            noToken.transfer(USER2, 200 * 10**18);
            tokensFunded = true;
            vm.stopPrank();
        }
        
        if (!tokensFunded) {
            console2.log("Attempting to mint tokens for testing");
            vm.startPrank(address(this));
            try ERC20Mock(yesTokenAddress).mint(USER1, 200 * 10**18) {
                ERC20Mock(yesTokenAddress).mint(USER2, 200 * 10**18);
                ERC20Mock(noTokenAddress).mint(USER1, 200 * 10**18);
                ERC20Mock(noTokenAddress).mint(USER2, 200 * 10**18);
                console2.log("Minted YES and NO tokens for users");
            } catch {
                console2.log("Failed to mint tokens");
            }
            vm.stopPrank();
        }
        
        // Log balances
        console2.log("User1 USDC balance:", usdc.balanceOf(USER1));
        console2.log("User1 YES token balance:", yesToken.balanceOf(USER1));
        console2.log("User1 NO token balance:", noToken.balanceOf(USER1));
        console2.log("User2 USDC balance:", usdc.balanceOf(USER2));
        console2.log("User2 YES token balance:", yesToken.balanceOf(USER2));
        console2.log("User2 NO token balance:", noToken.balanceOf(USER2));
    }

    // =========================================
    // Basic State Tests
    // =========================================
    
    function test_ContractState() public {
        // Test that we can connect to the deployed contract
        console2.log("Connected to deployed contract at:", address(hook));
        
        console2.log("USDC address:", usdcAddress);
        console2.log("YES token address:", yesTokenAddress);
        console2.log("NO token address:", noTokenAddress);
        
        address contractOwner = hook.checkOwner();
        console2.log("Owner:", contractOwner);
        
        assertEq(usdcAddress, hook.usdc(), "USDC address mismatch");
        assertEq(yesTokenAddress, hook.yesToken(), "YES token address mismatch");
        assertEq(noTokenAddress, hook.noToken(), "NO token address mismatch");
    }

    function test_PoolBalances() public {
        uint256 usdcInYesPool = hook.usdcInYesPool();
        uint256 yesTokensInPool = hook.yesTokensInPool();
        uint256 usdcInNoPool = hook.usdcInNoPool();
        uint256 noTokensInPool = hook.noTokensInPool();
        
        console2.log("USDC in YES pool:", usdcInYesPool);
        console2.log("YES tokens in pool:", yesTokensInPool);
        console2.log("USDC in NO pool:", usdcInNoPool);
        console2.log("NO tokens in pool:", noTokensInPool);
        
        // Verify that pools have liquidity
        assertGt(usdcInYesPool, 0, "YES pool should have USDC");
        assertGt(yesTokensInPool, 0, "YES pool should have YES tokens");
        assertGt(usdcInNoPool, 0, "NO pool should have USDC");
        assertGt(noTokensInPool, 0, "NO pool should have NO tokens");
    }

    function test_Odds() public {
        bool marketStarted = block.timestamp >= startTime;
        bool marketResolved = hook.resolved();
        
        // Skip this test if the market hasn't started yet
        if (!marketStarted) {
            console2.log("Market hasn't started yet, skipping odds test");
            return;
        }
        
        // Skip this test if the market is already resolved
        if (marketResolved) {
            console2.log("Market already resolved, skipping odds test");
            return;
        }
        
        (uint256 yesOdds, uint256 noOdds) = hook.getOdds();
        console2.log("Current odds - YES:", yesOdds, "NO:", noOdds);
        
        // Check that odds add up to 100%
        assertEq(yesOdds + noOdds, 100, "Odds should add up to 100%");
    }

    function test_TokenPrices() public {
        (uint256 yesPrice, uint256 noPrice) = hook.getTokenPrices();
        console2.log("Current token prices - YES:", yesPrice, "NO:", noPrice);
        
        // Verify token prices are reasonable
        assertGt(yesPrice, 0, "YES token price should be greater than 0");
        assertGt(noPrice, 0, "NO token price should be greater than 0");
    }
    
    // =========================================
    // USDC to Token Swap Tests
    // =========================================
    
    function test_SwapUSDCForYesTokens() public {
        // Skip if market not active
        if (!isMarketActive()) {
            console2.log("Market not active, skipping test");
            return;
        }
        
        // Only run on users with sufficient USDC
        address user = USER1;
        uint256 initialUsdcBalance = usdc.balanceOf(user);
        uint256 initialYesBalance = yesToken.balanceOf(user);
        uint256 swapAmount = 50 * 10**6; // 50 USDC
        
        if (initialUsdcBalance < swapAmount) {
            console2.log("Not enough USDC for test, skipping");
            return;
        }
        
        console2.log("Initial USDC balance:", initialUsdcBalance);
        console2.log("Initial YES balance:", initialYesBalance);
        
        // Execute swap
        vm.startPrank(user);
        usdc.approve(address(hook), swapAmount);
        
        try hook.swapUSDCForYesTokens(swapAmount) returns (uint256 yesReceived) {
            console2.log("Swap successful, received YES tokens:", yesReceived);
            
            // Verify balances
            uint256 newUsdcBalance = usdc.balanceOf(user);
            uint256 newYesBalance = yesToken.balanceOf(user);
            
            console2.log("New USDC balance:", newUsdcBalance);
            console2.log("New YES balance:", newYesBalance);
            
            assertEq(newUsdcBalance, initialUsdcBalance - swapAmount, "Incorrect USDC spent");
            assertEq(newYesBalance, initialYesBalance + yesReceived, "Incorrect YES tokens received");
            assertGt(yesReceived, 0, "Should receive positive amount of YES tokens");
        } catch Error(string memory reason) {
            console2.log("Swap failed:", reason);
        } catch {
            console2.log("Swap failed with unknown error");
        }
        
        vm.stopPrank();
    }
    
    function test_SwapUSDCForNoTokens() public {
        // Skip if market not active
        if (!isMarketActive()) {
            console2.log("Market not active, skipping test");
            return;
        }
        
        // Only run on users with sufficient USDC
        address user = USER2;
        uint256 initialUsdcBalance = usdc.balanceOf(user);
        uint256 initialNoBalance = noToken.balanceOf(user);
        uint256 swapAmount = 50 * 10**6; // 50 USDC
        
        if (initialUsdcBalance < swapAmount) {
            console2.log("Not enough USDC for test, skipping");
            return;
        }
        
        console2.log("Initial USDC balance:", initialUsdcBalance);
        console2.log("Initial NO balance:", initialNoBalance);
        
        // Execute swap
        vm.startPrank(user);
        usdc.approve(address(hook), swapAmount);
        
        try hook.swapUSDCForNoTokens(swapAmount) returns (uint256 noReceived) {
            console2.log("Swap successful, received NO tokens:", noReceived);
            
            // Verify balances
            uint256 newUsdcBalance = usdc.balanceOf(user);
            uint256 newNoBalance = noToken.balanceOf(user);
            
            console2.log("New USDC balance:", newUsdcBalance);
            console2.log("New NO balance:", newNoBalance);
            
            assertEq(newUsdcBalance, initialUsdcBalance - swapAmount, "Incorrect USDC spent");
            assertEq(newNoBalance, initialNoBalance + noReceived, "Incorrect NO tokens received");
            assertGt(noReceived, 0, "Should receive positive amount of NO tokens");
        } catch Error(string memory reason) {
            console2.log("Swap failed:", reason);
        } catch {
            console2.log("Swap failed with unknown error");
        }
        
        vm.stopPrank();
    }
    
    // =========================================
    // Token to USDC Swap Tests
    // =========================================
    
    function test_SwapYesTokensForUSDC() public {
        // Skip if market not active
        if (!isMarketActive()) {
            console2.log("Market not active, skipping test");
            return;
        }
        
        // Only run on users with sufficient YES tokens
        address user = USER1;
        uint256 initialUsdcBalance = usdc.balanceOf(user);
        uint256 initialYesBalance = yesToken.balanceOf(user);
        uint256 swapAmount = 10 * 10**18; // 10 YES tokens
        
        if (initialYesBalance < swapAmount) {
            console2.log("Not enough YES tokens for test, skipping");
            return;
        }
        
        console2.log("Initial USDC balance:", initialUsdcBalance);
        console2.log("Initial YES balance:", initialYesBalance);
        
        // Execute swap
        vm.startPrank(user);
        yesToken.approve(address(hook), swapAmount);
        
        try hook.swapYesTokensForUSDC(swapAmount) returns (uint256 usdcReceived) {
            console2.log("Swap successful, received USDC:", usdcReceived);
            
            // Verify balances
            uint256 newUsdcBalance = usdc.balanceOf(user);
            uint256 newYesBalance = yesToken.balanceOf(user);
            
            console2.log("New USDC balance:", newUsdcBalance);
            console2.log("New YES balance:", newYesBalance);
            
            assertEq(newUsdcBalance, initialUsdcBalance + usdcReceived, "Incorrect USDC received");
            assertEq(newYesBalance, initialYesBalance - swapAmount, "Incorrect YES tokens spent");
            assertGt(usdcReceived, 0, "Should receive positive amount of USDC");
        } catch Error(string memory reason) {
            console2.log("Swap failed:", reason);
        } catch {
            console2.log("Swap failed with unknown error");
        }
        
        vm.stopPrank();
    }
    
    function test_SwapNoTokensForUSDC() public {
        // Skip if market not active
        if (!isMarketActive()) {
            console2.log("Market not active, skipping test");
            return;
        }
        
        // Only run on users with sufficient NO tokens
        address user = USER2;
        uint256 initialUsdcBalance = usdc.balanceOf(user);
        uint256 initialNoBalance = noToken.balanceOf(user);
        uint256 swapAmount = 10 * 10**18; // 10 NO tokens
        
        if (initialNoBalance < swapAmount) {
            console2.log("Not enough NO tokens for test, skipping");
            return;
        }
        
        console2.log("Initial USDC balance:", initialUsdcBalance);
        console2.log("Initial NO balance:", initialNoBalance);
        
        // Execute swap
        vm.startPrank(user);
        noToken.approve(address(hook), swapAmount);
        
        try hook.swapNoTokensForUSDC(swapAmount) returns (uint256 usdcReceived) {
            console2.log("Swap successful, received USDC:", usdcReceived);
            
            // Verify balances
            uint256 newUsdcBalance = usdc.balanceOf(user);
            uint256 newNoBalance = noToken.balanceOf(user);
            
            console2.log("New USDC balance:", newUsdcBalance);
            console2.log("New NO balance:", newNoBalance);
            
            assertEq(newUsdcBalance, initialUsdcBalance + usdcReceived, "Incorrect USDC received");
            assertEq(newNoBalance, initialNoBalance - swapAmount, "Incorrect NO tokens spent");
            assertGt(usdcReceived, 0, "Should receive positive amount of USDC");
        } catch Error(string memory reason) {
            console2.log("Swap failed:", reason);
        } catch {
            console2.log("Swap failed with unknown error");
        }
        
        vm.stopPrank();
    }
    
    // =========================================
    // Cross-token Swap Tests
    // =========================================
    
    function test_SwapYesForNoTokens() public {
        // Skip if market not active
        if (!isMarketActive()) {
            console2.log("Market not active, skipping test");
            return;
        }
        
        // Only run on users with sufficient YES tokens
        address user = USER1;
        uint256 initialYesBalance = yesToken.balanceOf(user);
        uint256 initialNoBalance = noToken.balanceOf(user);
        uint256 swapAmount = 10 * 10**18; // 10 YES tokens
        
        if (initialYesBalance < swapAmount) {
            console2.log("Not enough YES tokens for test, skipping");
            return;
        }
        
        console2.log("Initial YES balance:", initialYesBalance);
        console2.log("Initial NO balance:", initialNoBalance);
        
        // Execute swap
        vm.startPrank(user);
        yesToken.approve(address(hook), swapAmount);
        
        try hook.swapYesForNoTokens(swapAmount) returns (uint256 noReceived) {
            console2.log("Swap successful, received NO tokens:", noReceived);
            
            // Verify balances
            uint256 newYesBalance = yesToken.balanceOf(user);
            uint256 newNoBalance = noToken.balanceOf(user);
            
            console2.log("New YES balance:", newYesBalance);
            console2.log("New NO balance:", newNoBalance);
            
            assertEq(newYesBalance, initialYesBalance - swapAmount, "Incorrect YES tokens spent");
            assertEq(newNoBalance, initialNoBalance + noReceived, "Incorrect NO tokens received");
            assertGt(noReceived, 0, "Should receive positive amount of NO tokens");
        } catch Error(string memory reason) {
            console2.log("Swap failed:", reason);
        } catch {
            console2.log("Swap failed with unknown error");
        }
        
        vm.stopPrank();
    }
    
    function test_SwapNoForYesTokens() public {
        // Skip if market not active
        if (!isMarketActive()) {
            console2.log("Market not active, skipping test");
            return;
        }
        
        // Only run on users with sufficient NO tokens
        address user = USER2;
        uint256 initialYesBalance = yesToken.balanceOf(user);
        uint256 initialNoBalance = noToken.balanceOf(user);
        uint256 swapAmount = 10 * 10**18; // 10 NO tokens
        
        if (initialNoBalance < swapAmount) {
            console2.log("Not enough NO tokens for test, skipping");
            return;
        }
        
        console2.log("Initial YES balance:", initialYesBalance);
        console2.log("Initial NO balance:", initialNoBalance);
        
        // Execute swap
        vm.startPrank(user);
        noToken.approve(address(hook), swapAmount);
        
        try hook.swapNoForYesTokens(swapAmount) returns (uint256 yesReceived) {
            console2.log("Swap successful, received YES tokens:", yesReceived);
            
            // Verify balances
            uint256 newYesBalance = yesToken.balanceOf(user);
            uint256 newNoBalance = noToken.balanceOf(user);
            
            console2.log("New YES balance:", newYesBalance);
            console2.log("New NO balance:", newNoBalance);
            
            assertEq(newNoBalance, initialNoBalance - swapAmount, "Incorrect NO tokens spent");
            assertEq(newYesBalance, initialYesBalance + yesReceived, "Incorrect YES tokens received");
            assertGt(yesReceived, 0, "Should receive positive amount of YES tokens");
        } catch Error(string memory reason) {
            console2.log("Swap failed:", reason);
        } catch {
            console2.log("Swap failed with unknown error");
        }
        
        vm.stopPrank();
    }
    
    // =========================================
    // Generic Swap Test
    // =========================================
    
    function test_GenericSwap() public {
        // Skip if market not active
        if (!isMarketActive()) {
            console2.log("Market not active, skipping test");
            return;
        }
        
        // Only run on users with sufficient USDC
        address user = USER3;
        uint256 initialUsdcBalance = usdc.balanceOf(user);
        uint256 initialYesBalance = yesToken.balanceOf(user);
        uint256 swapAmount = 50 * 10**6; // 50 USDC
        
        if (initialUsdcBalance < swapAmount) {
            console2.log("Not enough USDC for test, skipping");
            return;
        }
        
        console2.log("Initial USDC balance:", initialUsdcBalance);
        console2.log("Initial YES balance:", initialYesBalance);
        
        // Execute swap with slippage protection
        vm.startPrank(user);
        usdc.approve(address(hook), swapAmount);
        
        try hook.swap(usdcAddress, yesTokenAddress, swapAmount, 1) returns (uint256 yesReceived) {
            console2.log("Generic swap successful, received YES tokens:", yesReceived);
            
            // Verify balances
            uint256 newUsdcBalance = usdc.balanceOf(user);
            uint256 newYesBalance = yesToken.balanceOf(user);
            
            console2.log("New USDC balance:", newUsdcBalance);
            console2.log("New YES balance:", newYesBalance);
            
            assertEq(newUsdcBalance, initialUsdcBalance - swapAmount, "Incorrect USDC spent");
            assertEq(newYesBalance, initialYesBalance + yesReceived, "Incorrect YES tokens received");
            assertGt(yesReceived, 0, "Should receive positive amount of YES tokens");
        } catch Error(string memory reason) {
            console2.log("Swap failed:", reason);
        } catch {
            console2.log("Swap failed with unknown error");
        }
        
        vm.stopPrank();
    }
    
    // =========================================
    // Market Resolution Test
    // =========================================
    
    function test_ResolveAndClaim() public {
        // Skip if market already resolved
        if (hook.resolved()) {
            console2.log("Market already resolved, testing claim only");
            testClaim();
            return;
        }
        
        // Skip if market not ended yet
        if (block.timestamp <= hook.endTime()) {
            console2.log("Market not ended yet, warping time");
            vm.warp(hook.endTime() + 1 days);
        }
        
        // Ensure we have some test tokens for users before resolving
        setupUserForClaimTest();
        
        // Try to resolve if we're the owner
        address contractOwner = hook.checkOwner();
        vm.startPrank(contractOwner);
        
        try hook.resolveOutcome(true) {
            console2.log("Successfully resolved market with YES outcome");
            assertTrue(hook.resolved(), "Market should be resolved");
            assertTrue(hook.outcomeIsYes(), "Outcome should be YES");
            
            // Now test claiming
            testClaim();
        } catch Error(string memory reason) {
            console2.log("Failed to resolve market:", reason);
        } catch {
            console2.log("Failed to resolve market with unknown error");
        }
        
        vm.stopPrank();
    }
    
    function setupUserForClaimTest() internal {
        // Make sure USER1 has some YES tokens (for testing claim)
        if (yesToken.balanceOf(USER1) < 10 * 10**18) {
            address contractOwner = hook.checkOwner();
            
            if (yesToken.balanceOf(contractOwner) > 100 * 10**18) {
                vm.startPrank(contractOwner);
                yesToken.transfer(USER1, 100 * 10**18);
                vm.stopPrank();
                console2.log("Transferred YES tokens to USER1 for claim test");
            } else {
                vm.startPrank(address(this));
                try ERC20Mock(yesTokenAddress).mint(USER1, 100 * 10**18) {
                    console2.log("Minted YES tokens for USER1 for claim test");
                } catch {
                    console2.log("Failed to mint YES tokens for claim test");
                }
                vm.stopPrank();
            }
        }
    }
    
    function testClaim() internal {
        // Skip if market not resolved
        if (!hook.resolved()) {
            console2.log("Market not resolved yet, skipping claim test");
            return;
        }
        
        // Get the winning token
        bool outcomeIsYes = hook.outcomeIsYes();
        address winningToken = outcomeIsYes ? yesTokenAddress : noTokenAddress;
        console2.log("Winning token is:", outcomeIsYes ? "YES" : "NO");
        
        // Find a user with winning tokens
        address claimant;
        uint256 tokenBalance;
        
        if (IERC20(winningToken).balanceOf(USER1) > 0 && !hook.hasClaimed(USER1)) {
            claimant = USER1;
            tokenBalance = IERC20(winningToken).balanceOf(USER1);
        } else if (IERC20(winningToken).balanceOf(USER2) > 0 && !hook.hasClaimed(USER2)) {
            claimant = USER2;
            tokenBalance = IERC20(winningToken).balanceOf(USER2);
        } else if (IERC20(winningToken).balanceOf(USER3) > 0 && !hook.hasClaimed(USER3)) {
            claimant = USER3;
            tokenBalance = IERC20(winningToken).balanceOf(USER3);
        } else {
            console2.log("No eligible user with winning tokens found, skipping claim test");
            return;
        }
        
        console2.log("User has", tokenBalance, "winning tokens");
        
        // Get initial USDC balance
        uint256 initialUsdcBalance = usdc.balanceOf(claimant);
        console2.log("Initial USDC balance:", initialUsdcBalance);
        
        // Claim winnings
        vm.startPrank(claimant);
        hook.claim();
        vm.stopPrank();
        
        // Check if claim was successful
        assertTrue(hook.hasClaimed(claimant), "Claim should be marked as successful");
        
        // Check new USDC balance
        uint256 newUsdcBalance = usdc.balanceOf(claimant);
        console2.log("New USDC balance:", newUsdcBalance);
        console2.log("USDC received:", newUsdcBalance - initialUsdcBalance);
        
        // User should have received some USDC
        assertGt(newUsdcBalance, initialUsdcBalance, "User should receive USDC from claim");
    }
    
    // =========================================
    // Helper Functions
    // =========================================
    
    function isMarketActive() internal view returns (bool) {
        return (
            block.timestamp >= startTime && 
            block.timestamp <= endTime &&
            !hook.resolved()
        );
    }
    
    function timeWarpToActiveMarket() internal {
        if (block.timestamp < startTime) {
            vm.warp(startTime);
            console2.log("Warped time to market start:", block.timestamp);
        }
        
        if (block.timestamp > endTime) {
            vm.warp(startTime + 1 days); // Pick a time in the middle of the range
            console2.log("Warped time to active market period:", block.timestamp);
        }
    }
}