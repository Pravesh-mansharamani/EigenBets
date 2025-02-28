import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import '../main.dart';
import '../config/api_config.dart';

/// Exception classes for Coinbase CDK
class CdkException implements Exception {
  final String message;
  final int? statusCode;
  final String? response;
  
  CdkException(this.message, {this.statusCode, this.response});
  
  @override
  String toString() => 'CdkException: $message ${statusCode != null ? '(Status: $statusCode)' : ''}';
}

class CdkAuthException extends CdkException {
  CdkAuthException(String message, {int? statusCode, String? response}) 
      : super(message, statusCode: statusCode, response: response);
}

class CdkNetworkException extends CdkException {
  CdkNetworkException(String message) : super(message);
}

class CdkTokenException extends CdkException {
  CdkTokenException(String message) : super(message);
}

/// Service for interacting with Coinbase CDK (Coinbase Developer Kit)
class CoinbaseCdkService extends ChangeNotifier {
  // CDK Configuration from ApiConfig
  final String _cdkApiBase = ApiConfig.cdkApiBaseUrl.endsWith('/') 
      ? ApiConfig.cdkApiBaseUrl 
      : '${ApiConfig.cdkApiBaseUrl}/';
      
  final String _authApiBase = ApiConfig.cdkAuthBaseUrl.endsWith('/') 
      ? ApiConfig.cdkAuthBaseUrl 
      : '${ApiConfig.cdkAuthBaseUrl}/';
  
  // CDK API Keys from config
  final String _apiKey = ApiConfig.cdkApiKey;
  final String _clientId = ApiConfig.cdkClientId;
  final String _clientSecret = ApiConfig.cdkClientSecret;
  final String _redirectUri = ApiConfig.cdkRedirectUri;
  
  // Internal state
  bool _isInitialized = false;
  String? _sessionId;
  String? _accessToken;
  String? _refreshToken;
  String? _walletId;
  int? _tokenExpiresAt;
  
  // Token refresh timer
  Timer? _refreshTimer;
  
  // Public getters
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _accessToken != null;
  
