// SimpleTweetFetcher.js
import dotenv from 'dotenv';
dotenv.config();

import { Scraper, SearchMode } from "agent-twitter-client";
import Logger from "./Logger.js";

class SimpleTweetFetcher {
  constructor() {
    this.scraper = new Scraper();
  }

  /**
   * Process a tweet into a simplified format
   * @param {Object} tweet - Raw tweet object
   * @returns {Object} - Processed tweet data
   */
  processTweet(tweet) {
    if (!tweet || !tweet.id) return null;

    return {
      id: tweet.id,
      text: tweet.text,
      timestamp: tweet.timestamp || (tweet.timeParsed?.getTime()),
      createdAt: tweet.timestamp ? new Date(tweet.timestamp).toISOString() : null,
      isReply: Boolean(tweet.isReply),
      isRetweet: Boolean(tweet.isRetweet),
      likes: tweet.likes || 0,
      retweetCount: tweet.retweets || 0,
      replies: tweet.replies || 0,
      photos: tweet.photos || [],
      videos: tweet.videos || [],
      urls: tweet.urls || [],
      permanentUrl: tweet.permanentUrl,
      quotedTweet: tweet.quotedTweet ? this.processTweet(tweet.quotedTweet) : null,
      quotedStatusId: tweet.quotedStatusId,
      inReplyToStatusId: tweet.inReplyToStatusId,
      hashtags: tweet.hashtags || [],
    };
  }

  /**
   * Initializes the scraper by logging in
   * @returns {Promise<boolean>} - Whether login was successful
   */
  async initialize() {
    try {
      const username = process.env.TWITTER_USERNAME;
      const password = process.env.TWITTER_PASSWORD;

      if (!username || !password) {
        throw new Error("Twitter credentials not found. Please set TWITTER_USERNAME and TWITTER_PASSWORD in your .env file");
      }

      await this.scraper.login(username, password);
      return await this.scraper.isLoggedIn();
    } catch (error) {
      Logger.error(`Failed to initialize scraper: ${error.message}`);
      return false;
    }
  }

  /**
   * Fetches the latest tweets from a specified username
   * @param {string} username - Twitter username to fetch tweets from
   * @param {number} count - Number of tweets to fetch (default: 15)
   * @returns {Promise<Array>} - Array of processed tweets
   */
  async fetchLatestTweets(username, count = 15) {
    try {
      if (!await this.initialize()) {
        throw new Error("Failed to initialize Twitter scraper");
      }

      Logger.info(`Fetching the latest ${count} tweets from @${username}...`);
      
      const tweets = [];
      const searchResults = this.scraper.searchTweets(
        `from:${username}`,
        count,
        SearchMode.Latest
      );

      for await (const tweet of searchResults) {
        if (tweet) {
          const processedTweet = this.processTweet(tweet);
          if (processedTweet) {
            tweets.push(processedTweet);
          }
          
          // Break once we have enough tweets
          if (tweets.length >= count) {
            break;
          }
        }
      }

      Logger.success(`Successfully fetched ${tweets.length} tweets from @${username}`);
      return tweets;
    } catch (error) {
      Logger.error(`Error fetching tweets: ${error.message}`);
      throw error;
    } finally {
      // Clean up
      try {
        await this.scraper.logout();
      } catch (error) {
        Logger.warn(`Error during logout: ${error.message}`);
      }
    }
  }
}

export default SimpleTweetFetcher;