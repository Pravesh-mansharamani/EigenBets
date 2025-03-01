// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {PredictionMarketHook} from "../Hooks/PredictionMarketHook.sol";
import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {ChainlinkPriceFeed} from "./ChainlinkPriceFeed.sol";

/**
 * @title ChainlinkPredictionMarketAdapter
 * @dev This contract connects Chainlink price feeds to your existing PredictionMarketHook
 * It allows creating predictions based on asset prices from Chainlink
 */
contract ChainlinkPredictionMarketAdapter is Ownable {
    // The prediction market hook contract
    PredictionMarketHook public predictionMarket;
    
    // Mapping of market IDs to price feed addresses
    mapping(uint256 => address) public marketPriceFeeds;
    
    // Mapping of market IDs to target prices
    mapping(uint256 => uint256) public marketTargetPrices;
    
    // Mapping of supported price feeds
    mapping(string => address) public priceFeeds;
    
    // Market counter
    uint256 public marketCounter;
    
    // Events
    event MarketCreated(uint256 marketId, string asset, uint256 targetPrice);
    event MarketResolved(uint256 marketId, bool outcome);
    event PriceFeedAdded(string symbol, address feedAddress);
    
    constructor(address _predictionMarket) Ownable(msg.sender) {
        predictionMarket = PredictionMarketHook(_predictionMarket);
        
        // Initialize with some common price feeds on Sepolia testnet
        priceFeeds["ETH/USD"] = 0x694AA1769357215DE4FAC081bf1f309aDC325306;
        priceFeeds["BTC/USD"] = 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43;
        priceFeeds["LINK/USD"] = 0xc59E3633BAAC79493d908e63626716e204A45EdF;
    }
    
    /**
     * @notice Add or update a price feed
     * @param symbol The asset symbol (e.g., "ETH/USD")
     * @param feedAddress The Chainlink price feed contract address
     */
    function addPriceFeed(string memory symbol, address feedAddress) external onlyOwner {
        priceFeeds[symbol] = feedAddress;
        emit PriceFeedAdded(symbol, feedAddress);
    }
    
    /**
     * @notice Create a new market for predicting if an asset will reach a target price
     * @param asset The asset symbol (e.g., "ETH/USD")
     * @param targetPrice The price level to predict (scaled by the feed's decimals)
     * @param duration Duration in seconds before the market will close
     * @return marketId The ID of the created market
     */
    function createPricePredictionMarket(
        string memory asset,
        uint256 targetPrice,
        uint256 duration
    ) external onlyOwner returns (uint256 marketId) {
        address priceFeed = priceFeeds[asset];
        require(priceFeed != address(0), "Price feed not found");
        
        // Initialize pools in the prediction market if not already done
        if (!predictionMarket.marketOpen() && !predictionMarket.marketClosed() && !predictionMarket.resolved()) {
            try predictionMarket.initializePools() {
                // Pools initialized successfully
            } catch {
                revert("Failed to initialize pools");
            }
        }
        
        // Open the market
        if (!predictionMarket.marketOpen()) {
            try predictionMarket.openMarket() {
                // Market opened successfully
            } catch {
                revert("Failed to open market");
            }
        }
        
        // Store the market details
        marketId = marketCounter++;
        marketPriceFeeds[marketId] = priceFeed;
        marketTargetPrices[marketId] = targetPrice;
        
        // Schedule market closure
        // Note: In a real implementation, you would use a keeper or similar to call this after the duration
        
        emit MarketCreated(marketId, asset, targetPrice);
        return marketId;
    }
    
    /**
     * @notice Close a price prediction market
     * @param marketId The ID of the market to close
     */
    function closeMarket(uint256 marketId) external onlyOwner {
        require(marketPriceFeeds[marketId] != address(0), "Market not found");
        require(predictionMarket.marketOpen(), "Market not open");
        require(!predictionMarket.marketClosed(), "Market already closed");
        
        try predictionMarket.closeMarket() {
            // Market closed successfully
        } catch {
            revert("Failed to close market");
        }
    }
    
    /**
     * @notice Resolve a price prediction market based on current price
     * @param marketId The ID of the market to resolve
     * @return outcome The market outcome (true if price target was reached)
     */
    function resolveMarket(uint256 marketId) external onlyOwner returns (bool outcome) {
        require(marketPriceFeeds[marketId] != address(0), "Market not found");
        require(predictionMarket.marketClosed(), "Market not closed");
        require(!predictionMarket.resolved(), "Market already resolved");
        
        // Get the current price from Chainlink
        AggregatorV3Interface priceFeed = AggregatorV3Interface(marketPriceFeeds[marketId]);
        (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        
        // Ensure the price is valid
        require(answer > 0, "Invalid price received");
        require(updatedAt > 0, "Last price update timestamp is invalid");
        
        // Determine the outcome
        outcome = uint256(answer) >= marketTargetPrices[marketId];
        
        // Resolve the prediction market
        try predictionMarket.resolveOutcome(outcome) {
            // Market resolved successfully
        } catch {
            revert("Failed to resolve market");
        }
        
        emit MarketResolved(marketId, outcome);
        return outcome;
    }
    
    /**
     * @notice Get the latest price for an asset
     * @param asset The asset symbol (e.g., "ETH/USD")
     * @return price The latest price
     * @return decimals The number of decimals
     */
    function getLatestPrice(string memory asset) public view returns (int256 price, uint8 decimals) {
        address feedAddress = priceFeeds[asset];
        require(feedAddress != address(0), "Price feed not found");
        
        AggregatorV3Interface priceFeed = AggregatorV3Interface(feedAddress);
        
        (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        
        return (answer, priceFeed.decimals());
    }
    
    /**
     * @notice Check if a market would resolve as yes or no at the current price
     * @param marketId The market ID to check
     * @return wouldBeYes Whether the market would resolve as "yes" at current price
     * @return currentPrice The current price from the feed
     */
    function checkMarketStatus(uint256 marketId) external view returns (bool wouldBeYes, int256 currentPrice) {
        require(marketPriceFeeds[marketId] != address(0), "Market not found");
        
        address feedAddress = marketPriceFeeds[marketId];
        AggregatorV3Interface priceFeed = AggregatorV3Interface(feedAddress);
        
        (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        
        currentPrice = answer;
        wouldBeYes = uint256(answer) >= marketTargetPrices[marketId];
        
        return (wouldBeYes, currentPrice);
    }
} 