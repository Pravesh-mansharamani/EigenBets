# EigenBets: AI-Powered Prediction Markets

This project implements a decentralized prediction market platform with three core components:

1. **Smart Contracts (Uniswap v4 Hooks)**: A prediction market implementation enabling users to bet on binary outcomes (YES/NO) for events using USDC as the base currency. The market leverages an Automated Market Maker (AMM) with custom logic for swaps, liquidity management, and outcome resolution.

2. **Automated Verification System (AVS)**: A dual-purpose oracle service that provides cryptocurrency price data and social media sentiment analysis through AI agents, with robust validation mechanisms.

3. **Cross-Platform Frontend**: A Flutter-based mobile and web application that provides an intuitive interface for interacting with prediction markets, managing wallets, and viewing market data.

- **Deployed Hook Address**: [0xd35eef48a8b2efe557390845ce0d94d91a378ac0](https://sepolia.basescan.org/address/0xd35eef48a8b2efe557390845ce0d94d91a378ac0)

---

## Overview

The `PredictionMarketHook` contract allows users to:
- Bet on YES or NO outcomes by swapping USDC for custom YES/NO tokens.
- Add or remove liquidity to YES-USDC and NO-USDC pools.
- Claim winnings in USDC after the market resolves.

Two AI agents—one built using **Gaia** and the other using **Hyperbolic**—scrape Twitter data and perform sentiment analysis on tweets to predict a deterministic outcome (YES or NO). These predictions are verified through an **Automated Verification System (AVS)**, ensuring the outcome is accurate and presented in a verifiable form.

---

## Key Functions

- **`openMarket()`**: Opens the market for betting, callable only by the owner.
- **`closeMarket()`**: Closes the market, stopping further bets, callable only by the owner.
- **`resolveOutcome(bool _outcomeIsYes)`**: Resolves the market with the final outcome (YES/NO), callable only by the owner.
- **`swap(address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOutMinimum)`**: Swaps tokens (e.g., USDC to YES/NO or YES to NO) with slippage protection.
- **`initializePools()`**: Sets up YES-USDC and NO-USDC pools with initial liquidity, callable only by the owner.
- **`addLiquidity(PoolKey memory key, uint256 usdcAmount, uint256 tokenAmount)`**: Internal function to add liquidity to a specified pool during initialization or swaps.
- **`claim()`**: Allows users to claim USDC winnings based on their winning token holdings after resolution.
- **`getOdds()`**: Returns the current odds (as percentages) for YES and NO outcomes based on pool balances.
- **`getTokenPrices()`**: Returns the current prices of YES and NO tokens derived from pool ratios.
- **`resetMarket()`**: Resets the market for a new prediction round after resolution, callable only by the owner.

---

## AI Agents and Verification

The prediction market integrates two AI agents to determine outcomes:
- **Gaia Agent**: Scrapes Twitter data and runs sentiment analysis on tweets to predict the event outcome (YES/NO) using the Llama-3-8B-262k model. Acts as the Attestor node in our use-case.
- **Hyperbolic Agent**: Independently scrapes Twitter data and performs sentiment analysis for outcome prediction using the DeepSeek-V3 model. Acts as the performer node in our use-case.

Both agents analyze the sentiment of tweets related to the event (positive/negative) to reach a deterministic outcome. Their predictions are then verified by an **AVS (Automated Verification System)**, which cross-checks the results for consistency and accuracy. The verified outcome is presented in a transparent, verifiable format for market resolution.

---

## Automated Verification System (AVS)

The AVS component serves as a critical infrastructure element that ensures reliable oracle services for the prediction market system:

### Core Functionality
- **Cryptocurrency Price Oracle**: Fetches real-time cryptocurrency price data from Binance (with Binance US as fallback) to resolve markets based on price movements.
- **Social Media Analysis Oracle**: Uses AI to analyze Twitter/X posts to determine sentiment and specific content patterns for resolving prediction markets.
- **Data Persistence**: Stores all validation data on IPFS via Pinata for permanent, decentralized record-keeping.
- **Blockchain Integration**: Communicates with EigenLayer for AVS registration and verification.

### Architecture
- **Execution Service (Performer Node)**: 
  - Retrieves and processes initial data using the DeepSeek-V3 AI model
  - Implements prompt engineering to analyze social media content
  - Maintains a REST API for market creation and verification requests
  - Containerized with Docker for consistent deployment

- **Validation Service (Validator Node)**: 
  - Independently verifies data using the Llama-3-8B-262k AI model
  - Uses different AI models than the Execution Service to prevent collusion
  - Implements strict validation rules to ensure prediction accuracy
  - Runs as a separate microservice with its own API endpoints

- **Othentic Network Layer**: 
  - Aggregator node (10.8.0.69) coordinates the validation process
  - Multiple attester nodes (10.8.0.2 through 10.8.0.4) provide consensus
  - Custom bridge network ensures secure communication between components
  - Prometheus and Grafana monitoring for system health tracking

### Service Flow
1. Client submits a request to verify a price or analyze social media content or automatically verifies upon market close
2. Execution Service fetches data from sources (Binance or Twitter scraper)
3. AI model processes the data with specific prompts to ensure accurate analysis
4. Results are published to IPFS with a unique Content Identifier (CID)
5. Task is submitted to the Othentic network for verification
6. Validation Service independently fetches and analyzes the same data
7. Multiple attesters verify the results and sign the validation if consensus is reached
8. Final validated result is returned to the smart contract for market resolution
9. Verification status is made available through an API for frontend display

### Security Measures
- Dual AI validation prevents manipulation by requiring consensus
- IPFS storage ensures immutable record-keeping of all validation steps
- API authentication protects against unauthorized access
- Isolated Docker network prevents external tampering
- Input validation guards against injection attacks

The AVS ensures that EigenBets prediction markets are resolved based on accurate, verifiable, and tamper-resistant data, creating trust in the prediction market ecosystem.

---

## Flutter Frontend

The cross-platform frontend provides an intuitive interface for interacting with the EigenBets prediction markets:

### Key Features
- **Market Browsing**: Interactive dashboard to view available prediction markets with real-time odds and market details.
- **Betting Interface**: User-friendly interface for placing YES/NO bets on outcomes with customizable bet amounts.
- **Wallet Integration**: Seamless connection with multiple wallet options:
  - MetaMask for browser extension integration
  - WalletConnect for mobile wallet compatibility
  - Coinbase Wallet for direct Coinbase integration
- **Transaction History**: Comprehensive record of betting history, pending transactions, and winnings claims.
- **Market Creation**: Advanced interface for creating new prediction markets (admin users only).
- **Verification Status**: Real-time visual indicators showing AVS verification progress and status.
- **Live Data Feeds**: Integration with Twitter feeds related to the prediction market topics.
- **Sentiment Analysis Widget**: Visual representation of current sentiment analysis from AI agents.

### Technical Implementation
- **Framework**: Built with Flutter 3.19+ for true cross-platform compatibility (iOS, Android, Web).
- **Architecture**: Follows a clean architecture with separation of concerns:
  - Data models for structured information representation
  - Services for external API and blockchain interactions
  - Screens and widgets for UI presentation
- **Responsive Design**: Adaptive layouts that automatically adjust to different screen sizes:
  - Side rail navigation on desktop/tablet
  - Bottom navigation on mobile devices
  - Responsive grid layouts for market cards
- **Web3 Connectivity**: 
  - Custom JavaScript bridge for web platform
  - Native SDKs integration for mobile platforms
  - Support for multiple EVM networks (Base, Ethereum, Polygon)
- **AVS Integration**: Dedicated service classes to communicate with AVS APIs:
  - Real-time verification status updates
  - Market resolution monitoring
  - Outcome display for resolved markets
- **State Management**: Efficient state handling with Provider pattern for reactive UI updates.
- **Asset Management**: Optimized assets for different platforms and screen densities.

### Screens
- **Landing Page**: Introduction to EigenBets with wallet connection prompts
- **Dashboard**: Personalized view of active bets and relevant markets
- **Markets**: Filterable list of all available prediction markets
- **Betting Screen**: Detailed view for placing and managing bets on a specific market
- **Wallet Screen**: Comprehensive wallet management with balance display and transaction history
- **Create Market**: Form-based interface for creating new markets (admin only)

The frontend connects to both the smart contract infrastructure and the AVS component, providing a seamless user experience for participating in prediction markets across all platforms.

---

## Application Flow

The lifecycle of the prediction market follows these steps:

1. **Market Setup**:
   - The owner deploys the hook and calls `initializePools()` to create YES-USDC and NO-USDC pools with initial liquidity (50,000 USDC and 50,000 YES/NO tokens each).

2. **Betting Phase**:
   - The owner calls `openMarket()` to allow betting.
   - Users swap USDC for YES or NO tokens via `swap()` to place bets or trade between tokens.
   - Liquidity providers can indirectly add liquidity through swaps, tracked by the hook.

3. **Market Closure**:
   - The owner calls `closeMarket()` to stop betting and prepare for resolution.

4. **Outcome Resolution**:
   - The Gaia and Hyperbolic AI agents scrape Twitter and analyze sentiment to predict the outcome.
   - The AVS verifies the predictions, ensuring consensus.
   - The owner calls `resolveOutcome()` with the verified outcome, withdrawing liquidity and collecting USDC for distribution.

5. **Claiming Winnings**:
   - Users holding the winning token (YES or NO) call `claim()` to receive their proportional share of the USDC pool.
   - The market can be reset with `resetMarket()` for a new round.

---

## Automated Market Maker (AMM)

The AMM is built using Uniswap v4 hooks, providing custom logic for the prediction market:

- **Pool Structure**: Two pools (YES-USDC and NO-USDC) manage liquidity and swaps, initialized with a fee of 3000 and tick spacing of 60.
- **Price Discovery**: Token prices are derived from the ratio of USDC to YES/NO tokens in each pool, updated via `_afterSwap()` tracking.
- **Swap Logic**: The `swap()` function handles direct swaps (USDC ↔ YES/NO) or two-step swaps (YES ↔ NO via USDC), enforcing market state checks.
- **Liquidity Management**: The hook tracks pool balances (`usdcInYesPool`, `yesTokensInPool`, etc.) and adjusts them during swaps or liquidity operations.
- **Outcome Settlement**: Upon resolution, liquidity is removed, and the total USDC collected is distributed to winning token holders proportionally.

The AMM ensures continuous trading and odds reflection based on betting activity, with hooks enforcing rules like market state restrictions.

---

## How to Use

### Smart Contract Interaction
1. **Deploy the Hook**: Already deployed at [0xd35eef48a8b2efe557390845ce0d94d91a378ac0](https://sepolia.basescan.org/address/0xd35eef48a8b2efe557390845ce0d94d91a378ac0) on Base Sepolia.
2. **Initialize Pools**: Owner calls `initializePools()` to set up the market.
3. **Open Market**: Owner calls `openMarket()` to start betting.
4. **Place Bets**: Users call `swap()` to trade USDC for YES/NO tokens.
5. **Close Market**: Owner calls `closeMarket()` to end betting.
6. **Resolve Outcome**: Owner calls `resolveOutcome()` with AI-verified outcome.
7. **Claim Winnings**: Users call `claim()` to redeem winnings.

### Using the AVS
1. **Start Services**: Run `docker-compose up` in the AVS directory to start all services.
2. **Create Market**: Send a POST request to the Execution Service `/create-prediction` endpoint.
3. **Execute Validation**: Trigger the validation process through the Execution Service API.
4. **Monitor Status**: Check validation status through the API or view in the frontend.

### Using the Frontend
1. **Launch the App**: Run the Flutter app on your preferred platform (web, iOS, Android).
2. **Connect Wallet**: Use the wallet connection widget to connect your Web3 wallet.
3. **Browse Markets**: Navigate to the Markets screen to view available prediction markets.
4. **Place Bets**: Select a market and place your YES or NO bets.
5. **Track Progress**: Monitor your bets and market status on the Dashboard.
6. **Claim Winnings**: After market resolution, claim your winnings through the app.

---

## Future Development

- **Coinbase Onramp Integration**: Complete the fiat onramp integration with Coinbase to allow users to directly purchase crypto for betting.
- **Additional Verification Methods**: Expand AVS capabilities to include more data sources such as news APIs, financial data providers, and sports results.
- **Multi-outcome Markets**: Support for markets with more than binary outcomes (e.g., multiple choice options or range predictions).
- **Advanced Analytics**: Enhanced data visualization, market analytics, and prediction history tracking for users to improve their betting strategies.
- **Mobile App Store Release**: iOS App Store and Google Play Store releases with push notifications for market updates.
- **Layer 2 Expansion**: Support for additional Layer 2 networks to reduce transaction costs and increase speed.
- **Social Features**: Integration of social sharing, following other bettors, and community discussion boards.
- **Chainlink Integration**: Integration of chainlink as another data source

---
