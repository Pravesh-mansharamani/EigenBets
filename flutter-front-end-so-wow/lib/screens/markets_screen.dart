import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/market_card.dart';
import '../widgets/market_filter_widget.dart';
import '../models/market_data.dart';
import '../screens/create_market_screen.dart';
import '../services/wallet_service.dart';

class MarketsScreen extends StatefulWidget {
  const MarketsScreen({Key? key}) : super(key: key);

  @override
  State<MarketsScreen> createState() => _MarketsScreenState();
}

class _MarketsScreenState extends State<MarketsScreen> {
  final List<MarketData> _markets = MarketData.getDummyData();
  String _selectedCategory = 'All';
  String _searchQuery = '';

  List<MarketData> get _filteredMarkets {
    return _markets.where((market) {
      final matchesCategory = _selectedCategory == 'All' || market.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty || 
          market.title.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 1200;
    final isTablet = MediaQuery.of(context).size.width >= 600 && MediaQuery.of(context).size.width < 1200;
    final walletService = Provider.of<WalletService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prediction Markets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter',
            onPressed: () {
              // Show filter dialog on mobile
              if (!isDesktop && !isTablet) {
                _showFilterDialog();
              }
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSearchBar(),
            const SizedBox(height: 16),
            Expanded(
              child: isDesktop || isTablet
                  ? _buildDesktopLayout()
                  : _buildMobileLayout(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (!walletService.isConnected) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please connect your wallet to create a market'),
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateMarketScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Market'),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search markets...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left sidebar - Filters
        SizedBox(
          width: 240,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: MarketFilterWidget(
                selectedCategory: _selectedCategory,
                onCategoryChanged: (category) {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Right content - Market grid
        Expanded(
          child: _buildMarketGrid(),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return _buildMarketGrid();
  }

  Widget _buildMarketGrid() {
    final isDesktop = MediaQuery.of(context).size.width >= 1200;
    final isTablet = MediaQuery.of(context).size.width >= 600 && MediaQuery.of(context).size.width < 1200;
    
    int crossAxisCount = isDesktop ? 3 : isTablet ? 2 : 1;
    
    return _filteredMarkets.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No markets found',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Try adjusting your filters or search query',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                      ),
                ),
              ],
            ),
          )
        : GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
            ),
            itemCount: _filteredMarkets.length,
            itemBuilder: (context, index) {
              return MarketCard(market: _filteredMarkets[index]);
            },
          );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Filter Markets',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              MarketFilterWidget(
                selectedCategory: _selectedCategory,
                onCategoryChanged: (category) {
                  setState(() {
                    _selectedCategory = category;
                  });
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

