// fetchTweets.js
import fs from 'fs/promises';
import SimpleTweetFetcher from './SimpleTweetFetcher.js';
import Logger from './Logger.js';

/**
 * Fetches tweets and optionally saves them to a file
 * @param {string} username - Twitter username to fetch tweets from
 * @param {number} count - Number of tweets to fetch
 * @param {string|null} outputPath - Optional path to save tweets as JSON
 * @returns {Promise<Array>} - Array of tweets
 */
async function fetchTweets(username, count = 15, outputPath = null) {
  const fetcher = new SimpleTweetFetcher();
  
  try {
    const tweets = await fetcher.fetchLatestTweets(username, count);
    
    // Save to file if outputPath is provided
    if (outputPath) {
      await fs.writeFile(
        outputPath, 
        JSON.stringify(tweets, null, 2),
        'utf-8'
      );
      Logger.success(`Tweets saved to ${outputPath}`);
    }
    
    return tweets;
  } catch (error) {
    Logger.error(`Failed to fetch tweets: ${error.message}`);
    throw error;
  }
}

// Allow running as a standalone script
if (process.argv[1].includes('fetchTweets.js')) {
  const args = process.argv.slice(2);
  const username = args[0];
  const count = parseInt(args[1]) || 15;
  const outputPath = args[2] || `./tweets_${username}_${new Date().toISOString().split('T')[0]}.json`;
  
  if (!username) {
    console.error('Please provide a Twitter username as the first argument');
    process.exit(1);
  }
  
  fetchTweets(username, count, outputPath)
    .then(() => process.exit(0))
    .catch(() => process.exit(1));
}

export default fetchTweets;