import 'dart:async';
import 'dart:convert';
import 'package:js/js.dart';
import 'dart:js_util' as js_util;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A utility class to bridge Flutter and JavaScript for Web3 wallet interactions
/// This allows the app to directly connect to wallets like MetaMask when running in a browser
class Web3JsBridge {
  // Check if we're running in a browser environment where JS interop is available
  static bool get isSupported => kIsWeb;
  
  // JS code to be injected into the page for wallet integration
  static const String _web3JsInjectScript = '''
    // Wait for window.ethereum to be injected by Metamask
    window.addEventListener('load', async () => {
      console.log("Web3JsBridge script loaded");
      // Store connection status
      window.walletConnected = false;
      window.walletAddress = null;
      window.walletChainId = null;
      window.walletType = null;
      
      // Check for providers
      window.hasMetaMask = (typeof window.ethereum !== 'undefined');
      window.hasCoinbaseWallet = (typeof window.coinbaseWalletExtension !== 'undefined');
      window.hasWalletConnect = false; // Would need to load the WalletConnect SDK
      
      // Function to check if the wallet is connected
      window.isWalletConnected = () => {
        return window.walletConnected;
      };
      
      // Function to get wallet address
      window.getWalletAddress = () => {
        return window.walletAddress;
      };
      
      // Function to get chain ID
      window.getChainId = () => {
        return window.walletChainId;
      };
      
      // Function to connect to MetaMask
      window.connectMetaMask = async () => {
        if (!window.hasMetaMask) {
          return { success: false, error: 'MetaMask not installed' };
        }
        
        try {
          const accounts = await window.ethereum.request({ 
            method: 'eth_requestAccounts' 
          });
          
          if (accounts && accounts.length > 0) {
            window.walletConnected = true;
            window.walletAddress = accounts[0];
            window.walletType = 'metamask';
            
            // Get the chain ID
            window.walletChainId = await window.ethereum.request({
              method: 'eth_chainId'
            });
            
            // Listen for account changes
            window.ethereum.on('accountsChanged', (accounts) => {
              if (accounts.length === 0) {
                window.walletConnected = false;
                window.walletAddress = null;
              } else {
                window.walletAddress = accounts[0];
              }
            });
            
            // Listen for chain changes
            window.ethereum.on('chainChanged', (chainId) => {
              window.walletChainId = chainId;
            });
            
            return { 
              success: true, 
              address: accounts[0],
              chainId: window.walletChainId
            };
          } else {
            return { success: false, error: 'No accounts found' };
          }
        } catch (error) {
          return { success: false, error: error.message };
        }
      };
      
      // Function to connect to Coinbase Wallet
      window.connectCoinbaseWallet = async () => {
        if (!window.hasCoinbaseWallet) {
          return { success: false, error: 'Coinbase Wallet not installed' };
        }
        
        try {
          const accounts = await window.coinbaseWalletExtension.request({ 
            method: 'eth_requestAccounts' 
          });
          
          if (accounts && accounts.length > 0) {
            window.walletConnected = true;
            window.walletAddress = accounts[0];
            window.walletType = 'coinbase';
            
            // Get the chain ID
            window.walletChainId = await window.coinbaseWalletExtension.request({
              method: 'eth_chainId'
            });
            
            // Listen for account changes
            window.coinbaseWalletExtension.on('accountsChanged', (accounts) => {
              if (accounts.length === 0) {
                window.walletConnected = false;
                window.walletAddress = null;
              } else {
                window.walletAddress = accounts[0];
              }
            });
            
            // Listen for chain changes
            window.coinbaseWalletExtension.on('chainChanged', (chainId) => {
              window.walletChainId = chainId;
            });
            
            return { 
              success: true, 
              address: accounts[0],
              chainId: window.walletChainId
            };
          } else {
            return { success: false, error: 'No accounts found' };
          }
        } catch (error) {
          return { success: false, error: error.message };
        }
      };
      
      // Function to switch networks
      window.switchNetwork = async (chainId) => {
        if (!window.walletConnected) {
          return { success: false, error: 'No wallet connected' };
        }
        
        let provider;
        if (window.walletType === 'metamask') {
          provider = window.ethereum;
        } else if (window.walletType === 'coinbase') {
          provider = window.coinbaseWalletExtension;
        } else {
          return { success: false, error: 'Unsupported wallet type' };
        }
        
        try {
          await provider.request({
            method: 'wallet_switchEthereumChain',
            params: [{ chainId: chainId }],
          });
          
          window.walletChainId = chainId;
          return { success: true };
        } catch (error) {
          // This error code indicates that the chain has not been added to the wallet yet
          if (error.code === 4902) {
            return { 
              success: false, 
              error: 'Network not added to wallet',
              needsToAddNetwork: true
            };
          }
          
          return { success: false, error: error.message };
        }
      };
      
      // Function to add a new network
      window.addNetwork = async (networkConfig) => {
        if (!window.walletConnected) {
          return { success: false, error: 'No wallet connected' };
        }
        
        let provider;
        if (window.walletType === 'metamask') {
          provider = window.ethereum;
        } else if (window.walletType === 'coinbase') {
          provider = window.coinbaseWalletExtension;
        } else {
          return { success: false, error: 'Unsupported wallet type' };
        }
        
        try {
          await provider.request({
            method: 'wallet_addEthereumChain',
            params: [networkConfig],
          });
          
          // After adding, try to switch to the network
          return await window.switchNetwork(networkConfig.chainId);
        } catch (error) {
          return { success: false, error: error.message };
        }
      };
      
      // Function to get token balance
      window.getTokenBalance = async (tokenAddress, ownerAddress) => {
        if (!window.walletConnected) {
          return { success: false, error: 'No wallet connected' };
        }
        
        let provider;
        if (window.walletType === 'metamask') {
          provider = window.ethereum;
        } else if (window.walletType === 'coinbase') {
          provider = window.coinbaseWalletExtension;
        } else {
          return { success: false, error: 'Unsupported wallet type' };
        }
        
        try {
          console.log("Getting token balance for:", ownerAddress, "token:", tokenAddress);
          
          // Call the ERC20 balanceOf method
          const balanceOfAbi = 
            "0x70a08231000000000000000000000000" + 
            ownerAddress.replace(/^0x/, '');
          
          const result = await provider.request({
            method: 'eth_call',
            params: [
              {
                to: tokenAddress,
                data: balanceOfAbi
              },
              'latest'
            ]
          });
          
          console.log("Token balance result:", result);
          
          // Convert result from hex to decimal
          const balance = parseInt(result, 16);
          
          return { success: true, balance: balance };
        } catch (error) {
          console.error("Error getting token balance:", error);
          return { success: false, error: error.message };
        }
      };
      
      // Function to sign a message
      window.signMessage = async (message) => {
        if (!window.walletConnected) {
          return { success: false, error: 'No wallet connected' };
        }
        
        let provider;
        if (window.walletType === 'metamask') {
          provider = window.ethereum;
        } else if (window.walletType === 'coinbase') {
          provider = window.coinbaseWalletExtension;
        } else {
          return { success: false, error: 'Unsupported wallet type' };
        }
        
        try {
          const signature = await provider.request({
            method: 'personal_sign',
            params: [message, window.walletAddress]
          });
          
          return { success: true, signature: signature };
        } catch (error) {
          return { success: false, error: error.message };
        }
      };
      
      // Function to send a transaction
      window.sendTransaction = async (toAddress, value, data) => {
        if (!window.walletConnected) {
          return { success: false, error: 'No wallet connected' };
        }
        
        let provider;
        if (window.walletType === 'metamask') {
          provider = window.ethereum;
        } else if (window.walletType === 'coinbase') {
          provider = window.coinbaseWalletExtension;
        } else {
          return { success: false, error: 'Unsupported wallet type' };
        }
        
        try {
          const params = {
            from: window.walletAddress,
            to: toAddress,
            value: value,
            data: data
          };
          
          const txHash = await provider.request({
            method: 'eth_sendTransaction',
            params: [params]
          });
          
          return { success: true, txHash: txHash };
        } catch (error) {
          return { success: false, error: error.message };
        }
      };
      
      // Function to disconnect the wallet
      window.disconnectWallet = async () => {
        window.walletConnected = false;
        window.walletAddress = null;
        window.walletChainId = null;
        window.walletType = null;
        return { success: true };
      };
    });
  ''';
  
