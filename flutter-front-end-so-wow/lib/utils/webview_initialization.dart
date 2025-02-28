// Native-only imports
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

// Global variable to track initialization
bool _webViewInitialized = false;

// Initialize WebView platform
void initializeWebViewPlatform() {
  // Skip on web platforms or if already initialized
  if (kIsWeb || _webViewInitialized) return;
  
  try {
    // For this simplified version, we don't need to initialize anything specific
    _webViewInitialized = true;
    debugPrint('WebView initialized');
  } catch (e) {
    debugPrint('WebView initialization error: $e');
    // Try to prevent crashing on initialization failure
    _webViewInitialized = true; // Mark as initialized even though it failed
  }
}

// Create a controller for WebView
WebViewController createWebViewController({
  required NavigationDelegate? navigationDelegate,
  String? userAgent,
  JavaScriptMode javascriptMode = JavaScriptMode.unrestricted,
}) {
  // Create the controller
  final controller = WebViewController();
  
  // Configure controller settings
  controller.setJavaScriptMode(javascriptMode);
  
  if (navigationDelegate != null) {
    controller.setNavigationDelegate(navigationDelegate);
  }
  
  if (userAgent != null) {
    controller.setUserAgent(userAgent);
  }
  
  return controller;
}

// Platform detection that works safely across platforms
String getPlatformType() {
  if (kIsWeb) return 'web';
  return 'unknown';
}

class WebviewUtility {
  static Future<bool> openUrl(String url, {bool useExternalBrowser = false}) async {
    final Uri uri = Uri.parse(url);
    
    try {
      if (useExternalBrowser || kIsWeb) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        return await launchUrl(uri, mode: LaunchMode.inAppWebView);
      }
    } catch (e) {
      print('Error launching URL: $e');
      return false;
    }
  }

  static Future<bool> sendEmail(String email, {String subject = '', String body = ''}) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': subject,
        'body': body,
      },
    );
    
    try {
      return await launchUrl(emailLaunchUri);
    } catch (e) {
      print('Error launching email: $e');
      return false;
    }
  }
} 