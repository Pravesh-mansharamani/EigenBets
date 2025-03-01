// prediction_market_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'package:flutter/foundation.dart';

class PredictionMarketService {
  // Contract address
  final String contractAddress = '0x5a1df3b6FAcBBe873a26737d7b1027Ad47834AC0';
  
  // RPC URL - replace with your own Ethereum node URL or Infura
  final String rpcUrl = 'YOUR_RPC_URL';
  
  // USDC contract address - replace with actual USDC address on your network
  final String usdcAddress = 'YOUR_USDC_ADDRESS'; 
  
  // Web3 client
  late Web3Client _client;
  
  // Contract instance
  late DeployedContract _contract;
  
  // User's wallet credentials
  late Credentials _credentials;
  
  // User's Ethereum address
  late EthereumAddress _userAddress;
  
  // USDC contract instance
  late DeployedContract _usdcContract;
  
  // Stream controllers for market data
  final StreamController<Map<String, dynamic>> _marketDataController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  Stream<Map<String, dynamic>> get marketDataStream => _marketDataController.stream;
  
  // Initialize the service
  Future<void> initialize(String privateKey) async {
    // Create Web3 client
    _client = Web3Client(rpcUrl, Client());
    
    // Load contract ABI
    final abiString = await rootBundle.loadString('assets/PredictionMarketHook_abi.json');
    final abi = jsonDecode(abiString);
    
    // Create contract instance
    _contract = DeployedContract(
      ContractAbi.fromJson(jsonEncode(abi), 'PredictionMarketHook'),
      EthereumAddress.fromHex(contractAddress),
    );
    
    // Set up USDC contract
    final usdcAbiString = await rootBundle.loadString('assets/IERC20_abi.json');
    final usdcAbi = jsonDecode(usdcAbiString);
    
    _usdcContract = DeployedContract(
      ContractAbi.fromJson(jsonEncode(usdcAbi), 'IERC20'),
      EthereumAddress.fromHex(usdcAddress),
    );
    
    // Set up user credentials from private key
    _credentials = EthPrivateKey.fromHex(privateKey);
    _userAddress = await _credentials.extractAddress();
    
    // Start periodic updates
    _startPeriodicUpdates();
  }
  
  // Get contract functions
  ContractFunction _getFunction(String name) {
    return _contract.function(name);
  }
  
  ContractFunction _getUSDCFunction(String name) {
    return _usdcContract.function(name);
  }
  
  // Start periodic updates for market data
  void _startPeriodicUpdates() {
    Timer.periodic(Duration(hours: 1), (_) async {
      await _updateMarketData();
    });
    
    // Initial update
    _updateMarketData();
  }
  
  // Update market data
  Future<void> _updateMarketData() async {
    try {
      // Get market state
      final marketState = await _client.call(
        contract: _contract,
        function: _getFunction('getMarketState'),
        params: [],
      );
      
      bool isOpen = marketState[0] as bool;
      bool isClosed = marketState[1] as bool;
      bool isResolved = marketState[2] as bool;
      bool outcome = marketState[3] as bool;
      
      // If market is open, get prices and odds
      Map<String, dynamic> marketData = {
        'isOpen': isOpen,
        'isClosed': isClosed,
        'isResolved': isResolved,
        'outcome': outcome,
      };
      
      if (isOpen && !isResolved) {
        // Get token prices
        final prices = await _client.call(
          contract: _contract,
          function: _getFunction('getTokenPrices'),
          params: [],
        );
        
        // Convert BigInt to double and scale by 1e18
        double yesPrice = (prices[0] as BigInt).toDouble() / 1e18;
        double noPrice = (prices[1] as BigInt).toDouble() / 1e18;
        
        // Get odds
        final odds = await _client.call(
          contract: _contract,
          function: _getFunction('getOdds'),
          params: [],
        );
        
        int yesOdds = (odds[0] as BigInt).toInt();
        int noOdds = (odds[1] as BigInt).toInt();
        
        // Add to market data
        marketData['yesPrice'] = yesPrice;
        marketData['noPrice'] = noPrice;
        marketData['yesOdds'] = yesOdds;
        marketData['noOdds'] = noOdds;
        
        // Get owner
        final owner = await _client.call(
          contract: _contract,
          function: _getFunction('checkOwner'),
          params: [],
        );
        
        marketData['owner'] = (owner[0] as EthereumAddress).hex;
      }
      
      // Push updated data to stream
      _marketDataController.add(marketData);
    } catch (e) {
      print('Error updating market data: $e');
    }
  }
  