  // Initialize the Web3 JS bridge by injecting the script
  static Future<void> initialize() async {
    if (!isSupported) return;
    
    try {
      // Use js_util to inject the script
      js_util.callMethod(
        js_util.globalThis,
        'eval',
        [_web3JsInjectScript],
      );
      
      // Add a small delay to let the script initialize
      await Future.delayed(const Duration(milliseconds: 500));
      
      debugPrint('Web3JsBridge initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize Web3JsBridge: $e');
    }
  }
  
  // Check if MetaMask is available
  static Future<bool> hasMetaMask() async {
    if (!isSupported) return false;
    
    try {
      return js_util.getProperty(js_util.globalThis, 'hasMetaMask');
    } catch (e) {
      debugPrint('Error checking MetaMask availability: $e');
      return false;
    }
  }
  
  // Check if Coinbase Wallet is available
  static Future<bool> hasCoinbaseWallet() async {
    if (!isSupported) return false;
    
    try {
      return js_util.getProperty(js_util.globalThis, 'hasCoinbaseWallet');
    } catch (e) {
      debugPrint('Error checking Coinbase Wallet availability: $e');
      return false;
    }
  }
  
  // Connect to MetaMask
  static Future<Map<String, dynamic>> connectMetaMask() async {
    if (!isSupported) {
      return {'success': false, 'error': 'Not running in a web browser'};
    }
    
    try {
      final result = await js_util.promiseToFuture(
        js_util.callMethod(js_util.globalThis, 'connectMetaMask', [])
      );
      
      final dartResult = js_util.dartify(result);
      return dartResult is Map ? Map<String, dynamic>.from(dartResult) : {'success': false, 'error': 'Unexpected result type'};
    } catch (e) {
      debugPrint('Error connecting to MetaMask: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
  
  // Connect to Coinbase Wallet
  static Future<Map<String, dynamic>> connectCoinbaseWallet() async {
    if (!isSupported) {
      return {'success': false, 'error': 'Not running in a web browser'};
    }
    
    try {
      final result = await js_util.promiseToFuture(
        js_util.callMethod(js_util.globalThis, 'connectCoinbaseWallet', [])
      );
      
      final dartResult = js_util.dartify(result);
      return dartResult is Map ? Map<String, dynamic>.from(dartResult) : {'success': false, 'error': 'Unexpected result type'};
    } catch (e) {
      debugPrint('Error connecting to Coinbase Wallet: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
  
  // Switch network
  static Future<Map<String, dynamic>> switchNetwork(String chainId) async {
    if (!isSupported) {
      return {'success': false, 'error': 'Not running in a web browser'};
    }
    
    try {
      final result = await js_util.promiseToFuture(
        js_util.callMethod(js_util.globalThis, 'switchNetwork', [chainId])
      );
      
      final dartResult = js_util.dartify(result);
      return dartResult is Map ? Map<String, dynamic>.from(dartResult) : {'success': false, 'error': 'Unexpected result type'};
    } catch (e) {
      debugPrint('Error switching network: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
  
  // Add network
  static Future<Map<String, dynamic>> addNetwork(Map<String, dynamic> networkConfig) async {
    if (!isSupported) {
      return {'success': false, 'error': 'Not running in a web browser'};
    }
    
    try {
      final result = await js_util.promiseToFuture(
        js_util.callMethod(
          js_util.globalThis, 
          'addNetwork', 
          [js_util.jsify(networkConfig)]
        )
      );
      
      final dartResult = js_util.dartify(result);
      return dartResult is Map ? Map<String, dynamic>.from(dartResult) : {'success': false, 'error': 'Unexpected result type'};
    } catch (e) {
      debugPrint('Error adding network: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
  
  // Get token balance
  static Future<Map<String, dynamic>> getTokenBalance(String tokenAddress, String ownerAddress) async {
    if (!isSupported) {
      return {'success': false, 'error': 'Not running in a web browser'};
    }
    
    try {
      final result = await js_util.promiseToFuture(
        js_util.callMethod(
          js_util.globalThis, 
          'getTokenBalance', 
          [tokenAddress, ownerAddress]
        )
      );
      
      final dartResult = js_util.dartify(result);
      return dartResult is Map ? Map<String, dynamic>.from(dartResult) : {'success': false, 'error': 'Unexpected result type'};
    } catch (e) {
      debugPrint('Error getting token balance: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
  
  // Get native ETH balance
  static Future<Map<String, dynamic>> getNativeBalance(String address) async {
    if (!isSupported) {
      return {'success': false, 'error': 'Not running in a web browser'};
    }
    
    try {
      final result = await js_util.promiseToFuture(
        js_util.callMethod(
          js_util.globalThis, 
          'getNativeBalance', 
          [address]
        )
      );
      
      final dartResult = js_util.dartify(result);
      return dartResult is Map ? Map<String, dynamic>.from(dartResult) : {'success': false, 'error': 'Unexpected result type'};
    } catch (e) {
      debugPrint('Error getting native balance: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
  
  // Sign message
  static Future<Map<String, dynamic>> signMessage(String message) async {
    if (!isSupported) {
      return {'success': false, 'error': 'Not running in a web browser'};
    }
    
    try {
      final result = await js_util.promiseToFuture(
        js_util.callMethod(js_util.globalThis, 'signMessage', [message])
      );
      
      final dartResult = js_util.dartify(result);
      return dartResult is Map ? Map<String, dynamic>.from(dartResult) : {'success': false, 'error': 'Unexpected result type'};
    } catch (e) {
      debugPrint('Error signing message: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
  
  // Send transaction
  static Future<Map<String, dynamic>> sendTransaction(
    String toAddress, String value, String data
  ) async {
    if (!isSupported) {
      return {'success': false, 'error': 'Not running in a web browser'};
    }
    
    try {
      final result = await js_util.promiseToFuture(
        js_util.callMethod(
          js_util.globalThis, 
          'sendTransaction', 
          [toAddress, value, data]
        )
      );
      
      final dartResult = js_util.dartify(result);
      return dartResult is Map ? Map<String, dynamic>.from(dartResult) : {'success': false, 'error': 'Unexpected result type'};
    } catch (e) {
      debugPrint('Error sending transaction: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
  
  // Disconnect wallet
  static Future<Map<String, dynamic>> disconnectWallet() async {
    if (!isSupported) {
      return {'success': false, 'error': 'Not running in a web browser'};
    }
    
    try {
      final result = await js_util.promiseToFuture(
        js_util.callMethod(js_util.globalThis, 'disconnectWallet', [])
      );
      
      final dartResult = js_util.dartify(result);
      return dartResult is Map ? Map<String, dynamic>.from(dartResult) : {'success': false, 'error': 'Unexpected result type'};
    } catch (e) {
      debugPrint('Error disconnecting wallet: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
  
  // Check if the wallet is connected
  static Future<bool> isWalletConnected() async {
    if (!isSupported) return false;
    
    try {
      // Check if the function exists before calling it
      final hasFunction = js_util.hasProperty(js_util.globalThis, 'isWalletConnected');
      if (!hasFunction) {
        debugPrint('isWalletConnected function not found in global scope');
        return false;
      }
      
      // Call the function and ensure we get a boolean back
      final result = js_util.callMethod(js_util.globalThis, 'isWalletConnected', []);
      return result == true;
    } catch (e) {
      debugPrint('Error checking wallet connection: $e');
      return false;
    }
  }
  
  // Get the connected wallet address
  static Future<String?> getWalletAddress() async {
    if (!isSupported) return null;
    
    try {
      // Check if the function exists before calling it
      final hasFunction = js_util.hasProperty(js_util.globalThis, 'getWalletAddress');
      if (!hasFunction) {
        debugPrint('getWalletAddress function not found in global scope');
        return null;
      }
      
      final result = js_util.callMethod(js_util.globalThis, 'getWalletAddress', []);
      return result?.toString();
    } catch (e) {
      debugPrint('Error getting wallet address: $e');
      return null;
    }
  }
  
  // Get the connected chain ID
  static Future<String?> getChainId() async {
    if (!isSupported) return null;
    
    try {
      // Check if the function exists before calling it
      final hasFunction = js_util.hasProperty(js_util.globalThis, 'getChainId');
      if (!hasFunction) {
        debugPrint('getChainId function not found in global scope');
        return null;
      }
      
      final result = js_util.callMethod(js_util.globalThis, 'getChainId', []);
      return result?.toString();
    } catch (e) {
      debugPrint('Error getting chain ID: $e');
      return null;
    }
  }
}