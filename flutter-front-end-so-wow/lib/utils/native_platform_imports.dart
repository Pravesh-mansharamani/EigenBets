import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:webview_flutter/webview_flutter.dart';

// Very simplified WebView helper that works on all platforms
class WebViewPlatformHelper {
  static WebViewController getWebViewController() {
    final controller = WebViewController();
    controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    return controller;
  }
}

// Implementation of platform type detection for web and native platforms
String getPlatformType() {
  if (kIsWeb) return 'web';
  
  return 'unknown';
}