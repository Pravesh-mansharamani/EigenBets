import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:web3dart/web3dart.dart';
import '../config/api_config.dart';
import '../utils/native_platform_imports.dart';
import '../utils/web3_js_bridge.dart';
import '../main.dart'; // Import for navigatorKey

enum Web3WalletType {
  metamask,
  walletConnect,
  coinbase,
  trustWallet,
  rainbow,
  argent,
  ledger
}

enum EVMNetwork {
  ethereum,
  polygon,
  base,
  arbitrum,
  optimism,
  avalanche
}

class Web3Service extends ChangeNotifier {
  bool _isConnected = false;
  String? _walletAddress;
  Web3WalletType? _connectedWalletType;
  EVMNetwork _currentNetwork = EVMNetwork.base;
  bool _isConnecting = false;
  int _chainId = 8453; // Base chain ID
  
  // For WalletConnect sessions
  String? _wcSessionKey;
  
  // Track transaction status
  Map<String, String> _transactionStatus = {};
  
  /// Add a method to update connection info from WalletConnect
  void updateWalletConnect({
    required bool isConnected,
    String? address,
    String? chainId,
    required Web3WalletType? walletType,
  }) {
    _isConnected = isConnected;
    _walletAddress = address;
    _connectedWalletType = walletType;
    
    // Update chain ID if provided
    if (chainId != null) {
      try {
        // Parse chainId (which could be in hex format like '0x2105')
        int parsedChainId;
        if (chainId.startsWith('0x')) {
          parsedChainId = int.parse(chainId.substring(2), radix: 16);
        } else {
          parsedChainId = int.parse(chainId);
        }
        
        _chainId = parsedChainId;
        
        // Update current network based on chain ID
        _currentNetwork = _getNetworkFromChainId(parsedChainId);
      } catch (e) {
        debugPrint('Error parsing chain ID: $e');
      }
    }
    
    // Save to storage
    if (isConnected && address != null) {
      _saveConnectionState();
    }
    
    notifyListeners();
  }
  
  // Network configuration
  final Map<EVMNetwork, Map<String, dynamic>> _networkConfig = {
    EVMNetwork.ethereum: {
      'chainId': 1,
      'chainName': 'Ethereum',
      'rpcUrl': 'https://mainnet.infura.io/v3/your-infura-id',
      'blockExplorerUrl': 'https://etherscan.io',
      'nativeCurrency': {
        'name': 'Ether',
        'symbol': 'ETH',
        'decimals': 18
      }
    },
    EVMNetwork.polygon: {
      'chainId': 137,
      'chainName': 'Polygon',
      'rpcUrl': 'https://polygon-rpc.com',
      'blockExplorerUrl': 'https://polygonscan.com',
      'nativeCurrency': {
        'name': 'MATIC',
        'symbol': 'MATIC',
        'decimals': 18
      }
    },
    EVMNetwork.base: {
      'chainId': 8453,
      'chainName': 'Base',
      'rpcUrl': 'https://mainnet.base.org',
      'blockExplorerUrl': 'https://basescan.org',
      'nativeCurrency': {
        'name': 'Ether',
        'symbol': 'ETH',
        'decimals': 18
      }
    },
    EVMNetwork.arbitrum: {
      'chainId': 42161,
      'chainName': 'Arbitrum One',
      'rpcUrl': 'https://arb1.arbitrum.io/rpc',
      'blockExplorerUrl': 'https://arbiscan.io',
      'nativeCurrency': {
        'name': 'Ether',
        'symbol': 'ETH',
        'decimals': 18
      }
    },
    EVMNetwork.optimism: {
      'chainId': 10,
      'chainName': 'Optimism',
      'rpcUrl': 'https://mainnet.optimism.io',
      'blockExplorerUrl': 'https://optimistic.etherscan.io',
      'nativeCurrency': {
        'name': 'Ether',
        'symbol': 'ETH',
        'decimals': 18
      }
    },
    EVMNetwork.avalanche: {
      'chainId': 43114,
      'chainName': 'Avalanche C-Chain',
      'rpcUrl': 'https://api.avax.network/ext/bc/C/rpc',
      'blockExplorerUrl': 'https://snowtrace.io',
      'nativeCurrency': {
        'name': 'Avalanche',
        'symbol': 'AVAX',
        'decimals': 18
      }
    },
  };
  
