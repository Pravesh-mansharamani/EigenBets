// wallet_service.dart

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3dart/web3dart.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:ed25519_hd_key/ed25519_hd_key.dart';
import 'package:hex/hex.dart';

class WalletService with ChangeNotifier {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final String _privateKeyKey = 'private_key';
  final String _mnemonicKey = 'mnemonic';
  final String _hasWalletKey = 'has_wallet';
  
  String _privateKey = '';
  String _address = '';
  String _mnemonic = '';
  bool _isInitialized = false;
  
  String get privateKey => _privateKey;
  String get address => _address;
  String get mnemonic => _mnemonic;
  bool get isInitialized => _isInitialized;
  bool get hasWallet => _address.isNotEmpty;
  
  // Initialize wallet service
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasWallet = prefs.getBool(_hasWalletKey) ?? false;
      
      if (hasWallet) {
        await _loadWallet();
      }
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print('Error initializing wallet service: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }
  
  // Create a new wallet
  Future<void> createWallet() async {
    try {
      // Generate a new mnemonic
      final mnemonic = bip39.generateMnemonic();
      
      // Derive private key from mnemonic
      final seed = bip39.mnemonicToSeedHex(mnemonic);
      final root = await ED25519_HD_KEY.derivePath("m/44'/60'/0'/0/0", seed);
      final privateKey = HEX.encode(root.key);
      
      // Create credentials and extract address
      final credentials = EthPrivateKey.fromHex(privateKey);
      final address = await credentials.extractAddress();
      
      // Save wallet information
      await _secureStorage.write(key: _privateKeyKey, value: privateKey);
      await _secureStorage.write(key: _mnemonicKey, value: mnemonic);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hasWalletKey, true);
      
      // Update state
      _privateKey = privateKey;
      _address = address.hex;
      _mnemonic = mnemonic;
      
      notifyListeners();
    } catch (e) {
      print('Error creating wallet: $e');
      rethrow;
    }
  }
  
  // Import wallet from mnemonic
  Future<void> importFromMnemonic(String mnemonic) async {
    try {
      if (!bip39.validateMnemonic(mnemonic)) {
        throw Exception('Invalid mnemonic phrase');
      }
      
      // Derive private key from mnemonic
      final seed = bip39.mnemonicToSeedHex(mnemonic);
      final root = await ED25519_HD_KEY.derivePath("m/44'/60'/0'/0/0", seed);
      final privateKey = HEX.encode(root.key);
      
      // Create credentials and extract address
      final credentials = EthPrivateKey.fromHex(privateKey);
      final address = await credentials.extractAddress();
      
      // Save wallet information
      await _secureStorage.write(key: _privateKeyKey, value: privateKey);
      await _secureStorage.write(key: _mnemonicKey, value: mnemonic);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hasWalletKey, true);
      
      // Update state
      _privateKey = privateKey;
      _address = address.hex;
      _mnemonic = mnemonic;
      
      notifyListeners();
    } catch (e) {
      print('Error importing wallet from mnemonic: $e');
      rethrow;
    }
  }
  
  // Import wallet from private key
  Future<void> importFromPrivateKey(String privateKey) async {
    try {
      // Validate private key format
      if (!privateKey.startsWith('0x')) {
        privateKey = '0x$privateKey';
      }
      
      if (privateKey.length != 66 && privateKey.length != 64) {
        throw Exception('Invalid private key format');
      }
      
      // Clean up the private key if needed
      if (privateKey.startsWith('0x')) {
        privateKey = privateKey.substring(2);
      }
      
      // Create credentials and extract address
      final credentials = EthPrivateKey.fromHex(privateKey);
      final address = await credentials.extractAddress();
      
      // Save wallet information
      await _secureStorage.write(key: _privateKeyKey, value: privateKey);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hasWalletKey, true);
      
      // Update state
      _privateKey = privateKey;
      _address = address.hex;
      _mnemonic = ''; // No mnemonic when importing from private key
      
      notifyListeners();
    } catch (e) {
      print('Error importing wallet from private key: $e');
      rethrow;
    }
  }
  
  // Load wallet from secure storage
  Future<void> _loadWallet() async {
    try {
      final privateKey = await _secureStorage.read(key: _privateKeyKey);
      final mnemonic = await _secureStorage.read(key: _mnemonicKey);
      
      if (privateKey == null) {
        throw Exception('No private key found');
      }
      
      // Create credentials and extract address
      final credentials = EthPrivateKey.fromHex(privateKey);
      final address = await credentials.extractAddress();
      
      // Update state
      _privateKey = privateKey;
      _address = address.hex;
      _mnemonic = mnemonic ?? '';
    } catch (e) {
      print('Error loading wallet: $e');
      rethrow;
    }
  }
  
  // Sign a message with the private key
  Future<String> signMessage(String message) async {
    try {
      final credentials = EthPrivateKey.fromHex(_privateKey);
      final signature = await credentials.signPersonalMessage(
        message.codeUnits,
      );
      return HEX.encode(signature);
    } catch (e) {
      print('Error signing message: $e');
      rethrow;
    }
  }
  
  // Clear wallet data (logout)
  Future<void> clearWallet() async {
    try {
      await _secureStorage.delete(key: _privateKeyKey);
      await _secureStorage.delete(key: _mnemonicKey);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hasWalletKey, false);
      
      _privateKey = '';
      _address = '';
      _mnemonic = '';
      
      notifyListeners();
    } catch (e) {
      print('Error clearing wallet: $e');
      rethrow;
    }
  }
}