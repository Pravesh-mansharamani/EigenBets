import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/wallet_service.dart';
import '../utils/metamask.dart';
import 'coinbase_wallet_connector.dart';
import 'metamask_connector_widget.dart';

class WalletConnectionWidget extends StatelessWidget {
  final Function onConnect;
  
  const WalletConnectionWidget({
    Key? key,
    required this.onConnect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final walletService = Provider.of<WalletService>(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 16),
                Text(
                  'Connect Your Wallet',
                  style: theme.textTheme.titleLarge,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
            child: Text(
              'Choose your preferred wallet to connect with EigenBet',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
          
                  const SizedBox(height: 8),
          
          // MetaMask
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
            child: MetaMaskConnectorWidget(
              onConnect: () {
                final metamask = Provider.of<MetaMaskProvider>(context, listen: false);
                final walletService = Provider.of<WalletService>(context, listen: false);
                
                // Transfer wallet info from MetaMask to WalletService
                if (metamask.isConnected) {
                  walletService.setWalletAddress(
                    metamask.currentAddress,
                    WalletType.metamask,
                    NetworkType.ethereum
                  );
                }
                onConnect();
              },
            ),
          ),
          const SizedBox(height: 16),
          
          // WalletConnect
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
            child: _buildWalletOption(
              context,
              'WalletConnect',
              Icons.link,
              const Color(0xFF3B99FC), // WalletConnect blue
              () => _connectWallet(context, WalletType.walletConnect),
              'Connect with any WalletConnect compatible wallet',
            ),
          ),
          const SizedBox(height: 24),
          
          // Show mock wallet option in non-production builds
          if (!const bool.fromEnvironment('dart.library.io') || true) // Always show during development
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
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
                      'Use a demo wallet with pre-loaded funds for testing the application',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          try {
                            final walletService = Provider.of<WalletService>(context, listen: false);
                            walletService.connectWithMockWallet().then((_) {
                              print("Mock wallet connected successfully");
                              onConnect();
                            }).catchError((error) {
                              print("Error connecting mock wallet: $error");
                            });
                          } catch (e) {
                            print("Exception when connecting mock wallet: $e");
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.tertiary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Connect Demo Wallet'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWalletOption(
    BuildContext context,
    String name,
    IconData icon,
    Color color,
    VoidCallback onTap,
    String description,
  ) {
    final theme = Theme.of(context);
    final walletService = Provider.of<WalletService>(context);
    final isConnected = walletService.isConnected &&
        walletService.connectedWalletType.toString().split('.').last.toLowerCase() ==
            name.toLowerCase();
    
    return InkWell(
      onTap: isConnected ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
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
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _connectMetamask(BuildContext context) async {
    try {
      // Show connecting indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connecting to MetaMask...'),
          duration: const Duration(seconds: 1),
        ),
      );
      
      final metamaskProvider = Provider.of<MetaMaskProvider>(context, listen: false);
      final walletService = Provider.of<WalletService>(context, listen: false);
      
      print("Attempting to connect to MetaMask...");
      final connected = await metamaskProvider.connect();
      print("MetaMask connection result: $connected");
      
      if (connected) {
        // Update wallet service with MetaMask address
        walletService.setWalletAddress(
          metamaskProvider.currentAddress,
          WalletType.metamask,
          NetworkType.ethereum
        );
        
        print("MetaMask connected successfully: ${metamaskProvider.currentAddress}");
        onConnect();
      } else {
        print("MetaMask connection failed");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect to MetaMask'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print("Exception during MetaMask connection: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
  
  Future<void> _connectWallet(BuildContext context, WalletType type) async {
    try {
      final walletService = Provider.of<WalletService>(context, listen: false);
      
      // Show connecting indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connecting to ${type.toString().split('.').last} wallet...'),
          duration: const Duration(seconds: 1),
        ),
      );
      
      print("Attempting to connect wallet type: $type");
      final connected = await walletService.connectWallet(type);
      print("Connection result: $connected");
      
      if (connected) {
        print("Wallet connected, calling onConnect callback");
        onConnect();
      } else {
        print("Wallet connection failed");
        // Show error message if connection failed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect to ${type.toString().split('.').last} wallet'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print("Exception during wallet connection: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