  // Contract addresses
  final Map<EVMNetwork, Map<String, String>> _contractAddresses = {
    EVMNetwork.base: {
      'USDC': '0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913',
      'PRED': '0x0000000000000000000000000000000000000000', // Example - to be updated
      'MARKET': '0x0000000000000000000000000000000000000000', // Example - to be updated
    },
    EVMNetwork.ethereum: {
      'USDC': '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48',
      'PRED': '0x0000000000000000000000000000000000000000', // Example - to be updated
      'MARKET': '0x0000000000000000000000000000000000000000', // Example - to be updated
    },
    EVMNetwork.polygon: {
      'USDC': '0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174',
      'PRED': '0x0000000000000000000000000000000000000000', // Example - to be updated
      'MARKET': '0x0000000000000000000000000000000000000000', // Example - to be updated
    },
  };
  
  // ABIs would be stored/imported separately in a production app
  
  // Getters
  bool get isConnected => _isConnected;
  String? get walletAddress => _walletAddress;
  Web3WalletType? get connectedWalletType => _connectedWalletType;
  EVMNetwork get currentNetwork => _currentNetwork;
  int get chainId => _chainId;
  bool get isConnecting => _isConnecting;
  Map<String, String> get transactionStatus => _transactionStatus;
  
  // Constructor
  Web3Service() {
    // Initialize the Web3 JS bridge if running in a web browser
    if (kIsWeb) {
      Web3JsBridge.initialize().then((_) {
        // Check if wallet is already connected
        _checkBrowserWalletConnection();
      });
    } else {
      loadSavedConnection();
    }
  }
  
