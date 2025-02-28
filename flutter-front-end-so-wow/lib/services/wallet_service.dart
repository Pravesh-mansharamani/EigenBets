import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../config/api_config.dart';
import '../main.dart'; // Import the main.dart file for navigatorKey
import 'package:flutter/foundation.dart' show kIsWeb;
import '../utils/metamask.dart'; // For MetaMask integration
import 'package:flutter_web3/flutter_web3.dart';
import '../models/market_data.dart' as market_data; // Import market data for market creation

enum WalletType {
  metamask,
  walletConnect,
  mockWallet
}

enum NetworkType {
  base,
  ethereum,
  polygon
}

class WalletService extends ChangeNotifier {
  bool _isConnected = false;
  String? _walletAddress;
  WalletType? _connectedWalletType;
  NetworkType _currentNetwork = NetworkType.base;
  
  // Balances
  double _usdcBalance = 0.0;
  double _ethBalance = 0.0;
  double _predBalance = 0.0;
  
  // Transaction history
  List<Map<String, dynamic>> _transactions = [];
  
  // Wallet connection states and configurations
  static const String _baseNetworkRPC = 'https://mainnet.base.org';
  static const String _ethereumNetworkRPC = 'https://mainnet.infura.io/v3/your-infura-id';
  static const String _polygonNetworkRPC = 'https://polygon-rpc.com';
  
  // Getters and setters
  bool get isConnected => _isConnected;
  String? get walletAddress => _walletAddress;
  WalletType? get connectedWalletType => _connectedWalletType;
  NetworkType get currentNetwork => _currentNetwork;
  
  double get usdcBalance => _usdcBalance;
  set usdcBalance(double value) {
    _usdcBalance = value;
    notifyListeners();
  }
  
  double get ethBalance => _ethBalance;
  set ethBalance(double value) {
    _ethBalance = value;
    notifyListeners();
  }
  
  double get predBalance => _predBalance;
  set predBalance(double value) {
    _predBalance = value;
    notifyListeners();
  }
  
  List<Map<String, dynamic>> get transactions => _transactions;
  
  // Create or initialize wallet service
  WalletService() {
    // Initialize wallet service
    print('Wallet service initialized');
  }
  
  // Set wallet address directly (used by MetaMask provider)
  void setWalletAddress(String address, WalletType walletType, NetworkType network) {
    _walletAddress = address;
    _connectedWalletType = walletType;
    _currentNetwork = network;
    _isConnected = true;
    
    // Get balances
    refreshBalances();
    
    // Save connection state
    _saveConnectionState();
    
    notifyListeners();
  }
  
  // Connect wallet with simplified implementation
  Future<bool> connectWallet(WalletType walletType) async {
    try {
      // Initialize connection process
      bool success = false;
      
      // Handle different wallet types
      switch (walletType) {
        case WalletType.metamask:
          // For MetaMask, we now use the MetaMaskProvider directly
          // This codepath is only used as fallback
          await Future.delayed(const Duration(milliseconds: 800));
          _walletAddress = '0x71C7656EC7ab88b098defB751B7401B5f6d8976F';
          success = true;
          break;
          
        case WalletType.walletConnect:
          // For production implementation, use WalletConnect SDK
          // For this demo, we'll simulate it
          await Future.delayed(const Duration(milliseconds: 800));
          _walletAddress = '0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199';
          success = true;
          break;
          
        case WalletType.mockWallet:
          // Create a mock wallet for testing
          _walletAddress = '0x742d35Cc6634C0532925a3b844Bc454e4438f44e';
          success = true;
          break;
      }
      
      if (success) {
        _isConnected = true;
        _connectedWalletType = walletType;
        
        // Get mock balances
        await refreshBalances();
        
        // Save connection state
        _saveConnectionState();
        
        notifyListeners();
      }
      
      return success;
    } catch (e) {
      print('Error connecting wallet: $e');
      return false;
    }
  }
  
  // Disconnect wallet - simplified implementation
  Future<bool> disconnectWallet() async {
    try {
      // For MetaMask or WalletConnect, additional disconnection logic would go here
      
      _isConnected = false;
      _walletAddress = null;
      _connectedWalletType = null;
      
      _usdcBalance = 0.0;
      _ethBalance = 0.0;
      _predBalance = 0.0;
      _transactions = [];
      
      // Clear saved connection state
      await _clearConnectionState();
      
      notifyListeners();
      return true;
    } catch (e) {
      print('Error disconnecting wallet: $e');
      return false;
    }
  }
  
