/**
 * This file adapts ES modules for CommonJS usage
 */

const { JSDOM } = require('jsdom');
const axios = require('axios');

// Create CommonJS compatible logger
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  dim: '\x1b[2m',
  underscore: '\x1b[4m',
  blink: '\x1b[5m',
  reverse: '\x1b[7m',
  hidden: '\x1b[8m',
  
  // Foreground colors
  black: '\x1b[30m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  magenta: '\x1b[35m',
  cyan: '\x1b[36m',
  white: '\x1b[37m'
};

class Logger {
  constructor() {
    this.config = {
      useColors: true,
      showTimestamp: true,
      logLevel: 'info'
    };
    
    this.logLevels = {
      debug: 0,
      info: 1,
      success: 2,
      warn: 3,
      error: 4,
      none: 5
    };
  }
  
  getTimestamp() {
    const now = new Date();
    const hours = String(now.getHours()).padStart(2, '0');
    const minutes = String(now.getMinutes()).padStart(2, '0');
    const seconds = String(now.getSeconds()).padStart(2, '0');
    return `[${hours}:${minutes}:${seconds}]`;
  }
  
  formatMessage(message, level, levelColor) {
    const timestamp = this.config.showTimestamp ? `${colors.dim}${this.getTimestamp()} ` : '';
    const levelFormatted = this.config.useColors 
      ? `${levelColor}${level.toUpperCase()}${colors.reset}` 
      : level.toUpperCase();
    
    return `${timestamp}${levelFormatted}: ${message}${colors.reset}`;
  }
  
  shouldLog(level) {
    return this.logLevels[level] >= this.logLevels[this.config.logLevel];
  }
  
  info(message) {
    if (!this.shouldLog('info')) return;
    console.log(this.formatMessage(message, 'info', colors.blue));
  }
  
  success(message) {
    if (!this.shouldLog('success')) return;
    console.log(this.formatMessage(message, 'success', colors.green));
  }
  
  warn(message) {
    if (!this.shouldLog('warn')) return;
    console.log(this.formatMessage(message, 'warn', colors.yellow));
  }
  
  error(message) {
    if (!this.shouldLog('error')) return;
    console.error(this.formatMessage(message, 'error', colors.red));
  }
  
  debug(message) {
    if (!this.shouldLog('debug')) return;
    console.log(this.formatMessage(message, 'debug', colors.magenta));
  }
}

// Create a singleton logger instance
const logger = new Logger();

// Implement the tweet fetcher in CommonJS
const RATE_LIMIT_DELAY = 2000;

class SimpleTweetFetcher {
  constructor() {
    this.baseUrl = 'https://nitter.net';
    this.lastRequestTime = 0;
  }
  
  async sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
  
  async applyRateLimit() {
    const now = Date.now();
    const timeSinceLastRequest = now - this.lastRequestTime;
    
    if (timeSinceLastRequest < RATE_LIMIT_DELAY) {
      const delayNeeded = RATE_LIMIT_DELAY - timeSinceLastRequest;
      logger.debug(`Rate limiting: Waiting ${delayNeeded}ms before next request`);
      await this.sleep(delayNeeded);
    }
    
    this.lastRequestTime = Date.now();
  }
  
  async fetchHtml(url) {
    await this.applyRateLimit();
    
    try {
      logger.debug(`Fetching ${url}`);
      const response = await axios.get(url, {
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
          'Accept-Language': 'en-US,en;q=0.5'
        }
      });
      
      return response.data;
    } catch (error) {
      logger.error(`Failed to fetch HTML from ${url}: ${error.message}`);
      throw error;
    }
  }
  
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
        logger.debug(`Error parsing tweet: ${error.message}`);
      }
    });
    
    return tweets;
  }
  
  async fetchLatestTweets(username, count = 10) {
    try {
      // Remove @ if present
      username = username.replace('@', '');
      
      // Limit count to reasonable number
      count = Math.min(count, 20);
      
      const url = `${this.baseUrl}/${username}`;
      const html = await this.fetchHtml(url);
      
      const tweets = this.parseTweets(html);
      
      logger.info(`Fetched ${tweets.length} tweets from @${username}`);
      
      // Return the specified number of tweets
      return tweets.slice(0, count);
    } catch (error) {
      logger.error(`Failed to fetch tweets from @${username}: ${error.message}`);
      throw error;
    }
  }
}

// Export CommonJS modules
module.exports = {
  default: SimpleTweetFetcher,
  SimpleTweetFetcher,
  Logger: logger
};