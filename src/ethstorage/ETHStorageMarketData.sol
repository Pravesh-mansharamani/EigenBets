// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IETHStorage} from "ethstorage/IETHStorage.sol";

/**
 * @title ETHStorageMarketData
 * @dev Contract for storing prediction market data using ETH Storage's blob storage
 * @notice Implements ETH Storage API for decentralized data persistence
 */
contract ETHStorageMarketData is Ownable {
    // ETH Storage contract interface
    IETHStorage public ethStorage;
    
    // Structure for market outcome data
    struct MarketOutcomeData {
        address market;
        bool outcome;
        uint256 resolutionTimestamp;
        uint256 resolutionPrice;
        bytes32 blobHash;
        uint64 blobIndex;
    }
    
    // Structure for price feed history entries
    struct PriceFeedEntry {
        int256 price;
        uint256 timestamp;
        uint8 decimals;
    }
    
    // Mapping of market address to their outcome data
    mapping(address => MarketOutcomeData) public marketOutcomes;
    
    // Mapping of market data blobs by index
    mapping(uint64 => bytes32) public dataBlobs;
    
    // Counter for blob indices
    uint64 public nextBlobIndex;
    
    // ETH Storage constants based on documentation
    uint64 public constant SHARD_ID = 0;
    uint32 public constant MAX_BLOB_SIZE = 4194304; // 4MB in bytes
    
    // Events
    event MarketDataStored(address indexed market, bool outcome, uint256 timestamp, bytes32 blobHash);
    event PriceFeedDataStored(address indexed priceFeed, uint256 fromTimestamp, uint256 toTimestamp, bytes32 blobHash);
    event ETHStorageContractUpdated(address newContract);
    
    /**
     * @dev Constructor initializes the ETH Storage contract reference
     * @param _ethStorageContract Address of the ETH Storage contract
     */
    constructor(address _ethStorageContract) Ownable(msg.sender) {
        ethStorage = IETHStorage(_ethStorageContract);
    }
    
    /**
     * @notice Updates the ETH Storage contract address
     * @param _newContract Address of the new ETH Storage contract
     */
    function updateETHStorageContract(address _newContract) external onlyOwner {
        require(_newContract != address(0), "Invalid contract address");
        ethStorage = IETHStorage(_newContract);
        emit ETHStorageContractUpdated(_newContract);
    }
    
    /**
     * @notice Stores market outcome data on ETH Storage
     * @param market Address of the prediction market
     * @param outcome Boolean indicating the market outcome (true for YES, false for NO)
     * @param resolutionPrice The oracle price at market resolution
     * @param additionalData Any additional data to store with the outcome
     */
    function storeMarketOutcome(
        address market,
        bool outcome,
        uint256 resolutionPrice,
        bytes calldata additionalData
    ) external onlyOwner {
        // Prepare data for storage
        bytes memory dataToStore = abi.encode(
            market,
            outcome,
            block.timestamp,
            resolutionPrice,
            additionalData
        );
        
        // Store data in ETH Storage blob
        bytes32 blobHash = storeBlob(dataToStore);
        
        // Record the outcome data
        marketOutcomes[market] = MarketOutcomeData({
            market: market,
            outcome: outcome,
            resolutionTimestamp: block.timestamp,
            resolutionPrice: resolutionPrice,
            blobHash: blobHash,
            blobIndex: nextBlobIndex - 1
        });
        
        emit MarketDataStored(market, outcome, block.timestamp, blobHash);
    }
    
    /**
     * @notice Stores price feed history on ETH Storage
     * @param priceFeed Address of the price feed
     * @param entries Array of price feed entries (price, timestamp, decimals)
     */
    function storePriceFeedHistory(
        address priceFeed,
        PriceFeedEntry[] calldata entries
    ) external onlyOwner {
        require(entries.length > 0, "No entries provided");
        
        // Prepare data for storage
        bytes memory dataToStore = abi.encode(priceFeed, entries);
        
        // Store data in ETH Storage blob
        bytes32 blobHash = storeBlob(dataToStore);
        
        emit PriceFeedDataStored(
            priceFeed,
            entries[0].timestamp,
            entries[entries.length - 1].timestamp,
            blobHash
        );
    }
    
    /**
     * @notice Internal function to store a blob on ETH Storage
     * @param data The data to store as a blob
     * @return blobHash The hash of the stored blob
     */
    function storeBlob(bytes memory data) internal returns (bytes32 blobHash) {
        require(data.length <= MAX_BLOB_SIZE, "Data exceeds max blob size");
        
        // In a real implementation, this would call the ETH Storage store function
        // using the ETH Storage protocol according to documentation
        
        // Mock implementation for placeholder
        blobHash = keccak256(data);
        uint64 blobIndex = nextBlobIndex++;
        
        // Store blob index and hash
        dataBlobs[blobIndex] = blobHash;
        
        // Simulating ETH Storage API call
        // ethStorage.store(SHARD_ID, blobIndex, data);
        
        return blobHash;
    }
    
    /**
     * @notice Retrieves market outcome data from ETH Storage
     * @param market Address of the market to retrieve data for
     * @return The outcome data encoded as bytes
     */
    function getMarketOutcomeData(address market) external view returns (bytes memory) {
        MarketOutcomeData memory data = marketOutcomes[market];
        require(data.blobHash != bytes32(0), "No data for market");
        
        // In a real implementation, this would call the ETH Storage retrieve function
        // Example: ethStorage.retrieve(SHARD_ID, data.blobIndex);
        
        // Return mock data for now
        return abi.encode(
            data.market,
            data.outcome,
            data.resolutionTimestamp,
            data.resolutionPrice,
            "Additional data would be retrieved from ETH Storage"
        );
    }
    
    /**
     * @notice Checks if a market has outcome data stored
     * @param market Address of the market to check
     * @return Whether the market has outcome data
     */
    function hasMarketOutcomeData(address market) external view returns (bool) {
        return marketOutcomes[market].blobHash != bytes32(0);
    }
    
    /**
     * @notice Function to calculate storage and bandwidth costs based on ETH Storage pricing
     * @param dataSize Size of data in bytes
     * @return storageCost The cost in ETH for storing the data
     * @return bandwidthCost The cost in ETH for bandwidth to serve the data
     */
    function calculateStorageCosts(uint256 dataSize) external pure returns (uint256 storageCost, uint256 bandwidthCost) {
        // Based on ETH Storage pricing model from documentation
        // These are illustrative values and should be updated with actual pricing
        storageCost = (dataSize * 1 gwei) / 1_000_000;
        bandwidthCost = (dataSize * 2 gwei) / 1_000_000;
        
        return (storageCost, bandwidthCost);
    }
} 