  // Get user balances
  Future<Map<String, double>> getUserBalances() async {
    try {
      // Get YES token address
      final yesPoolComponents = await _client.call(
        contract: _contract,
        function: _getFunction('getYesPoolKeyComponents'),
        params: [],
      );
      
      EthereumAddress yesTokenAddress;
      
      // The YES token could be currency0 or currency1 depending on ordering
      Currency currency0 = yesPoolComponents[0] as Currency;
      Currency currency1 = yesPoolComponents[1] as Currency;
      
      // Create a temporary contract to get the YES token balance
      DeployedContract yesTokenContract;
      
      // Create a temporary contract to get the NO token balance
      final noPoolComponents = await _client.call(
        contract: _contract,
        function: _getFunction('getNoPoolKeyComponents'),
        params: [],
      );
      
      EthereumAddress noTokenAddress;
      
      // Similar logic for NO token
      Currency noCurrency0 = noPoolComponents[0] as Currency;
      Currency noCurrency1 = noPoolComponents[1] as Currency;
      
      DeployedContract noTokenContract;
      
      // Find the YES token address by checking which one is not USDC
      EthereumAddress usdcEthAddress = EthereumAddress.fromHex(usdcAddress);
      
      if (currency0.unwrap() != usdcEthAddress) {
        yesTokenAddress = currency0.unwrap();
      } else {
        yesTokenAddress = currency1.unwrap();
      }
      
      if (noCurrency0.unwrap() != usdcEthAddress) {
        noTokenAddress = noCurrency0.unwrap();
      } else {
        noTokenAddress = noCurrency1.unwrap();
      }
      
      // Create token contracts
      yesTokenContract = DeployedContract(
        ContractAbi.fromJson(await rootBundle.loadString('assets/IERC20_abi.json'), 'IERC20'),
        yesTokenAddress,
      );
      
      noTokenContract = DeployedContract(
        ContractAbi.fromJson(await rootBundle.loadString('assets/IERC20_abi.json'), 'IERC20'),
        noTokenAddress,
      );
      
      // Get balances
      final yesBalance = await _client.call(
        contract: yesTokenContract,
        function: yesTokenContract.function('balanceOf'),
        params: [_userAddress],
      );
      
      final noBalance = await _client.call(
        contract: noTokenContract,
        function: noTokenContract.function('balanceOf'),
        params: [_userAddress],
      );
      
      final usdcBalance = await _client.call(
        contract: _usdcContract,
        function: _getUSDCFunction('balanceOf'),
        params: [_userAddress],
      );
      
      // Return formatted balances
      return {
        'yes': (yesBalance[0] as BigInt).toDouble() / 1e18,
        'no': (noBalance[0] as BigInt).toDouble() / 1e18,
        'usdc': (usdcBalance[0] as BigInt).toDouble() / 1e6, // USDC has 6 decimals
      };
    } catch (e) {
      print('Error getting user balances: $e');
      return {'yes': 0, 'no': 0, 'usdc': 0};
    }
  }
  
  // USDC approval for contract interaction
  Future<String> approveUSDC(double amount) async {
    try {
      // Convert amount to wei (accounting for 6 decimals of USDC)
      final amountInWei = BigInt.from(amount * 1e6);
      
      // Create transaction
      final transaction = Transaction.callContract(
        contract: _usdcContract,
        function: _getUSDCFunction('approve'),
        parameters: [EthereumAddress.fromHex(contractAddress), amountInWei],
        from: _userAddress,
      );
      
      // Send transaction
      final txHash = await _client.sendTransaction(
        _credentials,
        transaction,
        chainId: null, // Set your chain ID or leave null for default
      );
      
      return txHash;
    } catch (e) {
      print('Error approving USDC: $e');
      throw e;
    }
  }
  
