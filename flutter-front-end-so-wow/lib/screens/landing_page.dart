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

  final String _contactEmail = 'dermottcole@gmail.com';
  
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
                'Nexus Predictions',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          // Menu items - hidden on small screens
          if (MediaQuery.of(context).size.width > 800)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildNavItem('Markets', theme, onTap: () => _navigateTo('markets')),
                _buildNavItem('About', theme, onTap: () => _navigateTo('about')),
                _buildNavItem('Documentation', theme, onTap: () => _navigateTo('docs')),
                _buildNavItem('Blog', theme, onTap: () => _navigateTo('blog')),
              ],
            ),
          
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
            child: ShaderMask(
              shaderCallback: (bounds) {
                return LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                  stops: const [0.5, 0.9],
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
              // Use a Container with gradient instead of image that's missing
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
          ),
          
          // Hero content
          Column(
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
                    width: size.width * 0.6,
                    child: Text(
                      'Trade with confidence on the most accurate prediction market platform powered by blockchain technology and AI-driven analytics.',
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
                      const SizedBox(width: 16),
                      TextButton(
                        onPressed: () => _navigateTo('learn-more'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 20,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Text('Learn More'),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                          ],
                        ),
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
  
  Widget _buildFeaturesSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 100),
      child: Column(
        children: [
          Text(
            'Why Choose Nexus Predictions',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Built for traders, by traders',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 80),
          
          // Feature grid
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 900 ? 3 : 
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
                'AI-Powered Insights',
                'Leverage advanced analytics and sentiment analysis to make informed decisions.',
                Icons.psychology_outlined,
                theme,
              ),
              _buildFeatureCard(
                'Zero-Knowledge Proofs',
                'Confidently trade with cryptographically verified outcomes ensuring fair resolution.',
                Icons.verified_outlined,
                theme,
              ),
              _buildFeatureCard(
                'Create Your Own Markets',
                'Launch custom prediction markets and earn fees on all trading activity.',
                Icons.add_chart,
                theme,
              ),
              _buildFeatureCard(
                'Multi-Chain Support',
                'Trade seamlessly across Ethereum, Base, and Polygon with unified liquidity.',
                Icons.hub_outlined,
                theme,
              ),
              _buildFeatureCard(
                'Social Trading',
                'Follow top traders, share strategies, and collaborate with the community.',
                Icons.people_outlined,
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
            'Market Stats',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 60),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatCard('\$14.5M', 'Trading Volume', theme),
              _buildStatCard('12K+', 'Active Markets', theme),
              _buildStatCard('98%', 'Resolution Rate', theme),
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
            'Connect your wallet and start trading on the most accurate prediction markets.',
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
                      'The next generation prediction market platform that combines blockchain technology with advanced analytics.',
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
                // Company links
                Expanded(
                  child: _footerLinks(
                    'Company',
                    [
                      FooterLinkItem('About Us', onTap: () => _navigateTo('about')),
                      FooterLinkItem('Team', onTap: () => _navigateTo('team')),
                      FooterLinkItem('Careers', onTap: () => _navigateTo('careers')),
                      FooterLinkItem('Contact', onTap: () => _sendEmail(_contactEmail)),
                    ],
                    theme,
                  ),
                ),
                // Products links
                Expanded(
                  child: _footerLinks(
                    'Products',
                    [
                      FooterLinkItem('Predictions', onTap: () => _navigateTo('predictions')),
                      FooterLinkItem('Analytics', onTap: () => _navigateTo('analytics')),
                      FooterLinkItem('API', onTap: () => _navigateTo('api')),
                      FooterLinkItem('Enterprise', onTap: () => _navigateTo('enterprise')),
                    ],
                    theme,
                  ),
                ),
                // Resources links
                Expanded(
                  child: _footerLinks(
                    'Resources',
                    [
                      FooterLinkItem('Blog', onTap: () => _navigateTo('blog')),
                      FooterLinkItem('Documentation', onTap: () => _navigateTo('docs')),
                      FooterLinkItem('Community', onTap: () => _navigateTo('community')),
                      FooterLinkItem('Help Center', onTap: () => _sendEmail(_contactEmail)),
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
                // Company links
                _footerLinksCompact(
                  'Company',
                  [
                    FooterLinkItem('About Us', onTap: () => _navigateTo('about')),
                    FooterLinkItem('Team', onTap: () => _navigateTo('team')),
                    FooterLinkItem('Careers', onTap: () => _navigateTo('careers')),
                    FooterLinkItem('Contact', onTap: () => _sendEmail(_contactEmail)),
                  ],
                  theme,
                ),
                // Products links
                _footerLinksCompact(
                  'Products',
                  [
                    FooterLinkItem('Predictions', onTap: () => _navigateTo('predictions')),
                    FooterLinkItem('Analytics', onTap: () => _navigateTo('analytics')),
                    FooterLinkItem('API', onTap: () => _navigateTo('api')),
                    FooterLinkItem('Enterprise', onTap: () => _navigateTo('enterprise')),
                  ],
                  theme,
                ),
              ],
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Resources links
                _footerLinksCompact(
                  'Resources',
                  [
                    FooterLinkItem('Blog', onTap: () => _navigateTo('blog')),
                    FooterLinkItem('Documentation', onTap: () => _navigateTo('docs')),
                    FooterLinkItem('Community', onTap: () => _navigateTo('community')),
                    FooterLinkItem('Help Center', onTap: () => _sendEmail(_contactEmail)),
                  ],
                  theme,
                ),
                const SizedBox(width: 40), // Empty spacer for alignment
              ],
            ),
          ],
          const SizedBox(height: 60),
          const Divider(color: Colors.white10),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '© 2023 Nexus Predictions. All rights reserved.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
              if (MediaQuery.of(context).size.width > 600)
                Row(
                  children: [
                    InkWell(
                      onTap: () => _navigateTo('privacy'),
                      child: Text(
                        'Privacy Policy',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onBackground.withOpacity(0.7),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    InkWell(
                      onTap: () => _navigateTo('terms'),
                      child: Text(
                        'Terms of Service',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onBackground.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
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
    
    const pointCount = 20;
    final path = Path();
    final rand = math.Random(42);
    
    for (var i = 0; i < pointCount; i++) {
      final x = size.width * i / (pointCount - 1);
      final heightFactor = 0.5 + (math.sin(i / 3) * 0.3) + (rand.nextDouble() * 0.2);
      final y = size.height * (1 - heightFactor);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    
    canvas.drawPath(path, paint);
    
    // Draw area below the line
    final areaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withOpacity(0.3), color.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    final areaPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    
    canvas.drawPath(areaPath, areaPaint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}