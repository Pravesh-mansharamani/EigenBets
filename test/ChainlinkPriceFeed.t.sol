// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console2} from "forge-std/Test.sol";
import {ChainlinkPriceFeed} from "../src/chainlink/ChainlinkPriceFeed.sol";

contract ChainlinkPriceFeedTest is Test {
    ChainlinkPriceFeed public priceFeed;
    address public admin;
    
    // Define the RPC URL
    string constant FORK_URL = "https://sepolia.infura.io/v3/YOUR_INFURA_KEY"; // Replace with your Infura key
    
    // Test users
    address public constant USER1 = address(0x1111);
    address public constant USER2 = address(0x2222);
    
    function setUp() public {
        // Create a fork of Sepolia
        uint256 forkId = vm.createFork(FORK_URL);
        vm.selectFork(forkId);
        
        // Deploy the contract
        admin = address(this);
        priceFeed = new ChainlinkPriceFeed();
        
        // Fund test users
        vm.deal(USER1, 10 ether);
        vm.deal(USER2, 10 ether);
    }
    
    function test_GetEthUsdPrice() public {
        // Test fetching ETH/USD price
        (int256 price, uint8 decimals, uint256 timestamp) = priceFeed.getLatestPrice("ETH/USD");
        
        console2.log("ETH/USD Price:", price);
        console2.log("Decimals:", decimals);
        console2.log("Timestamp:", timestamp);
        
        // Price should be positive and recent
        assertGt(price, 0, "ETH price should be positive");
        assertEq(decimals, 8, "ETH/USD should have 8 decimals");
        assertGt(timestamp, 0, "Timestamp should be valid");
    }
    
    function test_GetBtcUsdPrice() public {
        // Test fetching BTC/USD price
        (int256 price, uint8 decimals, uint256 timestamp) = priceFeed.getLatestPrice("BTC/USD");
        
        console2.log("BTC/USD Price:", price);
        console2.log("Decimals:", decimals);
        console2.log("Timestamp:", timestamp);
        
        // Price should be positive and recent
        assertGt(price, 0, "BTC price should be positive");
        assertEq(decimals, 8, "BTC/USD should have 8 decimals");
        assertGt(timestamp, 0, "Timestamp should be valid");
    }
    
    function test_CreateAndResolvePrediction() public {
        // Create a prediction for ETH price
        uint256 currentTime = block.timestamp;
        
        // Get current ETH price
        (int256 currentPrice, , ) = priceFeed.getLatestPrice("ETH/USD");
        
        // Create a prediction that ETH will be at or above its current price in 1 day
        uint256 targetPrice = uint256(currentPrice);
        uint256 duration = 1 days;
        
        uint256 predictionId = priceFeed.createPrediction("ETH/USD", targetPrice, duration);
        
        // Check prediction was created correctly
        ChainlinkPriceFeed.Prediction memory prediction = priceFeed.getPrediction(predictionId);
        assertEq(prediction.asset, "ETH/USD", "Asset should be ETH/USD");
        assertEq(prediction.targetPrice, targetPrice, "Target price should match");
        assertEq(prediction.expiryTime, currentTime + duration, "Expiry time should match");
        assertEq(prediction.resolved, false, "Prediction should not be resolved yet");
        
        // Fast forward time to expiry
        vm.warp(currentTime + duration + 1);
        
        // Resolve the prediction
        bool outcome = priceFeed.resolvePrediction(predictionId);
        
        // Get updated prediction
        prediction = priceFeed.getPrediction(predictionId);
        
        // Check prediction was resolved
        assertEq(prediction.resolved, true, "Prediction should now be resolved");
        
        // The outcome will depend on price movement, but we should at least check it matches
        assertEq(prediction.outcome, outcome, "Outcome should match return value");
    }
    
    function test_AddNewPriceFeed() public {
        // Test adding a new price feed
        string memory symbol = "LINK/ETH";
        address feedAddress = 0xc59E3633BAAC79493d908e63626716e204A45EdF; // This is a real Sepolia address for LINK/ETH
        
        priceFeed.addPriceFeed(symbol, feedAddress);
        
        // Check price feed was added
        assertEq(priceFeed.priceFeeds(symbol), feedAddress, "Price feed should be added");
    }
    
    function testFail_NonAdminCannotAddPriceFeed() public {
        // Non-admin should not be able to add price feeds
        vm.startPrank(USER1);
        
        string memory symbol = "DAI/USD";
        address feedAddress = 0x14866185B1962B63C3Ea9E03Bc1da838bab34C19; // Sepolia DAI/USD
        
        priceFeed.addPriceFeed(symbol, feedAddress);
        
        vm.stopPrank();
    }
    
    function testFail_CannotResolvePredictionBeforeExpiry() public {
        // Create a prediction
        uint256 predictionId = priceFeed.createPrediction("ETH/USD", 2000 * 10**8, 1 days);
        
        // Try to resolve it immediately (should fail)
        priceFeed.resolvePrediction(predictionId);
    }
} 