  // Check browser wallet connection status
  Future<void> _checkBrowserWalletConnection() async {
    if (!kIsWeb) return;
    
    try {
      final isConnected = await Web3JsBridge.isWalletConnected();
      if (isConnected) {
        // Get wallet address and chain ID
        final address = await Web3JsBridge.getWalletAddress();
        final chainId = await Web3JsBridge.getChainId();
        
        if (address != null) {
          _walletAddress = address;
          _isConnected = true;
          
          if (chainId != null) {
            _chainId = int.tryParse(chainId.replaceFirst('0x', ''), radix: 16) ?? 8453;
            // Map chain ID to network type
            _currentNetwork = _getNetworkFromChainId(_chainId);
          }
          
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error checking browser wallet connection: $e');
    }
  }
  
  // Helper method to get network from chain ID
  EVMNetwork _getNetworkFromChainId(int chainId) {
    switch (chainId) {
      case 1:
        return EVMNetwork.ethereum;
      case 137:
        return EVMNetwork.polygon;
      case 8453:
        return EVMNetwork.base;
      case 42161:
        return EVMNetwork.arbitrum;
      case 10:
        return EVMNetwork.optimism;
      case 43114:
        return EVMNetwork.avalanche;
      default:
        return EVMNetwork.base;
    }
  }
  
  // Connect wallet with various methods
  Future<bool> connectWallet(Web3WalletType walletType) async {
    if (_isConnecting) return false;
    
    _isConnecting = true;
    notifyListeners();
    
    try {
      bool success = false;
      
      switch (walletType) {
        case Web3WalletType.metamask:
          success = await _connectMetaMask();
          break;
        case Web3WalletType.walletConnect:
          success = await _connectWalletConnect();
          break;
        case Web3WalletType.coinbase:
          success = await _connectCoinbaseWallet();
          break;
        case Web3WalletType.trustWallet:
        case Web3WalletType.rainbow:
        case Web3WalletType.argent:
        case Web3WalletType.ledger:
          // These would use WalletConnect under the hood
          success = await _connectWalletConnect();
          break;
      }
      
      if (success) {
        _isConnected = true;
        _connectedWalletType = walletType;
        
        // Switch to the default network
        await switchNetwork(_currentNetwork);
        
        // Save connection state
        await _saveConnectionState();
        
        notifyListeners();
      }
      
      return success;
    } catch (e) {
      print('Error connecting wallet: $e');
      return false;
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
  }
  
  // MetaMask connection
  Future<bool> _connectMetaMask() async {
    try {
      if (kIsWeb) {
        // Check if MetaMask is available
        final hasMetaMask = await Web3JsBridge.hasMetaMask();
        if (!hasMetaMask) {
          // Show a message to the user that MetaMask is not installed
          if (navigatorKey.currentContext != null) {
            ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
              const SnackBar(
                content: Text('MetaMask extension not detected. Please install MetaMask and refresh the page.'),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 5),
              ),
            );
          }
          return false;
        }
        
        // Connect using Web3JsBridge
        final result = await Web3JsBridge.connectMetaMask();
        if (result['success'] == true && result['address'] != null) {
          _walletAddress = result['address'] as String;
          _connectedWalletType = Web3WalletType.metamask;
          
          // Get chain ID
          if (result['chainId'] != null) {
            final chainIdStr = result['chainId'] as String;
            _chainId = int.tryParse(chainIdStr.replaceFirst('0x', ''), radix: 16) ?? 8453;
            _currentNetwork = _getNetworkFromChainId(_chainId);
          } else {
            _chainId = 8453; // Default to Base network
            _currentNetwork = EVMNetwork.base;
          }
          
          return true;
        } else {
          // Show error if provided
          if (result['error'] != null && navigatorKey.currentContext != null) {
            ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
              SnackBar(
                content: Text('MetaMask connection error: ${result['error']}'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.red,
              ),
            );
          }
          return false;
        }
      } else {
        // Mobile implementation using deep linking
        final url = Uri.parse('https://metamask.app.link/dapp/${Uri.encodeFull('https://eigenbet.xyz')}');
        final canLaunch = await canLaunchUrl(url);
        
        if (canLaunch) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
          
          // Wait for callback through deep link handling
          // This would be completed when your app receives a deep link callback
          final completer = Completer<bool>();
          
          // Set timeout
          Future.delayed(const Duration(seconds: 60), () {
            if (!completer.isCompleted) {
              completer.complete(false);
            }
          });
          
          // In a real implementation, this would be triggered by a deep link handler
          // For demo with actual connection, we'll prompt user to enter address
          _showAddressPrompt().then((address) {
            if (address != null && address.isNotEmpty) {
              _walletAddress = address;
              _chainId = 8453; // Base network
              _currentNetwork = EVMNetwork.base;
              completer.complete(true);
            } else {
              completer.complete(false);
            }
          });
          
          return await completer.future;
        } else {
          // MetaMask not installed, show error or prompt to install
          if (navigatorKey.currentContext != null) {
            ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
              const SnackBar(
                content: Text('MetaMask app not installed. Please install the MetaMask app.'),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 5),
              ),
            );
          }
          return false;
        }
      }
    } catch (e) {
      debugPrint('Error connecting to MetaMask: $e');
      return false;
    }
  }
  
  // Helper method to prompt user for wallet address
  Future<String?> _showAddressPrompt() async {
    // This would normally be done via JS interop
    // But for this demo we'll use the navigatorKey to show a dialog
    
    if (navigatorKey.currentContext == null) {
      return null;
    }
    
    final context = navigatorKey.currentContext!;
    final controller = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connect Wallet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your wallet address:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: '0x...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Navigator.pop(context, controller.text);
              }
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
    
    return result;
  }
  
  // WalletConnect implementation
  Future<bool> _connectWalletConnect() async {
    try {
      if (kIsWeb) {
        // In a production app, you'd load and initialize the WalletConnect SDK
        // For this demo, we'll inform the user that this requires WalletConnect SDK setup
        if (navigatorKey.currentContext != null) {
          ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
            const SnackBar(
              content: Text('WalletConnect requires loading the WalletConnect SDK. For this demo, please use MetaMask or Coinbase Wallet instead.'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 5),
            ),
          );
        }
        
        // For demo purposes, let's prompt for address entry as a fallback
        final address = await _showAddressPrompt();
        if (address == null || address.isEmpty) {
          return false;
        }
        
        _walletAddress = address;
        _connectedWalletType = Web3WalletType.walletConnect;
        _chainId = 8453; // Base network by default
        _currentNetwork = EVMNetwork.base;
        return true;
      } else {
        // For mobile, we'd need to launch the WalletConnect compatible wallet
        // For demo, we'll use the address prompt
        final address = await _showAddressPrompt();
        if (address == null || address.isEmpty) {
          return false;
        }
        
        _walletAddress = address;
        _connectedWalletType = Web3WalletType.walletConnect;
        _chainId = 8453; // Base network by default
        _currentNetwork = EVMNetwork.base;
        return true;
      }
    } catch (e) {
      debugPrint('Error connecting with WalletConnect: $e');
      return false;
    }
  }
  
  // Coinbase Wallet implementation
  Future<bool> _connectCoinbaseWallet() async {
    try {
      if (kIsWeb) {
        // Check if Coinbase Wallet is available
        final hasCoinbaseWallet = await Web3JsBridge.hasCoinbaseWallet();
        if (!hasCoinbaseWallet) {
          // Show a message to the user that Coinbase Wallet is not installed
          if (navigatorKey.currentContext != null) {
            ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
              const SnackBar(
                content: Text('Coinbase Wallet extension not detected. Please install Coinbase Wallet and refresh the page.'),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 5),
              ),
            );
          }
          return false;
        }
        
        // Connect using Web3JsBridge
        final result = await Web3JsBridge.connectCoinbaseWallet();
        if (result['success'] == true && result['address'] != null) {
          _walletAddress = result['address'] as String;
          _connectedWalletType = Web3WalletType.coinbase;
          
          // Get chain ID
          if (result['chainId'] != null) {
            final chainIdStr = result['chainId'] as String;
            _chainId = int.tryParse(chainIdStr.replaceFirst('0x', ''), radix: 16) ?? 8453;
            _currentNetwork = _getNetworkFromChainId(_chainId);
          } else {
            _chainId = 8453; // Default to Base network
            _currentNetwork = EVMNetwork.base;
          }
          
          return true;
        } else {
          // Show error if provided
          if (result['error'] != null && navigatorKey.currentContext != null) {
            ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
              SnackBar(
                content: Text('Coinbase Wallet connection error: ${result['error']}'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.red,
              ),
            );
          }
          return false;
        }
      } else {
        // Mobile implementation using deep linking
        final url = Uri.parse('https://go.cb-w.com/dapp?cb_url=${Uri.encodeFull('https://eigenbet.xyz')}');
        final canLaunch = await canLaunchUrl(url);
        
        if (canLaunch) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
          
          // Wait for callback through deep link handling
          final completer = Completer<bool>();
          
          // Set timeout
          Future.delayed(const Duration(seconds: 60), () {
            if (!completer.isCompleted) {
              completer.complete(false);
            }
          });
          
          // For demo, we'll prompt user to enter address
          _showAddressPrompt().then((address) {
            if (address != null && address.isNotEmpty) {
              _walletAddress = address;
              _chainId = 8453; // Base network
              _currentNetwork = EVMNetwork.base;
              completer.complete(true);
            } else {
              completer.complete(false);
            }
          });
          
          return await completer.future;
        } else {
          // Coinbase Wallet not installed
          if (navigatorKey.currentContext != null) {
            ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
              const SnackBar(
                content: Text('Coinbase Wallet app not installed. Please install the Coinbase Wallet app.'),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 5),
              ),
            );
          }
          return false;
        }
      }
    } catch (e) {
      debugPrint('Error connecting to Coinbase Wallet: $e');
      return false;
    }
  }
  
  // Disconnect wallet
  Future<bool> disconnectWallet() async {
    try {
      if (kIsWeb && _isConnected) {
        // Use the Web3JsBridge to disconnect
        final result = await Web3JsBridge.disconnectWallet();
        if (result['success'] != true) {
          debugPrint('Error disconnecting wallet via JS bridge: ${result['error']}');
        }
      }
      
      // Reset all wallet state
      _isConnected = false;
      _walletAddress = null;
      _connectedWalletType = null;
      _transactionStatus = {};
      
      // Clear saved connection state
      await _clearConnectionState();
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error disconnecting wallet: $e');
      return false;
    }
  }
  
  // Switch network
  Future<bool> switchNetwork(EVMNetwork network) async {
    try {
      if (!_isConnected) return false;
      
      final networkData = _networkConfig[network];
      if (networkData == null) return false;
      
      if (kIsWeb) {
        // Format the chainId as a hex string
        final chainIdHex = '0x${networkData['chainId'].toRadixString(16)}';
        
        // Try to switch to the network using Web3JsBridge
        final result = await Web3JsBridge.switchNetwork(chainIdHex);
        
        if (result['success'] == true) {
          _currentNetwork = network;
          _chainId = networkData['chainId'];
          
          // Save updated state
          await _saveConnectionState();
          
          notifyListeners();
          return true;
        } else if (result['needsToAddNetwork'] == true) {
          // The network needs to be added to the wallet first
          final addNetworkConfig = {
            'chainId': chainIdHex,
            'chainName': networkData['chainName'],
            'rpcUrls': [networkData['rpcUrl']],
            'blockExplorerUrls': [networkData['blockExplorerUrl']],
            'nativeCurrency': networkData['nativeCurrency'],
          };
          
          // Add the network to the wallet
          final addResult = await Web3JsBridge.addNetwork(addNetworkConfig);
          
          if (addResult['success'] == true) {
            _currentNetwork = network;
            _chainId = networkData['chainId'];
            
            // Save updated state
            await _saveConnectionState();
            
            notifyListeners();
            return true;
          } else {
            // Show error if provided
            if (addResult['error'] != null && navigatorKey.currentContext != null) {
              ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
                SnackBar(
                  content: Text('Error adding network: ${addResult['error']}'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.red,
                ),
              );
            }
            return false;
          }
        } else {
          // Show error if provided
          if (result['error'] != null && navigatorKey.currentContext != null) {
            ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
              SnackBar(
                content: Text('Error switching network: ${result['error']}'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.red,
              ),
            );
          }
          return false;
        }
      } else {
        // For demo in non-web environments, we'll simulate success
        await Future.delayed(const Duration(milliseconds: 500));
        
        _currentNetwork = network;
        _chainId = networkData['chainId'];
        
        // Save updated state
        await _saveConnectionState();
        
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error switching network: $e');
      return false;
    }
  }
  
  // Get token balance
  Future<double> getTokenBalance(String tokenSymbol) async {
    try {
      if (!_isConnected || _walletAddress == null) return 0.0;
      
      if (kIsWeb) {
        debugPrint('Getting $tokenSymbol balance for $_walletAddress');
        
        // Get the token contract address based on network and token symbol
        final networkAddresses = _contractAddresses[_currentNetwork];
        if (networkAddresses == null) {
          debugPrint('No contract addresses found for network $_currentNetwork');
          return 0.0;
        }
        
        // Handle native token (ETH) separately
        if (tokenSymbol == 'ETH' || 
            (tokenSymbol == 'MATIC' && _currentNetwork == EVMNetwork.polygon) ||
            (tokenSymbol == 'AVAX' && _currentNetwork == EVMNetwork.avalanche)) {
          debugPrint('Getting native token balance');
          // Get the native token balance through Web3JsBridge
          try {
            final ethBalanceResult = await Web3JsBridge.getNativeBalance(_walletAddress!);
            debugPrint('Native balance result: $ethBalanceResult');
            
            if (ethBalanceResult['success'] == true && ethBalanceResult['balance'] != null) {
              final balanceWei = ethBalanceResult['balance'] as int;
              // Convert from wei (10^18) to ether
              final etherBalance = balanceWei / 1e18;
              debugPrint('ETH balance: $etherBalance');
              return etherBalance;
            } else if (ethBalanceResult['error'] != null) {
              debugPrint('Error getting native balance: ${ethBalanceResult['error']}');
            }
          } catch (e) {
            debugPrint('Exception getting native token balance: $e');
          }
          return 0.0; // Default to zero if there's an error
        }
        
        // For ERC20 tokens, get the contract address
        final tokenAddress = networkAddresses[tokenSymbol];
        if (tokenAddress == null) {
          debugPrint('No contract address found for token $tokenSymbol');
          return 0.0;
        }
        
        debugPrint('Getting ERC20 token balance for $tokenSymbol at $tokenAddress');
        
        // Call the balanceOf method using Web3JsBridge
        final result = await Web3JsBridge.getTokenBalance(tokenAddress, _walletAddress!);
        debugPrint('Token balance result: $result');
        
        if (result['success'] == true && result['balance'] != null) {
          // Convert the balance to a human-readable format
          // The balance is typically returned in the smallest unit
          // We need to divide by 10^decimals to get the actual token amount
          final balance = result['balance'] as num;
          
          // For now, we'll assume all tokens have 18 decimals
          // In a real implementation, you'd get the decimals from the token contract
          final decimals = 18;
          final formattedBalance = balance / (pow(10, decimals));
          
          debugPrint('$tokenSymbol balance: $formattedBalance');
          return formattedBalance.toDouble();
        } else if (result['error'] != null) {
          debugPrint('Error getting token balance: ${result['error']}');
        }
      }
      
      // If not web or if the balance check failed, return zero balance
      return 0.0;
    } catch (e) {
      debugPrint('Exception in getTokenBalance: $e');
      return 0.0;
    }
  }
  
  // Send transaction
  Future<String?> sendTransaction({
    required String to,
    required double amount,
    required String tokenSymbol,
    String? data,
  }) async {
    try {
      if (!_isConnected) return null;
      
      // Check if it's native token (ETH, MATIC, etc.) or ERC20
      final isNativeToken = tokenSymbol == _networkConfig[_currentNetwork]?['nativeCurrency']['symbol'];
      
      if (kIsWeb) {
        if (isNativeToken) {
          // For native token (ETH), convert amount to wei (18 decimals)
          final amountInWei = BigInt.from(amount * 1e18).toString();
          final hexAmountInWei = '0x${BigInt.parse(amountInWei).toRadixString(16)}';
          
          // Call the sendTransaction method using Web3JsBridge
          final result = await Web3JsBridge.sendTransaction(
            to,
            hexAmountInWei,
            data ?? '0x',
          );
          
          if (result['success'] == true && result['txHash'] != null) {
            final txHash = result['txHash'] as String;
            
            // Track transaction status
            _transactionStatus[txHash] = 'pending';
            notifyListeners();
            
            // In a real implementation, you'd listen for transaction confirmation
            // For demo, we'll simulate it
            Future.delayed(const Duration(seconds: 3), () {
              _transactionStatus[txHash] = 'confirmed';
              notifyListeners();
            });
            
            return txHash;
          } else {
            // Show error if provided
            if (result['error'] != null && navigatorKey.currentContext != null) {
              ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
                SnackBar(
                  content: Text('Transaction error: ${result['error']}'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.red,
                ),
              );
            }
            return null;
          }
        } else {
          // For ERC20 tokens, we need to call the token contract's transfer method
          // This would require creating the contract instance and calling its methods
          // For demo purposes, we'll just simulate it
          
          // In a real implementation, you would:
          // 1. Get the token contract address
          // 2. Create the transaction data for the ERC20 transfer function
          // 3. Send the transaction
          
          // Simulate a successful transaction
          await Future.delayed(const Duration(seconds: 1));
          final txHash = '0x${List.generate(64, (_) => '0123456789ABCDEF'[DateTime.now().microsecond % 16]).join()}';
          
          // Track transaction status
          _transactionStatus[txHash] = 'pending';
          notifyListeners();
          
          // Simulate transaction confirmation
          Future.delayed(const Duration(seconds: 3), () {
            _transactionStatus[txHash] = 'confirmed';
            notifyListeners();
          });
          
          return txHash;
        }
      } else {
        // For non-web platforms, simulate a transaction
        await Future.delayed(const Duration(seconds: 1));
        final txHash = '0x${List.generate(64, (_) => '0123456789ABCDEF'[DateTime.now().microsecond % 16]).join()}';
        
        // Track transaction status
        _transactionStatus[txHash] = 'pending';
        notifyListeners();
        
        // Simulate transaction confirmation
        Future.delayed(const Duration(seconds: 3), () {
          _transactionStatus[txHash] = 'confirmed';
          notifyListeners();
        });
        
        return txHash;
      }
    } catch (e) {
      debugPrint('Error sending transaction: $e');
      return null;
    }
  }
  
  // Sign message for authentication
  Future<String?> signMessage(String message) async {
    try {
      if (!_isConnected) return null;
      
      // In a real implementation, you would:
      // 1. Use the personal_sign method for web3 providers
      // 2. For WalletConnect, use the signPersonalMessage method
      
      // For demo, generate a mock signature
      await Future.delayed(const Duration(milliseconds: 800));
      return '0x${List.generate(130, (_) => '0123456789ABCDEF'[DateTime.now().microsecond % 16]).join()}';
    } catch (e) {
      print('Error signing message: $e');
      return null;
    }
  }
  
  // Get transaction receipt
  Future<Map<String, dynamic>?> getTransactionReceipt(String txHash) async {
    try {
      if (!_isConnected) return null;
      
      // In a real implementation, you would:
      // 1. Call eth_getTransactionReceipt RPC method
      
      // For demo, return a mock receipt
      final status = _transactionStatus[txHash] ?? 'unknown';
      
      return {
        'transactionHash': txHash,
        'status': status == 'confirmed' ? '0x1' : '0x0',
        'blockNumber': '0x${(DateTime.now().millisecondsSinceEpoch ~/ 1000).toRadixString(16)}',
        'blockHash': '0x${List.generate(64, (_) => '0123456789ABCDEF'[DateTime.now().microsecond % 16]).join()}',
        'from': _walletAddress,
        'to': '0x${List.generate(40, (_) => '0123456789ABCDEF'[DateTime.now().microsecond % 16]).join()}',
        'gasUsed': '0x${(100000).toRadixString(16)}',
      };
    } catch (e) {
      print('Error getting transaction receipt: $e');
      return null;
    }
  }
  
  // Get transaction history
  Future<List<Map<String, dynamic>>> getTransactionHistory() async {
    try {
      if (!_isConnected) return [];
      
      // In a real implementation, you would:
      // 1. Call an indexer API like Etherscan, The Graph, or Covalent
      
      // For demo, return mock transactions
      return List.generate(
        5,
        (index) {
          final timestamp = DateTime.now().subtract(Duration(days: index));
          final isEven = index % 2 == 0;
          
          return {
            'hash': '0x${List.generate(64, (_) => '0123456789ABCDEF'[(index + DateTime.now().microsecond) % 16]).join()}',
            'from': isEven ? _walletAddress : '0x${List.generate(40, (_) => '0123456789ABCDEF'[(index + 3) % 16]).join()}',
            'to': isEven ? '0x${List.generate(40, (_) => '0123456789ABCDEF'[(index + 7) % 16]).join()}' : _walletAddress,
            'value': isEven ? '0x0' : '0x${(index * 1000000000000000).toRadixString(16)}',
            'tokenSymbol': index % 3 == 0 ? 'ETH' : (index % 3 == 1 ? 'USDC' : 'PRED'),
            'tokenValue': index % 3 == 0 ? 0.1 * (index + 1) : (index % 3 == 1 ? 100.0 * (index + 1) : 50.0 * (index + 1)),
            'timestamp': timestamp.millisecondsSinceEpoch,
            'status': index == 0 ? 'pending' : 'confirmed',
            'blockNumber': index == 0 ? null : '0x${(DateTime.now().millisecondsSinceEpoch ~/ 1000 - index * 100).toRadixString(16)}',
          };
        },
      );
    } catch (e) {
      print('Error getting transaction history: $e');
      return [];
    }
  }
  
  // Persistence methods
  Future<void> _saveConnectionState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('web3_connected', _isConnected);
      if (_walletAddress != null) {
        await prefs.setString('web3_address', _walletAddress!);
      }
      if (_connectedWalletType != null) {
        await prefs.setInt('web3_wallet_type', _connectedWalletType!.index);
      }
      await prefs.setInt('web3_network', _currentNetwork.index);
      await prefs.setInt('web3_chain_id', _chainId);
    } catch (e) {
      print('Error saving web3 connection state: $e');
    }
  }
  
  Future<void> loadSavedConnection() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isConnected = prefs.getBool('web3_connected') ?? false;
      
      if (isConnected) {
        final walletAddress = prefs.getString('web3_address');
        final walletTypeIndex = prefs.getInt('web3_wallet_type');
        final networkIndex = prefs.getInt('web3_network') ?? EVMNetwork.base.index;
        final chainId = prefs.getInt('web3_chain_id') ?? 8453;
        
        if (walletAddress != null && walletTypeIndex != null) {
          _isConnected = true;
          _walletAddress = walletAddress;
          _connectedWalletType = Web3WalletType.values[walletTypeIndex];
          _currentNetwork = EVMNetwork.values[networkIndex];
          _chainId = chainId;
          
          notifyListeners();
        }
      }
    } catch (e) {
      print('Error loading web3 saved connection: $e');
    }
  }
  
  Future<void> _clearConnectionState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('web3_connected');
      await prefs.remove('web3_address');
      await prefs.remove('web3_wallet_type');
      await prefs.remove('web3_network');
      await prefs.remove('web3_chain_id');
    } catch (e) {
      print('Error clearing web3 connection state: $e');
    }
  }
  
  // Get public config for current network
  Map<String, dynamic>? getNetworkConfig() {
    return _networkConfig[_currentNetwork];
  }
  
  // Get formatted wallet address display
  String getFormattedAddress() {
    if (_walletAddress == null || _walletAddress!.isEmpty) {
      return '';
    }
    
    if (_walletAddress!.length < 10) {
      return _walletAddress!;
    }
    
    return '${_walletAddress!.substring(0, 6)}...${_walletAddress!.substring(_walletAddress!.length - 4)}';
  }
  
  // Get wallet icon
  IconData getWalletIcon() {
    switch (_connectedWalletType) {
      case Web3WalletType.metamask:
        return Icons.pets; // Fox icon as a placeholder for MetaMask
      case Web3WalletType.walletConnect:
        return Icons.link;
      case Web3WalletType.coinbase:
        return Icons.account_balance_wallet;
      case Web3WalletType.trustWallet:
        return Icons.security;
      case Web3WalletType.rainbow:
        return Icons.art_track;
      case Web3WalletType.argent:
        return Icons.shield;
      case Web3WalletType.ledger:
        return Icons.memory;
      default:
        return Icons.account_balance_wallet;
    }
  }
  
  // Get network icon
  IconData getNetworkIcon() {
    switch (_currentNetwork) {
      case EVMNetwork.ethereum:
        return Icons.currency_exchange;
      case EVMNetwork.polygon:
        return Icons.hexagon;
      case EVMNetwork.base:
        return Icons.circle;
      case EVMNetwork.arbitrum:
        return Icons.blur_circular;
      case EVMNetwork.optimism:
        return Icons.tonality;
      case EVMNetwork.avalanche:
        return Icons.ac_unit;
      default:
        return Icons.circle;
    }
  }
}