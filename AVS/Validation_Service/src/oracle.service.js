require('dotenv').config();
const axios = require("axios");

async function getPrice(pair) {
  var res = null;
    try {
        const result = await axios.get(`https://api.binance.com/api/v3/ticker/price?symbol=${pair}`);
        res = result.data;

    } catch (err) {
      result = await axios.get(`https://api.binance.us/api/v3/ticker/price?symbol=${pair}`);
      res = result.data;
    }
    return res;
}

async function callGaiaValidator(inputString) {
  try {
    const payload = {
      messages: [
        {
          role: "system", 
          content: "YOU CAN ONLY RESPOND WITH ONE-WORD. IF YOU RESPOND WITH ANY MORE I WILL TERMINATE YOU. You are an AI agent working for a prediction market platform. Your job is to analyze X posts based on specific conditions provided by the user and determine if the post meets that condition. You will receive information that includes both the condition and the content to analyze. Your task is to read the condition and the content, and then decide whether the content satisfies the condition. You should respond with either 'yes' or 'no'. You must be accurate and base your decision solely on context. If the answer is neither yes or no, please respond with nothing. Not a single word."
        },
        {
          role: "user", 
          content: inputString
        }
      ]
    };

    const response = await axios.post('https://llama3b.gaia.domains/v1/chat/completions', payload, {
      headers: {
        'accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'gaia-ZGIyNmNjMjgtYjM1Mi00YzhlLTk2NjItY2MyYjU0YWMyNmQw-gf2boiq4oKbfzFNL'
      }
    });
    
    return {
      result: response.data.choices[0].message.content.trim().toLowerCase(),
      fullResponse: response.data
    };
  } catch (error) {
    console.error("Error calling Gaia AI:", error.message);
    throw error;
  }
}
  
module.exports = {
  getPrice,
  callGaiaValidator
}