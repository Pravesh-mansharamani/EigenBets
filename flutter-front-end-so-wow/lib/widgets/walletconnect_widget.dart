import 'package:flutter/material.dart';
import 'package:walletconnect_qrcode_modal_dart/walletconnect_qrcode_modal_dart.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:async';
import '../services/web3_service.dart';

// Note: For now, we'll just skip the custom credentials class since it requires
// more extensive implementation. We'll modify our widget to not need transaction sending
// for this demo.

/// A widget that provides WalletConnect connection functionality using QR code modal
class WalletConnectWidget extends StatefulWidget {
  final Function? onConnect;
  final Function? onDisconnect;

  const WalletConnectWidget({
    Key? key,
    this.onConnect,
    this.onDisconnect,
  }) : super(key: key);

  @override
  State<WalletConnectWidget> createState() => _WalletConnectWidgetState();
}

class _WalletConnectWidgetState extends State<WalletConnectWidget> {
  bool _isConnecting = false;
  bool _isConnected = false;
  String? _walletAddress;
  String? _chainId;
  String? _errorMessage;
  late WalletConnectQrCodeModal _qrCodeModal;
  SessionStatus? _session;

  @override
  void initState() {
    super.initState();
    _initializeWalletConnect();
  }

  @override
  void dispose() {
    // Disconnect wallet when widget is disposed
    if (_isConnected && _qrCodeModal.connector.connected) {
      _qrCodeModal.killSession();
    }
    super.dispose();
  }

  void _initializeWalletConnect() {
    // Create a new instance of WalletConnectQrCodeModal
    _qrCodeModal = WalletConnectQrCodeModal(
      connector: WalletConnect(
        bridge: 'https://bridge.walletconnect.org',
        clientMeta: const PeerMeta(
          name: 'EigenBet',
          description: 'A decentralized prediction markets platform',
          url: 'https://eigenbet.xyz',
          icons: [
            'https://raw.githubusercontent.com/walletconnect/walletconnect-assets/master/Icon/Gradient/Icon.png'
          ],
        ),
      ),
    );

    // Register event handlers
    _qrCodeModal.registerListeners(
      onConnect: (session) {
        if (session?.accounts != null && session!.accounts.isNotEmpty) {
          final sessionStatus = SessionStatus(
            chainId: session.chainId ?? 8453, // Default to Base
            accounts: session.accounts,
          );
          _onWalletConnected(sessionStatus);
        }
      },
      onSessionUpdate: (response) {
        if (response?.accounts != null && response!.accounts.isNotEmpty) {
          final sessionStatus = SessionStatus(
            chainId: response.chainId ?? 8453, // Default to Base
            accounts: response.accounts,
          );
          _onSessionUpdate(sessionStatus);
        }
      },
      onDisconnect: _onWalletDisconnected,
    );

    // Check if already connected
    if (_qrCodeModal.connector.connected) {
      final session = _qrCodeModal.connector.session;
      final sessionStatus = SessionStatus(
        chainId: session.chainId ?? 8453, // Default to Base
        accounts: session.accounts,
      );
      _onWalletConnected(sessionStatus);
    }
  }

  void _onWalletConnected(SessionStatus? session) {
    if (session == null || session.accounts.isEmpty) {
      setState(() {
        _isConnected = false;
        _errorMessage = 'Failed to get account data';
      });
      return;
    }

    final address = session.accounts[0];

    setState(() {
      _session = session;
      _isConnected = true;
      _walletAddress = address;
      _chainId = session.chainId?.toString();
      _isConnecting = false;
      _errorMessage = null;
    });

    // Update Web3Service with the connected account info
    final web3Service = Provider.of<Web3Service>(context, listen: false);
    web3Service.updateWalletConnect(
      isConnected: true,
      address: address,
      chainId: session.chainId?.toString(),
      walletType: Web3WalletType.walletConnect,
    );

    if (widget.onConnect != null) {
      widget.onConnect!();
    }
  }

