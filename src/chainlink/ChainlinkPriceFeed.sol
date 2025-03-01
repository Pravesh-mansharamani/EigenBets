// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/**
 * @title ChainlinkPriceFeed
 * @dev This contract fetches price data from Chainlink price feeds and can be used
 * for prediction markets on token prices, sports events, or other data feeds.
 */
contract ChainlinkPriceFeed {
    // Mapping of asset symbols to price feed addresses
    mapping(string => address) public priceFeeds;
    
    // Admin address for managing price feeds
    address public admin;
    
    // Events
    event PriceFeedAdded(string symbol, address feedAddress);
    event PriceFeedUpdated(string symbol, address feedAddress);
    event PredictionCreated(uint256 predictionId, string asset, uint256 targetPrice, uint256 expiryTime);
    event PredictionResolved(uint256 predictionId, bool outcome);
    
    // Prediction structure
    struct Prediction {
        string asset;         // Asset symbol (e.g., "ETH/USD")
        uint256 targetPrice;  // Target price for prediction
        uint256 expiryTime;   // When the prediction expires
        bool resolved;        // Whether this prediction has been resolved
        bool outcome;         // The outcome once resolved
    }
    
    // Store all predictions
    mapping(uint256 => Prediction) public predictions;
    uint256 public nextPredictionId = 1;
    
    constructor() {
        admin = msg.sender;
        
        // Initialize with some common price feeds on Sepolia testnet
        // These are Sepolia addresses - use appropriate network addresses
        priceFeeds["ETH/USD"] = 0x694AA1769357215DE4FAC081bf1f309aDC325306;
        priceFeeds["BTC/USD"] = 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43;
        priceFeeds["LINK/USD"] = 0xc59E3633BAAC79493d908e63626716e204A45EdF;
    }
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }
    
    /**
     * @notice Add a new price feed to the contract
     * @param symbol The symbol of the asset (e.g., "ETH/USD")
     * @param feedAddress The Chainlink price feed address
     */
    function addPriceFeed(string memory symbol, address feedAddress) external onlyAdmin {
        require(priceFeeds[symbol] == address(0), "Price feed already exists");
        priceFeeds[symbol] = feedAddress;
        emit PriceFeedAdded(symbol, feedAddress);
    }
    
    /**
     * @notice Update an existing price feed
     * @param symbol The symbol of the asset to update
     * @param feedAddress The new Chainlink price feed address
     */
    function updatePriceFeed(string memory symbol, address feedAddress) external onlyAdmin {
        require(priceFeeds[symbol] != address(0), "Price feed does not exist");
        priceFeeds[symbol] = feedAddress;
        emit PriceFeedUpdated(symbol, feedAddress);
    }
    
    /**
     * @notice Get the latest price from a Chainlink price feed
     * @param symbol The symbol of the asset to get the price for
     * @return price The latest price (scaled by decimals)
     * @return decimals The number of decimals in the price
     * @return timestamp The timestamp of the latest price
     */
    function getLatestPrice(string memory symbol) public view returns (int256 price, uint8 decimals, uint256 timestamp) {
        address feedAddress = priceFeeds[symbol];
        require(feedAddress != address(0), "Price feed not found");
        
        AggregatorV3Interface priceFeed = AggregatorV3Interface(feedAddress);
        
        // Get the latest round data
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
        
        return (answer, priceFeed.decimals(), updatedAt);
    }
    
    /**
     * @notice Create a new price prediction
     * @param asset The symbol of the asset to predict (e.g., "ETH/USD")
     * @param targetPrice The target price for the prediction
     * @param durationInSeconds How long until the prediction expires
     * @return predictionId The ID of the created prediction
     */
    function createPrediction(
        string memory asset,
        uint256 targetPrice,
        uint256 durationInSeconds
    ) external returns (uint256 predictionId) {
        // Ensure the asset has a price feed
        require(priceFeeds[asset] != address(0), "Price feed not found for asset");
        
        // Create the prediction
        uint256 expiryTime = block.timestamp + durationInSeconds;
        
        predictionId = nextPredictionId++;
        predictions[predictionId] = Prediction({
            asset: asset,
            targetPrice: targetPrice,
            expiryTime: expiryTime,
            resolved: false,
            outcome: false
        });
        
        emit PredictionCreated(predictionId, asset, targetPrice, expiryTime);
        return predictionId;
    }
    
    /**
     * @notice Resolve a prediction based on the current price
     * @param predictionId The ID of the prediction to resolve
     * @return outcome The outcome of the prediction
     */
    function resolvePrediction(uint256 predictionId) external returns (bool outcome) {
        Prediction storage prediction = predictions[predictionId];
        
        // Validation
        require(!prediction.resolved, "Prediction already resolved");
        require(block.timestamp >= prediction.expiryTime, "Prediction has not expired yet");
        
        // Get the current price
        (int256 currentPrice, , ) = getLatestPrice(prediction.asset);
        
        // Determine outcome (if price is greater than or equal to target)
        outcome = uint256(currentPrice) >= prediction.targetPrice;
        
        // Update prediction
        prediction.resolved = true;
        prediction.outcome = outcome;
        
        emit PredictionResolved(predictionId, outcome);
        return outcome;
    }
    
    /**
     * @notice Check if a prediction would be resolved as true or false at current price
     * @param predictionId The ID of the prediction to check
     * @return wouldBeTrue Whether the prediction would be true at current price
     * @return currentPrice The current price of the asset
     */
    function checkPredictionStatus(uint256 predictionId) external view returns (bool wouldBeTrue, int256 currentPrice) {
        Prediction storage prediction = predictions[predictionId];
        require(prediction.expiryTime > 0, "Prediction does not exist");
        
        // Get current price
        (currentPrice, , ) = getLatestPrice(prediction.asset);
        
        // Check if target price is reached
        wouldBeTrue = uint256(currentPrice) >= prediction.targetPrice;
        
        return (wouldBeTrue, currentPrice);
    }
    
    /**
     * @notice Get all details about a prediction
     * @param predictionId The ID of the prediction
     * @return The prediction details
     */
    function getPrediction(uint256 predictionId) external view returns (Prediction memory) {
        require(predictions[predictionId].expiryTime > 0, "Prediction does not exist");
        return predictions[predictionId];
    }
} 