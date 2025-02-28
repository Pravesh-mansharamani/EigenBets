import 'package:flutter/material.dart';
import 'package:flutter_web3/flutter_web3.dart';

class MetaMaskProvider extends ChangeNotifier {
  // For testing with Ethereum mainnet
  // static const int operatingChain = 1;
  
  // For testing with Base
  static const int operatingChain = 8453; 
  
  String currentAddress = '';
  int currentChain = -1;
  bool _isLoading = false;
  String? _error;
  
  // Getters
  bool get isEnabled => ethereum != null;
  bool get isInOperatingChain => currentChain == operatingChain;
  bool get isConnected => isEnabled && currentAddress.isNotEmpty;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Helper for formatted address display
  String get formattedAddress {
    if (currentAddress.length > 10) {
      return '${currentAddress.substring(0, 6)}...${currentAddress.substring(currentAddress.length - 4)}';
    }
    return currentAddress;
  }
  
  // Connect to MetaMask
  Future<bool> connect() async {
    if (isEnabled) {
      try {
        _setLoading(true);
        _error = null;
        
        print("MetaMask is enabled, requesting account...");
        final accs = await ethereum!.requestAccount();
        print("Accounts received: $accs");
        
        if (accs.isNotEmpty) {
          currentAddress = accs.first;
          print("Current address set to: $currentAddress");
        }
        
        currentChain = await ethereum!.getChainId();
        print("Current chain ID: $currentChain");
        
        _setLoading(false);
        notifyListeners();
        return isConnected;
      } catch (e) {
        print("Error connecting to MetaMask: $e");
        _setError("Failed to connect: ${e.toString()}");
        return false;
      }
    } else {
      _setError("MetaMask is not installed");
      print("MetaMask is not enabled");
      return false;
    }
  }
  
  // Disconnect from MetaMask
  Future<void> disconnect() async {
    _setLoading(true);
    try {
      // There's no direct disconnect method in MetaMask
      // Just clear our local state
      clear();
      _setLoading(false);
    } catch (e) {
      _setError("Error disconnecting: ${e.toString()}");
    }
  }
  
  // Switch network
  Future<bool> switchNetwork(int chainId) async {
    if (isEnabled) {
      try {
        _setLoading(true);
        _error = null;
        
        await ethereum!.walletSwitchChain(chainId);
        currentChain = await ethereum!.getChainId();
        
        _setLoading(false);
        notifyListeners();
        return true;
      } catch (e) {
        print("Error switching chain: $e");
        _setError("Failed to switch network: ${e.toString()}");
        return false;
      }
    }
    _setError("MetaMask is not installed");
    return false;
  }
  
  // Clear wallet state
  void clear() {
    currentAddress = '';
    currentChain = -1;
    _error = null;
    notifyListeners();
  }
  
  // Initialize and setup listeners
  void init() {
    if (isEnabled) {
      // Listen for account changes
      ethereum!.onAccountsChanged((accounts) {
        print("MetaMask accounts changed: $accounts");
        if (accounts.isEmpty) {
          clear();
        } else {
          currentAddress = accounts.first;
          notifyListeners();
        }
      });
      
      // Listen for chain changes
      ethereum!.onChainChanged((chainId) {
        print("MetaMask chain changed to: $chainId");
        currentChain = chainId;
        notifyListeners();
      });
      
      // Check if already connected
      ethereum!.getAccounts().then((accounts) {
        if (accounts.isNotEmpty) {
          currentAddress = accounts.first;
          ethereum!.getChainId().then((chainId) {
            currentChain = chainId;
            notifyListeners();
          });
        }
      }).catchError((e) {
        print("Error checking MetaMask connection: $e");
      });
    }
  }
  
  // Helper methods for state management
  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) {
      _error = null;
    }
    notifyListeners();
  }
  
  void _setError(String? errorMessage) {
    _error = errorMessage;
    _isLoading = false;
    notifyListeners();
  }
}