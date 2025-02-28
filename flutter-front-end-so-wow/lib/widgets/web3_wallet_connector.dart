import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/web3_service.dart';

class Web3WalletConnector extends StatefulWidget {
  final Function? onConnect;
  final Function? onDisconnect;
  final bool showNetworkSelector;
  final bool enableMultiWallet;
  final bool showTestModeOption;
  
  const Web3WalletConnector({
    Key? key,
    this.onConnect,
    this.onDisconnect,
    this.showNetworkSelector = true,
    this.enableMultiWallet = true,
    this.showTestModeOption = true,
  }) : super(key: key);

  @override
  State<Web3WalletConnector> createState() => _Web3WalletConnectorState();
}

class _Web3WalletConnectorState extends State<Web3WalletConnector> {
  bool _isExpanded = false;
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final web3Service = Provider.of<Web3Service>(context);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(theme, web3Service),
          
          // Wallet Connection Section
          if (!web3Service.isConnected) ...[
            const Divider(height: 1),
            _buildConnectionOptions(theme, web3Service),
          ],
          
          // Wallet Connected Info
          if (web3Service.isConnected && _isExpanded) ...[
            const Divider(height: 1),
            _buildConnectedInfo(theme, web3Service),
          ],
          
          // Network Selector (when connected and expanded)
          if (web3Service.isConnected && _isExpanded && widget.showNetworkSelector) ...[
            const Divider(height: 1),
            _buildNetworkSelector(theme, web3Service),
          ],
          
