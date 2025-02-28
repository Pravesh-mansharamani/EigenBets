import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:webview_flutter/webview_flutter.dart';
import '../utils/webview_initialization.dart';
import '../main.dart';

class WebviewManager {
  static final WebviewManager _instance = WebviewManager._internal();
  factory WebviewManager() => _instance;
  WebviewManager._internal();
  
  // Track initialization status
  bool _isInitialized = false;
  
  // Initialize WebView
  void initialize() {
    if (_isInitialized || kIsWeb) return;
    
    try {
      initializeWebViewPlatform();
      _isInitialized = true;
    } catch (e) {
      print('WebView manager initialization error: $e');
    }
  }
  
  // Launch a URL either in WebView (native) or browser (web)
  Future<bool> launchUrl(String url, {bool useWebView = true}) async {
    if (kIsWeb) {
      // On web, always launch in browser
      final uri = Uri.parse(url);
      return await url_launcher.launchUrl(uri, mode: url_launcher.LaunchMode.externalApplication);
    }
    
    // For native platforms, use WebView if requested
    if (useWebView) {
      return await _launchInWebView(url);
    } else {
      final uri = Uri.parse(url);
      return await url_launcher.launchUrl(uri);
    }
  }
  
  // Launch URL in embedded WebView
  Future<bool> _launchInWebView(String url) async {
    if (kIsWeb) return false;
    
    final navigatorContext = navigatorKey.currentContext;
    if (navigatorContext == null) return false;
    
    try {
      if (!_isInitialized) initialize();
      
      // Create a simple WebViewController
      final controller = WebViewController();
      
      // Track loading state
      bool isLoading = true;
      
      // Configure the controller
      controller
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.white)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              debugPrint('WebView page started loading: $url');
              isLoading = true;
              if (navigatorContext.mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (navigatorContext.mounted) {
                    ScaffoldMessenger.of(navigatorContext).setState(() {});
                  }
                });
              }
            },
            onPageFinished: (String url) {
              debugPrint('WebView page finished loading: $url');
              isLoading = false;
              if (navigatorContext.mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (navigatorContext.mounted) {
                    ScaffoldMessenger.of(navigatorContext).setState(() {});
                  }
                });
              }
            },
            onWebResourceError: (WebResourceError error) {
              debugPrint('WebView resource error: ${error.description}');
            },
            onNavigationRequest: (NavigationRequest request) {
              return NavigationDecision.navigate;
            },
          ),
        )
        ..setUserAgent('EigenBet-App/1.0')
        ..loadRequest(Uri.parse(url));
      
      // Show WebView in fullscreen dialog
      await Navigator.of(navigatorContext).push(
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: Text(isLoading ? 'Loading...' : 'EigenBet'),
              actions: [
                if (isLoading)
                  Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.only(right: 16),
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.open_in_browser),
                  tooltip: 'Open in browser',
                  onPressed: () {
                    url_launcher.launchUrl(
                      Uri.parse(url),
                      mode: url_launcher.LaunchMode.externalApplication,
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            body: WebViewWidget(controller: controller),
          ),
        ),
      );
      
      return true;
    } catch (e) {
      debugPrint('Error launching WebView: $e');
      
      // Fallback to external browser on failure
      try {
        return await url_launcher.launchUrl(
          Uri.parse(url),
          mode: url_launcher.LaunchMode.externalApplication,
        );
      } catch (_) {
        return false;
      }
    }
  }
} 