# EigenBet: Decentralized Prediction Markets Platform with AVS Integration

## Project Overview

EigenBet is an advanced decentralized prediction market platform built on Ethereum's Layer 2 networks, with integrated AVS (Automated Verification Services) for secure and reliable market resolution. The platform allows users to create, participate in, and trade prediction market outcomes across a variety of categories including crypto, finance, sports, politics, and technology.

This repository contains the Flutter-based frontend implementation that provides a seamless and intuitive interface for interacting with prediction markets across mobile, desktop, and web platforms.

## Technical Architecture

### Core Components

1. **User Interface Layer**
   - Cross-platform Flutter UI with responsive design supporting mobile, tablet, and desktop layouts
   - MaterialApp-based theming system with dark/light mode support
   - Custom widgets optimized for prediction market interactions

2. **State Management**
   - Provider pattern for local state management
   - Flutter Bloc for complex state flows
   - GetX for reactive programming and dependency injection

3. **Blockchain Integration Layer**
   - Web3 connectivity with multiple wallet providers (MetaMask, WalletConnect, Coinbase Wallet)
   - Custom bridge for communication between Dart and JavaScript for Web3 interactions
   - Transaction handling with loading states and error recovery

4. **AVS Integration**
   - Custom AVS service for market outcome verification
   - Integration with EigenLayer's data availability and verification system
   - Transaction attestation and verification workflow

5. **Data Layer**
   - Models for market data, transactions, user profiles, and verification status
   - HTTP/REST API services for off-chain data
   - Local storage for user preferences and session data

## Key Features & Implementation Details

### Prediction Market Creation and Interaction

Markets are represented by the `MarketData` class which encapsulates:
- Market metadata (title, description, category)
- Price information (yes/no probabilities)
- Historical price data for charts
- Verification status and resolution information

```dart
// Key market data structure
class MarketData {
  final String id;
  final String title;
  final String description;
  final String category;
  final double yesPrice;
  final double noPrice;
  final double volume;
  final DateTime expiryDate;
  final String imageUrl;
  final List<PricePoint> priceHistory;
  final MarketStatus status;
  final String? avsVerificationId;
  final bool isAvsVerified;
  final DateTime? avsVerificationTimestamp;
  final String? outcomeResult;
  
  // Constructor and methods...
}
```

The application supports different market statuses:
- `open`: Active markets accepting bets
- `pending`: Markets awaiting resolution
- `closed`: Markets no longer accepting bets
- `resolved`: Markets with verified outcomes

### Wallet Integration

The wallet service provides a unified interface for connecting to multiple wallet providers:

```dart
class WalletService {
  // Wallet connection state
  bool isConnected = false;
  String? walletAddress;
  WalletType? connectedWalletType;
  
  // Connection methods for different providers
  Future<bool> connectMetamask() { /* ... */ }
  Future<bool> connectCoinbaseWallet() { /* ... */ }
  Future<bool> connectWalletConnect() { /* ... */ }
  
  // Transaction methods
  Future<String?> placeBet(MarketData market, String outcome, double amount) { /* ... */ }
  Future<bool> createMarket(MarketData newMarket) { /* ... */ }
}
```

The platform uses a dual approach for Web3 integration:
- JavaScript interop bridges for web environments
- Native mobile SDKs for iOS and Android

### AVS Verification System

The AVS service handles market outcome verification through EigenLayer's restaking system:

```dart
class AvsService {
  // Submit verification request to AVS nodes
  Future<String?> submitMarketVerification(MarketData market) { /* ... */ }
  
  // Check verification status
  Future<Map<String, dynamic>?> checkVerificationStatus(String verificationId) { /* ... */ }
  
  // Finalize market outcome based on verification
  Future<bool> finalizeMarketOutcome(String marketId, String verificationId, String outcome) { /* ... */ }
}
```

Verification flow:
1. Market reaches expiry date
2. User or oracle initiates verification request
3. AVS nodes validate the outcome through EigenLayer's consensus
4. Market is updated with verified result
5. Winners can claim payouts

### Responsive UI Implementation

The application implements three distinct layouts optimized for different screen sizes:
- Desktop (>1200px): Multi-column layout with fixed navigation
- Tablet (600-1200px): Hybrid layout with responsive adjustments
- Mobile (<600px): Single column layout with adaptive components

Key responsive UI components:
- `BettingScreen`: Primary interface for placing bets with adaptive layouts
- `MarketCard`: Displays market overview with dynamic sizing
- `WalletConnectionWidget`: Multi-wallet connection interface

### Data Visualization

Market data visualization is implemented using:
- `FL_Chart` for price history and probability charts
- Custom animation for price movements
- Gradient-based UI indicating market sentiment

## Smart Contract Integration

The frontend interacts with the following smart contracts:
- Market Factory Contract: Creates new prediction markets
- Market Contract: Individual market instances with betting functionality
- AVS Contract: Handles verification and attestation
- Token Contract: ERC-20 tokens used for betting and rewards

Contract interaction occurs through the `Web3Service` class which abstracts the low-level details of transaction construction, gas estimation, and error handling.

## Security Considerations

- User funds are secured through non-custodial wallet integration
- All transactions require explicit user confirmation
- Verification process is secured through EigenLayer's decentralized restaking system
- UI prevents invalid actions (e.g., betting on expired markets)
- Market creation includes spam prevention mechanisms

## Development and Deployment

### Setup and Configuration

1. Clone the repository
```bash
git clone https://github.com/yourusername/eigenbet-frontend.git
cd eigenbet-frontend
```

2. Install dependencies
```bash
flutter pub get
```

3. Configure network settings in `lib/config/api_config.dart`

4. Run the application
```bash
flutter run
```

### Building for Production

```bash
# Web
flutter build web --release

# Android
flutter build apk --release

# iOS
flutter build ios --release
```

## Future Roadmap

- Integration with additional L2 networks (Optimism, Arbitrum, Base)
- Enhanced AVS verification with multi-oracle support
- Social features with integrated market discussions
- Mobile-optimized wallet with biometric security

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributors

- Cole Dermott (@coledermo)
- Pravesh (@ImTheBigP)

## Acknowledgments

- EigenLayer team for AVS infrastructure support
- Flutter community for comprehensive UI libraries
- Web3 ecosystem contributors
- Othentic team for contributions on technical help
- My cat for being a goofy guy
- This line of text that I'll acknowledge you probably won't read :D