import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/market_outcome_card.dart';
import '../widgets/sentiment_analysis_widget.dart';
import '../widgets/live_twitter_feed.dart';
import '../widgets/privacy_verification_indicator.dart';
import '../widgets/wallet_balance_widget.dart';
import '../widgets/wallet_connection_widget.dart';
import '../models/market_data.dart';
import '../models/sentiment_data.dart';
import '../models/twitter_data.dart';
import '../services/wallet_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<MarketData> _marketData = MarketData.getDummyData();
  final List<SentimentData> _sentimentData = SentimentData.getDummyData();
  final List<TwitterData> _twitterData = TwitterData.getDummyData();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Refresh wallet balances on dashboard load for better UX
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final walletService = Provider.of<WalletService>(context, listen: false);
      if (walletService.isConnected) {
        walletService.refreshBalances();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 1200;
    final isTablet = MediaQuery.of(context).size.width >= 600 && MediaQuery.of(context).size.width < 1200;

    return Scaffold(
      appBar: AppBar(
        title: const Text('EigenBets Predictions Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          const PrivacyVerificationIndicator(),
          const SizedBox(width: 16),
          CircleAvatar(
            radius: 16,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
            child: Icon(
              Icons.person_outline,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 24),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isDesktop
            ? _buildDesktopLayout()
            : isTablet
                ? _buildTabletLayout()
                : _buildMobileLayout(),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return SingleChildScrollView(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left column - 70% width
          Expanded(
            flex: 7,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWalletSection(),
                const SizedBox(height: 24),
                _buildMarketOutcomesSection(),
                const SizedBox(height: 24),
                _buildSentimentAnalysisSection(),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Right column - 30% width
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTwitterFeedSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWalletSection(),
          const SizedBox(height: 24),
          _buildMarketOutcomesSection(),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: _buildSentimentAnalysisSection(),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 4,
                child: _buildTwitterFeedSection(),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildWalletSection() {
    final walletService = Provider.of<WalletService>(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your Wallet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (walletService.isConnected)
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamed('/wallet');
                },
                icon: const Icon(Icons.account_balance_wallet, size: 18),
                label: const Text('Manage'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        WalletBalanceWidget(
          onConnect: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => DraggableScrollableSheet(
                initialChildSize: 0.9,
                minChildSize: 0.5,
                maxChildSize: 0.95,
                builder: (_, controller) => Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.background,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Connect Wallet',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          child: WalletConnectionWidget(
                            onConnect: () {
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWalletSection(),
          const SizedBox(height: 24),
          _buildMarketOutcomesSection(),
          const SizedBox(height: 24),
          _buildSentimentAnalysisSection(),
          const SizedBox(height: 24),
          _buildTwitterFeedSection(),
        ],
      ),
    );
  }

  Widget _buildMarketOutcomesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Real-Time Market Outcomes',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          'Computed by Othentic AVS',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
              ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _marketData.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: MarketOutcomeCard(market: _marketData[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSentimentAnalysisSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI Agent Sentiment Analysis',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          'Weighted averages from multiple sources',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
              ),
        ),
        const SizedBox(height: 16),
        SentimentAnalysisWidget(sentimentData: _sentimentData),
      ],
    );
  }

  Widget _buildTwitterFeedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verified Twitter Data',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          'Via Chainlink external adapter',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
              ),
        ),
        const SizedBox(height: 16),
        LiveTwitterFeed(twitterData: _twitterData),
      ],
    );
  }
}