  // Buy YES tokens with USDC
  Future<String> buyYesTokens(double usdcAmount) async {
    try {
      // Convert amount to wei (accounting for 6 decimals of USDC)
      final amountInWei = BigInt.from(usdcAmount * 1e6);
      
      // Create transaction
      final transaction = Transaction.callContract(
        contract: _contract,
        function: _getFunction('swapUSDCForYesTokens'),
        parameters: [amountInWei],
        from: _userAddress,
      );
      
      // Send transaction
      final txHash = await _client.sendTransaction(
        _credentials,
        transaction,
        chainId: null, // Set your chain ID or leave null for default
      );
      
      return txHash;
    } catch (e) {
      print('Error buying YES tokens: $e');
      throw e;
    }
  }
  
  // Buy NO tokens with USDC
  Future<String> buyNoTokens(double usdcAmount) async {
    try {
      // Convert amount to wei (accounting for 6 decimals of USDC)
      final amountInWei = BigInt.from(usdcAmount * 1e6);
      
      // Create transaction
      final transaction = Transaction.callContract(
        contract: _contract,
        function: _getFunction('swapUSDCForNoTokens'),
        parameters: [amountInWei],
        from: _userAddress,
      );
      
      // Send transaction
      final txHash = await _client.sendTransaction(
        _credentials,
        transaction,
        chainId: null, // Set your chain ID or leave null for default
      );
      
      return txHash;
    } catch (e) {
      print('Error buying NO tokens: $e');
      throw e;
    }
  }
  
  // Sell YES tokens for USDC
  Future<String> sellYesTokens(double tokenAmount) async {
    try {
      // Convert amount to wei (accounting for 18 decimals of tokens)
      final amountInWei = BigInt.from(tokenAmount * 1e18);
      
      // Create transaction
      final transaction = Transaction.callContract(
        contract: _contract,
        function: _getFunction('swapYesTokensForUSDC'),
        parameters: [amountInWei],
        from: _userAddress,
      );
      
      // Send transaction
      final txHash = await _client.sendTransaction(
        _credentials,
        transaction,
        chainId: null, // Set your chain ID or leave null for default
      );
      
      return txHash;
    } catch (e) {
      print('Error selling YES tokens: $e');
      throw e;
    }
  }
  
  // Sell NO tokens for USDC
  Future<String> sellNoTokens(double tokenAmount) async {
    try {
      // Convert amount to wei (accounting for 18 decimals of tokens)
      final amountInWei = BigInt.from(tokenAmount * 1e18);
      
      // Create transaction
      final transaction = Transaction.callContract(
        contract: _contract,
        function: _getFunction('swapNoTokensForUSDC'),
        parameters: [amountInWei],
        from: _userAddress,
      );
      
      // Send transaction
      final txHash = await _client.sendTransaction(
        _credentials,
        transaction,
        chainId: null, // Set your chain ID or leave null for default
      );
      
      return txHash;
    } catch (e) {
      print('Error selling NO tokens: $e');
      throw e;
    }
  }
  
