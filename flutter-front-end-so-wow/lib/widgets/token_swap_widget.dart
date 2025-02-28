import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/wallet_service.dart';

class TokenSwapWidget extends StatefulWidget {
  const TokenSwapWidget({Key? key}) : super(key: key);

  @override
  State<TokenSwapWidget> createState() => _TokenSwapWidgetState();
}

class _TokenSwapWidgetState extends State<TokenSwapWidget> {
  String _fromToken = 'ETH';
  String _toToken = 'USDC';
  final TextEditingController _fromAmountController = TextEditingController(text: '0.1');
  final TextEditingController _toAmountController = TextEditingController(text: '200.00');
  bool _isSwapping = false;

  final Map<String, double> _exchangeRates = {
    'ETH': 2000.0,
    'USDC': 1.0,
    'PRED': 0.5,
  };

  @override
  void initState() {
    super.initState();
    _fromAmountController.addListener(_updateToAmount);
  }

  @override
  void dispose() {
    _fromAmountController.removeListener(_updateToAmount);
    _fromAmountController.dispose();
    _toAmountController.dispose();
    super.dispose();
  }

  void _updateToAmount() {
    final fromAmount = double.tryParse(_fromAmountController.text) ?? 0;
    final fromRate = _exchangeRates[_fromToken] ?? 1;
    final toRate = _exchangeRates[_toToken] ?? 1;
    
    final toAmount = fromAmount * fromRate / toRate;
    _toAmountController.text = toAmount.toStringAsFixed(2);
  }

