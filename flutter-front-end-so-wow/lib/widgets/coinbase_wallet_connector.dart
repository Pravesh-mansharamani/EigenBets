import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/wallet_service.dart';

class CoinbaseWalletConnector extends StatefulWidget {
  const CoinbaseWalletConnector({Key? key}) : super(key: key);

  @override
  State<CoinbaseWalletConnector> createState() => _CoinbaseWalletConnectorState();
}

class _CoinbaseWalletConnectorState extends State<CoinbaseWalletConnector> {
  bool _isConnecting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final walletService = Provider.of<WalletService>(context);
    final isConnected = walletService.isConnected;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: isConnected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceVariant.withOpacity(0.3),
          width: isConnected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(16),
        color: isConnected 
            ? theme.colorScheme.primary.withOpacity(0.05)
            : theme.colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0052FF).withOpacity(0.1), // Coinbase blue
                  shape: BoxShape.circle,
                ),
                // Using icon directly instead of asset image
                child: Icon(
                  Icons.account_balance_wallet, 
                  size: 20, 
                  color: const Color(0xFF0052FF),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Coinbase Wallet',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isConnected)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Connected',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (isConnected)
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: theme.colorScheme.primary,
                    size: 18,
                  ),
                ),
            ],
          ),
          if (!isConnected) ...[
            const SizedBox(height: 10),
            Text(
              'Connect with Coinbase\'s secure wallet for the best experience',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isConnecting 
                    ? null
                    : () => _connectCoinbaseWallet(walletService),
                style: ButtonStyle(
                  backgroundColor: MaterialStatePropertyAll(
                    const Color(0xFF0052FF), // Coinbase blue
                  ),
                  foregroundColor: MaterialStatePropertyAll(
                    Colors.white,
                  ),
                  padding: const MaterialStatePropertyAll(
                    EdgeInsets.symmetric(vertical: 14),
                  ),
                  elevation: const MaterialStatePropertyAll(0),
                ),
                child: _isConnecting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Connect with Coinbase',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _connectCoinbaseWallet(WalletService walletService) async {
    if (_isConnecting) return;
    
    setState(() {
      _isConnecting = true;
    });
    
    try {
      final connected = await walletService.connectWallet(WalletType.metamask);
      
      if (connected && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Successfully connected to Coinbase Wallet'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to connect to Coinbase Wallet'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
      }
    }
  }
} 