  // Generic swap with slippage protection
  Future<String> swap(
    String tokenInAddress,
    String tokenOutAddress,
    double amountIn,
    double minimumAmountOut
  ) async {
    try {
      // Convert amounts to wei
      BigInt amountInWei;
      if (tokenInAddress.toLowerCase() == usdcAddress.toLowerCase()) {
        // USDC has 6 decimals
        amountInWei = BigInt.from(amountIn * 1e6);
      } else {
        // YES/NO tokens have 18 decimals
        amountInWei = BigInt.from(amountIn * 1e18);
      }
      
      BigInt minAmountOutWei;
      if (tokenOutAddress.toLowerCase() == usdcAddress.toLowerCase()) {
        // USDC has 6 decimals
        minAmountOutWei = BigInt.from(minimumAmountOut * 1e6);
      } else {
        // YES/NO tokens have 18 decimals
        minAmountOutWei = BigInt.from(minimumAmountOut * 1e18);
      }
      
      // Create transaction
      final transaction = Transaction.callContract(
        contract: _contract,
        function: _getFunction('swap'),
        parameters: [
          EthereumAddress.fromHex(tokenInAddress),
          EthereumAddress.fromHex(tokenOutAddress),
          amountInWei,
          minAmountOutWei
        ],
        from: _userAddress,
      );
      
      // Send transaction
      final txHash = await _client.sendTransaction(
        _credentials,
        transaction,
        chainId: null, // Set your chain ID or leave null for default
      );
      
      return txHash;
    } catch (e) {
      print('Error performing swap: $e');
      throw e;
    }
  }
  
  // Claim rewards after market resolution
  Future<String> claimRewards() async {
    try {
      // Create transaction
      final transaction = Transaction.callContract(
        contract: _contract,
        function: _getFunction('claim'),
        parameters: [],
        from: _userAddress,
      );
      
      // Send transaction
      final txHash = await _client.sendTransaction(
        _credentials,
        transaction,
        chainId: null, // Set your chain ID or leave null for default
      );
      
      return txHash;
    } catch (e) {
      print('Error claiming rewards: $e');
      throw e;
    }
  }
  
  // For market admin: Open market
  Future<String> openMarket() async {
    try {
      // Create transaction
      final transaction = Transaction.callContract(
        contract: _contract,
        function: _getFunction('openMarket'),
        parameters: [],
        from: _userAddress,
      );
      
      // Send transaction
      final txHash = await _client.sendTransaction(
        _credentials,
        transaction,
        chainId: null, // Set your chain ID or leave null for default
      );
      
      return txHash;
    } catch (e) {
      print('Error opening market: $e');
      throw e;
    }
  }
  
  // For market admin: Close market
  Future<String> closeMarket() async {
    try {
      // Create transaction
      final transaction = Transaction.callContract(
        contract: _contract,
        function: _getFunction('closeMarket'),
        parameters: [],
        from: _userAddress,
      );
      
      // Send transaction
      final txHash = await _client.sendTransaction(
        _credentials,
        transaction,
        chainId: null, // Set your chain ID or leave null for default
      );
      
      return txHash;
    } catch (e) {
      print('Error closing market: $e');
      throw e;
    }
  }
  
  // For market admin: Resolve outcome
  Future<String> resolveOutcome(bool outcomeIsYes) async {
    try {
      // Create transaction
      final transaction = Transaction.callContract(
        contract: _contract,
        function: _getFunction('resolveOutcome'),
        parameters: [outcomeIsYes],
        from: _userAddress,
      );
      
      // Send transaction
      final txHash = await _client.sendTransaction(
        _credentials,
        transaction,
        chainId: null, // Set your chain ID or leave null for default
      );
      
      return txHash;
    } catch (e) {
      print('Error resolving outcome: $e');
      throw e;
    }
  }
  
  // For market admin: Reset market
  Future<String> resetMarket() async {
    try {
      // Create transaction
      final transaction = Transaction.callContract(
        contract: _contract,
        function: _getFunction('resetMarket'),
        parameters: [],
        from: _userAddress,
      );
      
      // Send transaction
      final txHash = await _client.sendTransaction(
        _credentials,
        transaction,
        chainId: null, // Set your chain ID or leave null for default
      );
      
      return txHash;
    } catch (e) {
      print('Error resetting market: $e');
      throw e;
    }
  }
  
  // Check if user has claimed rewards
  Future<bool> hasUserClaimed() async {
    try {
      final result = await _client.call(
        contract: _contract,
        function: _getFunction('hasClaimed'),
        params: [_userAddress],
      );
      
      return result[0] as bool;
    } catch (e) {
      print('Error checking claim status: $e');
      return false;
    }
  }
  
  // Dispose resources
  void dispose() {
    _client.dispose();
    _marketDataController.close();
  }
}