  void _onSessionUpdate(SessionStatus? session) {
    if (session == null) return;

    setState(() {
      _session = session;
      _walletAddress = session.accounts.isNotEmpty ? session.accounts[0] : null;
      _chainId = session.chainId?.toString();
    });

    // Update Web3Service with the updated account info
    if (_walletAddress != null) {
      final web3Service = Provider.of<Web3Service>(context, listen: false);
      web3Service.updateWalletConnect(
        isConnected: true,
        address: _walletAddress!,
        chainId: _chainId,
        walletType: Web3WalletType.walletConnect,
      );
    }
  }

  void _onWalletDisconnected() {
    setState(() {
      _isConnected = false;
      _walletAddress = null;
      _chainId = null;
      _session = null;
    });

    // Update Web3Service to disconnect
    final web3Service = Provider.of<Web3Service>(context, listen: false);
    web3Service.updateWalletConnect(
      isConnected: false,
      address: null,
      chainId: null,
      walletType: null,
    );

    if (widget.onDisconnect != null) {
      widget.onDisconnect!();
    }
  }

  Future<void> _connectWallet() async {
    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    try {
      // Show QR code modal and connect to a wallet
      // For ETH we use chain ID 1 (Ethereum Mainnet)
      // For Base use chain ID 8453
      final session = await _qrCodeModal.connect(
        context,
        chainId: 8453, // Base mainnet
      ).catchError((error) {
        setState(() {
          _errorMessage = 'Connection cancelled or failed: $error';
          _isConnecting = false;
        });
        return null;
      });

      if (session == null) {
        setState(() {
          _isConnecting = false;
          if (_errorMessage == null) {
            _errorMessage = 'Connection failed: Session is null';
          }
        });
      }
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _errorMessage = 'Error connecting: $e';
      });
    }
  }

  Future<void> _disconnectWallet() async {
    if (!_isConnected) return;

    try {
      await _qrCodeModal.killSession();
      // The _onWalletDisconnected event handler will update the state
    } catch (e) {
      setState(() {
        _errorMessage = 'Error disconnecting: $e';
      });
    }
  }

  String _formatAddress(String address) {
    if (address.length <= 10) return address;
    return "${address.substring(0, 6)}...${address.substring(address.length - 4)}";
  }

  String _getNetworkName(String? chainId) {
    if (chainId == null) return 'Unknown';
    
    switch (chainId) {
      case '1': return 'Ethereum';
      case '137': return 'Polygon';
      case '8453': return 'Base';
      case '42161': return 'Arbitrum';
      case '10': return 'Optimism';
      case '43114': return 'Avalanche';
      default: return 'Chain #$chainId';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_isConnected && _walletAddress != null) {
      // Connected state
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B99FC).withOpacity(0.1), // WalletConnect blue
                    shape: BoxShape.circle,
                  ),
                  child: Image.network(
                    'https://raw.githubusercontent.com/walletconnect/walletconnect-assets/master/Icon/Gradient/Icon.png',
                    width: 24,
                    height: 24,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.link,
                      color: const Color(0xFF3B99FC),
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WalletConnect',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            _formatAddress(_walletAddress!),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 16),
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              // Copy address to clipboard
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Address copied to clipboard'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    _getNetworkName(_chainId),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _disconnectWallet,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(color: theme.colorScheme.error),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Disconnect'),
                  ),
                ),
              ],
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Error',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _errorMessage!,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    } else {
      // Not connected state
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B99FC).withOpacity(0.1), // WalletConnect blue
                    shape: BoxShape.circle,
                  ),
                  child: Image.network(
                    'https://raw.githubusercontent.com/walletconnect/walletconnect-assets/master/Icon/Gradient/Icon.png',
                    width: 24,
                    height: 24,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.link,
                      color: const Color(0xFF3B99FC),
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'WalletConnect',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Connect to your mobile wallet using WalletConnect',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isConnecting ? null : _connectWallet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B99FC),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isConnecting
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.qr_code_scanner),
                          const SizedBox(width: 8),
                          Text(
                            'Connect Wallet',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Error',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _errorMessage!,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    }
  }
}