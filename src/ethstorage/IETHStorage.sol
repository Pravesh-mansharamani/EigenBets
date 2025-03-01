// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title IETHStorage
 * @dev Interface for interacting with ETH Storage protocol
 * @notice Based on ETH Storage documentation at https://docs.ethstorage.io/
 */
interface IETHStorage {
    /**
     * @notice Stores data in ETH Storage
     * @param shardId The ID of the shard to store data in
     * @param index The index in the shard where data will be stored
     * @param data The data to store
     * @return success Whether the store operation was successful
     */
    function store(uint64 shardId, uint64 index, bytes calldata data) external payable returns (bool success);
    
    /**
     * @notice Retrieves data from ETH Storage
     * @param shardId The ID of the shard to retrieve data from
     * @param index The index in the shard where data is stored
     * @return data The retrieved data
     */
    function retrieve(uint64 shardId, uint64 index) external view returns (bytes memory data);
    
    /**
     * @notice Encodes data to be stored as blob in ETH Storage
     * @param data The raw data to encode
     * @return encodedData The encoded data ready for storage
     */
    function encodeData(bytes calldata data) external pure returns (bytes memory encodedData);
    
    /**
     * @notice Calculates storage fee for a given data size
     * @param dataSize Size of data in bytes
     * @return fee The storage fee in ETH
     */
    function calculateStorageFee(uint256 dataSize) external view returns (uint256 fee);
    
    /**
     * @notice Verifies data against a stored blob hash
     * @param shardId The ID of the shard where data is stored
     * @param index The index in the shard where data is stored
     * @param data The data to verify
     * @return isValid Whether the data matches what is stored
     */
    function verifyData(uint64 shardId, uint64 index, bytes calldata data) external view returns (bool isValid);
    
    /**
     * @notice Gets the availability status of a shard
     * @param shardId The ID of the shard to check
     * @return isAvailable Whether the shard is available
     */
    function getShardAvailability(uint64 shardId) external view returns (bool isAvailable);
    
    /**
     * @notice Gets the hash of data stored at a specific location
     * @param shardId The ID of the shard
     * @param index The index in the shard
     * @return dataHash The hash of the stored data
     */
    function getDataHash(uint64 shardId, uint64 index) external view returns (bytes32 dataHash);
} 