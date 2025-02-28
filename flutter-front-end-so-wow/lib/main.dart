import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
// Conditionally import webview_flutter based on platform
import 'screens/dashboard_screen.dart';
import 'screens/betting_screen.dart';
import 'screens/wallet_screen.dart';
import 'screens/markets_screen.dart';
import 'screens/create_market_screen.dart';
import 'theme/app_theme.dart';
import 'services/wallet_service.dart';
import 'services/web3_service.dart';
import 'services/deep_link_handler.dart';
import 'utils/webview_initialization.dart'; // Create this utility file
import 'services/webview_manager.dart';
import 'screens/landing_page.dart';
import 'utils/web3_js_bridge.dart';
import 'utils/metamask.dart';

// Add global navigator key for WebView context
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize WebView platform safely
  if (!kIsWeb) {
    try {
      // Use our centralized WebView manager
      WebviewManager().initialize();
    } catch (e) {
      print('WebView initialization failed: $e');
    }
  } else {
    // Initialize Web3JsBridge for web platform
    try {
      // Web3JsBridge already imported at the top
      Web3JsBridge.initialize().then((_) {
        print('Web3JsBridge initialized successfully');
      });
    } catch (e) {
      print('Web3JsBridge initialization failed: $e');
    }
  }
  
  // Initialize sensitive configuration from secure storage
  loadCredentials().then((_) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => WalletService()),
          ChangeNotifierProvider(create: (context) => Web3Service()),
          ChangeNotifierProvider(create: (context) => MetaMaskProvider()..init()),
        ],
        child: const PredictionMarketApp(),
      ),
    );
  });
}

Future<void> loadCredentials() async {
  // In a real app, you'd use flutter_secure_storage or a similar solution
  // This is just a placeholder for demonstration
  // const secureStorage = FlutterSecureStorage();
  // final apiKey = await secureStorage.read(key: 'COINBASE_API_KEY');
  // ... load other credentials
}

class PredictionMarketApp extends StatelessWidget {
  const PredictionMarketApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Initialize deep link handler after app is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DeepLinkHandler().initialize(context);
    });
    
    return MaterialApp(
      title: 'EigenBet',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainAppScaffold(),
      navigatorKey: navigatorKey,
      scrollBehavior: const ScrollBehavior().copyWith(
        scrollbars: false,
        physics: const BouncingScrollPhysics(),
        overscroll: false,
      ),
    );
  }
}

class MainAppScaffold extends StatefulWidget {
  const MainAppScaffold({Key? key}) : super(key: key);

  @override
  State<MainAppScaffold> createState() => _MainAppScaffoldState();
}

class _MainAppScaffoldState extends State<MainAppScaffold> {
  int _selectedIndex = 0;
  
  final List<Widget> _screens = [
    const DashboardScreen(),
    const MarketsScreen(),
    const BettingScreen(),
    const WalletScreen(),
  ];

  // Show landing page initially if user is not connected
  bool _showLandingPage = true;
  
  // For responsive layout
  double _railWidth = 84.0;
  bool _isRailExtended = false;
  
  @override
  void initState() {
    super.initState();
    
    // Check for existing wallet connection on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final walletService = Provider.of<WalletService>(context, listen: false);
      walletService.loadSavedConnection();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update rail state based on screen width
    final width = MediaQuery.of(context).size.width;
    setState(() {
      _isRailExtended = width > 1200;
      _railWidth = _isRailExtended ? 220.0 : 84.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final walletService = Provider.of<WalletService>(context);
    
    // If we're showing landing page and wallet is not connected
    if (_showLandingPage && !walletService.isConnected) {
      return LandingPage(
        onGetStarted: () {
          setState(() {
            _showLandingPage = false;
          });
        },
      );
    }
    
    // Otherwise show the main scaffold
    return Scaffold(
      body: Row(
        children: [
          // Side Navigation Bar
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _railWidth,
            child: NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (int index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              extended: _isRailExtended,
              minExtendedWidth: 220,
              backgroundColor: Theme.of(context).colorScheme.background,
              selectedIconTheme: IconThemeData(
                color: Theme.of(context).colorScheme.primary,
              ),
              unselectedIconTheme: IconThemeData(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              selectedLabelTextStyle: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelTextStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              leading: _isRailExtended 
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Row(
                      children: [
                        Icon(
                          Icons.analytics_outlined,
                          color: Theme.of(context).colorScheme.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'EigenBet',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Icon(
                      Icons.analytics_outlined,
                      color: Theme.of(context).colorScheme.primary,
                      size: 28,
                    ),
                  ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: Text('Dashboard'),
                  padding: EdgeInsets.symmetric(vertical: 8),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.show_chart_outlined),
                  selectedIcon: Icon(Icons.show_chart),
                  label: Text('Markets'),
                  padding: EdgeInsets.symmetric(vertical: 8),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.casino_outlined),
                  selectedIcon: Icon(Icons.casino),
                  label: Text('Betting'),
                  padding: EdgeInsets.symmetric(vertical: 8),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  selectedIcon: Icon(Icons.account_balance_wallet),
                  label: Text('Wallet'),
                  padding: EdgeInsets.symmetric(vertical: 8),
                ),
              ],
            ),
          ),
          // Main Content
          Expanded(
            child: _screens[_selectedIndex],
          ),
        ],
      ),
      // Bottom Navigation for Mobile
      bottomNavigationBar: MediaQuery.of(context).size.width < 600
          ? NavigationBar(
              onDestinationSelected: (int index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              selectedIndex: _selectedIndex,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                NavigationDestination(
                  icon: Icon(Icons.show_chart_outlined),
                  selectedIcon: Icon(Icons.show_chart),
                  label: 'Markets',
                ),
                NavigationDestination(
                  icon: Icon(Icons.casino_outlined),
                  selectedIcon: Icon(Icons.casino),
                  label: 'Betting',
                ),
                NavigationDestination(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  selectedIcon: Icon(Icons.account_balance_wallet),
                  label: 'Wallet',
                ),
              ],
            )
          : null,
    );
  }
}

