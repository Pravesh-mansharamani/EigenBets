require('dotenv').config();
const axios = require("axios");

var ipfsHost='';

function init() {
  ipfsHost = process.env.IPFS_HOST;
}

async function getIPfsTask(cid) {
  try {
    const { data } = await axios.get(ipfsHost + cid);
    
    // Handle both price-based and prediction market tasks
    if (data.symbol && data.price) {
      // Original price task format
      return {
        symbol: data.symbol,
        price: parseFloat(data.price),
      };
    } else if (data.inputString) {
      // New AI prediction market format with single input string
      return {
        inputString: data.inputString,
        result: data.result,
        timestamp: data.timestamp
      };
    } else {
      throw new Error("Unknown task format in IPFS data");
    }
  } catch (error) {
    console.error("Error retrieving IPFS task:", error.message);
    throw error;
  }
}  
  
module.exports = {
  init,
  getIPfsTask
}