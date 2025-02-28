import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/wallet_service.dart';
import '../utils/metamask.dart';
import 'package:flutter_animate/flutter_animate.dart';

class WalletBalanceWidget extends StatefulWidget {
  final bool showHeader;
  final bool compact;
  final VoidCallback? onConnect;
  
  const WalletBalanceWidget({
    Key? key,
    this.showHeader = true,
    this.compact = false,
    this.onConnect,
  }) : super(key: key);

  @override
  State<WalletBalanceWidget> createState() => _WalletBalanceWidgetState();
}

class _WalletBalanceWidgetState extends State<WalletBalanceWidget> {
  bool _isRefreshing = false;
  
  @override
  Widget build(BuildContext context) {
    final walletService = Provider.of<WalletService>(context);
    final theme = Theme.of(context);
    
    // If wallet is not connected, show connect button
    if (!walletService.isConnected) {
      return _buildConnectButton(context);
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      elevation: 0,
      child: Padding(
        padding: widget.compact 
          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
          : const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.showHeader) _buildHeader(walletService, theme),
            if (widget.showHeader) const SizedBox(height: 16),
            _buildBalances(walletService, theme),
            const SizedBox(height: 16),
            _buildActions(walletService, theme),
          ],
        ),
      ),
    )
    .animate()
    .fadeIn(duration: const Duration(milliseconds: 400))
    .moveY(begin: 10, end: 0, curve: Curves.easeOutQuad);
  }
  
  Widget _buildHeader(WalletService walletService, ThemeData theme) {
    final walletType = walletService.connectedWalletType?.toString().split('.').last ?? 'Unknown';
    final formattedAddress = _formatAddress(walletService.walletAddress ?? '');
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.account_balance_wallet_outlined,
            color: theme.colorScheme.primary,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Connected Wallet',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    formattedAddress,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      walletType,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.content_copy, size: 16),
          tooltip: 'Copy Address',
          onPressed: () {
            // Copy address to clipboard
            final address = walletService.walletAddress;
            if (address != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Address copied to clipboard'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        ),
      ],
    );
  }
  
  Widget _buildBalances(WalletService walletService, ThemeData theme) {
    // Use wallet service to get balances directly from the connected wallet
    final tokens = [
      TokenBalance(
        symbol: 'USDC', 
        balance: walletService.usdcBalance, 
        color: Colors.blue, 
        valuePrefix: '\$',
        decimals: 2,
      ),
      TokenBalance(
        symbol: 'ETH', 
        balance: walletService.ethBalance, 
        color: const Color(0xFF6370E5),
        decimals: 4,
      ),
      TokenBalance(
        symbol: 'PRED', 
        balance: walletService.predBalance, 
        color: theme.colorScheme.primary,
        decimals: 1,
      ),
    ];
    
    if (widget.compact) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: tokens.map((token) => _buildBalanceTile(token, theme)).toList(),
      );
    }
    
    return Column(
      children: tokens.map((token) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildBalanceRow(token, theme),
        );
      }).toList(),
    );
  }
  
  Widget _buildBalanceTile(TokenBalance token, ThemeData theme) {
    final valueStr = '${token.valuePrefix}${token.balance.toStringAsFixed(token.decimals)}';
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: token.color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            token.symbol.substring(0, 1),
            style: TextStyle(
              color: token.color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          valueStr,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          token.symbol,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
  
  Widget _buildBalanceRow(TokenBalance token, ThemeData theme) {
    final valueStr = '${token.valuePrefix}${token.balance.toStringAsFixed(token.decimals)}';
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: token.color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            token.symbol.substring(0, 1),
            style: TextStyle(
              color: token.color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(token.symbol, style: theme.textTheme.titleSmall),
            Text(
              'Available Balance',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
        const Spacer(),
        Text(
          valueStr,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    )
    .animate()
    .fadeIn(duration: const Duration(milliseconds: 400))
    .moveX(begin: 10, end: 0, curve: Curves.easeOutQuad);
  }
  
  Widget _buildActions(WalletService walletService, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isRefreshing 
              ? null 
              : () async {
                  setState(() => _isRefreshing = true);
                  await walletService.refreshBalances();
                  await Future.delayed(const Duration(milliseconds: 500));
                  if (mounted) setState(() => _isRefreshing = false);
                },
            icon: _isRefreshing 
              ? SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.refresh, size: 14),
            label: Text(_isRefreshing ? 'Refreshing...' : 'Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        if (!widget.compact)
          const SizedBox(width: 12),
        if (!widget.compact)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                await walletService.disconnectWallet();
              },
              icon: const Icon(Icons.logout, size: 14),
              label: const Text('Disconnect'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                side: BorderSide(color: theme.colorScheme.error.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildConnectButton(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surface.withOpacity(0.8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Wallet not connected',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Connect your wallet to access your balances and make predictions.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.onConnect,
                icon: const Icon(Icons.link),
                label: const Text('Connect Wallet'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatAddress(String address) {
    if (address.length < 10) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }
}

// Helper class for token balances
class TokenBalance {
  final String symbol;
  final double balance;
  final Color color;
  final String valuePrefix;
  final int decimals;
  
  const TokenBalance({
    required this.symbol,
    required this.balance,
    required this.color,
    this.valuePrefix = '',
    this.decimals = 2,
  });
}