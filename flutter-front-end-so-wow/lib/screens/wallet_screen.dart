import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/wallet_connection_widget.dart';
import '../widgets/web3_wallet_connector.dart';
import '../widgets/fiat_onramp_widget.dart';
import '../widgets/token_swap_widget.dart';
import '../widgets/transaction_history_widget.dart';
import '../widgets/metamask_connector_widget.dart';
import '../widgets/walletconnect_widget.dart';
import '../models/transaction_data.dart';
import '../services/wallet_service.dart';
import '../services/web3_service.dart';
import '../utils/metamask.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({Key? key}) : super(key: key);

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showWeb3Connector = true; // Set to true to show the new Web3 connector

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Load saved wallet connection, if any
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final walletService = Provider.of<WalletService>(context, listen: false);
      walletService.loadSavedConnection();
      
      // Also load Web3 wallet connection if available
      final web3Service = Provider.of<Web3Service>(context, listen: false);
      web3Service.loadSavedConnection();
      
      // Initialize MetaMask provider
      final metaMaskProvider = Provider.of<MetaMaskProvider>(context, listen: false);
      metaMaskProvider.init();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _connectWallet() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 1200;
    final isTablet = MediaQuery.of(context).size.width >= 600 && MediaQuery.of(context).size.width < 1200;
    final walletService = Provider.of<WalletService>(context);
    final web3Service = Provider.of<Web3Service>(context);
    
    // Determine if any wallet is connected (either Web3 or legacy wallet)
    final isAnyWalletConnected = walletService.isConnected || web3Service.isConnected;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet & Onboarding'),
        actions: [
          if (isAnyWalletConnected)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh Balances',
              onPressed: () async {
                if (web3Service.isConnected) {
                  // Get token balances for ETH, USDC, and PRED
                  await web3Service.getTokenBalance('ETH');
                  await web3Service.getTokenBalance('USDC');
                  await web3Service.getTokenBalance('PRED');
                } else if (walletService.isConnected) {
                  await walletService.refreshBalances();
                }
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Balances refreshed'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
          if (isAnyWalletConnected && !_showWeb3Connector)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Disconnect Wallet',
              onPressed: () async {
                if (web3Service.isConnected) {
                  await web3Service.disconnectWallet();
                } else if (walletService.isConnected) {
                  await walletService.disconnectWallet();
                }
                setState(() {});
              },
            ),
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Toggle Wallet Type',
            onPressed: () {
              setState(() {
                _showWeb3Connector = !_showWeb3Connector;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Help',
            onPressed: () {
              // Show help dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Wallet Help'),
                  content: const Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Connect your Web3 Wallet to:'),
                      SizedBox(height: 12),
                      Text('• Buy crypto with zero fees on Base'),
                      Text('• Create and trade on prediction markets'),
                      Text('• Swap tokens at the best rates'),
                      Text('• Track your transaction history'),
                      SizedBox(height: 12),
                      Text('Supported wallets: MetaMask, WalletConnect, Coinbase Wallet, and more'),
                      SizedBox(height: 12),
                      Text('Supported networks: Ethereum, Base, Polygon, Arbitrum, Optimism, Avalanche'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isAnyWalletConnected
            ? isDesktop
                ? _buildConnectedDesktopLayout(walletService, web3Service)
                : isTablet
                    ? _buildConnectedTabletLayout(walletService, web3Service)
                    : _buildConnectedMobileLayout(walletService, web3Service)
            : _buildWalletConnectionLayout(),
      ),
    );
  }

  Widget _buildWalletConnectionLayout() {
    return Center(
      child: Card(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: _showWeb3Connector
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: MetaMaskConnectorWidget(
                          onConnect: _connectWallet,
                          onDisconnect: () => setState(() {}),
                        ),
                      ),
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: WalletConnectWidget(
                          onConnect: _connectWallet,
                          onDisconnect: () => setState(() {}),
                        ),
                      ),
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.only(top: 24.0),
                        child: Web3WalletConnector(
                          onConnect: _connectWallet,
                          showNetworkSelector: true,
                          enableMultiWallet: true,
                          showTestModeOption: true,
                        ),
                      ),
                    ],
                  )
                : WalletConnectionWidget(
                    onConnect: _connectWallet,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectedDesktopLayout(WalletService walletService, Web3Service web3Service) {
    final isWeb3Connected = web3Service.isConnected;
    
    return SingleChildScrollView(
      child: SizedBox(
        // Set a minimum height to ensure the layout fills the screen
        height: MediaQuery.of(context).size.height - 100, // Account for AppBar and padding
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column - Wallet info and fiat onramp
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  isWeb3Connected
                      ? _buildWeb3WalletInfoCard(web3Service)
                      : _buildWalletInfoCard(walletService),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: FiatOnrampWidget(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            // Right column - Swap and transaction history
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTabBar(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Swap tab
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: SingleChildScrollView(
                              child: TokenSwapWidget(),
                            ),
                          ),
                        ),
                        // Transaction history tab
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: SingleChildScrollView(
                              child: isWeb3Connected
                                  ? _buildWeb3TransactionHistory(web3Service)
                                  : TransactionHistoryWidget(
                                      transactions: _getTransactions(walletService),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectedTabletLayout(WalletService walletService, Web3Service web3Service) {
    final isWeb3Connected = web3Service.isConnected;
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isWeb3Connected
              ? _buildWeb3WalletInfoCard(web3Service)
              : _buildWalletInfoCard(walletService),
          const SizedBox(height: 24),
          _buildTabBar(),
          SizedBox(
            height: 600, // Fixed height for TabBarView
            child: TabBarView(
              controller: _tabController,
              children: [
                // Swap tab
                SingleChildScrollView(
                  child: Column(
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: TokenSwapWidget(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: FiatOnrampWidget(),
                        ),
                      ),
                    ],
                  ),
                ),
                // Transaction history tab
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: SingleChildScrollView(
                      child: isWeb3Connected
                          ? _buildWeb3TransactionHistory(web3Service)
                          : TransactionHistoryWidget(
                              transactions: _getTransactions(walletService),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedMobileLayout(WalletService walletService, Web3Service web3Service) {
    final isWeb3Connected = web3Service.isConnected;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        isWeb3Connected
            ? _buildWeb3WalletInfoCard(web3Service)
            : _buildWalletInfoCard(walletService),
        const SizedBox(height: 24),
        _buildTabBar(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Swap tab
              SingleChildScrollView(
                child: Column(
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: TokenSwapWidget(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: FiatOnrampWidget(),
                      ),
                    ),
                  ],
                ),
              ),
              // Transaction history tab
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: isWeb3Connected
                      ? _buildWeb3TransactionHistory(web3Service)
                      : TransactionHistoryWidget(
                          transactions: _getTransactions(walletService),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  // New Web3 Wallet Info Card
  Widget _buildWeb3WalletInfoCard(Web3Service web3Service) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    web3Service.getWalletIcon(),
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getWalletTypeName(web3Service.connectedWalletType),
                        style: theme.textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 4, // horizontal spacing
                        children: [
                          Text(
                            web3Service.getFormattedAddress(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onBackground.withOpacity(0.6),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          InkWell(
                            onTap: () {
                              // Copy address to clipboard
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Address copied to clipboard'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.copy, size: 14),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildWeb3NetworkBadge(web3Service.currentNetwork, theme),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Your Balances',
                    style: theme.textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Flexible(
                  child: TextButton(
                    onPressed: () async {
                      await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Switch Network'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: EVMNetwork.values.map((network) {
                              return ListTile(
                                leading: Icon(web3Service.getNetworkIcon()),
                                title: Text(_getNetworkName(network)),
                                selected: web3Service.currentNetwork == network,
                                onTap: () {
                                  web3Service.switchNetwork(network);
                                  Navigator.pop(context);
                                },
                              );
                            }).toList(),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                          ],
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(10, 36),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.swap_horiz, size: 14),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Switch',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<double>(
              future: web3Service.getTokenBalance('ETH'),
              builder: (context, snapshot) {
                final ethBalance = snapshot.data ?? 0.0;
                return FutureBuilder<double>(
                  future: web3Service.getTokenBalance('USDC'),
                  builder: (context, snapshot) {
                    final usdcBalance = snapshot.data ?? 0.0;
                    return FutureBuilder<double>(
                      future: web3Service.getTokenBalance('PRED'),
                      builder: (context, snapshot) {
                        final predBalance = snapshot.data ?? 0.0;
                        return Row(
                          children: [
                            Expanded(
                              child: _buildBalanceTile(
                                'USDC',
                                '\$${usdcBalance.toStringAsFixed(2)}',
                                Colors.green,
                                theme,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildBalanceTile(
                                'ETH',
                                '${ethBalance.toStringAsFixed(4)} ETH',
                                Colors.blue,
                                theme,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildBalanceTile(
                                'PRED',
                                '${predBalance.toStringAsFixed(2)} PRED',
                                theme.colorScheme.primary,
                                theme,
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await web3Service.disconnectWallet();
                  setState(() {});
                },
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Disconnect Wallet'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(color: theme.colorScheme.error.withOpacity(0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Web3 Transaction History
  Widget _buildWeb3TransactionHistory(Web3Service web3Service) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: web3Service.getTransactionHistory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading transactions: ${snapshot.error}'),
          );
        }
        
        final transactions = snapshot.data ?? [];
        
        if (transactions.isEmpty) {
          return const Center(
            child: Text('No transactions found'),
          );
        }
        
        // Convert Web3 transactions to TransactionData model
        final txData = transactions.map((tx) {
          final tokenSymbol = tx['tokenSymbol'] as String? ?? 'ETH';
          final timestamp = DateTime.fromMillisecondsSinceEpoch(tx['timestamp'] as int);
          final isIncoming = tx['to'] == web3Service.walletAddress;
          
          return TransactionData(
            txHash: tx['hash'] as String,
            type: isIncoming ? TransactionType.swap : TransactionType.swap,
            description: isIncoming 
                ? 'Received from ${_formatAddress(tx['from'] as String)}'
                : 'Sent to ${_formatAddress(tx['to'] as String)}',
            amount: tx['tokenValue'] as double,
            token: tokenSymbol,
            timestamp: timestamp,
            status: tx['status'] as String,
          );
        }).toList();
        
        return TransactionHistoryWidget(
          transactions: txData,
        );
      },
    );
  }
  
  // Web3 Network Badge
  Widget _buildWeb3NetworkBadge(EVMNetwork network, ThemeData theme) {
    String networkName = _getNetworkName(network);
    Color color;
    
    switch (network) {
      case EVMNetwork.base:
        color = Colors.blue;
        break;
      case EVMNetwork.ethereum:
        color = Colors.purple;
        break;
      case EVMNetwork.polygon:
        color = Colors.indigo;
        break;
      case EVMNetwork.arbitrum:
        color = Colors.red;
        break;
      case EVMNetwork.optimism:
        color = Colors.red.shade700;
        break;
      case EVMNetwork.avalanche:
        color = Colors.red.shade800;
        break;
      default:
        color = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        networkName,
        style: theme.textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10, // Smaller font size
        ),
        overflow: TextOverflow.ellipsis, // Handle text overflow
      ),
    );
  }
  
  // Helper for Web3 wallet type name
  String _getWalletTypeName(Web3WalletType? walletType) {
    if (walletType == null) return 'Unknown Wallet';
    
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
  
  // Helper for Web3 network name
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

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      tabs: const [
        Tab(text: 'Swap & Buy'),
        Tab(text: 'Transactions'),
      ],
    );
  }

  Widget _buildWalletInfoCard(WalletService walletService) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getWalletIcon(walletService.connectedWalletType),
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getWalletName(walletService.connectedWalletType),
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            _formatAddress(walletService.walletAddress ?? ''),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onBackground.withOpacity(0.6),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 16),
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              // Copy address to clipboard
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildNetworkBadge(walletService.currentNetwork, theme),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Your Balances',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildBalanceTile(
                    'USDC',
                    '\$${walletService.usdcBalance.toStringAsFixed(2)}',
                    Colors.green,
                    theme,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildBalanceTile(
                    'ETH',
                    '${walletService.ethBalance.toStringAsFixed(4)} ETH',
                    Colors.blue,
                    theme,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildBalanceTile(
                    'PRED',
                    '${walletService.predBalance.toStringAsFixed(2)} PRED',
                    theme.colorScheme.primary,
                    theme,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkBadge(NetworkType network, ThemeData theme) {
    String networkName;
    Color color;
    
    switch (network) {
      case NetworkType.base:
        networkName = 'Base';
        color = Colors.blue;
        break;
      case NetworkType.ethereum:
        networkName = 'Ethereum';
        color = Colors.purple;
        break;
      case NetworkType.polygon:
        networkName = 'Polygon';
        color = Colors.indigo;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        networkName,
        style: theme.textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildBalanceTile(String token, String amount, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            token,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  amount,
                  style: theme.textTheme.titleSmall?.copyWith(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getWalletIcon(WalletType? type) {
    switch (type) {
      case WalletType.mockWallet:
        return Icons.account_balance_wallet;
      case WalletType.metamask:
        return Icons.pets; // Fox icon as a stand-in for Metamask
      case WalletType.walletConnect:
        return Icons.link;
      default:
        return Icons.account_balance_wallet;
    }
  }

  String _getWalletName(WalletType? type) {
    switch (type) {
      case WalletType.mockWallet:
        return 'Demo Wallet';
      case WalletType.metamask:
        return 'MetaMask';
      case WalletType.walletConnect:
        return 'WalletConnect';
      default:
        return 'Connected Wallet';
    }
  }

  String _formatAddress(String address) {
    if (address.length < 10) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  List<TransactionData> _getTransactions(WalletService walletService) {
    // Convert wallet service transactions to TransactionData model
    final txs = walletService.transactions;
    if (txs.isEmpty) {
      return TransactionData.getDummyData(); // Use dummy data if no real txs
    }
    
    return txs.map((tx) {
      final timestamp = DateTime.fromMillisecondsSinceEpoch(tx['timestamp'] as int);
      return TransactionData(
        txHash: tx['hash'] as String,
        type: TransactionType.swap, // Would need proper mapping in real app
        description: 'Transfer to ${_formatAddress(tx['to'] as String)}',
        amount: tx['amount'] as double,
        token: tx['token'] as String,
        timestamp: timestamp,
        status: tx['status'] as String,
      );
    }).toList();
  }
}