  void _swapTokens() {
    setState(() {
      final temp = _fromToken;
      _fromToken = _toToken;
      _toToken = temp;
      
      final fromAmount = double.tryParse(_fromAmountController.text) ?? 0;
      final fromRate = _exchangeRates[_fromToken] ?? 1;
      final toRate = _exchangeRates[_toToken] ?? 1;
      
      final toAmount = fromAmount * fromRate / toRate;
      _toAmountController.text = toAmount.toStringAsFixed(2);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final walletService = Provider.of<WalletService>(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Swap Tokens',
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Powered by Uniswap',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onBackground.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 24),
        _buildTokenInput(
          context,
          'From',
          _fromToken,
          _fromAmountController,
          (token) {
            setState(() {
              if (token == _toToken) {
                _toToken = _fromToken;
              }
              _fromToken = token;
              _updateToAmount();
            });
          },
        ),
        const SizedBox(height: 16),
        Center(
          child: IconButton(
            onPressed: _swapTokens,
            icon: const Icon(Icons.swap_vert),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.surface,
              padding: const EdgeInsets.all(12),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildTokenInput(
          context,
          'To',
          _toToken,
          _toAmountController,
          (token) {
            setState(() {
              if (token == _fromToken) {
                _fromToken = _toToken;
              }
              _toToken = token;
              _updateToAmount();
            });
          },
          readOnly: true,
        ),
        const SizedBox(height: 24),
        Text(
          'Swap Details',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildSwapDetailRow(
                context,
                'Exchange Rate',
                '1 $_fromToken = ${(_exchangeRates[_fromToken] ?? 0) / (_exchangeRates[_toToken] ?? 1)} $_toToken',
              ),
              const SizedBox(height: 8),
              _buildSwapDetailRow(
                context,
                'Network Fee',
                _fromToken == 'USDC' || _toToken == 'USDC' ? 'FREE' : '~\$2.50',
                isHighlighted: _fromToken == 'USDC' || _toToken == 'USDC',
              ),
              const SizedBox(height: 8),
              _buildSwapDetailRow(
                context,
                'Slippage Tolerance',
                '0.5%',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSwapping || !walletService.isConnected 
                ? null 
                : () => _executeSwap(walletService),
            child: _isSwapping
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text('Swapping...'),
                    ],
                  )
                : Text('Swap $_fromToken to $_toToken'),
          ),
        ),
        if (!walletService.isConnected)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Center(
              child: Text(
                'Please connect your wallet first',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ),
        const SizedBox(height: 16),
        if (_fromToken == 'USDC' || _toToken == 'USDC')
          Center(
            child: Text(
              'Zero fees on USDC transfers on Base',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTokenInput(
    BuildContext context,
    String label,
    String selectedToken,
    TextEditingController controller,
    Function(String) onTokenChanged, {
    bool readOnly = false,
  }) {
    final theme = Theme.of(context);
    final walletService = Provider.of<WalletService>(context);
    
    String balance = '0';
    if (selectedToken == 'ETH') {
      balance = walletService.ethBalance.toString();
    } else if (selectedToken == 'USDC') {
      balance = walletService.usdcBalance.toString();
    } else if (selectedToken == 'PRED') {
      balance = walletService.predBalance.toString();
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onBackground.withOpacity(0.6),
                ),
              ),
              if (walletService.isConnected)
                Text(
                  'Balance: $balance',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onBackground.withOpacity(0.6),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  readOnly: readOnly,
                  style: theme.textTheme.headlineSmall,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () => _showTokenSelector(context, selectedToken, onTokenChanged),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.surface,
                  elevation: 0,
                  side: BorderSide(
                    color: theme.colorScheme.onBackground.withOpacity(0.1),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: Row(
                  children: [
                    _getTokenIcon(selectedToken, theme),
                    const SizedBox(width: 8),
                    Text(selectedToken),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_drop_down,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (label == 'From' && walletService.isConnected)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  // Set max amount based on balance
                  if (selectedToken == 'ETH') {
                    _fromAmountController.text = walletService.ethBalance.toString();
                  } else if (selectedToken == 'USDC') {
                    _fromAmountController.text = walletService.usdcBalance.toString();
                  } else if (selectedToken == 'PRED') {
                    _fromAmountController.text = walletService.predBalance.toString();
                  }
                  _updateToAmount();
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'MAX',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSwapDetailRow(
    BuildContext context,
    String label,
    String value, {
    bool isHighlighted = false,
  }) {
    final theme = Theme.of(context);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onBackground.withOpacity(0.6),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isHighlighted ? theme.colorScheme.primary : null,
          ),
        ),
      ],
    );
  }

  void _showTokenSelector(
    BuildContext context,
    String selectedToken,
    Function(String) onTokenChanged,
  ) {
    final tokens = ['ETH', 'USDC', 'PRED'];
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Token'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: tokens.map((token) {
              return ListTile(
                leading: _getTokenIcon(token, theme),
                title: Text(token),
                subtitle: Text('Balance: ${_getTokenBalance(token, context)}'),
                selected: token == selectedToken,
                onTap: () {
                  onTokenChanged(token);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _getTokenIcon(String token, ThemeData theme) {
    IconData iconData;
    Color color;
    
    switch (token) {
      case 'ETH':
        iconData = Icons.currency_bitcoin;
        color = Colors.blue;
        break;
      case 'USDC':
        iconData = Icons.monetization_on;
        color = Colors.green;
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

  String _getTokenBalance(String token, BuildContext context) {
    final walletService = Provider.of<WalletService>(context, listen: false);
    
    if (!walletService.isConnected) {
      switch (token) {
        case 'ETH':
          return '0.842';
        case 'USDC':
          return '1,245.00';
        case 'PRED':
          return '500.00';
        default:
          return '0.00';
      }
    }
    
    switch (token) {
      case 'ETH':
        return walletService.ethBalance.toString();
      case 'USDC':
        return walletService.usdcBalance.toString();
      case 'PRED':
        return walletService.predBalance.toString();
      default:
        return '0.00';
    }
  }

  Future<void> _executeSwap(WalletService walletService) async {
    final fromAmount = double.tryParse(_fromAmountController.text) ?? 0;
    if (fromAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    // Check if user has enough balance
    bool hasEnoughBalance = false;
    switch (_fromToken) {
      case 'ETH':
        hasEnoughBalance = walletService.ethBalance >= fromAmount;
        break;
      case 'USDC':
        hasEnoughBalance = walletService.usdcBalance >= fromAmount;
        break;
      case 'PRED':
        hasEnoughBalance = walletService.predBalance >= fromAmount;
        break;
    }
    
    if (!hasEnoughBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Insufficient $_fromToken balance'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    
    setState(() {
      _isSwapping = true;
    });
    
    // Simulate executing swap
    final toAmount = double.tryParse(_toAmountController.text) ?? 0;
    final result = await walletService.sendTransaction(
      to: '0xUniswapRouterAddress',
      amount: fromAmount,
      token: _fromToken,
    );
    
    setState(() {
      _isSwapping = false;
    });
    
    if (result != null) {
      // Update balances based on the swap
      if (_fromToken == 'ETH') {
        walletService.ethBalance -= fromAmount;
      } else if (_fromToken == 'USDC') {
        walletService.usdcBalance -= fromAmount;
      } else if (_fromToken == 'PRED') {
        walletService.predBalance -= fromAmount;
      }
      
      if (_toToken == 'ETH') {
        walletService.ethBalance += toAmount;
      } else if (_toToken == 'USDC') {
        walletService.usdcBalance += toAmount;
      } else if (_toToken == 'PRED') {
        walletService.predBalance += toAmount;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Swapped $fromAmount $_fromToken for $toAmount $_toToken'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Swap failed. Please try again.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}