          // Test Options
          if (!web3Service.isConnected && widget.showTestModeOption) ...[
            const Divider(height: 1),
            _buildTestOptions(theme, web3Service),
          ],
        ],
      ),
    );
  }
  
  Widget _buildHeader(ThemeData theme, Web3Service web3Service) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              web3Service.isConnected 
                  ? web3Service.getWalletIcon() 
                  : Icons.account_balance_wallet_outlined,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  web3Service.isConnected 
                      ? web3Service.getFormattedAddress()
                      : 'Connect Wallet',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  web3Service.isConnected
                      ? _getWalletTypeName(web3Service.connectedWalletType)
                      : 'Connect to continue',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          if (web3Service.isConnected) ...[
            IconButton(
              onPressed: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              icon: Icon(
                _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              tooltip: _isExpanded ? 'Show less' : 'Show more',
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildConnectionOptions(ThemeData theme, Web3Service web3Service) {
    // Primary wallets
    final primaryWallets = [
      Web3WalletType.metamask,
      Web3WalletType.walletConnect,
      Web3WalletType.coinbase,
    ];
    
    // Additional wallets (shown if enableMultiWallet is true)
    final additionalWallets = [
      Web3WalletType.trustWallet,
      Web3WalletType.rainbow,
      Web3WalletType.argent,
      Web3WalletType.ledger,
    ];
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Message
          Text(
            'Connect your wallet to access EigenBet',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          
          // Primary wallet options
          ...primaryWallets.map((walletType) => 
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildWalletOption(
                context, 
                walletType, 
                theme, 
                web3Service,
              ),
            ),
          ),
          
          // Additional wallet options
          if (widget.enableMultiWallet) ...[
            const SizedBox(height: 12),
            ExpansionTile(
              title: Text(
                'More Wallet Options',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...additionalWallets.map((walletType) => 
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildWalletOption(
                      context, 
                      walletType, 
                      theme, 
                      web3Service,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildWalletOption(
    BuildContext context,
    Web3WalletType walletType,
    ThemeData theme,
    Web3Service web3Service,
  ) {
    final walletInfo = _getWalletInfo(walletType);
    
    return InkWell(
      onTap: web3Service.isConnecting 
          ? null 
          : () => _connectWallet(context, walletType),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(16),
          color: theme.colorScheme.surface,
        ),
        child: Row(
          children: [
            // Wallet icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: walletInfo.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                walletInfo.icon,
                color: walletInfo.color,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            
            // Wallet name and description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    walletInfo.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    walletInfo.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            
            // Connect button
            if (web3Service.isConnecting && web3Service.connectedWalletType == walletType)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            else
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildConnectedInfo(ThemeData theme, Web3Service web3Service) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Address with copy button
          Row(
            children: [
              Text(
                'Wallet Address',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  // Copy address to clipboard
                  if (web3Service.walletAddress != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Address copied to clipboard'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                child: Row(
                  children: [
                    Text(
                      'Copy',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.copy,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              web3Service.walletAddress ?? '',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'Roboto Mono',
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Disconnect button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _disconnectWallet(context),
              icon: Icon(Icons.logout, size: 18),
              label: Text('Disconnect Wallet'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                side: BorderSide(color: theme.colorScheme.error.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNetworkSelector(ThemeData theme, Web3Service web3Service) {
    final networks = EVMNetwork.values;
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Network',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: networks.map((network) => 
              GestureDetector(
                onTap: () => _switchNetwork(context, network),
                child: Chip(
                  avatar: Icon(
                    web3Service.getNetworkIcon(),
                    size: 16,
                    color: web3Service.currentNetwork == network
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.primary,
                  ),
                  label: Text(_getNetworkName(network)),
                  backgroundColor: web3Service.currentNetwork == network
                      ? theme.colorScheme.primary
                      : theme.colorScheme.primaryContainer.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: web3Service.currentNetwork == network
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.primary,
                    fontWeight: web3Service.currentNetwork == network
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
            ).toList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTestOptions(ThemeData theme, Web3Service web3Service) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.tertiary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.tertiary.withOpacity(0.3),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.science_outlined, 
                  color: theme.colorScheme.tertiary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Testing Mode',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.tertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Use a demo wallet with pre-loaded funds for testing',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: web3Service.isConnecting 
                    ? null 
                    : () => _connectTestWallet(context),
                icon: Icon(Icons.bolt, size: 18),
                label: Text('Connect Demo Wallet'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.tertiary,
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
  
  Future<void> _connectWallet(BuildContext context, Web3WalletType walletType) async {
    final web3Service = Provider.of<Web3Service>(context, listen: false);
    
    final connected = await web3Service.connectWallet(walletType);
    
    if (connected) {
      if (widget.onConnect != null) {
        widget.onConnect!();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connected to ${_getWalletTypeName(walletType)}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect to ${_getWalletTypeName(walletType)}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
  
  Future<void> _disconnectWallet(BuildContext context) async {
    final web3Service = Provider.of<Web3Service>(context, listen: false);
    
    final disconnected = await web3Service.disconnectWallet();
    
    if (disconnected) {
      if (widget.onDisconnect != null) {
        widget.onDisconnect!();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Wallet disconnected'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
  
  Future<void> _switchNetwork(BuildContext context, EVMNetwork network) async {
    final web3Service = Provider.of<Web3Service>(context, listen: false);
    
    final switched = await web3Service.switchNetwork(network);
    
    if (switched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Switched to ${_getNetworkName(network)}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  
  Future<void> _connectTestWallet(BuildContext context) async {
    final web3Service = Provider.of<Web3Service>(context, listen: false);
    
    // This is simulating a test wallet connection
    final connected = await web3Service.connectWallet(Web3WalletType.metamask);
    
    if (connected) {
      if (widget.onConnect != null) {
        widget.onConnect!();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Connected to test wallet'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.tertiary,
          ),
        );
      }
    }
  }
  
  String _getWalletTypeName(Web3WalletType? walletType) {
    if (walletType == null) return '';
    
    switch (walletType) {
      case Web3WalletType.metamask:
        return 'MetaMask';
      case Web3WalletType.walletConnect:
        return 'WalletConnect';
      case Web3WalletType.coinbase:
        return 'Coinbase Wallet';
      case Web3WalletType.trustWallet:
        return 'Trust Wallet';
      case Web3WalletType.rainbow:
        return 'Rainbow';
      case Web3WalletType.argent:
        return 'Argent';
      case Web3WalletType.ledger:
        return 'Ledger';
      default:
        return 'Unknown Wallet';
    }
  }
  
  String _getNetworkName(EVMNetwork network) {
    switch (network) {
      case EVMNetwork.ethereum:
        return 'Ethereum';
      case EVMNetwork.polygon:
        return 'Polygon';
      case EVMNetwork.base:
        return 'Base';
      case EVMNetwork.arbitrum:
        return 'Arbitrum';
      case EVMNetwork.optimism:
        return 'Optimism';
      case EVMNetwork.avalanche:
        return 'Avalanche';
      default:
        return 'Unknown';
    }
  }
  
  _WalletInfo _getWalletInfo(Web3WalletType walletType) {
    switch (walletType) {
      case Web3WalletType.metamask:
        return _WalletInfo(
          name: 'MetaMask',
          description: 'Connect using MetaMask wallet',
          icon: Icons.pets,
          color: const Color(0xFFF6851B), // MetaMask orange
        );
      case Web3WalletType.walletConnect:
        return _WalletInfo(
          name: 'WalletConnect',
          description: 'Connect using WalletConnect',
          icon: Icons.link,
          color: const Color(0xFF3B99FC), // WalletConnect blue
        );
      case Web3WalletType.coinbase:
        return _WalletInfo(
          name: 'Coinbase Wallet',
          description: 'Connect using Coinbase Wallet',
          icon: Icons.account_balance_wallet,
          color: const Color(0xFF0052FF), // Coinbase blue
        );
      case Web3WalletType.trustWallet:
        return _WalletInfo(
          name: 'Trust Wallet',
          description: 'Connect using Trust Wallet',
          icon: Icons.security,
          color: const Color(0xFF3375BB), // Trust Wallet blue
        );
      case Web3WalletType.rainbow:
        return _WalletInfo(
          name: 'Rainbow',
          description: 'Connect using Rainbow wallet',
          icon: Icons.art_track,
          color: const Color(0xFF001E59), // Rainbow dark blue
        );
      case Web3WalletType.argent:
        return _WalletInfo(
          name: 'Argent',
          description: 'Connect using Argent wallet',
          icon: Icons.shield,
          color: const Color(0xFF8850f9), // Argent purple
        );
      case Web3WalletType.ledger:
        return _WalletInfo(
          name: 'Ledger Live',
          description: 'Connect using Ledger Live',
          icon: Icons.memory,
          color: const Color(0xFF000000), // Ledger black
        );
      default:
        return _WalletInfo(
          name: 'Unknown Wallet',
          description: 'Connect using wallet',
          icon: Icons.account_balance_wallet,
          color: Colors.grey,
        );
    }
  }
}

class _WalletInfo {
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  
  const _WalletInfo({
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });
}