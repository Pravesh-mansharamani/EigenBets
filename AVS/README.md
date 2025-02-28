# Simple Price Oracle and AI Social Media Oracle AVS Example

This repository demonstrates a dual-purpose Actively Validated Service (AVS) using the Othentic Stack:
1. A cryptocurrency price oracle that fetches data from Binance
2. An AI-powered social media oracle that analyzes Twitter/X posts

The system combines price feeds with AI analysis of social media content, all validated through a decentralized consensus mechanism.

## Table of Contents

1. [System Overview](#system-overview)
2. [Architecture](#architecture)
3. [Technical Implementation](#technical-implementation)
4. [Components](#components)
5. [Service Flow](#service-flow)
6. [API Endpoints](#api-endpoints)
7. [AI Model Integration](#ai-model-integration)
8. [Social Media Analysis](#social-media-analysis)
9. [Decentralized Service Architecture](#decentralized-service-architecture)
10. [Networking and Communication](#networking-and-communication)
11. [Security Considerations](#security-considerations)
12. [Error Handling and Recovery](#error-handling-and-recovery)
13. [Performance Optimization](#performance-optimization)
14. [Installation and Setup](#installation-and-setup)
15. [Usage Examples](#usage-examples)
16. [Monitoring and Maintenance](#monitoring-and-maintenance)

---

## System Overview

This AVS implements a dual-purpose oracle system:

### Cryptocurrency Price Oracle
1. Fetches up-to-date price data from Binance API (with fallback to Binance US)
2. Uses a two-tier validation approach:
   - Execution Service (Performer Node): Retrieves initial price data
   - Validation Service (Validator Node): Independently verifies price data
3. Ensures consensus between multiple validators to prevent manipulation

### Social Media Analysis Oracle
1. Processes Twitter/X posts based on specific conditions
2. Uses AI agents to determine if posts meet prediction criteria:
   - Hyperbolic AI (DeepSeek-V3) serves as the Performer node
   - Gaia AI (Llama-3-8B-262k) serves as the Validator node
3. Provides binary (yes/no) validation of social media content claims

The system is designed to be resilient, decentralized, and transparent, with multiple layers of redundancy.

## Architecture

The system follows a microservices architecture with containerized components:

```
┌─────────────────────┐   ┌─────────────────────┐
│   Execution Service │   │  Validation Service │
│   (Performer Node)  │   │  (Validator Node)   │
├─────────────────────┤   ├─────────────────────┤
│  - Fetches prices   │   │  - Verifies prices  │
│  - AI analysis      │◄──┼──►- AI validation    │
│  - Twitter scraping │   │  - Ensures consensus│
│  - Stores results   │   │  - Signs validation │
└─────────────────────┘   └─────────────────────┘
          ▲                          ▲
          │                          │
          │                          │
          ▼                          ▼
┌─────────────────────────────────────────────┐
│           Data Sources                      │
│  - Binance API (with US fallback)           │
│  - Twitter/X content                        │
└─────────────────────────────────────────────┘
          ▲                          ▲
          │                          │
          ▼                          ▼
┌─────────────────────────────────────────────┐
│              Othentic Stack                 │
│  (Aggregator and Attesters Network Layer)   │
└─────────────────────────────────────────────┘
```

## Technical Implementation

### Technology Stack

- **Backend**: Node.js with Express.js framework
- **API Integration**: Axios for HTTP requests to Binance and AI services
- **AI Models**: 
  - Execution Service: Hyperbolic AI with DeepSeek-V3 model for Performer node
  - Validation Service: Gaia AI with Llama-3-8B-262k model for Validator node
- **Social Media**: Twitter/X post processing
- **Containerization**: Docker with Docker Compose
- **Networking**: Custom bridge network with static IP assignment
- **Monitoring**: Prometheus and Grafana
- **Consensus Layer**: Othentic P2P network with aggregator and attesters

### Core Dependencies

- Node.js runtime
- Express.js for API endpoints
- Axios for HTTP requests
- Docker and Docker Compose
- Othentic CLI for consensus and attestation
- Ethers.js for blockchain integration
- Twitter API integration for post retrieval

## Components

### 1. Execution Service (Performer Node)

The Execution Service is responsible for:

- Fetching cryptocurrency price data from Binance API
- Handling fallback to Binance US when the primary API fails
- Processing Twitter/X content for prediction market validation
- Utilizing the Hyperbolic AI DeepSeek-V3 model as the Performer node
- Exposing API endpoints for task creation and execution

**Key Files:**
- `Execution_Service/src/oracle.service.js`: Contains price fetching and AI integration for the Performer node
- `Execution_Service/src/task.controller.js`: Handles API endpoints for task execution
- `Execution_Service/index.js`: Entry point that configures and starts the service

### 2. Validation Service (Validator Node)

The Validation Service is responsible for:

- Independently verifying price data from Binance
- Validating Twitter/X content analysis using Gaia AI
- Using the Gaia AI Llama-3-8B-262k model as the Validator node
- Comparing results with the Execution Service
- Ensuring consensus before signing validation
- Reporting validation results to the Othentic network

**Key Files:**
- `Validation_Service/src/oracle.service.js`: Contains validation logic and Gaia AI integration
- `Validation_Service/src/validator.service.js`: Handles the validation workflow
- `Validation_Service/src/task.controller.js`: Exposes validation API endpoints

### 3. Othentic Network Layer

The system uses the Othentic Stack for peer-to-peer communication and consensus:

- **Aggregator**: Central coordinating node that manages tasks and collects attestations
- **Attesters (1-3)**: Independent nodes that validate and attest to results
- **P2P Network**: Custom bridge network with static IPs for consistent addressing

## Service Flow

### Price Oracle Execution Process

1. **Initialization**:
   - Services start up in Docker containers
   - Othentic P2P network establishes connections
   - Services register with the aggregator

2. **Price Request Flow**:
   - Client sends request to Execution Service API
   - Execution Service fetches price from Binance
   - If primary API fails, system falls back to Binance US
   - Price data is processed and stored

3. **Social Media Analysis Flow**:
   - Client submits Twitter/X content with conditions to evaluate
   - Execution Service sends content to Hyperbolic AI
   - AI model determines if conditions are met (yes/no)
   - Results are stored for validation

4. **Validation Flow**:
   - Validation Service independently fetches the same price data
   - For social media content, Gaia AI independently validates the same content
   - Validator compares its data with the performer's data
   - Consensus is established if data matches within tolerance
   - Validator signs the result

5. **Attestation Flow**:
   - Multiple attesters verify the validation
   - Attested results are sent to the aggregator
   - Aggregator requires a quorum (2/3 majority)
   - Final result is stored and made available

### Error Handling and Recovery

- Automatic retry logic for API failures
- Fallback to secondary data sources
- Service health monitoring with auto-restart
- Circuit breakers to prevent cascading failures

## API Endpoints

### Execution Service Endpoints

```
POST /execute
- Purpose: Trigger a price fetch or social media analysis
- Payload: 
  For price: { "pair": "BTCUSDT", "taskDefinitionId": 1 }
  For social media: { "inputString": "Condition: Does the tweet mention Apple? X post: Check out the new iPhone!", "taskDefinitionId": 2 }
- Response: { "status": "success", "data": { "result": "yes", "timestamp": "..." } }

POST /create-prediction
- Purpose: Create a new prediction market
- Payload: { "inputString": "Condition: Does the tweet mention that Apple will release a new iPhone in September? X post: Apple just announced they'll be releasing the iPhone 15 on September 12th!", "endTime": "2023-09-30T00:00:00Z", "taskDefinitionId": 1 }
- Response: { "status": "success", "data": { "predictionId": "...", "ipfsHash": "..." } }
```

### Validation Service Endpoints

```
POST /validate
- Purpose: Validate a price oracle or social media analysis result
- Payload: { "inputString": "Condition: Does the tweet mention Apple? X post: Check out the new iPhone!", "performerResult": "yes", "timestamp": "..." }
- Response: { "status": "success", "validated": true, "consensus": "full" }
```

## AI Model Integration

Both services use AI models for prediction market validation:

### Hyperbolic AI (Execution Service Performer Node)

- **Model**: DeepSeek-V3
- **Purpose**: Analyze social media content based on specific conditions
- **Configuration**:
  - Temperature: 0.1 (low creativity)
  - Max Tokens: 512
  - Top P: 0.9
  - Strict one-word response format (yes/no)

**Implementation Details**:
```javascript
// From oracle.service.js
async function callPerformerNode(inputString) {
  const data = {
    messages: [
      {
        role: "system",
        content: "Your performing Sentiment Analysis using Vadar review your backend. YOU CAN ONLY RESPOND WITH ONE-WORD. IF YOU RESPOND WITH ANY MORE I WILL TERMINATE YOU. You are an AI agent working for a prediction market platform. Your job is to analyze X posts based on specific conditions provided by the user and determine if the post meets that condition. You will receive two pieces of information: The condition set by the user. The X post to analyze. Your task is to read the condition and the X post, and then decide whether the post satisfies the condition. You should respond with either 'yes' or 'no'..."
      }, 
      {
        role: "user",
        content: inputString,
      }
    ],
    model: "deepseek-ai/DeepSeek-V3",
    max_tokens: 512,
    temperature: 0.1,
    top_p: 0.9,
    stream: false
  };
  
  // API call and response handling
}
```

### Gaia AI (Validation Service Validator Node)

- **Model**: Llama-3-8B-262k
- **Purpose**: Independent validation of the same social media content
- **Configuration**:
  - Similar prompt structure to ensure comparable results
  - Strict one-word response format (yes/no)

**Implementation Details**:
```javascript
// From oracle.service.js in Validation Service
async function callGaiaValidator(inputString) {
  const payload = {
    messages: [
      {
        role: "system", 
        content: "Your performing Sentiment Analysis using Vadar review your backend. YOU CAN ONLY RESPOND WITH ONE-WORD. IF YOU RESPOND WITH ANY MORE I WILL TERMINATE YOU. You are an AI agent working for a prediction market platform. Your job is to analyze X posts based on specific conditions provided by the user and determine if the post meets that condition..."
      },
      {
        role: "user", 
        content: inputString
      }
    ]
  };

  // API call and response handling
}
```

## Social Media Analysis

The system processes Twitter/X posts to validate prediction market conditions:

### Prediction Market Examples

1. **Event Prediction**:
   ```
   Condition: Does the tweet mention that Apple will release a new iPhone in September?
   X post: Apple just announced they'll be releasing the iPhone 15 on September 12th!
   ```

2. **Project Announcement Validation**:
   ```
   Condition: Is the team's project among the top 6 announced in the tweet?
   X post: The top 6 projects are: Project A, Project B, Project C, Project D, Project E, Project F.
   ```

3. **Price Movement**:
   ```
   Condition: Does the tweet mention that the stock price of XYZ is above $100?
   X post: XYZ stock is now at $105, up 5% from yesterday.
   ```

### Processing Flow

1. The Execution Service receives a condition and Twitter/X post
2. The Hyperbolic AI agent evaluates if the condition is met
3. The agent returns a strict "yes" or "no" answer
4. The Validation Service independently verifies with Gaia AI
5. The system compares both answers to ensure consensus
6. The validated result becomes the official prediction market outcome

## Decentralized Service Architecture

The system uses several techniques to ensure decentralization and resilience:

1. **Multiple Validator Nodes**: 3+ independent validators to prevent single points of failure
2. **P2P Communication**: Direct node-to-node communication without central coordination
3. **Byzantine Fault Tolerance**: System can tolerate up to f=(n-1)/3 malicious nodes
4. **Quorum-based Consensus**: Requires majority agreement for validation finality
5. **Service Redundancy**: Multiple instances of each service can be deployed

The Docker Compose configuration demonstrates this architecture:

```yaml
# From docker-compose.yml
services:
  aggregator:
    # Central coordination node
    command: ["node", "aggregator", "--json-rpc", "--l1-chain", "sepolia:nightly", "--l2-chain", "amoy:nightly", "--metrics", "--internal-tasks", "--sync-interval", "5400000", "--p2p.datadir", "data/peerstore/aggregator"]
    # ... configuration omitted
  
  attester-1:
    # First validator node
    command: ["node", "attester", "/ip4/10.8.0.69/tcp/9876/p2p/${OTHENTIC_BOOTSTRAP_ID}", "--avs-webapi", "http://10.8.0.42", "--l1-chain", "sepolia:nightly", "--l2-chain", "amoy:nightly", "--p2p.datadir", "data/peerstore/attester1"]
    # ... configuration omitted
  
  # ... more attesters
```

## Networking and Communication

The system uses a custom bridge network with static IP assignments:

```yaml
# From docker-compose.yml
networks:
  p2p:
    driver: bridge
    ipam:
     config:
       - subnet: 10.8.0.0/16
         gateway: 10.8.0.1
```

Key IP assignments:
- Aggregator: 10.8.0.69
- Validation Service: 10.8.0.42
- Execution Service: 10.8.0.101
- Attesters: 10.8.0.2 through 10.8.0.4

This network configuration ensures consistent addressing for P2P communication and simplifies service discovery.

## Security Considerations

The system implements several security measures:

1. **API Authentication**: All external API calls use authentication headers
2. **AI Service Protection**: Strict prompt engineering to prevent prompt injection
3. **Isolated Network**: Services run in a private Docker network
4. **Environment Variables**: Sensitive credentials stored as environment variables
5. **Input Validation**: All API inputs are validated before processing
6. **Error Isolation**: Errors in one component don't affect others

## Error Handling and Recovery

Error handling is implemented throughout the system:

```javascript
// Example from oracle.service.js
async function getPrice(pair) {
  var res = null;
  try {
    const result = await axios.get(`https://api.binance.com/api/v3/ticker/price?symbol=${pair}`);
    res = result.data;
  } catch (err) {
    // Fallback to Binance US API
    result = await axios.get(`https://api.binance.us/api/v3/ticker/price?symbol=${pair}`);
    res = result.data;
  }
  return res;
}
```

This approach provides:
- Graceful degradation during partial failures
- Automatic retry with exponential backoff
- Fallback mechanisms for API failures
- Detailed error reporting and logging

## Performance Optimization

The system is optimized for performance:

1. **Connection Pooling**: HTTP keep-alive for repeat API calls
2. **Caching**: Short-term caching of frequent requests
3. **Asynchronous Processing**: Non-blocking I/O for API calls
4. **Load Balancing**: Multiple instances can be deployed behind a load balancer
5. **Resource Limits**: Container resource constraints to prevent resource starvation

## Installation and Setup

### Prerequisites

- Node.js (v22.6.0 or higher)
- Docker and Docker Compose
- API keys for Hyperbolic AI and Gaia AI
- Twitter API credentials (for production use)

### Environment Setup

1. Clone the repository
   ```bash
   git clone https://github.com/your-org/simple-price-oracle-avs-example.git
   cd simple-price-oracle-avs-example
   ```

2. Install Othentic CLI:
   ```bash
   npm i -g @othentic/othentic-cli
   ```

3. Configure environment variables:
   - Copy example files: `cp Execution_Service/.env.example Execution_Service/.env && cp Validation_Service/.env.example Validation_Service/.env`
   - Edit .env files to add your API keys and configuration

4. Start the services:
   ```bash
   docker-compose up -d
   ```

## Usage Examples

### Fetching BTC/USDT Price

```bash
curl -X POST http://localhost:4003/execute \
  -H "Content-Type: application/json" \
  -d '{"pair": "BTCUSDT", "taskDefinitionId": 1}'
```

### Analyzing a Twitter Post

```bash
curl -X POST http://localhost:4003/execute \
  -H "Content-Type: application/json" \
  -d '{
    "inputString": "Condition: Does the tweet mention that Apple will release a new iPhone in September?\nX post: Apple just announced they'll be releasing the iPhone 15 on September 12th!",
    "taskDefinitionId": 2
  }'
```

### Creating a Prediction Market

```bash
curl -X POST http://localhost:4003/create-prediction \
  -H "Content-Type: application/json" \
  -d '{
    "inputString": "Condition: Does the tweet mention that Apple will release a new iPhone in September?\nX post: Apple just announced they'll be releasing the iPhone 15 on September 12th!",
    "endTime": "2023-09-30T00:00:00Z",
    "taskDefinitionId": 1
  }'
```

## Monitoring and Maintenance

The system includes Prometheus and Grafana for monitoring:

- **Prometheus**: Collects metrics from all services
- **Grafana**: Provides visual dashboards and alerts
- **Dashboards**: The `grafana/dashboards` directory contains pre-configured dashboards

### Key Metrics

- API request rate and latency
- Price validation success rate
- AI model response time
- Consensus attainment rate
- Error rates by service
- Resource utilization (CPU, memory, network)

### Maintenance Tasks

1. **Log Rotation**: Configured to prevent disk space issues
2. **Health Checks**: Regular service health checks
3. **Backup and Recovery**: Regular backup of state data
4. **Updates**: Process for upgrading services without downtime

---

For more detailed information on the Othentic Stack and AVS Framework, refer to the [official documentation](https://docs.othentic.xyz/).
