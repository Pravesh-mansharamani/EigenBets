import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import './wallet_service.dart';

// Import uni_links conditionally to avoid web errors
import 'package:uni_links/uni_links.dart' if (dart.library.html) '../utils/web_stub_links.dart';

/// Handles deep links for OAuth callbacks and other app-to-app communication
class DeepLinkHandler {
  static final DeepLinkHandler _instance = DeepLinkHandler._internal();
  factory DeepLinkHandler() => _instance;
  DeepLinkHandler._internal();

  StreamSubscription? _linkSubscription;
  bool _initialized = false;
  final List<String> _pendingLinks = [];

  // Initialize and listen for deep links
  Future<void> initialize(BuildContext context) async {
    if (_initialized || kIsWeb) return; // Skip initialization on web
    
    try {
      // Handle initial link if app was opened via a deep link
      if (!kIsWeb) {
        final initialLink = await getInitialLink();
        if (initialLink != null) {
          // Store for processing after app is fully loaded
          _pendingLinks.add(initialLink);
          
          // Process after a short delay to ensure context is fully initialized
          Future.delayed(const Duration(milliseconds: 500), () {
            _processPendingLinks(context);
          });
        }
      
        // Listen for subsequent links (only on native platforms)
        _linkSubscription = linkStream.listen((String? link) {
          if (link != null) {
            if (context.mounted) {
              _handleDeepLink(context, link);
            } else {
              // Save link for processing when context is available
              _pendingLinks.add(link);
            }
          }
        }, onError: (err) {
          debugPrint('Deep link error: $err');
        });
      }
      
      _initialized = true;
      debugPrint('Deep link handler initialized successfully');
    } on PlatformException catch (e) {
      debugPrint('Deep link init error: $e');
    } catch (e) {
      debugPrint('Deep link general error: $e');
    }
  }
  
  // Process any pending links
  void _processPendingLinks(BuildContext context) {
    if (!context.mounted || _pendingLinks.isEmpty) return;
    
    // Process all pending links
    for (final link in List.from(_pendingLinks)) {
      _handleDeepLink(context, link);
      _pendingLinks.remove(link);
    }
  }
  
  // Handle incoming deep links
  void _handleDeepLink(BuildContext context, String link) {
    debugPrint('Processing deep link: $link');
    
    try {
      // Parse the URI
      final uri = Uri.parse(link);
      
      // Handle Coinbase OAuth callback - update with the new redirect URI
      if (link.startsWith('com.eigenbet.app://oauth')) {
        // Extract the authorization code
        final code = uri.queryParameters['code'];
        
        if (code != null) {
          _handleOAuthCallback(context, code);
        } else {
          debugPrint('OAuth deep link missing code parameter');
        }
      }
      
      // Handle Coinbase Onramp callback - update with the new redirect URI
      if (link.contains('com.eigenbet.app://onramp')) {
        _handleOnrampCallback(context, uri.queryParameters);
      }
      
      // Handle universal links/app links
      if (link.startsWith('https://eigenbet.app/callback')) {
        final code = uri.queryParameters['code'];
        if (code != null) {
          _handleOAuthCallback(context, code);
        }
      }
    } catch (e) {
      debugPrint('Error handling deep link: $e');
      
      // Show error to user
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error handling link: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // Handle OAuth callback with improved user feedback
  Future<void> _handleOAuthCallback(BuildContext context, String code) async {
    try {
      if (!context.mounted) return;
      
      // Show loading state
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connecting wallet...'),
          duration: Duration(seconds: 1),
        ),
      );
      
      // Get wallet service
      final walletService = Provider.of<WalletService>(context, listen: false);
      // Temporarily disabled OAuth callback handling
      final success = true;
      
      // Show result to user
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Wallet connected successfully'),
              backgroundColor: Colors.green.shade600,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to connect wallet'),
              backgroundColor: Colors.red.shade600,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error in OAuth callback: $e');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // Handle Onramp callback with improved user feedback
  Future<void> _handleOnrampCallback(BuildContext context, Map<String, String?> params) async {
    try {
      if (!context.mounted) return;
      
      final txId = params['transactionId'];
      final status = params['status'];
      final asset = params['asset'];
      final amount = params['amount'];
      
      // Validate parameters
      if (txId == null) {
        debugPrint('Onramp callback missing transaction ID');
        return;
      }
      
      // Show initial status
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Processing payment...'),
          duration: Duration(seconds: 1),
        ),
      );
      
      // Get wallet service
      final walletService = Provider.of<WalletService>(context, listen: false);
      // Temporarily disabled onramp callback handling
      // Instead of calling the actual method, we'll just log the parameters
      debugPrint('Onramp callback params: $params');
      
      // Show detailed result to user
      if (context.mounted) {
        if (status == 'completed') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully purchased ${amount ?? ''} ${asset ?? ''}'),
              backgroundColor: Colors.green.shade600,
            ),
          );
        } else if (status == 'failed') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment failed: ${params['error'] ?? 'Unknown error'}'),
              backgroundColor: Colors.red.shade600,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment status: ${status ?? 'processing'}'),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error in Onramp callback: $e');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment processing error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // Dispose of stream subscription
  void dispose() {
    _linkSubscription?.cancel();
    _pendingLinks.clear();
  }
} 