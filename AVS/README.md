# AI-Powered Prediction Market Oracle AVS

This repository demonstrates how to implement an AI-powered prediction market oracle AVS using the Othentic Stack. The system uses AI agents to validate prediction market outcomes based on social media content.

---

## Table of Contents

1. [Overview](#overview)
2. [Project Structure](#project-structure)
3. [Architecture](#architecture)
4. [Prerequisites](#prerequisites)
5. [Installation](#installation)
6. [Usage](#usage)

---

## Overview

This AVS implements an AI-powered oracle system for prediction markets. It enables the creation and validation of prediction markets based on social media content (specifically X/Twitter posts), with AI agents determining outcomes.

### Features

- **AI Agent Integration:** Uses Hyperbolic AI for execution and Gaia AI for validation
- **Prediction Market Support:** Create markets with conditions based on social media content
- **Containerised deployment:** Simplifies deployment and scaling
- **Prometheus and Grafana integration:** Enables real-time monitoring and observability

## Project Structure

```mdx
📂 ai-prediction-market-avs
├── 📂 Execution_Service         # Implements Task execution logic - Express JS Backend
│   ├── 📂 config/
│   │   └── app.config.js        # An Express.js app setup with dotenv, and a task controller route for handling `/task` endpoints
│   ├── 📂 src/
│   │   └── dal.service.js       # A module that interacts with Pinata for IPFS uploads
│   │   ├── oracle.service.js    # Service that calls Hyperbolic AI agent to determine prediction outcomes
│   │   ├── task.controller.js   # Express.js router handling `/execute` and `/create-prediction` endpoints
│   │   ├── 📂 utils             # Defines custom classes for standardizing API responses
│   ├── Dockerfile               # A Dockerfile that sets up a Node.js environment and runs the application
|   ├── index.js                 # Server entry point that initializes services and starts the server
│   └── package.json             # Node.js dependencies and scripts
│
├── 📂 Validation_Service         # Implements task validation logic - Express JS Backend
│   ├── 📂 config/
│   │   └── app.config.js         # An Express.js app setup for handling validation endpoints
│   ├── 📂 src/
│   │   └── dal.service.js        # A module that retrieves task data from IPFS
│   │   ├── oracle.service.js     # Service that calls Gaia AI agent to validate prediction outcomes
│   │   ├── task.controller.js    # Express.js router handling `/validate` POST endpoint
│   │   ├── validator.service.js  # Validation module that compares performer and validator AI results
│   │   ├── 📂 utils              # Defines custom classes for standardizing API responses
│   ├── Dockerfile                # A Dockerfile that sets up a Node.js environment and runs the application
|   ├── index.js                  # Server entry point that initializes services and starts the server
│   └── package.json              # Node.js dependencies and scripts
│
├── 📂 grafana                    # Grafana monitoring configuration
├── docker-compose.yml            # Docker setup for services and monitoring tools
├── .env.example                  # An example .env file containing configuration details
├── README.md                     # Project documentation
└── prometheus.yaml               # Prometheus configuration for logs
```

## Architecture

The system consists of two main components:

### Execution Service
- **Performer Node:** Uses the Hyperbolic AI agent to analyze social media content and determine prediction outcomes
- Creates prediction markets with specific conditions
- Executes validations when the market end time is reached
- Stores results on IPFS

### Validation Service
- **Validator Node:** Uses the Gaia AI agent to independently validate the same content
- Compares Performer and Validator results to ensure consensus
- Approved results are signed and validated on-chain

## AI Agent Integration

Both services use specialized AI agents:

1. **Hyperbolic AI (Performer):** 
   - Analyzes social media content based on specific conditions
   - Determines if conditions are met with yes/no answers
   - Acts as the primary performer node

2. **Gaia AI (Validator):**
   - Independently validates the same content with the same prompt
   - Provides a second opinion to ensure consensus
   - Uses Llama-3-8B-262k model for determinations

## Prediction Market Flow

1. Create a prediction market with a specific condition
2. The prediction is stored in IPFS and added to the prediction registry
3. When the market end time is reached, the scheduler:
   - Retrieves relevant social media content via the Twitter scraper
   - Sends content to the Performer AI for analysis
   - Stores the result on IPFS
   - Updates the prediction status in the registry
4. The Validator service:
   - Retrieves the data from IPFS
   - Independently validates using the Validator AI
   - Compares results to ensure consensus
   - Reports validation results

## Decentralized Storage

The system uses IPFS through Pinata for all data storage:

1. **Individual predictions** are stored directly on IPFS
2. **Prediction registry** maintains the list of all predictions with their status
3. **Results** are stored on IPFS when predictions are executed
4. **No central database** is used, keeping the system decentralized

---

## Prerequisites

- Node.js (v 22.6.0 )
- Foundry
- [Yarn](https://yarnpkg.com/)
- [Docker](https://docs.docker.com/engine/install/)
- API keys for Hyperbolic AI and Gaia AI (configured in .env files)

## Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/Othentic-Labs/ai-prediction-market-avs.git
   cd ai-prediction-market-avs
   ```

2. Install Othentic CLI:

   ```bash
   npm i -g @othentic/othentic-cli
   ```

3. Configure environment variables:
   - Copy .env.example to .env in both Execution_Service and Validation_Service directories
   - Add your Hyperbolic API key and other required credentials

## Usage

### Creating a Prediction Market

Send a POST request to `/create-prediction` with:

```json
{
  "inputString": "Condition: Does the tweet mention that Apple will release a new iPhone in September?\nX post: Apple just announced they'll be releasing the iPhone 15 on September 12th!",
  "endTime": "2023-09-30T00:00:00Z",
  "taskDefinitionId": 1
}
```

### Executing Validation

Send a POST request to `/execute` with:

```json
{
  "inputString": "Condition: Does the tweet mention that Apple will release a new iPhone in September?\nX post: Apple just announced they'll be releasing the iPhone 15 on September 12th!",
  "taskDefinitionId": 1
}
```

### Validating Results

The validation happens automatically when the validator node receives the task.

---

For detailed setup and deployment instructions, follow the official documentation's [Quickstart](https://docs.othentic.xyz/main/avs-framework/quick-start#steps) Guide.

Happy Building! 🚀

