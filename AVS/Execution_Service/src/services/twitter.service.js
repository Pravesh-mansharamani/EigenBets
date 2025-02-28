require('dotenv').config();
const { SimpleTweetFetcher, Logger } = require('../utils/twitter/CompatWrapper');
const path = require('path');
const fs = require('fs').promises;

// Twitter scraper instance
let tweetFetcher = null;

// Initialize Twitter scraper service
function init() {
  console.log('Initializing Twitter scraper service...');
  
  try {
    // Create the tweet fetcher instance
    tweetFetcher = new SimpleTweetFetcher();
    console.log('Twitter scraper service initialized successfully');
  } catch (error) {
    console.error('Failed to initialize Twitter scraper:', error);
  }
}

/**
 * Extract keywords from a condition string
 * @param {string} condition - The condition to analyze
 * @returns {string[]} - Array of extracted keywords
 */
function extractKeywords(condition) {
  if (!condition) return [];
  
  // Remove common words and punctuation
  const commonWords = ['the', 'and', 'or', 'a', 'an', 'is', 'are', 'was', 'were', 
                      'will', 'would', 'should', 'could', 'be', 'to', 'of', 'in', 
                      'that', 'have', 'for', 'on', 'with', 'as', 'at', 'this', 'there',
                      'from', 'by', 'does', 'do', 'did', 'has', 'had', 'tweet', 'post', 
                      'mention', 'about', 'any', 'some'];
  
  // Extract potential keywords (nouns, proper nouns, product names, etc.)
  const words = condition.toLowerCase()
    .replace(/[^\w\s]/g, ' ')  // Replace punctuation with spaces
    .split(/\s+/)              // Split by whitespace
    .filter(word => 
      word.length > 2 &&       // Ignore very short words
      !commonWords.includes(word)
    );
  
  // Find potential usernames or mentions
  const mentions = condition.match(/@\w+/g) || [];
  
  // Find potential cashtags or stock symbols
  const cashtags = condition.match(/\$[A-Za-z]+/g) || [];
  
  // Find hashtags
  const hashtags = condition.match(/#\w+/g) || [];
  
  // Combine all potential search terms
  const searchTerms = [...new Set([...words, ...mentions, ...cashtags, ...hashtags])];
  
  // For best results, limit to the most relevant terms
  return searchTerms.slice(0, 5);
}

/**
 * Identify likely Twitter accounts to search based on condition
 * @param {string} condition - The condition to analyze
 * @returns {string[]} - Array of Twitter usernames to check
 */
function identifyRelevantAccounts(condition) {
  // Extract company or entity names from the condition
  const lowercaseCondition = condition.toLowerCase();
  
  // Check for common companies, products, or entities
  const entityMap = {
    'apple': ['Apple', 'tim_cook', 'AppleSupport'],
    'iphone': ['Apple', 'tim_cook', 'AppleSupport'],
    'google': ['Google', 'sundarpichai', 'Android'],
    'android': ['Google', 'Android', 'sundarpichai'],
    'microsoft': ['Microsoft', 'satyanadella', 'Windows'],
    'windows': ['Microsoft', 'Windows', 'satyanadella'],
    'tesla': ['Tesla', 'elonmusk', 'TeslaMotors'],
    'spacex': ['SpaceX', 'elonmusk'],
    'amazon': ['Amazon', 'AmazonHelp', 'JeffBezos'],
    'facebook': ['Facebook', 'Meta', 'zuck'],
    'meta': ['Meta', 'Facebook', 'zuck'],
    'netflix': ['Netflix', 'netflixhelp'],
    'bitcoin': ['Bitcoin', 'bitcoinmagazine', 'DocumentingBTC'],
    'ethereum': ['ethereum', 'VitalikButerin', 'ethdotorg'],
    'crypto': ['Bitcoin', 'ethereum', 'binance', 'cz_binance'],
    'nft': ['opensea', 'nft_tokens', 'BoredApeYC']
  };
  
  // Identify relevant accounts based on keywords in the condition
  let accounts = [];
  
  Object.entries(entityMap).forEach(([keyword, relatedAccounts]) => {
    if (lowercaseCondition.includes(keyword)) {
      accounts = [...accounts, ...relatedAccounts];
    }
  });
  
  // Add some default news accounts if no specific entity is found
  if (accounts.length === 0) {
    accounts = ['cnnbrk', 'BBCBreaking', 'WSJ', 'CNBC', 'Reuters'];
  }
  
  // Return unique accounts
  return [...new Set(accounts)];
}

/**
 * Fetch relevant tweets based on a condition
 * @param {string} condition - The condition to find relevant tweets for
 * @returns {Promise<Array>} - Array of tweet objects
 */
async function fetchRelevantTweets(condition) {
  try {
    console.log(`Fetching tweets for condition: ${condition}`);
    
    if (!tweetFetcher) {
      throw new Error('Twitter scraper not initialized');
    }
    
    // Identify relevant Twitter accounts to search
    const relevantAccounts = identifyRelevantAccounts(condition);
    console.log(`Identified relevant accounts: ${relevantAccounts.join(', ')}`);
    
    let allTweets = [];
    
    // Fetch tweets from each relevant account
    for (const username of relevantAccounts) {
      try {
        const tweets = await tweetFetcher.fetchLatestTweets(username, 10);
        console.log(`Fetched ${tweets.length} tweets from @${username}`);
        allTweets = [...allTweets, ...tweets];
      } catch (error) {
        console.warn(`Error fetching tweets from @${username}:`, error.message);
        // Continue with other accounts even if one fails
      }
    }
    
    // Extract keywords from condition for filtering
    const keywords = extractKeywords(condition);
    console.log(`Filtering tweets using keywords: ${keywords.join(', ')}`);
    
    // Filter tweets by relevance to the condition
    const filteredTweets = allTweets.filter(tweet => {
      const tweetText = tweet.text.toLowerCase();
      // Check if any keyword appears in the tweet
      return keywords.some(keyword => tweetText.includes(keyword.toLowerCase()));
    });
    
    console.log(`Found ${filteredTweets.length} relevant tweets out of ${allTweets.length} total`);
    
    // Take only the 5 most recent relevant tweets
    const recentTweets = filteredTweets
      .sort((a, b) => new Date(b.created_at) - new Date(a.created_at))
      .slice(0, 5);
    
    // If no relevant tweets found, return a placeholder tweet
    if (recentTweets.length === 0) {
      Logger.warn('No relevant tweets found for the condition');
      return [
        {
          id: 'placeholder',
          text: `No relevant tweets found for this condition: "${condition}". Please check again later for updates or modify the condition.`,
          author: 'placeholder_user',
          created_at: new Date().toISOString()
        }
      ];
    }
    
    // Log the found tweets
    Logger.success(`Found ${recentTweets.length} relevant tweets for condition`);
    
    return recentTweets;
  } catch (error) {
    Logger.error(`Error fetching tweets: ${error.message}`);
    return [
      {
        id: 'error',
        text: `Error fetching tweets: ${error.message}. Using original condition for validation.`,
        author: 'system',
        created_at: new Date().toISOString()
      }
    ];
  }
}

module.exports = {
  init,
  fetchRelevantTweets,
  extractKeywords,
  identifyRelevantAccounts
};