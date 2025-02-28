import 'package:flutter/foundation.dart' show kIsWeb;

// Platform helper for safely detecting platform across all platforms
class PlatformHelper {
  static bool get isWeb => kIsWeb;
  
  static bool get isAndroid {
    if (kIsWeb) return false;
    try {
      return _getPlatformImpl() == 'android';
    } catch (_) {
      return false;
    }
  }
  
  static bool get isIOS {
    if (kIsWeb) return false;
    try {
      return _getPlatformImpl() == 'ios';
    } catch (_) {
      return false;
    }
  }
  
  static String getPlatformType() {
    if (kIsWeb) return 'web';
    try {
      return _getPlatformImpl();
    } catch (_) {
      return 'unknown';
    }
  }
  
  // Use conditional imports better
  static String _getPlatformImpl() {
    if (kIsWeb) return 'web';
    
    // We dynamically import dart:io only on non-web platforms
    try {
      // ignore: undefined_prefixed_name
      if (io.Platform.isAndroid) return 'android';
      // ignore: undefined_prefixed_name
      if (io.Platform.isIOS) return 'ios';
      // ignore: undefined_prefixed_name
      return io.Platform.operatingSystem;
    } catch (_) {
      return 'unknown';
    }
  }
}

// We use conditional compilation for importing the right library
// ignore: uri_does_not_exist
import 'dart:io' if (dart.library.html) 'dart:html' as io;

// Initialize WebView platform safely
void initializeWebView() {
  if (kIsWeb) return; // Skip on web
  
  try {
    if (isAndroid) {
      import 'package:webview_flutter_android/webview_flutter_android.dart';
      import 'package:webview_flutter/webview_flutter.dart';
      WebViewPlatform.instance = AndroidWebViewPlatform();
    } else if (isIOS) {
      import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
      import 'package:webview_flutter/webview_flutter.dart';
      WebViewPlatform.instance = WebKitWebViewPlatform();
    }
  } catch (e) {
    print('WebView initialization error: $e');
  }
} 