  // Save connection state to persistent storage
  Future<void> _saveConnectionState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('wallet_connected', _isConnected);
      if (_walletAddress != null) {
        await prefs.setString('wallet_address', _walletAddress!);
      }
      if (_connectedWalletType != null) {
        await prefs.setInt('wallet_type', _connectedWalletType!.index);
      }
      await prefs.setInt('current_network', _currentNetwork.index);
    } catch (e) {
      print('Error saving connection state: $e');
    }
  }
  
  // Load connection state from persistent storage
  Future<void> loadSavedConnection() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isConnected = prefs.getBool('wallet_connected') ?? false;
      
      if (isConnected) {
        final walletAddress = prefs.getString('wallet_address');
        final walletTypeIndex = prefs.getInt('wallet_type');
        final networkIndex = prefs.getInt('current_network') ?? NetworkType.base.index;
        
        if (walletAddress != null && walletTypeIndex != null) {
          _isConnected = true;
          _walletAddress = walletAddress;
          _connectedWalletType = WalletType.values[walletTypeIndex];
          _currentNetwork = NetworkType.values[networkIndex];
          
          // Get balances
          await refreshBalances();
          
          notifyListeners();
        }
      }
    } catch (e) {
      print('Error loading saved connection: $e');
    }
  }
  
  // Clear saved connection state
  Future<void> _clearConnectionState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('wallet_connected');
      await prefs.remove('wallet_address');
      await prefs.remove('wallet_type');
    } catch (e) {
      print('Error clearing connection state: $e');
    }
  }
  
  // Set current network
  Future<void> setNetwork(NetworkType network) async {
    _currentNetwork = network;
    await _saveConnectionState();
    await refreshBalances();
    notifyListeners();
  }
  
  // Refresh balances with real data where possible
  Future<void> refreshBalances() async {
    if (!_isConnected) return;
    
    try {
      // Due to provider conflicts, we'll just use simulated balances for now
      _generateSimulatedBalances();
      notifyListeners();
    } catch (e) {
      print('Error refreshing balances: $e');
      // Generate simulated balances as fallback
      _generateSimulatedBalances();
      notifyListeners();
    }
  }
  
  // Get actual balances from MetaMask - disabled due to provider conflicts
  Future<void> _getMetaMaskBalances(dynamic metamaskProvider) async {
    try {
      // This function is currently disabled due to provider conflicts
      _generateSimulatedBalances();
    } catch (e) {
      print('Error getting MetaMask balances: $e');
      // Fall back to simulated balances
      _generateSimulatedBalances();
    }
  }
  
  // Generate realistic balances for demo purposes based on wallet address
  void _generateSimulatedBalances() {
    if (!_isConnected || _walletAddress == null) {
      _ethBalance = 0;
      _usdcBalance = 0;
      _predBalance = 0;
      return;
    }
    
    // Create deterministic balances based on wallet address
    // This ensures same wallet always shows same balances
    final seed = _walletAddress!.codeUnits.fold<int>(0, (a, b) => a + b);
    final r = Random(seed);
    
    // Generate balances with some variance but tied to the wallet address
    _ethBalance = 0.5 + (r.nextDouble() * 2.5);
    _usdcBalance = 1000.0 + (r.nextDouble() * 5000.0);
    _predBalance = 100.0 + (r.nextDouble() * 1000.0);
    
    // Special case for our team's wallets to show higher balances
    if (_walletAddress!.toLowerCase().contains('71c7656e') || 
        _walletAddress!.toLowerCase().contains('8626f694')) {
      _ethBalance *= 1.5;
      _usdcBalance *= 2.0;
      _predBalance *= 3.0;
    }
  }
  
  // Get transaction history - simplified implementation
  Future<void> refreshTransactionHistory() async {
    if (!_isConnected) return;
    
    try {
      // For production, we would query transaction history from blockchain
      // via Etherscan API, TheGraph, or direct RPC calls
      
      // For demo purposes, we'll generate mock transactions
      _generateMockTransactions();
      
      notifyListeners();
    } catch (e) {
      print('Error refreshing transaction history: $e');
      // Still generate mock transactions even if there's an error
      _generateMockTransactions();
      notifyListeners();
    }
  }
  
  // Generate mock transactions for demo purposes
  void _generateMockTransactions() {
    final now = DateTime.now();
    final types = ['send', 'receive', 'swap', 'bet', 'deposit', 'withdrawal'];
    final tokens = ['USDC', 'ETH', 'PRED'];
    final statuses = ['completed', 'pending', 'failed'];
    
    _transactions = List.generate(
      5,
      (index) {
        final type = types[now.microsecond % types.length];
        final token = tokens[now.microsecond % tokens.length];
        final status = index == 0 ? 'pending' : statuses[now.microsecond % statuses.length];
        
        return {
          'hash': '0x${List.generate(64, (_) => '0123456789ABCDEF'[DateTime.now().microsecond % 16]).join()}',
          'type': type,
          'token': token,
          'amount': type == 'ETH' ? 0.1 * (index + 1) : 100.0 * (index + 1),
          'timestamp': now.subtract(Duration(days: index, hours: index)).millisecondsSinceEpoch,
          'to': '0x${List.generate(40, (_) => '0123456789ABCDEF'[DateTime.now().microsecond % 16]).join()}',
          'from': _walletAddress ?? '',
          'status': status,
        };
      },
    );
  }
  
  // Send Transaction (mock implementation)
  Future<Map<String, dynamic>?> sendTransaction({
    required String to,
    required double amount,
    required String token,
  }) async {
    if (!_isConnected) return null;
    
    try {
      // Check balance
      double balance;
      switch (token) {
        case 'USDC':
          balance = _usdcBalance;
          break;
        case 'ETH':
          balance = _ethBalance;
          break;
        case 'PRED':
          balance = _predBalance;
          break;
        default:
          balance = 0;
      }
      
      if (balance < amount) {
        return {
          'success': false,
          'error': 'Insufficient balance',
        };
      }
      
      // Simulate sending transaction
      await Future.delayed(const Duration(seconds: 2));
      
      // Update balance
      switch (token) {
        case 'USDC':
          _usdcBalance -= amount;
          break;
        case 'ETH':
          _ethBalance -= amount;
          break;
        case 'PRED':
          _predBalance -= amount;
          break;
      }
      
      // Add to transaction history
      final txHash = '0x${List.generate(64, (_) => '0123456789ABCDEF'[DateTime.now().microsecond % 16]).join()}';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      _transactions.insert(0, {
        'hash': txHash,
        'type': 'send',
        'token': token,
        'amount': amount,
        'timestamp': timestamp,
        'to': to,
        'from': _walletAddress ?? '',
        'status': 'completed',
      });
      
      notifyListeners();
      
      return {
        'success': true,
        'txHash': txHash,
        'timestamp': timestamp,
      };
    } catch (e) {
      print('Error sending transaction: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  // Launch Coinbase Onramp with options for WebView or external browser
  Future<bool> launchCoinbaseOnramp({
    required BuildContext context,
    required String asset,
    double amount = 0.0,
    bool useWebView = true,
  }) async {
    try {
      // For web platform, use a different approach
      if (kIsWeb) {
        try {
          // Build the URL
          final uri = Uri.parse('${ApiConfig.onrampBaseUrl}/onramp');
          
          // Launch in browser with proper Uri parameter
          return await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
        } catch (e) {
          print('Error launching onramp on web: $e');
          return false;
        }
      }
      
      // Build the Onramp URL
      final onrampUrl = _buildOnrampUrl(
        destinationAddress: _walletAddress ?? '',
        destinationChain: _currentNetwork.toString(),
        assetToBuy: asset,
        amount: amount,
      );
      
      bool success = false;
      
      // Use WebView or external browser based on preference
      if (useWebView) {
        // Get BuildContext from the navigator key
        final context = navigatorKey.currentContext;
        if (context != null) {
          success = await _launchOnrampWebView(context, onrampUrl);
        } else {
          // Fallback to URL launcher if context is not available
          final uri = Uri.parse(onrampUrl);
          success = await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } else {
        // Launch in external browser as documented in the PDF
        final uri = Uri.parse(onrampUrl);
        success = await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      
      // If the user completed the purchase, update the balances
      if (success) {
        // This would be handled by callbacks in a real implementation
        // Simulating a successful purchase here
        double purchaseAmount = amount ?? 100.0;
        
        // Update balance to reflect the purchase based on the selected asset
        switch (asset) {
          case 'USDC':
            _usdcBalance += purchaseAmount;
            break;
          case 'ETH':
            _ethBalance += purchaseAmount / 2000; // Approximate ETH price in USD
            break;
          case 'PRED':
            _predBalance += purchaseAmount * 2; // Approximate PRED price in USD
            break;
        }
        
        // Add to transaction history - following the format expected by the app
        final txHash = '0x${List.generate(64, (_) => '0123456789ABCDEF'[DateTime.now().microsecond % 16]).join()}';
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        
        _transactions.insert(0, {
          'hash': txHash,
          'type': 'deposit',
          'token': asset,
          'amount': asset == 'ETH' ? purchaseAmount / 2000 : purchaseAmount,
          'timestamp': timestamp,
          'to': _walletAddress ?? '',
          'from': 'Coinbase Onramp',
          'status': 'completed',
        });
        
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error launching Coinbase Onramp: $e');
      return false;
    }
  }
  
  // Launch Coinbase Onramp in WebView
  Future<bool> launchCoinbaseOnrampInWebView(BuildContext context, {
    required String destinationAddress,
    required String destinationChain,
    required String assetToBuy,
    required double amount,
  }) async {
    try {
      if (amount <= 0) {
        return false;
      }
      
      // Build the Coinbase Onramp URL
      final onrampUrl = '${ApiConfig.onrampBaseUrl}/buy?'
          'appId=${ApiConfig.onrampClientId}'
          '&destinationWallets=[{"address":"$destinationAddress","blockchains":["$destinationChain"]}]'
          '&defaultNetwork=$destinationChain'
          '&presetCryptoAmount=$amount'
          '&presetCryptoCurrency=${assetToBuy.toLowerCase()}'
          '&appName=${Uri.encodeComponent(ApiConfig.onrampAppName)}';
      
      // Show WebView in a dialog
      final result = await showDialog<bool>(
        context: context,
        builder: (context) {
          return Dialog(
            insetPadding: EdgeInsets.zero,
            child: Column(
              children: [
                AppBar(
                  title: const Text('Coinbase Onramp'),
                  leading: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ),
                Expanded(
                  child: WebViewWidget(
                    controller: WebViewController()
                      ..setJavaScriptMode(JavaScriptMode.unrestricted)
                      ..loadRequest(Uri.parse(onrampUrl)),
                  ),
                ),
              ],
            ),
          );
        },
      );
      
      // If the user completed the purchase, update the balances
      if (result == true) {
        // Update balance to reflect the purchase
        switch (assetToBuy) {
          case 'USDC':
            _usdcBalance += amount;
            break;
          case 'ETH':
            _ethBalance += amount / 2000; // Approximate ETH price in USD
            break;
          case 'PRED':
            _predBalance += amount * 2; // Approximate PRED price in USD
            break;
        }
        
        // Add to transaction history
        final txHash = '0x${List.generate(64, (_) => '0123456789ABCDEF'[DateTime.now().microsecond % 16]).join()}';
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        
        _transactions.insert(0, {
          'hash': txHash,
          'type': 'deposit',
          'token': assetToBuy,
          'amount': assetToBuy == 'ETH' ? amount / 2000 : amount,
          'timestamp': timestamp,
          'to': _walletAddress ?? '',
          'from': 'Coinbase Onramp',
          'status': 'completed',
        });
        
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error launching Coinbase Onramp in WebView: $e');
      return false;
    }
  }
  
  // Execute on-chain action using CDP SDK
  Future<Map<String, dynamic>?> executeOnChainAction({
    required String action,
    required Map<String, dynamic> params,
  }) async {
    if (!_isConnected) return null;
    
    try {
      // Simulate on-chain interaction loading time
      // Between 2-4 seconds to make it feel realistic
      final loadingDuration = 2000 + (DateTime.now().millisecond % 2000);
      await Future.delayed(Duration(milliseconds: loadingDuration));
      
      // Mock successful response
      return {
        'success': true,
        'txHash': '0x${List.generate(64, (_) => '0123456789ABCDEF'[DateTime.now().microsecond % 16]).join()}',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
    } catch (e) {
      print('Error executing on-chain action: $e');
      return null;
    }
  }
  
  // Sign message for authentication - simplified implementation
  Future<String?> signMessage(String message) async {
    if (!_isConnected) return null;
    
    try {
      // For production:
      // - MetaMask: window.ethereum.request({method: 'personal_sign', params: [message, address]})
      // - WalletConnect: connector.signPersonalMessage([message, address])
      
      // Simulate signing with 2-3 second delay for realistic wallet popup experience
      final loadingDuration = 2000 + (DateTime.now().millisecond % 1000);
      await Future.delayed(Duration(milliseconds: loadingDuration));
      
      return '0x${List.generate(130, (_) => '0123456789ABCDEF'[DateTime.now().microsecond % 16]).join()}';
    } catch (e) {
      print('Error signing message: $e');
      return null;
    }
  }
  
  // Create a prediction market
  Future<Map<String, dynamic>?> createMarket({
    required String question,
    required String category,
    required String resolutionCriteria,
    required String dataSource,
    required DateTime endDate,
    required double initialFunding,
  }) async {
    if (!_isConnected) return null;
    
    try {
      // Check USDC balance
      if (_usdcBalance < initialFunding) {
        return {
          'success': false,
          'error': 'Insufficient USDC balance',
        };
      }
      
      // Check PRED token balance for creation fee
      if (_predBalance < 10) {
        return {
          'success': false,
          'error': 'Insufficient PRED tokens for market creation fee (10 PRED required)',
        };
      }
      
      // Prepare market creation data
      final marketData = {
        'question': question,
        'category': category,
        'resolutionCriteria': resolutionCriteria,
        'dataSource': dataSource,
        'endDate': endDate.millisecondsSinceEpoch,
        'initialFunding': initialFunding,
      };
      
      // Execute contract call
      final result = await executeOnChainAction(
        action: 'createMarket',
        params: {
          'contractAddress': '0xPredictionMarketContractAddress',
          'token': 'USDC',
          'amount': initialFunding,
          'data': jsonEncode(marketData),
        },
      );
      
      if (result != null && result['success'] == true) {
        // Update balances
        usdcBalance -= initialFunding;
        predBalance -= 10; // Market creation fee
        
        // Create a new market entry in our market data
        // This allows the new market to appear in the UI immediately
        final marketId = result['txHash'] ?? 'market-${DateTime.now().millisecondsSinceEpoch}';
        _createDemoMarket(
          marketId: marketId,
          title: question,
          description: resolutionCriteria,
          category: category,
          endDate: endDate,
          initialFunding: initialFunding,
        );
        
        return {
          'success': true,
          'marketId': marketId,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        };
      }
      
      return {
        'success': false,
        'error': 'Transaction failed',
      };
    } catch (e) {
      print('Error creating market: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  // Creates a new demo market and adds it to the global markets list
  // This allows newly created markets to show up in the UI
  void _createDemoMarket({
    required String marketId,
    required String title,
    required String description,
    required String category,
    required DateTime endDate,
    required double initialFunding,
  }) {
    try {
      // Generate a default yes/no price based on a deterministic value from the title
      final titleHash = title.hashCode.abs() % 100;
      final yesPrice = (40 + (titleHash % 50)) / 100; // Between 0.4 and 0.9
      final noPrice = 1.0 - yesPrice;
      
      // Create a new market with provided details
      final newMarket = market_data.MarketData(
        id: marketId,
        title: title,
        description: description,
        category: category,
        yesPrice: yesPrice,
        noPrice: noPrice,
        volume: initialFunding * 2.5, // Estimate some trading happened already
        expiryDate: endDate,
        imageUrl: 'assets/images/placeholder.txt', // Use placeholder as fallback
        priceHistory: [], // We'll generate the price history outside the constructor
        status: market_data.MarketStatus.open, // Start as open
      );
      
      // Add to global market list
      market_data.addMarketToGlobalList(newMarket);
      
      // Let the UI know a new market was created
      notifyListeners();
    } catch (e) {
      print('Error creating demo market: $e');
    }
  }
  
  // Build the Onramp URL
  String _buildOnrampUrl({
    required String destinationAddress, 
    required String destinationChain, 
    required String assetToBuy,
    double? amount,
  }) {
    // Base URL
    final baseUrl = Uri.parse('${ApiConfig.onrampBaseUrl}/buy');
    
    // Build query parameters according to Coinbase Onramp docs
    final queryParams = {
      'appId': ApiConfig.onrampClientId,
      'destinationWallets': jsonEncode([
        {
          'address': destinationAddress,
          'blockchains': [destinationChain],
          'supportedAssets': [assetToBuy],
        }
      ]),
      'defaultAsset': assetToBuy,
      'exploreName': ApiConfig.onrampAppName,
      // Specify the callback scheme for deep linking
      'redirectUrl': 'nexuspredictions://onramp',
    };
    
    // Add optional amount parameter if provided
    if (amount != null && amount > 0) {
      queryParams['presetFiatAmount'] = amount.toString();
    }
    
    // Build the complete URL
    final onrampUrl = Uri.parse(baseUrl.toString()).replace(queryParameters: queryParams);
    
    return onrampUrl.toString();
  }
  
  // Handle the Coinbase Onramp callback and extract the transaction info
  Map<String, dynamic>? _parseOnrampCallback(String callbackUrl) {
    try {
      final uri = Uri.parse(callbackUrl);
      
      // Check if the callback contains transaction data
      if (uri.queryParameters.containsKey('transactionId')) {
        return {
          'transactionId': uri.queryParameters['transactionId'],
          'status': uri.queryParameters['status'] ?? 'completed',
          'assetPurchased': uri.queryParameters['asset'],
          'amount': double.tryParse(uri.queryParameters['amount'] ?? '0'),
        };
      }
      
      return null;
    } catch (e) {
      print('Error parsing Onramp callback: $e');
      return null;
    }
  }
  
  // Implement Coinbase Onramp checkout in WebView
  Future<bool> _launchOnrampWebView(BuildContext context, String onrampUrl) async {
    final resultCompleter = Completer<bool>();
    
    // Create a properly initialized controller based on platform
    final controller = WebViewController();
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            // Handle redirects and callbacks
            if (request.url.startsWith('nexuspredictions://')) {
              final transactionInfo = _parseOnrampCallback(request.url);
              if (transactionInfo != null) {
                resultCompleter.complete(true);
                Navigator.pop(context);
                return NavigationDecision.prevent;
              }
            }
            return NavigationDecision.navigate;
          },
          onPageFinished: (url) {
            // Check if we reached a success/cancel page
            if (url.contains('success') || url.contains('complete')) {
              if (!resultCompleter.isCompleted) {
                resultCompleter.complete(true);
                Navigator.pop(context);
              }
            } else if (url.contains('cancel') || url.contains('error')) {
              if (!resultCompleter.isCompleted) {
                resultCompleter.complete(false);
                Navigator.pop(context);
              }
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(onrampUrl));
    
    // Show WebView
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          insetPadding: EdgeInsets.zero,
          child: Container(
            width: 500,
            height: 700,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                // Dialog header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Coinbase Onramp',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          resultCompleter.complete(false);
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(),
                // WebView
                Expanded(
                  child: WebViewWidget(
                    controller: controller,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    
    return resultCompleter.future;
  }
  
  // For EVM wallet integration, we'd implement methods like:
  // - switchNetwork(NetworkType network)
  // - estimateGas(String to, double amount, String data)
  // - getGasPrice()
  // - getBlockNumber()
  // In a production app, these would interact with the connected wallet
  
  // Development helper method
  Future<bool> connectWithMockWallet() async {
    _walletAddress = "0x742d35Cc6634C0532925a3b844Bc454e4438f44e";
    _isConnected = true;
    _connectedWalletType = WalletType.mockWallet;
    _usdcBalance = 1000.0;
    _ethBalance = 1.5;
    _predBalance = 500.0;
    
    // Add mock transactions
    _transactions = [
      {
        'hash': '0x${List.generate(40, (_) => '0123456789ABCDEF'[DateTime.now().microsecond % 16]).join()}',
        'type': 'deposit',
        'token': 'USDC',
        'amount': 1000.0,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'to': _walletAddress ?? '',
        'from': 'Mock Faucet',
        'status': 'completed',
      }
    ];
    
    // Save state
    _saveConnectionState();
    
    notifyListeners();
    return true;
  }
} 