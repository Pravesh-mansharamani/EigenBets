import 'package:flutter/material.dart';
import '../widgets/bet_placement_form.dart';
import '../widgets/market_odds_display.dart';
import '../widgets/token_swap_widget.dart';
import '../widgets/wallet_balance_widget.dart';
import '../widgets/avs_verification_indicator.dart';
import '../models/market_data.dart';
import '../services/avs_service.dart';
import 'dart:math' as math;

class BettingScreen extends StatefulWidget {
  const BettingScreen({Key? key}) : super(key: key);

  @override
  State<BettingScreen> createState() => _BettingScreenState();
}

class _BettingScreenState extends State<BettingScreen> {
  final List<MarketData> _markets = MarketData.getDummyData();
  late MarketData _selectedMarket;
  final AvsService _avsService = AvsService();
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _selectedMarket = _markets.first;
  }
  
  // Handle AVS verification result
  void _handleVerificationComplete(Map<String, dynamic> result) {
    final marketId = result['marketId'];
    // FORCE outcome to Yes for demo
    const outcome = 'Yes';
    final verificationId = result['verificationId'];
    final timestamp = DateTime.parse(result['timestamp']);
    
    setState(() {
      // Find market and update with verification data
      final index = _markets.indexWhere((m) => m.id == marketId);
      if (index != -1) {
        final updatedMarket = MarketData(
          id: _markets[index].id,
          title: _markets[index].title,
          description: _markets[index].description,
          category: _markets[index].category,
          yesPrice: _markets[index].yesPrice,
          noPrice: _markets[index].noPrice,
          volume: _markets[index].volume,
          expiryDate: _markets[index].expiryDate,
          imageUrl: _markets[index].imageUrl,
          priceHistory: _markets[index].priceHistory,
          status: MarketStatus.resolved,
          isAvsVerified: true,
          avsVerificationId: verificationId,
          avsVerificationTimestamp: timestamp,
          outcomeResult: 'Yes', // FORCE outcome to YES
        );
        
        _markets[index] = updatedMarket;
        
        // If this was the selected market, update it
        if (_selectedMarket.id == marketId) {
          _selectedMarket = updatedMarket;
        }
      }
    });
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Market verified by AVS: Outcome is YES'),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  // This method has been replaced with _verifyWithAVSDialog for a more interactive UI experience

  // Verify market with AVS button action handler
  Future<void> _verifyWithAVSDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Verifying Market with AVS...'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 16),
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Requesting verification from AVS nodes...'),
            ],
          ),
        );
      },
    );
    
    // Simulate verification delay
    await Future.delayed(const Duration(seconds: 3));
    
    // Close the loading dialog
    if (mounted) {
      Navigator.of(context).pop();
    }
    
    // FORCE "Yes" outcome for demo - 100% guaranteed
    const String outcome = 'Yes';
    final result = {
      'verificationId': 'avs_${DateTime.now().millisecondsSinceEpoch}',
      'marketId': _selectedMarket.id,
      'status': 'verified',
      'outcome': outcome,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    // Update market with verification results
    _handleVerificationComplete(result);
    
    // Show verification result dialog
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('AVS Verification Complete'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified,
                  color: Colors.blue,
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Market Outcome: YES',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 16),
                Text('The market has been verified by the AVS network and is now resolved.'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    }
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
          // Add a dedicated AVS verification button in the app bar
          if (_selectedMarket.expiryDate.isBefore(DateTime.now()) && !_selectedMarket.isAvsVerified)
            TextButton.icon(
              onPressed: _verifyWithAVSDialog,
              icon: const Icon(Icons.verified_user, color: Colors.white),
              label: const Text(
                'Verify with AVS',
                style: TextStyle(color: Colors.white),
              ),
            ),
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
                    const SizedBox(height: 24),
                    AvsVerificationIndicator(
                      market: _selectedMarket,
                      onVerificationComplete: _handleVerificationComplete,
                    ),
                    if (_selectedMarket.expiryDate.isBefore(DateTime.now()) && !_selectedMarket.isAvsVerified)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: _isVerifying
                            ? const Center(child: CircularProgressIndicator())
                            : ElevatedButton.icon(
                                onPressed: _verifyWithAVSDialog,
                                icon: const Icon(Icons.verified_user),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.secondary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                                ),
                                label: const Text('Verify and Close Betting with AVS'),
                              ),
                        ),
                      ),
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
                  const SizedBox(height: 24),
                  AvsVerificationIndicator(
                    market: _selectedMarket,
                    onVerificationComplete: _handleVerificationComplete,
                  ),
                  if (_selectedMarket.expiryDate.isBefore(DateTime.now()) && !_selectedMarket.isAvsVerified)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: _isVerifying
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton.icon(
                              onPressed: _verifyWithAVSDialog,
                              icon: const Icon(Icons.verified_user),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.secondary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16.0),
                              ),
                              label: const Text('Verify and Close Betting with AVS'),
                            ),
                      ),
                    ),
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
              child: Column(
                children: [
                  MarketOddsDisplay(market: _selectedMarket),
                  const SizedBox(height: 16),
                  AvsVerificationIndicator(
                    market: _selectedMarket,
                    onVerificationComplete: _handleVerificationComplete,
                  ),
                  if (_selectedMarket.expiryDate.isBefore(DateTime.now()) && !_selectedMarket.isAvsVerified)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: _isVerifying
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton.icon(
                              onPressed: _verifyWithAVSDialog,
                              icon: const Icon(Icons.verified_user),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.secondary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12.0),
                              ),
                              label: const Text('Verify and Close Betting with AVS'),
                            ),
                      ),
                    ),
                ],
              ),
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
    // Get available width for dropdown
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1200;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    
    // Calculate appropriate width constraints based on device size
    double dropdownWidth = isDesktop 
        ? screenWidth * 0.5  // Desktop gets half the screen width
        : isTablet 
            ? screenWidth * 0.75  // Tablet gets 75% of the screen width
            : screenWidth - 60;   // Mobile gets almost full width (accounting for padding)
    
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: dropdownWidth),
      child: DropdownButtonFormField<MarketData>(
        value: _selectedMarket,
        isExpanded: true, // Important for handling long text
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
          child: Text(
            market.title,
            overflow: TextOverflow.ellipsis,
            maxLines: 1, 
          ),
        );
      }).toList(),
      onChanged: (MarketData? newValue) {
        if (newValue != null) {
          setState(() {
            _selectedMarket = newValue;
          });
        }
      },
    ));
  }
}

