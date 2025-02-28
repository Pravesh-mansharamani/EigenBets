/**
 * A simple tweet fetcher that uses web scraping to fetch tweets
 * without requiring Twitter API access
 */

import { JSDOM } from 'jsdom';
import axios from 'axios';
import Logger from './Logger.js';

// Rate limiting to avoid IP blocks
const RATE_LIMIT_DELAY = 2000; // 2 seconds between requests

class SimpleTweetFetcher {
  constructor() {
    // Base URL for Twitter's web interface
    this.baseUrl = 'https://nitter.net'; // Using Nitter as it's more scraper-friendly
    
    // Track timestamps of last requests to implement rate limiting
    this.lastRequestTime = 0;
  }
  
  /**
   * Sleep for a specified number of milliseconds
   * @param {number} ms - Milliseconds to sleep
   * @returns {Promise} - Resolves after the specified time
   */
  async sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
  
  /**
   * Apply rate limiting to avoid getting blocked
   */
  async applyRateLimit() {
    const now = Date.now();
    const timeSinceLastRequest = now - this.lastRequestTime;
    
    if (timeSinceLastRequest < RATE_LIMIT_DELAY) {
      const delayNeeded = RATE_LIMIT_DELAY - timeSinceLastRequest;
      Logger.debug(`Rate limiting: Waiting ${delayNeeded}ms before next request`);
      await this.sleep(delayNeeded);
    }
    
    this.lastRequestTime = Date.now();
  }
  
  /**
   * Fetch HTML content from Twitter
   * @param {string} url - The URL to fetch
   * @returns {Promise<string>} - The HTML content
   */
  async fetchHtml(url) {
    await this.applyRateLimit();
    
    try {
      Logger.debug(`Fetching ${url}`);
      const response = await axios.get(url, {
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
          'Accept-Language': 'en-US,en;q=0.5'
        }
      });
      
      return response.data;
    } catch (error) {
      Logger.error(`Failed to fetch HTML from ${url}: ${error.message}`);
      throw error;
    }
  }
  
  /**
   * Parse tweets from HTML
   * @param {string} html - HTML content to parse
   * @returns {Array} - Array of tweet objects
   */
  parseTweets(html) {
    const dom = new JSDOM(html);
    const document = dom.window.document;
    const tweetElements = document.querySelectorAll('.timeline-item');
    
    const tweets = [];
    
    tweetElements.forEach((tweetElement) => {
      try {
        // Extract tweet ID
        const permalinkElement = tweetElement.querySelector('.tweet-link');
        if (!permalinkElement) return;
        
        const permalink = permalinkElement.getAttribute('href');
        const tweetId = permalink.split('/').pop();
        
        // Extract tweet content
        const contentElement = tweetElement.querySelector('.tweet-content');
        if (!contentElement) return;
        
        const tweetText = contentElement.textContent.trim();
        
        // Extract username and display name
        const userElement = tweetElement.querySelector('.username');
        const displayNameElement = tweetElement.querySelector('.fullname');
        const username = userElement ? userElement.textContent.trim() : '';
        const displayName = displayNameElement ? displayNameElement.textContent.trim() : '';
        
        // Extract timestamp
        const timestampElement = tweetElement.querySelector('.tweet-date a');
        const timestamp = timestampElement ? timestampElement.getAttribute('title') : '';
        
        // Create tweet object
        tweets.push({
          id: tweetId,
          text: tweetText,
          username,
          displayName,
          created_at: timestamp || new Date().toISOString(),
          permalink: `https://twitter.com${permalink}`
        });
      } catch (error) {
        Logger.debug(`Error parsing tweet: ${error.message}`);
      }
    });
    
    return tweets;
  }
  
  /**
   * Fetch latest tweets from a user
   * @param {string} username - Twitter username (without @)
   * @param {number} count - Number of tweets to fetch (max 20)
   * @returns {Promise<Array>} - Array of tweet objects
   */
  async fetchLatestTweets(username, count = 10) {
    try {
      // Remove @ if present
      username = username.replace('@', '');
      
      // Limit count to reasonable number
      count = Math.min(count, 20);
      
      const url = `${this.baseUrl}/${username}`;
      const html = await this.fetchHtml(url);
      
      const tweets = this.parseTweets(html);
      
      Logger.info(`Fetched ${tweets.length} tweets from @${username}`);
      
      // Return the specified number of tweets
      return tweets.slice(0, count);
    } catch (error) {
      Logger.error(`Failed to fetch tweets from @${username}: ${error.message}`);
      throw error;
    }
  }
}

export default SimpleTweetFetcher;