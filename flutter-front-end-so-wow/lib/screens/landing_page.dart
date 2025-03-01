import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:ui';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/wallet_connection_widget.dart';
import '../utils/webview_initialization.dart';
import '../services/wallet_service.dart';
import '../main.dart';

class LandingPage extends StatefulWidget {
  final VoidCallback onGetStarted;
  
  const LandingPage({
    Key? key,
    required this.onGetStarted,
  }) : super(key: key);

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> with TickerProviderStateMixin {
  late final AnimationController _backgroundController;
  late final AnimationController _cardController;
  late final AnimationController _textController;
  final ScrollController _scrollController = ScrollController();

  bool _showConnect = false;
  double _scrollPosition = 0.0;
  
  // URLs for external links
  final Map<String, String> _socialLinks = {
    'Facebook': 'https://www.facebook.com/Coinbase/',
    'Telegram': 'https://t.me/EigenLayerOfficial',
    'Discord': 'https://discord.com/invite/eigenlayer',
    'Reddit': 'https://www.reddit.com/r/EigenLayer/?rdt=36109',
  };

  final String _contactEmail = 'eigenbet@example.com';
  
  @override
  void initState() {
    super.initState();
    
    // Controllers for various animations
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat(reverse: true);
    
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    // Start animations in sequence
    Future.delayed(const Duration(milliseconds: 300), () {
      _textController.forward();
    });
    
    Future.delayed(const Duration(milliseconds: 800), () {
      _cardController.forward();
    });
    
    // Track scroll for parallax effects
    _scrollController.addListener(() {
      setState(() {
        _scrollPosition = _scrollController.offset;
      });
    });
  }
  
  @override
  void dispose() {
    _backgroundController.dispose();
    _cardController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _navigateTo(String route) {
    print('Navigating to: $route');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigating to: $route'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }
  
  void _openSocialLink(String platform) {
    if (_socialLinks.containsKey(platform)) {
      WebviewUtility.openUrl(_socialLinks[platform]!);
    }
  }
  
  void _sendEmail(String email) {
    WebviewUtility.sendEmail(email, subject: 'Inquiry from Prediction Markets App');
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    
    // Debug check wallet connection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final walletService = Provider.of<WalletService>(context, listen: false);
        print("Current wallet connection state: ${walletService.isConnected}");
        if (walletService.isConnected) {
          print("Wallet is connected: ${walletService.walletAddress}");
        }
      } catch (e) {
        print("Error checking wallet state: $e");
      }
    });
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Animated background
          AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, child) {
              return Container(
                width: size.width,
                height: size.height,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(
                      math.sin(_backgroundController.value * math.pi * 2) * 0.2,
                      math.cos(_backgroundController.value * math.pi * 2) * 0.2,
                    ),
                    radius: 1.0 + (0.5 * _backgroundController.value),
                    colors: const [
                      Color(0xFF6C5CE7),
                      Color(0xFF483D8B),
                      Color(0xFF191970),
                      Color(0xFF000000),
                    ],
                    stops: const [0.0, 0.4, 0.7, 1.0],
                  ),
                ),
              );
            },
          ),
          
          // Particles/stars effect
          CustomPaint(
            size: Size(size.width, size.height),
            painter: ParticlesPainter(
              particleCount: 100,
              animationValue: _backgroundController.value,
            ),
          ),
          
          // Main content
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                // Navigation bar
                _buildNavBar(theme),
                
                // Hero section
                _buildHeroSection(theme, size),
                
                // Features section
                _buildFeaturesSection(theme),
                
                // Stats section
                _buildStatsSection(theme),
                
                // Call to action
                _buildCallToAction(theme),
                
                // Footer
                _buildFooter(theme),
              ],
            ),
          ),
          
          // Connection dialog
          if (_showConnect)
            Positioned.fill(
              child: _buildConnectionDialog(theme),
            ),
        ],
      ),
    );
  }
  
  Widget _buildNavBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 28,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'EigenBets',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          // No menu items until implementation is complete
          
          // Action buttons
          Row(
            children: [
              OutlinedButton(
                onPressed: () => setState(() => _showConnect = true),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: theme.colorScheme.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: Text(
                  'Connect Wallet',
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildNavItem(String title, ThemeData theme, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeroSection(ThemeData theme, Size size) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      height: size.height * 0.8,
      width: double.infinity,
      child: Stack(
        children: [
          // Parallax background effect
          Positioned(
            left: -50 + _scrollPosition * 0.1,
            right: -50 - _scrollPosition * 0.1,
            top: -50,
            bottom: -50,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF6C5CE7).withOpacity(0.3),
                    Color(0xFF1E1E2E).withOpacity(0.6),
                  ],
                ),
              ),
            ),
          ),
          
          // Conditional content based on screen width
          if (size.width > 900)
            // Desktop layout
            Row(
              children: [
                // Left content - Text
                Expanded(
                  flex: 3,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Animated text intro
                      SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, -0.2),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _textController,
                          curve: Curves.easeOutQuart,
                        )),
                        child: FadeTransition(
                          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                            CurvedAnimation(
                              parent: _textController,
                              curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
                            ),
                          ),
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'The future of ',
                                  style: theme.textTheme.displayMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w300,
                                    height: 1.1,
                                  ),
                                ),
                                TextSpan(
                                  text: 'prediction markets',
                                  style: theme.textTheme.displayMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    height: 1.1,
                                  ),
                                ),
                                TextSpan(
                                  text: ' is here.',
                                  style: theme.textTheme.displayMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w300,
                                    height: 1.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Subtitle
                      SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, -0.2),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _textController,
                          curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
                        )),
                        child: FadeTransition(
                          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                            CurvedAnimation(
                              parent: _textController,
                              curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
                            ),
                          ),
                          child: SizedBox(
                            width: size.width * 0.5,
                            child: Text(
                              'Trade on prediction markets with confidence using EigenLayer AVS for trusted and verifiable outcomes.',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: Colors.white.withOpacity(0.7),
                                fontWeight: FontWeight.w300,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 48),
                      
                      // CTA buttons
                      SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, -0.2),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _textController,
                          curve: const Interval(0.4, 0.9, curve: Curves.easeOut),
                        )),
                        child: FadeTransition(
                          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                            CurvedAnimation(
                              parent: _textController,
                              curve: const Interval(0.4, 0.9, curve: Curves.easeOut),
                            ),
                          ),
                          child: Row(
                            children: [
                              ElevatedButton(
                                onPressed: () => setState(() => _showConnect = true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 20,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text('Get Started'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Right content - Graphic
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(30),
                    margin: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          size: 80,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'AVS Verification',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Powered by EigenLayer',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          else
            // Mobile layout
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'The future of ',
                        style: theme.textTheme.displaySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w300,
                          height: 1.1,
                        ),
                      ),
                      TextSpan(
                        text: 'prediction markets',
                        style: theme.textTheme.displaySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                        ),
                      ),
                      TextSpan(
                        text: ' is here.',
                        style: theme.textTheme.displaySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w300,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Subtitle
                Text(
                  'Trade on prediction markets with confidence using EigenLayer AVS for trusted and verifiable outcomes.',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white.withOpacity(0.7),
                    fontWeight: FontWeight.w300,
                    height: 1.4,
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // CTA button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => setState(() => _showConnect = true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Get Started'),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Simple graphic
                Center(
                  child: Container(
                    height: 180,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          size: 50,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'AVS Verification',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
  
  // We don't need this method anymore as we've inlined the graphic widgets
  // in the _buildHeroSection method directly

  Widget _buildFeaturesSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 100),
      child: Column(
        children: [
          Text(
            'Why Choose EigenBet',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Built for secure prediction markets',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 80),
          
          // Feature grid - ensure even number of cards that divide well
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 900 ? 2 : 
                           MediaQuery.of(context).size.width > 600 ? 2 : 1,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 30,
            crossAxisSpacing: 30,
            children: [
              _buildFeatureCard(
                'Low Fee Trading',
                'Trade with near-zero fees on Base network, maximizing your profits on every position.',
                Icons.savings_outlined,
                theme,
              ),
              _buildFeatureCard(
                'AVS Integration',
                'Leverage Eigen Layer AVS verification for secure and reliable market resolution.',
                Icons.verified_user_outlined,
                theme,
              ),
              _buildFeatureCard(
                'Create Your Own Markets',
                'Launch custom prediction markets and earn fees on all trading activity.',
                Icons.add_chart,
                theme,
              ),
              _buildFeatureCard(
                'Base Network',
                'Built on Base for high-speed, low-cost transactions with Ethereum security.',
                Icons.hub_outlined,
                theme,
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildFeatureCard(
    String title,
    String description,
    IconData icon,
    ThemeData theme,
  ) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.8, end: 1.0).animate(_cardController),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(_cardController),
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.7),
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatsSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
      ),
      child: Column(
        children: [
          Text(
            'Development Stats',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 60),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatCard('Demo', 'Project Status', theme),
              _buildStatCard('EigenLayer', 'AVS Integration', theme),
              _buildStatCard('24hrs', 'Hackathon Build', theme),
            ],
          ),
          const SizedBox(height: 60),
          
          // Market chart visualization
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            height: 160,
            child: CustomPaint(
              painter: ChartPainter(theme.colorScheme.primary),
              size: const Size(double.infinity, 160),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatCard(String value, String label, ThemeData theme) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.displaySmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
  
  Widget _buildCallToAction(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 100),
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 80),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withOpacity(0.3),
            theme.colorScheme.primary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            'Ready to trade on the future?',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Connect your wallet and try our demo prediction markets with EigenLayer AVS.',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => setState(() => _showConnect = true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: theme.colorScheme.primary,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 20,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Connect Wallet & Start Trading'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFooter(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 40),
      color: const Color(0xFF0A0A0A),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Company info column
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.analytics_outlined,
                          size: 28,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Nexus Predictions',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'A prediction market platform powered by EigenLayer AVS for verified market outcomes.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.7),
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Social media buttons
                    Row(
                      children: [
                        _socialButton(Icons.facebook, onTap: () => _openSocialLink('Facebook')),
                        const SizedBox(width: 16),
                        _socialButton(Icons.telegram, onTap: () => _openSocialLink('Telegram')),
                        const SizedBox(width: 16),
                        _socialButton(Icons.discord, onTap: () => _openSocialLink('Discord')),
                        const SizedBox(width: 16),
                        _socialButton(Icons.reddit, onTap: () => _openSocialLink('Reddit')),
                      ],
                    ),
                  ],
                ),
              ),
              if (MediaQuery.of(context).size.width > 700) ...[
                // Demo links
                Expanded(
                  child: _footerLinks(
                    'Demo',
                    [
                      FooterLinkItem('Contact', onTap: () => _sendEmail(_contactEmail)),
                    ],
                    theme,
                  ),
                ),
                // Resources links
                Expanded(
                  child: _footerLinks(
                    'Resources',
                    [
                      FooterLinkItem('EigenLayer', onTap: () => WebviewUtility.openUrl('https://www.eigenlayer.xyz/')),
                    ],
                    theme,
                  ),
                ),
              ],
            ],
          ),
          if (MediaQuery.of(context).size.width <= 700) ...[
            const SizedBox(height: 40),
            // Mobile footer links in rows
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Demo links
                _footerLinksCompact(
                  'Demo',
                  [
                    FooterLinkItem('Contact', onTap: () => _sendEmail(_contactEmail)),
                  ],
                  theme,
                ),
                // Resources links
                _footerLinksCompact(
                  'Resources',
                  [
                    FooterLinkItem('EigenLayer', onTap: () => WebviewUtility.openUrl('https://www.eigenlayer.xyz/')),
                  ],
                  theme,
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
          const SizedBox(height: 60),
          const Divider(color: Colors.white10),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '© 2025 EigenBet Demo. Hackathon Project.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _socialButton(IconData icon, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          size: 24,
          color: Colors.white,
        ),
      ),
    );
  }
  
  Widget _footerLinks(String title, List<FooterLinkItem> links, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        ...links.map((link) => _buildFooterLinkItem(link, theme)).toList(),
      ],
    );
  }
  
  Widget _buildFooterLinkItem(FooterLinkItem link, ThemeData theme) {
    return InkWell(
      onTap: link.onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          link.title,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ),
    );
  }
  
  Widget _footerLinksCompact(String title, List<FooterLinkItem> links, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        ...links.map((link) => _buildFooterLinkItem(link, theme)).toList(),
      ],
    );
  }
  
  Widget _buildConnectionDialog(ThemeData theme) {
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                margin: const EdgeInsets.all(20),
                width: 450,
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Connect Wallet',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(() => _showConnect = false),
                          icon: const Icon(Icons.close, color: Colors.white70),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    WalletConnectionWidget(
                      onConnect: () {
                        print("WalletConnectionWidget onConnect callback triggered");
                        setState(() => _showConnect = false);
                        widget.onGetStarted();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FooterLinkItem {
  final String title;
  final VoidCallback onTap;

  FooterLinkItem(this.title, {required this.onTap});
}

// We've removed this custom painter class as it was causing syntax errors

class ParticlesPainter extends CustomPainter {
  final int particleCount;
  final double animationValue;
  
  ParticlesPainter({
    required this.particleCount,
    required this.animationValue,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(42);
    
    for (var i = 0; i < particleCount; i++) {
      final particleSize = rnd.nextDouble() * 3 + 0.5;
      final baseX = rnd.nextDouble() * size.width;
      final baseY = rnd.nextDouble() * size.height;
      final animOffset = math.sin((animationValue * math.pi * 2) + (i / 10)) * 5;
      
      final paint = Paint()
        ..color = Colors.white.withOpacity(rnd.nextDouble() * 0.6 + 0.2)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(baseX + animOffset, baseY),
        particleSize,
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(ParticlesPainter oldDelegate) => 
      animationValue != oldDelegate.animationValue;
}

class ChartPainter extends CustomPainter {
  final Color color;
  
  ChartPainter(this.color);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    // Create more complex and realistic chart pattern
    const pointCount = 40; // More points for smoother curve
    final path = Path();
    final rand = math.Random(DateTime.now().millisecondsSinceEpoch); // Different seed each time
    
    // Create patterns similar to real market data with trends and volatility
    List<double> trendsPattern = [0.2, 0.3, 0.4, 0.5, 0.45, 0.52, 0.6, 0.65, 0.58, 0.63,
                                 0.7, 0.72, 0.68, 0.73, 0.78, 0.75, 0.8, 0.82, 0.79, 0.85,
                                 0.82, 0.79, 0.81, 0.83, 0.81, 0.85, 0.87, 0.84, 0.88, 0.9,
                                 0.87, 0.83, 0.85, 0.89, 0.92, 0.9, 0.88, 0.92, 0.95, 0.93];
    
    // Add volatility based on index and random variation
    for (var i = 0; i < pointCount; i++) {
      final baseIndex = i % trendsPattern.length;
      final x = size.width * i / (pointCount - 1);
      
      // Combine base pattern with random factor for realistic movement
      final volatility = 0.05 + (0.02 * math.sin(i * 0.4));
      final randomFactor = (rand.nextDouble() - 0.5) * volatility;
      
      // Combine base pattern, random factor, and some cyclical movement
      final heightFactor = trendsPattern[baseIndex] + randomFactor + (0.03 * math.sin(i * 0.8));
      
      // Ensure value stays in reasonable range
      final adjustedHeight = math.max(0.1, math.min(0.9, heightFactor));
      final y = size.height * (1 - adjustedHeight);
      
      // Start or continue path
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        // Use cubicTo for smoother curves occasionally
        if (i % 4 == 0 && i > 0 && i < pointCount - 1) {
          final prevX = size.width * (i - 1) / (pointCount - 1);
          final prevY = size.height * (1 - (trendsPattern[(i-1) % trendsPattern.length] + 
                         (rand.nextDouble() - 0.5) * 0.05));
          final nextX = size.width * (i + 1) / (pointCount - 1);
          final nextY = size.height * (1 - (trendsPattern[(i+1) % trendsPattern.length] + 
                          (rand.nextDouble() - 0.5) * 0.05));
          
          final ctrlX1 = prevX + (x - prevX) * 0.5;
          final ctrlY1 = prevY;
          final ctrlX2 = x - (nextX - x) * 0.5;
          final ctrlY2 = y;
          
          path.cubicTo(ctrlX1, ctrlY1, ctrlX2, ctrlY2, x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      
      // Add occasional market "events" - sharp moves
      if (rand.nextInt(pointCount) == i && i > 5 && i < pointCount - 5) {
        final eventSize = (rand.nextDouble() - 0.3) * 0.15; // -3% to +10% event
        final eventY = y - (eventSize * size.height);
        path.lineTo(x + (size.width / pointCount * 0.5), eventY);
        path.lineTo(x + (size.width / pointCount), y);
      }
    }
    
    canvas.drawPath(path, paint);
    
    // Draw area below the line with gradient
    final areaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withOpacity(0.5), color.withOpacity(0.01)],
        stops: const [0.2, 0.9],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    final areaPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    
    canvas.drawPath(areaPath, areaPaint);
    
    // Add indicator dots at key points
    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
      
    // Add dots at key positions: start, end, high, low
    final startX = 0.0;
    final startY = size.height * (1 - trendsPattern[0]);
    final endX = size.width;
    final endY = size.height * (1 - trendsPattern.last);
    
    // Find highest and lowest points
    double maxY = double.infinity;
    double minY = -double.infinity;
    double maxX = 0.0;
    double minX = 0.0;
    
    for (var i = 0; i < pointCount; i++) {
      final x = size.width * i / (pointCount - 1);
      final heightFactor = trendsPattern[i % trendsPattern.length];
      final y = size.height * (1 - heightFactor);
      
      if (y < maxY) {
        maxY = y;
        maxX = x;
      }
      
      if (y > minY) {
        minY = y;
        minX = x;
      }
    }
    
    // Draw key points - white dots with colored outlines
    final keyPoints = [
      Offset(startX, startY),
      Offset(endX, endY),
      Offset(maxX, maxY),
      Offset(minX, minY),
    ];
    
    for (final point in keyPoints) {
      // Outer circle (colored)
      canvas.drawCircle(
        point, 
        5.0, 
        Paint()
          ..color = color
          ..style = PaintingStyle.fill
      );
      
      // Inner circle (white)
      canvas.drawCircle(
        point, 
        2.5, 
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true; // Allow repainting for animation
}