import 'package:flutter/material.dart';
import '../models/market_data.dart';
import '../services/avs_service.dart';
import '../models/transaction_data.dart';

class BetPlacementForm extends StatefulWidget {
  final MarketData market;

  const BetPlacementForm({
    Key? key,
    required this.market,
  }) : super(key: key);

  @override
  State<BetPlacementForm> createState() => _BetPlacementFormState();
}

class _BetPlacementFormState extends State<BetPlacementForm> {
  String _selectedOutcome = 'Yes';
  double _betAmount = 100;
  final TextEditingController _amountController = TextEditingController(text: '100');
  final AvsService _avsService = AvsService();
  bool _isVerificationInProgress = false;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_updateBetAmount);
  }

  @override
  void dispose() {
    _amountController.removeListener(_updateBetAmount);
    _amountController.dispose();
    super.dispose();
  }

  void _updateBetAmount() {
    final text = _amountController.text;
    if (text.isNotEmpty) {
      setState(() {
        _betAmount = double.tryParse(text) ?? 0;
      });
    } else {
      setState(() {
        _betAmount = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Place Your Bet',
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          widget.market.title,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onBackground.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Select Outcome',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        _buildOutcomeSelector(context),
        const SizedBox(height: 24),
        Text(
          'Bet Amount',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        _buildAmountInput(context),
        const SizedBox(height: 8),
        _buildQuickAmountButtons(context),
        const SizedBox(height: 24),
        _buildBetSummary(context),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: _isVerificationInProgress 
          ? const Center(child: CircularProgressIndicator())
          : ElevatedButton(
              onPressed: _betAmount > 0 ? _placeBet : null,
              child: widget.market.expiryDate.isBefore(DateTime.now()) && !widget.market.isAvsVerified
                ? const Text('Request AVS Verification')
                : const Text('Place Bet'),
            ),
        ),
      ],
    );
  }

  Widget _buildOutcomeSelector(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedOutcome = 'Yes';
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: _selectedOutcome == 'Yes'
                    ? theme.colorScheme.primary.withOpacity(0.1)
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedOutcome == 'Yes'
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Yes',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: _selectedOutcome == 'Yes'
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onBackground,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(widget.market.yesPrice * 100).toStringAsFixed(1)}%',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: _selectedOutcome == 'Yes'
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onBackground.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedOutcome = 'No';
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: _selectedOutcome == 'No'
                    ? theme.colorScheme.error.withOpacity(0.1)
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedOutcome == 'No'
                      ? theme.colorScheme.error
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'No',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: _selectedOutcome == 'No'
                          ? theme.colorScheme.error
                          : theme.colorScheme.onBackground,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(widget.market.noPrice * 100).toStringAsFixed(1)}%',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: _selectedOutcome == 'No'
                          ? theme.colorScheme.error
                          : theme.colorScheme.onBackground.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAmountInput(BuildContext context) {
    final theme = Theme.of(context);
    
    return TextField(
      controller: _amountController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        prefixIcon: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'USDC',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: theme.colorScheme.surface,
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildQuickAmountButtons(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildQuickAmountButton(context, 10),
        _buildQuickAmountButton(context, 50),
        _buildQuickAmountButton(context, 100),
        _buildQuickAmountButton(context, 500),
      ],
    );
  }

  Widget _buildQuickAmountButton(BuildContext context, double amount) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: () {
        setState(() {
          _betAmount = amount;
          _amountController.text = amount.toString();
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '\$${amount.toInt()}',
          style: theme.textTheme.bodySmall,
        ),
      ),
    );
  }

  Widget _buildBetSummary(BuildContext context) {
    final theme = Theme.of(context);
    final outcomePrice = _selectedOutcome == 'Yes'
        ? widget.market.yesPrice
        : widget.market.noPrice;
    final potentialWinnings = _betAmount / outcomePrice;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bet Amount',
                style: theme.textTheme.bodyMedium,
              ),
              Text(
                '\$${_betAmount.toStringAsFixed(2)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Outcome Price',
                style: theme.textTheme.bodyMedium,
              ),
              Text(
                '${(outcomePrice * 100).toStringAsFixed(1)}%',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Potential Winnings',
                style: theme.textTheme.bodyMedium,
              ),
              Text(
                '\$${potentialWinnings.toStringAsFixed(2)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _placeBet() async {
    if (widget.market.status != MarketStatus.open) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This market is not open for betting',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    // Check if market needs AVS verification (if past expiry date)
    if (widget.market.expiryDate.isBefore(DateTime.now()) && !widget.market.isAvsVerified) {
      _requestAvsVerification();
      return;
    }
    
    // Regular bet placement logic for open markets
    setState(() {
      _isVerificationInProgress = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Bet placed successfully: $_betAmount USDC on $_selectedOutcome',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  Future<void> _requestAvsVerification() async {
    setState(() {
      _isVerificationInProgress = true;
    });
    
    // For demo purposes, we'll use the simulation function
    try {
      final result = await _avsService.simulateAvsVerification(widget.market);
      
      setState(() {
        _isVerificationInProgress = false;
      });
      
      // Show verification result
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Market verified by AVS. Outcome: ${result['outcome']}',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green[700],
        ),
      );
    } catch (e) {
      setState(() {
        _isVerificationInProgress = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('AVS verification failed: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }
}
