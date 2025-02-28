// main_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'prediction_market_service.dart';
import 'wallet_service.dart';

class PredictionMarketScreen extends StatefulWidget {
  const PredictionMarketScreen({Key? key}) : super(key: key);

  @override
  _PredictionMarketScreenState createState() => _PredictionMarketScreenState();
}

class _PredictionMarketScreenState extends State<PredictionMarketScreen> {
  late PredictionMarketService _marketService;
  late WalletService _walletService;
  bool _isLoading = true;
  bool _isAdmin = false;
  
  Map<String, dynamic> _marketData = {};
  Map<String, double> _userBalances = {'yes': 0, 'no': 0, 'usdc': 0};
  
  final TextEditingController _usdcAmountController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _marketService = Provider.of<PredictionMarketService>(context, listen: false);
    _walletService = Provider.of<WalletService>(context, listen: false);
    
    _initialize();
  }
  
  Future<void> _initialize() async {
    try {
      // Initialize market service with user's private key
      await _marketService.initialize(_walletService.privateKey);
      
      // Subscribe to market data updates
      _marketService.marketDataStream.listen((data) {
        setState(() {
          _marketData = data;
          _isAdmin = _marketData['owner'] == _walletService.address;
        });
      });
      
      // Load user balances
      await _refreshBalances();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error initializing: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error connecting to the prediction market'))
      );
    }
  }
  
  Future<void> _refreshBalances() async {
    final balances = await _marketService.getUserBalances();
    setState(() {
      _userBalances = balances;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prediction Market'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshBalances,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMarketStatusCard(),
            const SizedBox(height: 16),
            _buildBalancesCard(),
            const SizedBox(height: 16),
            if (_marketData['isOpen'] && !_marketData['isResolved'])
              _buildTradingCard(),
            if (_marketData['isResolved'])
              _buildResolutionCard(),
            if (_isAdmin)
              _buildAdminCard(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMarketStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Market Status',
              style: Theme.of(context).textTheme.headline6,
            ),
            const SizedBox(height: 8),
            _buildStatusItem('Open', _marketData['isOpen']),
            _buildStatusItem('Closed', _marketData['isClosed']),
            _buildStatusItem('Resolved', _marketData['isResolved']),
            if (_marketData['isResolved'])
              _buildStatusItem(
                'Outcome',
                _marketData['outcome'] ? 'YES' : 'NO',
                isText: true,
              ),
            const Divider(),
            if (_marketData['isOpen'] && !_marketData['isResolved']) ...[
              Text(
                'Current Odds',
                style: Theme.of(context).textTheme.subtitle1,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: _buildOddsItem(
                      'YES',
                      _marketData['yesOdds'] ?? 50,
                      Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _buildOddsItem(
                      'NO',
                      _marketData['noOdds'] ?? 50,
                      Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Current Prices',
                style: Theme.of(context).textTheme.subtitle1,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: _buildPriceItem(
                      'YES Token',
                      _marketData['yesPrice'] ?? 0,
                      Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _buildPriceItem(
                      'NO Token',
                      _marketData['noPrice'] ?? 0,
                      Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatusItem(String label, dynamic value, {bool isText = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text('$label: '),
          if (isText)
            Text(
              value.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: value == 'YES' ? Colors.green : Colors.red,
              ),
            )
          else
            Icon(
              value ? Icons.check_circle : Icons.cancel,
              color: value ? Colors.green : Colors.red,
              size: 16,
            ),
        ],
      ),
    );
  }
  
  Widget _buildOddsItem(String label, int percentage, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 40,
              width: 40,
              child: CircularProgressIndicator(
                value: percentage / 100,
                strokeWidth: 8,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                backgroundColor: Colors.grey[300],
              ),
            ),
            Text(
              '$percentage%',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildPriceItem(String label, double price, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '\$${price.toStringAsFixed(4)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBalancesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Balances',
              style: Theme.of(context).textTheme.headline6,
            ),
            const SizedBox(height: 8),
            _buildBalanceItem('USDC', _userBalances['usdc'] ?? 0, Colors.blue),
            _buildBalanceItem('YES Tokens', _userBalances['yes'] ?? 0, Colors.green),
            _buildBalanceItem('NO Tokens', _userBalances['no'] ?? 0, Colors.red),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBalanceItem(String token, double amount, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(token),
          Text(
            amount.toStringAsFixed(token == 'USDC' ? 2 : 4),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTradingCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trade Tokens',
              style: Theme.of(context).textTheme.headline6,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _usdcAmountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'USDC Amount',
                hintText: 'Enter amount of USDC',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('Buy YES'),
                    style: ElevatedButton.styleFrom(
                      primary: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => _handleBuyYes(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('Buy NO'),
                    style: ElevatedButton.styleFrom(
                      primary: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => _handleBuyNo(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.sell),
                    label: const Text('Sell YES'),
                    style: OutlinedButton.styleFrom(
                      primary: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: _userBalances['yes']! > 0
                        ? () => _showSellDialog('yes')
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.sell),
                    label: const Text('Sell NO'),
                    style: OutlinedButton.styleFrom(
                      primary: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: _userBalances['no']! > 0
                        ? () => _showSellDialog('no')
                        : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildResolutionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Market Resolved',
              style: Theme.of(context).textTheme.headline6,
            ),
            const SizedBox(height: 8),
            Text(
              'The outcome was: ${_marketData['outcome'] ? 'YES' : 'NO'}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: _marketData['outcome'] ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.attach_money),
              label: const Text('Claim Rewards'),
              style: ElevatedButton.styleFrom(
                primary: Colors.amber,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 24,
                ),
              ),
              onPressed: _handleClaimRewards,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAdminCard() {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.admin_panel_settings),
                const SizedBox(width: 8),
                Text(
                  'Admin Controls',
                  style: Theme.of(context).textTheme.headline6,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Open Market'),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.green,
                  ),
                  onPressed: !_marketData['isOpen'] && !_marketData['isResolved']
                      ? _handleOpenMarket
                      : null,
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.stop),
                  label: const Text('Close Market'),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.orange,
                  ),
                  onPressed: _marketData['isOpen'] && !_marketData['isClosed']
                      ? _handleCloseMarket
                      : null,
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Resolve YES'),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.green[700],
                  ),
                  onPressed: _marketData['isClosed'] && !_marketData['isResolved']
                      ? () => _handleResolveOutcome(true)
                      : null,
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.cancel),
                  label: const Text('Resolve NO'),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.red[700],
                  ),
                  onPressed: _marketData['isClosed'] && !_marketData['isResolved']
                      ? () => _handleResolveOutcome(false)
                      : null,
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset Market'),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.blueGrey,
                  ),
                  onPressed: _marketData['isResolved']
                      ? _handleResetMarket
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  void _showSellDialog(String tokenType) {
    final TextEditingController amountController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Sell ${tokenType.toUpperCase()} Tokens'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Available: ${_userBalances[tokenType]?.toStringAsFixed(4)}'),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount to Sell',
                  hintText: 'Enter amount of $tokenType tokens',
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Sell'),
              onPressed: () {
                Navigator.of(context).pop();
                _handleSellTokens(
                  tokenType,
                  double.tryParse(amountController.text) ?? 0,
                );
              },
            ),
          ],
        );
      },
    );
  }
  
  Future<void> _handleBuyYes() async {
    final amount = double.tryParse(_usdcAmountController.text);
    if (amount == null || amount <= 0) {
      _showErrorSnackBar('Please enter a valid amount');
      return;
    }
    
    try {
      _showLoadingDialog('Approving USDC...');
      await _marketService.approveUSDC(amount);
      Navigator.of(context).pop(); // Close approval dialog
      
      _showLoadingDialog('Buying YES tokens...');
      await _marketService.buyYesTokens(amount);
      Navigator.of(context).pop(); // Close buying dialog
      
      _usdcAmountController.clear();
      await _refreshBalances();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully bought YES tokens!'))
      );
    } catch (e) {
      Navigator.of(context).pop(); // Close any open dialog
      _showErrorSnackBar('Error: ${e.toString()}');
    }
  }
  
  Future<void> _handleBuyNo() async {
    final amount = double.tryParse(_usdcAmountController.text);
    if (amount == null || amount <= 0) {
      _showErrorSnackBar('Please enter a valid amount');
      return;
    }
    
    try {
      _showLoadingDialog('Approving USDC...');
      await _marketService.approveUSDC(amount);
      Navigator.of(context).pop(); // Close approval dialog
      
      _showLoadingDialog('Buying NO tokens...');
      await _marketService.buyNoTokens(amount);
      Navigator.of(context).pop(); // Close buying dialog
      
      _usdcAmountController.clear();
      await _refreshBalances();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully bought NO tokens!'))
      );
    } catch (e) {
      Navigator.of(context).pop(); // Close any open dialog
      _showErrorSnackBar('Error: ${e.toString()}');
    }
  }
  
  Future<void> _handleSellTokens(String tokenType, double amount) async {
    if (amount <= 0 || amount > (_userBalances[tokenType] ?? 0)) {
      _showErrorSnackBar('Please enter a valid amount');
      return;
    }
    
    try {
      _showLoadingDialog('Selling ${tokenType.toUpperCase()} tokens...');
      
      if (tokenType == 'yes') {
        await _marketService.sellYesTokens(amount);
      } else {
        await _marketService.sellNoTokens(amount);
      }
      
      Navigator.of(context).pop(); // Close dialog
      await _refreshBalances();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully sold ${tokenType.toUpperCase()} tokens!'))
      );
    } catch (e) {
      Navigator.of(context).pop(); // Close dialog
      _showErrorSnackBar('Error: ${e.toString()}');
    }
  }
  
  Future<void> _handleClaimRewards() async {
    try {
      _showLoadingDialog('Claiming rewards...');
      await _marketService.claimRewards();
      Navigator.of(context).pop(); // Close dialog
      
      await _refreshBalances();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully claimed rewards!'))
      );
    } catch (e) {
      Navigator.of(context).pop(); // Close dialog
      _showErrorSnackBar('Error: ${e.toString()}');
    }
  }
  
  Future<void> _handleOpenMarket() async {
    try {
      _showLoadingDialog('Opening market...');
      await _marketService.openMarket();
      Navigator.of(context).pop(); // Close dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Market opened successfully!'))
      );
    } catch (e) {
      Navigator.of(context).pop(); // Close dialog
      _showErrorSnackBar('Error: ${e.toString()}');
    }
  }
  
  Future<void> _handleCloseMarket() async {
    try {
      _showLoadingDialog('Closing market...');
      await _marketService.closeMarket();
      Navigator.of(context).pop(); // Close dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Market closed successfully!'))
      );
    } catch (e) {
      Navigator.of(context).pop(); // Close dialog
      _showErrorSnackBar('Error: ${e.toString()}');
    }
  }
  
  Future<void> _handleResolveOutcome(bool outcomeIsYes) async {
    try {
      _showLoadingDialog('Resolving market...');
      await _marketService.resolveOutcome(outcomeIsYes);
      Navigator.of(context).pop(); // Close dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Market resolved as ${outcomeIsYes ? "YES" : "NO"}!'),
        )
      );
    } catch (e) {
      Navigator.of(context).pop(); // Close dialog
      _showErrorSnackBar('Error: ${e.toString()}');
    }
  }
  
  Future<void> _handleResetMarket() async {
    try {
      _showLoadingDialog('Resetting market...');
      await _marketService.resetMarket();
      Navigator.of(context).pop(); // Close dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Market reset successfully!'))
      );
    } catch (e) {
      Navigator.of(context).pop(); // Close dialog
      _showErrorSnackBar('Error: ${e.toString()}');
    }
  }
  
  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(message),
            ],
          ),
        );
      },
    );
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      )
    );
  }
  
  @override
  void dispose() {
    _usdcAmountController.dispose();
    super.dispose();
  }
}