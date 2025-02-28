import 'package:flutter/material.dart';
import '../widgets/bet_placement_form.dart';
import '../widgets/market_odds_display.dart';
import '../widgets/token_swap_widget.dart';
import '../widgets/wallet_balance_widget.dart';
import '../models/market_data.dart';

class BettingScreen extends StatefulWidget {
  const BettingScreen({Key? key}) : super(key: key);

  @override
  State<BettingScreen> createState() => _BettingScreenState();
}

class _BettingScreenState extends State<BettingScreen> {
  final List<MarketData> _markets = MarketData.getDummyData();
  late MarketData _selectedMarket;

  @override
  void initState() {
    super.initState();
    _selectedMarket = _markets.first;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 1200;
    final isTablet = MediaQuery.of(context).size.width >= 600 && MediaQuery.of(context).size.width < 1200;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Place Your Bets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Betting History',
            onPressed: () {},
          ),
          const SizedBox(width: 16),
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
          // Left column - Market selection and odds
          Expanded(
            flex: 6,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Market',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _buildMarketSelector(),
                    const SizedBox(height: 24),
                    MarketOddsDisplay(market: _selectedMarket),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          // Right column - Bet placement and token swap
          Expanded(
            flex: 4,
            child: Column(
              children: [
                // Show wallet balances first
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: const WalletBalanceWidget(
                      compact: true,
                      showHeader: true,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: BetPlacementForm(market: _selectedMarket),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: const TokenSwapWidget(),
                  ),
                ),
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
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Market',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildMarketSelector(),
                  const SizedBox(height: 24),
                  MarketOddsDisplay(market: _selectedMarket),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: BetPlacementForm(market: _selectedMarket),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: const TokenSwapWidget(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Market',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildMarketSelector(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: MarketOddsDisplay(market: _selectedMarket),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: BetPlacementForm(market: _selectedMarket),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: const TokenSwapWidget(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketSelector() {
    return DropdownButtonFormField<MarketData>(
      value: _selectedMarket,
      decoration: InputDecoration(
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      items: _markets.map((market) {
        return DropdownMenuItem<MarketData>(
          value: market,
          child: Text(market.title),
        );
      }).toList(),
      onChanged: (MarketData? newValue) {
        if (newValue != null) {
          setState(() {
            _selectedMarket = newValue;
          });
        }
      },
    );
  }
}

