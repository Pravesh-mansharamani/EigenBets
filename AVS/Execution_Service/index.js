"use strict";
require('dotenv').config();
const app = require("./configs/app.config");
const PORT = process.env.port || process.env.PORT || 4003;
const dalService = require("./src/dal.service");
const schedulerService = require("./src/services/scheduler.service");
const twitterService = require("./src/services/twitter.service");

// Initialize all services
async function initializeServices() {
  try {
    // Initialize DAL service (data access layer)
    dalService.init();
    
    // Initialize Twitter service
    twitterService.init();
    
    // Initialize scheduler service (after other services are ready)
    schedulerService.init();
    
    // Start the server
    app.listen(PORT, () => {
      console.log("Server started on port:", PORT);
      console.log("Execution Service is running and ready to process prediction markets");
    });
  } catch (error) {
    console.error("Failed to initialize services:", error);
    process.exit(1);
  }
}

// Start the application
initializeServices();