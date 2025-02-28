// This file provides stub implementations for web platform
// so the imports in webview_initialization.dart won't fail
import 'package:flutter/widgets.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

// Define type aliases for all required callback types
typedef VoidCallback = void Function();
typedef ConsoleMessageCallback = void Function(String message);
typedef JavaScriptDialogCallback = void Function(String message);
typedef PermissionRequestCallback = void Function(String permission);
typedef UrlCallback = void Function(String url);

// Define getPlatformTypeImpl function for web context
String getPlatformTypeImpl() {
  return 'web';
}

// Android stub that extends WebViewPlatform
class AndroidWebViewPlatform extends WebViewPlatform {
  AndroidWebViewPlatform._();
  
  static final AndroidWebViewPlatform _instance = AndroidWebViewPlatform._();
  factory AndroidWebViewPlatform() => _instance;
  
  @override
  PlatformWebViewController createPlatformWebViewController(
    PlatformWebViewControllerCreationParams params,
  ) {
    return StubWebViewController(params);
  }
  
  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
    PlatformWebViewWidgetCreationParams params,
  ) {
    return StubWebViewWidget(params);
  }
  
  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(
    PlatformNavigationDelegateCreationParams params,
  ) {
    return StubNavigationDelegate(params);
  }
}

// iOS stub that extends WebViewPlatform
class WebKitWebViewPlatform extends WebViewPlatform {
  WebKitWebViewPlatform._();
  
  static final WebKitWebViewPlatform _instance = WebKitWebViewPlatform._();
  factory WebKitWebViewPlatform() => _instance;
  
  @override
  PlatformWebViewController createPlatformWebViewController(
    PlatformWebViewControllerCreationParams params,
  ) {
    return StubWebViewController(params);
  }
  
  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
    PlatformWebViewWidgetCreationParams params,
  ) {
    return StubWebViewWidget(params);
  }
  
  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(
    PlatformNavigationDelegateCreationParams params,
  ) {
    return StubNavigationDelegate(params);
  }
}

// Stub implementations for required components with ALL required methods
class StubWebViewController implements PlatformWebViewController {
  final PlatformWebViewControllerCreationParams params;
  
  StubWebViewController(this.params);
  
  @override
  Future<void> loadRequest(LoadRequestParams params) async {}
  
  @override
  Future<String> currentUrl() async => '';
  
  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async {}
  
  @override
  Future<void> setBackgroundColor(Color color) async {}
  
  @override
  Future<void> setPlatformNavigationDelegate(PlatformNavigationDelegate handler) async {}
  
  @override
  Future<void> addJavaScriptChannel(JavaScriptChannelParams params) async {}
  
  @override
  Future<void> clearCache() async {}
  
  @override
  Future<void> clearLocalStorage() async {}
  
  @override
  Future<String?> getTitle() async => null;
  
  @override
  Future<void> loadFlutterAsset(String key) async {}
  
  @override
  Future<void> loadHtmlString(String html, {String? baseUrl}) async {}
  
  @override
  Future<void> removeJavaScriptChannel(String javaScriptChannelName) async {}
  
  @override
  Future<void> runJavaScript(String javaScript) async {}
  
  @override
  Future<String> runJavaScriptReturningResult(String javaScript) async => '';
  
  @override
  Future<void> setUserAgent(String? userAgent) async {}
  
  @override
  Future<void> enableZoom(bool enabled) async {}
  
  @override
  Future<void> reload() async {}
  
  @override
  Future<void> goBack() async {}
  
  @override
  Future<bool> canGoBack() async => false;
  
  @override
  Future<void> goForward() async {}
  
  @override
  Future<bool> canGoForward() async => false;
  
  // Additional required implementations
  @override
  Future<Offset> getScrollPosition() async => Offset.zero;
  
  @override
  Future<String?> getUserAgent() async => null;
  
  @override
  Future<void> loadFile(String absoluteFilePath) async {}
  
  @override
  Future<void> scrollBy(int x, int y) async {}
  
  @override
  Future<void> scrollTo(int x, int y) async {}
  
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class StubWebViewWidget implements PlatformWebViewWidget {
  final PlatformWebViewWidgetCreationParams params;
  
  StubWebViewWidget(this.params);
  
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('WebView not available on this platform'));
  }
}

class StubNavigationDelegate implements PlatformNavigationDelegate {
  final PlatformNavigationDelegateCreationParams params;
  
  StubNavigationDelegate(this.params);
  
  @override
  Future<void> setOnNavigationRequest(NavigationRequestCallback onNavigationRequest) async {}
  
  @override
  Future<void> setOnPageFinished(PageEventCallback onPageFinished) async {}
  
  @override
  Future<void> setOnPageStarted(PageEventCallback onPageStarted) async {}
  
  @override
  Future<void> setOnProgress(ProgressCallback onProgress) async {}
  
  @override
  Future<void> setOnWebResourceError(WebResourceErrorCallback onWebResourceError) async {}
  
  // Use noSuchMethod to handle any missing methods
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
} 