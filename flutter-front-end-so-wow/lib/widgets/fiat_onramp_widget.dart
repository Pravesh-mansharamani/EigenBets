import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/wallet_service.dart';
import 'package:webview_flutter/webview_flutter.dart';

class FiatOnrampWidget extends StatefulWidget {
  const FiatOnrampWidget({Key? key}) : super(key: key);

  @override
  State<FiatOnrampWidget> createState() => _FiatOnrampWidgetState();
}

class _FiatOnrampWidgetState extends State<FiatOnrampWidget> {
  String _selectedCurrency = 'USD';
  String _selectedToken = 'USDC';
  final TextEditingController _amountController = TextEditingController(text: '100.00');
  bool _isProcessing = false;
  bool _useWebView = true; // Option to use WebView or external browser

  final List<String> _currencies = ['USD', 'EUR', 'GBP', 'CAD', 'AUD'];
  final List<String> _tokens = ['USDC', 'ETH', 'PRED'];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final walletService = Provider.of<WalletService>(context);
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Row(
          children: [
            Icon(
              Icons.local_atm,
              color: theme.colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Buy Crypto',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Powered by Coinbase',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onBackground.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Image.asset(
              'assets/icons/coinbase.png',
              width: 32,
              height: 32,
              errorBuilder: (context, error, stackTrace) => 
                Icon(Icons.monetization_on, size: 32, color: theme.colorScheme.primary),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Amount',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        _buildAmountInput(context),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pay with',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  _buildCurrencyDropdown(context),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Receive',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  _buildTokenDropdown(context),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Card(
          elevation: 0,
          color: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: theme.colorScheme.outline.withOpacity(0.5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transaction Details',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'You\'ll receive approximately',
                      style: theme.textTheme.bodyMedium,
                    ),
                    RichText(
                      text: TextSpan(
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        children: [
                          TextSpan(
                            text: _getTokenAmount(double.tryParse(_amountController.text) ?? 0),
                            style: TextStyle(
                              color: _getTokenColor(_selectedToken, theme),
                            ),
                          ),
                          TextSpan(
                            text: ' $_selectedToken',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Fee',
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      'Zero fee on Base',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
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
                      'Network',
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      'Base',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Checkbox(
              value: _useWebView,
              onChanged: (value) {
                setState(() {
                  _useWebView = value ?? true;
                });
              },
            ),
            Expanded(
              child: Text(
                'Use in-app browser for payment (recommended)',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isProcessing || !walletService.isConnected
                ? null
                : () => _initiateOnramp(walletService),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
            child: _isProcessing
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.onPrimary,
                    ),
                  )
                : Text(
                    'Buy $_selectedToken',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'Securely powered by Coinbase Onramp',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onBackground.withOpacity(0.6),
            ),
          ),
        ),
      ],
    ),
    );
  }

  Widget _buildAmountInput(BuildContext context) {
    final theme = Theme.of(context);
    
    return TextFormField(
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Text(
            _selectedCurrency == 'EUR' ? '€' : 
            _selectedCurrency == 'GBP' ? '£' : 
            _selectedCurrency == 'JPY' ? '¥' : '\$',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      onChanged: (_) {
        setState(() {
          // Just to rebuild the UI with updated token amount
        });
      },
    );
  }

  Widget _buildCurrencyDropdown(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.5),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCurrency,
          isExpanded: true,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          borderRadius: BorderRadius.circular(8),
          items: _currencies.map((currency) {
            return DropdownMenuItem<String>(
              value: currency,
              child: Row(
                children: [
                  _buildCurrencyIcon(currency, theme),
                  const SizedBox(width: 8),
                  Text(currency),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCurrency = value!;
            });
          },
        ),
      ),
    );
  }

  Widget _buildTokenDropdown(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.5),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedToken,
          isExpanded: true,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          borderRadius: BorderRadius.circular(8),
          items: _tokens.map((token) {
            return DropdownMenuItem<String>(
              value: token,
              child: Row(
                children: [
                  _buildTokenIcon(token, theme),
                  const SizedBox(width: 8),
                  Text(token),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedToken = value!;
            });
          },
        ),
      ),
    );
  }

  Widget _buildCurrencyIcon(String currency, ThemeData theme) {
    IconData iconData;
    Color color;
    
    switch (currency) {
      case 'USD':
        iconData = Icons.attach_money;
        color = Colors.green;
        break;
      case 'EUR':
        iconData = Icons.euro;
        color = Colors.blue;
        break;
      case 'GBP':
        iconData = Icons.currency_pound;
        color = Colors.indigo;
        break;
      case 'CAD':
        iconData = Icons.attach_money;
        color = Colors.red;
        break;
      case 'AUD':
        iconData = Icons.attach_money;
        color = Colors.deepPurple;
        break;
      default:
        iconData = Icons.attach_money;
        color = theme.colorScheme.primary;
    }
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: color,
        size: 16,
      ),
    );
  }

  Widget _buildTokenIcon(String token, ThemeData theme) {
    IconData iconData;
    Color color;
    
    switch (token) {
      case 'USDC':
        iconData = Icons.currency_exchange;
        color = Colors.blue;
        break;
      case 'ETH':
        iconData = Icons.diamond_outlined;
        color = Colors.purple;
        break;
      case 'PRED':
        iconData = Icons.show_chart;
        color = theme.colorScheme.primary;
        break;
      default:
        iconData = Icons.token;
        color = theme.colorScheme.primary;
    }
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: color,
        size: 16,
      ),
    );
  }

  Color _getTokenColor(String token, ThemeData theme) {
    switch (token) {
      case 'USDC':
        return Colors.blue;
      case 'ETH':
        return Colors.purple;
      case 'PRED':
        return theme.colorScheme.primary;
      default:
        return theme.colorScheme.primary;
    }
  }

  String _getTokenAmount(double fiatAmount) {
    switch (_selectedToken) {
      case 'ETH':
        return (fiatAmount / 2000).toStringAsFixed(6);
      case 'USDC':
        return fiatAmount.toStringAsFixed(2);
      case 'PRED':
        return (fiatAmount * 2).toStringAsFixed(2);
      default:
        return fiatAmount.toStringAsFixed(2);
    }
  }

  Future<void> _initiateOnramp(WalletService walletService) async {
    if (!walletService.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please connect your wallet first'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    setState(() {
      _isProcessing = true;
    });
    
    // Determine destination chain based on the network
    String destinationChain;
    switch (walletService.currentNetwork) {
      case NetworkType.base:
        destinationChain = 'base';
        break;
      case NetworkType.ethereum:
        destinationChain = 'ethereum';
        break;
      case NetworkType.polygon:
        destinationChain = 'polygon';
        break;
    }
    
    // Launch Coinbase Onramp flow
    try {
      final success = await walletService.launchCoinbaseOnramp(
        context: context,
        asset: _selectedToken,
        amount: amount,
        useWebView: _useWebView,
      );
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully purchased $_selectedToken!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Purchase failed or was canceled. Please try again.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error initiating onramp: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
    
    setState(() {
      _isProcessing = false;
    });
  }
}