  // Initialize the CDK
  Future<bool> initialize() async {
    try {
      if (kIsWeb) {
        // Web platform has limited CDK support, use alternative approach
        debugPrint('CDK initialization adapted for web platform');
        _isInitialized = true;
        await _loadSession();
        // Check if we have a valid token already
        if (_accessToken != null && _tokenExpiresAt != null) {
          final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
          if (_tokenExpiresAt! > now) {
            _scheduleTokenRefresh();
            return true;
          }
        }
        return true;
      }
      
      if (_isInitialized) return true;
      
      // Load any saved session
      await _loadSession();
      
      // Check if token needs refresh
      if (_accessToken != null && _refreshToken != null && _tokenExpiresAt != null) {
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        if (_tokenExpiresAt! <= now) {
          await _refreshAccessToken();
        } else {
          _scheduleTokenRefresh();
        }
      }
      
      // Initialize CDK client based on the docs
      final response = await http.post(
        Uri.parse('${_cdkApiBase}initialize'),
        headers: {
          'Content-Type': 'application/json',
          'X-API-Key': _apiKey,
          'User-Agent': 'EigenBet-Flutter-App',
        },
        body: jsonEncode({
          'client_id': _clientId,
          'redirect_uri': _redirectUri
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _sessionId = data['session_id'];
        _isInitialized = true;
        _saveSession();
        notifyListeners();
        return true;
      } else {
        final errorMessage = 'CDK initialization failed: ${response.statusCode} ${response.body}';
        debugPrint(errorMessage);
        throw CdkAuthException(
          'Failed to initialize CDK service',
          statusCode: response.statusCode,
          response: response.body
        );
      }
    } catch (e) {
      if (e is CdkException) {
        rethrow;
      }
      debugPrint('Error initializing CDK: $e');
      throw CdkNetworkException('Network error during CDK initialization: $e');
    }
  }
  
  /// Schedule token refresh before it expires
  void _scheduleTokenRefresh() {
    // Cancel any existing timer
    _refreshTimer?.cancel();
    
    if (_tokenExpiresAt == null || _refreshToken == null) return;
    
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final expiresIn = _tokenExpiresAt! - now;
    
    // If token is already expired or expires in less than a minute, refresh now
    if (expiresIn < 60) {
      _refreshAccessToken();
      return;
    }
    
    // Schedule refresh for 5 minutes before expiration
    final refreshIn = expiresIn - 300; // 5 minutes before expiry
    _refreshTimer = Timer(Duration(seconds: refreshIn), () {
      _refreshAccessToken();
    });
  }
  
  /// Refresh the access token using the refresh token
  Future<bool> _refreshAccessToken() async {
    if (_refreshToken == null) return false;
    
    try {
      final response = await http.post(
        Uri.parse('${_authApiBase}token'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'grant_type': 'refresh_token',
          'refresh_token': _refreshToken,
          'client_id': _clientId,
          'client_secret': _clientSecret,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access_token'];
        
        // Some OAuth providers return a new refresh token, some don't
        if (data.containsKey('refresh_token')) {
          _refreshToken = data['refresh_token'];
        }
        
        if (data.containsKey('expires_in')) {
          final expiresIn = data['expires_in'] as int;
          _tokenExpiresAt = DateTime.now().millisecondsSinceEpoch ~/ 1000 + expiresIn;
        }
        
        _saveSession();
        _scheduleTokenRefresh();
        return true;
      } else {
        debugPrint('Token refresh failed: ${response.statusCode} ${response.body}');
        // Clear session on token refresh failure
        _clearSession();
        throw CdkTokenException('Failed to refresh token');
      }
    } catch (e) {
      if (e is CdkException) {
        rethrow;
      }
      debugPrint('Error refreshing token: $e');
      throw CdkNetworkException('Network error during token refresh: $e');
    }
  }
  
  // Generate OAuth URL with proper scopes and PKCE support
  String _getOAuthUrl() {
    // Get all scopes from config
    final scopesStr = ApiConfig.cdkOAuthScopes.join(',');
    
    // Generate PKCE code verifier and challenge if supported
    // For simplicity in this implementation we're using standard flow
    // In production, implement PKCE for additional security
    
    return '${_authApiBase}authorize?'
        'response_type=code&'
        'client_id=$_clientId&'
        'redirect_uri=$_redirectUri&'
        'state=$_sessionId&'
        'scope=$scopesStr';
  }
  
  // Authenticate user with Coinbase account using OAuth flow
  Future<bool> authenticate() async {
    if (!_isInitialized) {
      try {
        await initialize();
      } catch (e) {
        debugPrint('Failed to initialize during authentication: $e');
        return false;
      }
    }
    
    if (_accessToken != null) {
      // Check if token is still valid
      if (_tokenExpiresAt != null) {
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        if (_tokenExpiresAt! > now) {
          // Already authenticated with valid token
          return true;
        } else if (_refreshToken != null) {
          // Try to refresh the token
          try {
            final success = await _refreshAccessToken();
            if (success) return true;
          } catch (e) {
            debugPrint('Token refresh failed during authentication: $e');
            // Continue with re-authentication
          }
        }
      }
    }
    
    try {
      // Generate OAuth URL
      final oauthUrl = _getOAuthUrl();
      
      // Open OAuth flow based on platform
      if (kIsWeb) {
        // For web, use pop-up window approach
        final uri = Uri.parse(oauthUrl);
        await launchUrl(uri, mode: LaunchMode.platformDefault);
        // Web flow requires external callback handling
        return false;
      }
      
      // For mobile/desktop use WebView when possible
      final context = navigatorKey.currentContext;
      if (context != null) {
        final result = await _showAuthWebView(context, oauthUrl);
        if (result != null && result.containsKey('code')) {
          final code = result['code'];
          if (code != null) {
            // Exchange the auth code for tokens
            try {
              final tokens = await _exchangeCodeForTokens(code);
              if (tokens != null) {
                _accessToken = tokens['access_token'];
                _refreshToken = tokens['refresh_token'];
                
                // Store the expiration time
                if (tokens.containsKey('expires_in')) {
                  final expiresIn = tokens['expires_in'] as int;
                  _tokenExpiresAt = DateTime.now().millisecondsSinceEpoch ~/ 1000 + expiresIn;
                }
                
                _saveSession();
                _scheduleTokenRefresh();
                notifyListeners();
                return true;
              }
            } catch (e) {
              debugPrint('Error exchanging code for tokens: $e');
              throw CdkAuthException('Failed to exchange authorization code for tokens');
            }
          }
        }
      } else {
        // Fallback to URL launcher for external browser
        debugPrint('No BuildContext available, falling back to external browser');
        final uri = Uri.parse(oauthUrl);
        final launched = await launchUrl(
          uri, 
          mode: LaunchMode.externalApplication
        );
        
        if (!launched) {
          throw CdkAuthException('Failed to launch browser for authentication');
        }
        
        // We can't handle the callback here directly, so return false
        // The app should handle the deep link callback separately
        return false;
      }
      
      return false;
    } catch (e) {
      if (e is CdkException) {
        rethrow;
      }
      debugPrint('Authentication error: $e');
      throw CdkAuthException('Authentication failed: $e');
    }
  }
  
  // Exchange OAuth code for access token - from PDF docs
  Future<Map<String, dynamic>?> _exchangeCodeForTokens(String code) async {
    try {
      final response = await http.post(
        Uri.parse('${_authApiBase}token'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'grant_type': 'authorization_code',
          'code': code,
          'client_id': _clientId,
          'client_secret': _clientSecret,
          'redirect_uri': _redirectUri,
        }),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      
      print('Token exchange failed: ${response.statusCode} ${response.body}');
      return null;
    } catch (e) {
      print('Error exchanging token: $e');
      return null;
    }
  }
  
  // Show WebView for OAuth flow
  Future<Map<String, String>?> _showAuthWebView(BuildContext context, String url) async {
    final resultCompleter = Completer<Map<String, String>?>();
    
    // Create a standard WebViewController
    final controller = WebViewController();
    
    // Configure the controller
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            // Check if this is the redirect URI we're expecting
            if (request.url.startsWith(_redirectUri)) {
              // Parse the URL to extract parameters
              final uri = Uri.parse(request.url);
              final params = uri.queryParameters;
              
              // Complete with the authorization code and close the dialog
              resultCompleter.complete(params);
              Navigator.pop(context);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onWebResourceError: (error) {
            debugPrint('WebView resource error: ${error.description}');
            return;
          },
        ),
      )
      ..setUserAgent('EigenBet-App')
      ..loadRequest(Uri.parse(url));
    
    // Show dialog with WebView
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          insetPadding: EdgeInsets.zero,
          child: Container(
            width: MediaQuery.of(context).size.width > 500 ? 500 : MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height > 700 ? 700 : MediaQuery.of(context).size.height * 0.8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Connect Coinbase',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          if (!resultCompleter.isCompleted) {
                            resultCompleter.complete(null);
                          }
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: Stack(
                    children: [
                      WebViewWidget(
                        controller: controller,
                      ),
                      // Loading indicator that disappears when page is loaded
                      FutureBuilder<void>(
                        future: Future.delayed(const Duration(seconds: 2)), // Wait for initial load
                        builder: (context, snapshot) {
                          if (snapshot.connectionState != ConnectionState.done) {
                            return Container(
                              color: Colors.black26,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    
    // Add a timeout to prevent hanging forever
    Future.delayed(const Duration(minutes: 5), () {
      if (!resultCompleter.isCompleted) {
        debugPrint('WebView authentication timed out after 5 minutes');
        resultCompleter.complete(null);
        try {
          Navigator.pop(navigatorKey.currentContext!);
        } catch (e) {
          // Ignore if navigator is already gone
        }
      }
    });
    
    return resultCompleter.future;
  }
  
  // Create or get MPC wallet - based on the CDK API
  Future<Map<String, dynamic>?> createMpcWallet() async {
    if (!_isInitialized || _accessToken == null) {
      debugPrint('Not initialized or authenticated');
      throw CdkAuthException('Must be authenticated to create or get wallet');
    }
    
    try {
      // First check if there's an existing wallet
      final wallets = await getWallets();
      if (wallets != null && wallets.isNotEmpty) {
        _walletId = wallets[0]['id'];
        debugPrint('Found existing wallet: ${_walletId}');
        return wallets[0];
      }
      
      // Create a new wallet if none exists
      debugPrint('No existing wallet found, creating a new MPC wallet');
      
      final response = await http.post(
        Uri.parse('${_cdkApiBase}wallets'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_accessToken',
          'User-Agent': 'EigenBet-Flutter-App',
        },
        body: jsonEncode({
          'name': 'EigenBet Predictions Wallet',
          'network': ApiConfig.defaultNetwork,
        }),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _walletId = data['id'];
        _saveSession();
        debugPrint('Successfully created new wallet: ${_walletId}');
        return data;
      }
      
      debugPrint('Failed to create wallet: ${response.statusCode} ${response.body}');
      throw CdkException(
        'Failed to create wallet',
        statusCode: response.statusCode,
        response: response.body
      );
    } catch (e) {
      if (e is CdkException) {
        rethrow;
      }
      debugPrint('Error creating wallet: $e');
      throw CdkException('Error creating wallet: $e');
    }
  }
  
  // Get list of wallets - from CDK docs
  Future<List<Map<String, dynamic>>?> getWallets() async {
    if (!_isInitialized || _accessToken == null) {
      return null;
    }
    
    try {
      final response = await http.get(
        Uri.parse('${_cdkApiBase}wallets'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['wallets']);
      }
      
      print('Failed to get wallets: ${response.statusCode} ${response.body}');
      return null;
    } catch (e) {
      print('Error getting wallets: $e');
      return null;
    }
  }
  
  // Get wallet balances - specific to CDK API
  Future<Map<String, dynamic>?> getBalances() async {
    if (!_isInitialized || _accessToken == null || _walletId == null) {
      return null;
    }
    
    try {
      final response = await http.get(
        Uri.parse('${_cdkApiBase}wallets/$_walletId/balances'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'balances': data['balances'],
          'totalUsdValue': data['total_usd_value'],
        };
      }
      
      print('Failed to get balances: ${response.statusCode} ${response.body}');
      return null;
    } catch (e) {
      print('Error getting balances: $e');
      return null;
    }
  }
  
  // Get transaction history - from CDK docs
  Future<Map<String, dynamic>?> getTransactions() async {
    if (!_isInitialized || _accessToken == null || _walletId == null) {
      return null;
    }
    
    try {
      final response = await http.get(
        Uri.parse('${_cdkApiBase}wallets/$_walletId/transactions'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'transactions': data['transactions'],
          'cursor': data['cursor'],
        };
      }
      
      print('Failed to get transactions: ${response.statusCode} ${response.body}');
      return null;
    } catch (e) {
      print('Error getting transactions: $e');
      return null;
    }
  }
  
  // Sign message - based on CDK docs
  Future<Map<String, dynamic>?> signMessage(String message) async {
    if (!_isInitialized || _accessToken == null || _walletId == null) {
      return null;
    }
    
    try {
      final response = await http.post(
        Uri.parse('${_cdkApiBase}wallets/$_walletId/sign'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_accessToken',
        },
        body: jsonEncode({
          'message': message,
          'standard': 'personal_sign',
        }),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      
      print('Failed to sign message: ${response.statusCode} ${response.body}');
      return null;
    } catch (e) {
      print('Error signing message: $e');
      return null;
    }
  }
  
  // Logout - revoke token as per API docs
  Future<bool> logout() async {
    if (_accessToken == null) {
      return true; // Already logged out
    }
    
    try {
      final response = await http.post(
        Uri.parse('${_authApiBase}revoke'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'token': _accessToken,
          'client_id': _clientId,
          'client_secret': _clientSecret,
        }),
      );
      
      // Clear local session even if the API call fails
      _clearSession();
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error during logout: $e');
      _clearSession();
      return false;
    }
  }
  
  // Save session to persistent storage
  Future<void> _saveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save all session data
      if (_sessionId != null) {
        await prefs.setString('cdk_session_id', _sessionId!);
      }
      if (_accessToken != null) {
        await prefs.setString('cdk_access_token', _accessToken!);
      }
      if (_refreshToken != null) {
        await prefs.setString('cdk_refresh_token', _refreshToken!);
      }
      if (_walletId != null) {
        await prefs.setString('cdk_wallet_id', _walletId!);
      }
      if (_tokenExpiresAt != null) {
        await prefs.setInt('cdk_token_expires_at', _tokenExpiresAt!);
      }
      
      // Also save a timestamp of when the session was last saved
      await prefs.setInt('cdk_session_last_saved', 
          DateTime.now().millisecondsSinceEpoch ~/ 1000);
      
      debugPrint('CDK session saved successfully');
    } catch (e) {
      debugPrint('Error saving CDK session: $e');
      // Even if saving fails, we don't want to stop the application flow
    }
  }
  
  // Load session from persistent storage
  Future<void> _loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load all session data
      _sessionId = prefs.getString('cdk_session_id');
      _accessToken = prefs.getString('cdk_access_token');
      _refreshToken = prefs.getString('cdk_refresh_token');
      _walletId = prefs.getString('cdk_wallet_id');
      _tokenExpiresAt = prefs.getInt('cdk_token_expires_at');
      
      // Initialize if sessionId exists (basic validation)
      _isInitialized = _sessionId != null;
      
      // Check if there's a valid token and schedule refresh if needed
      if (_accessToken != null && _tokenExpiresAt != null) {
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        if (_tokenExpiresAt! > now) {
          _scheduleTokenRefresh();
        } else if (_refreshToken != null) {
          // Token is expired but we have a refresh token, try to refresh
          debugPrint('Loaded expired token, attempting to refresh');
          unawaited(_refreshAccessToken());
        }
      }
      
      debugPrint('CDK session loaded: ' +
          (_isInitialized ? 'initialized' : 'not initialized') +
          (_accessToken != null ? ', authenticated' : ', not authenticated'));
    } catch (e) {
      debugPrint('Error loading CDK session: $e');
      // On error, reset session data to be safe
      _sessionId = null;
      _accessToken = null;
      _refreshToken = null;
      _walletId = null;
      _tokenExpiresAt = null;
      _isInitialized = false;
    }
  }
  
  // Clear session data
  Future<void> _clearSession() async {
    try {
      // Cancel token refresh timer if active
      _refreshTimer?.cancel();
      _refreshTimer = null;
      
      final prefs = await SharedPreferences.getInstance();
      
      // Clear all session data from storage
      await prefs.remove('cdk_session_id');
      await prefs.remove('cdk_access_token');
      await prefs.remove('cdk_refresh_token');
      await prefs.remove('cdk_wallet_id');
      await prefs.remove('cdk_token_expires_at');
      await prefs.remove('cdk_session_last_saved');
      
      // Reset in-memory session state
      _sessionId = null;
      _accessToken = null;
      _refreshToken = null;
      _walletId = null;
      _tokenExpiresAt = null;
      _isInitialized = false;
      
      notifyListeners();
      debugPrint('CDK session cleared successfully');
    } catch (e) {
      debugPrint('Error clearing CDK session: $e');
      // Try to reset in-memory state anyway
      _sessionId = null;
      _accessToken = null;
      _refreshToken = null;
      _walletId = null;
      _tokenExpiresAt = null;
      _isInitialized = false;
      notifyListeners();
    }
  }
  
  // Helper to allow using async functions without await
  void unawaited(Future<dynamic> future) {
    future.then((_) {
      // Successful completion, nothing to do
    }).catchError((error) {
      // Log errors from unawaited futures
      debugPrint('Error in unawaited future: $error');
    });
  }
  
  // Exchange an external OAuth code for tokens
  Future<bool> exchangeExternalCodeForTokens(String code) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      final response = await http.post(
        Uri.parse('${_authApiBase}token'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'grant_type': 'authorization_code',
          'code': code,
          'client_id': _clientId,
          'client_secret': _clientSecret,
          'redirect_uri': _redirectUri,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access_token'];
        _refreshToken = data['refresh_token'];
        _saveSession();
        notifyListeners();
        
        // Get or create MPC wallet after successful authentication
        await createMpcWallet();
        
        return true;
      } else {
        print('Token exchange failed: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error exchanging code for token: $e');
      return false;
    }
  }
} 