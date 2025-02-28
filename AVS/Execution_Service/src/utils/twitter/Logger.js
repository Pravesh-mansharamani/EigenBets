/**
 * Logger - A simple, colorful logging utility for Node.js applications
 * 
 * Features:
 * - Colorful console output based on log level
 * - Timestamp prefixing
 * - Support for different log levels (info, success, warn, error, debug)
 * - Optional file logging
 */

// ANSI color codes for terminal output
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
  white: '\x1b[37m',
  
  // Background colors
  bgBlack: '\x1b[40m',
  bgRed: '\x1b[41m',
  bgGreen: '\x1b[42m',
  bgYellow: '\x1b[43m',
  bgBlue: '\x1b[44m',
  bgMagenta: '\x1b[45m',
  bgCyan: '\x1b[46m',
  bgWhite: '\x1b[47m'
};

class Logger {
  constructor() {
    // Set default config
    this.config = {
      useColors: true,
      showTimestamp: true,
      logLevel: 'info', // 'debug', 'info', 'success', 'warn', 'error', or 'none'
      logToFile: false,
      logFilePath: './application.log'
    };
    
    // Log level hierarchy
    this.logLevels = {
      debug: 0,
      info: 1,
      success: 2,
      warn: 3,
      error: 4,
      none: 5
    };
  }
  
  /**
   * Configure logger settings
   * @param {Object} options - Configuration options
   */
  configure(options = {}) {
    this.config = { ...this.config, ...options };
    return this;
  }
  
  /**
   * Get formatted timestamp
   * @returns {string} Formatted timestamp [HH:MM:SS]
   */
  getTimestamp() {
    const now = new Date();
    const hours = String(now.getHours()).padStart(2, '0');
    const minutes = String(now.getMinutes()).padStart(2, '0');
    const seconds = String(now.getSeconds()).padStart(2, '0');
    return `[${hours}:${minutes}:${seconds}]`;
  }
  
  /**
   * Format a log message with appropriate styling
   * @param {string} message - The message to log
   * @param {string} level - Log level
   * @param {string} levelColor - ANSI color code for the level
   * @returns {string} Formatted log message
   */
  formatMessage(message, level, levelColor) {
    const timestamp = this.config.showTimestamp ? `${colors.dim}${this.getTimestamp()} ` : '';
    const levelFormatted = this.config.useColors 
      ? `${levelColor}${level.toUpperCase()}${colors.reset}` 
      : level.toUpperCase();
    
    return `${timestamp}${levelFormatted}: ${message}${colors.reset}`;
  }
  
  /**
   * Check if a log level should be output based on configured level
   * @param {string} level - The log level to check
   * @returns {boolean} Whether the message should be logged
   */
  shouldLog(level) {
    return this.logLevels[level] >= this.logLevels[this.config.logLevel];
  }
  
  /**
   * Log an info message (blue)
   * @param {string} message - Message to log
   */
  info(message) {
    if (!this.shouldLog('info')) return;
    console.log(this.formatMessage(message, 'info', colors.blue));
  }
  
  /**
   * Log a success message (green)
   * @param {string} message - Message to log
   */
  success(message) {
    if (!this.shouldLog('success')) return;
    console.log(this.formatMessage(message, 'success', colors.green));
  }
  
  /**
   * Log a warning message (yellow)
   * @param {string} message - Message to log
   */
  warn(message) {
    if (!this.shouldLog('warn')) return;
    console.log(this.formatMessage(message, 'warn', colors.yellow));
  }
  
  /**
   * Log an error message (red)
   * @param {string} message - Message to log
   */
  error(message) {
    if (!this.shouldLog('error')) return;
    console.error(this.formatMessage(message, 'error', colors.red));
  }
  
  /**
   * Log a debug message (magenta)
   * @param {string} message - Message to log
   */
  debug(message) {
    if (!this.shouldLog('debug')) return;
    console.log(this.formatMessage(message, 'debug', colors.magenta));
  }
  
  /**
   * Create a section header
   * @param {string} title - Section title
   */
  section(title) {
    if (!this.shouldLog('info')) return;
    const line = '─'.repeat(title.length + 4);
    console.log(`\n${colors.cyan}┌${line}┐`);
    console.log(`│  ${colors.bright}${title}${colors.reset}${colors.cyan}  │`);
    console.log(`└${line}┘${colors.reset}\n`);
  }
}

// Export a singleton instance
const logger = new Logger();
export default logger;