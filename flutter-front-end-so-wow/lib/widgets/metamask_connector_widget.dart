import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/metamask.dart';

class MetaMaskConnectorWidget extends StatefulWidget {
  final Function? onConnect;
  final Function? onDisconnect;
  
  const MetaMaskConnectorWidget({
    Key? key,
    this.onConnect,
    this.onDisconnect,
  }) : super(key: key);

  @override
  State<MetaMaskConnectorWidget> createState() => _MetaMaskConnectorWidgetState();
}

class _MetaMaskConnectorWidgetState extends State<MetaMaskConnectorWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Consumer<MetaMaskProvider>(
      builder: (context, provider, child) {
        if (provider.isConnected && provider.isInOperatingChain) {
          // Connected to the correct chain
          return Container(
            padding: const EdgeInsets.all(16),
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
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_outline,
                        color: Colors.green,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MetaMask Connected',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            provider.formattedAddress,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        await provider.disconnect();
                        if (widget.onDisconnect != null) {
                          widget.onDisconnect!();
                        }
                      },
                      icon: Icon(
                        Icons.link_off,
                        color: theme.colorScheme.error,
                      ),
                      tooltip: 'Disconnect',
                    ),
                  ],
                ),
              ],
            ),
          );
        } else if (provider.isConnected && !provider.isInOperatingChain) {
          // Connected but to the wrong chain
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.orange.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Wrong Network',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Please switch to Base network',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () async {
                        await provider.disconnect();
                        if (widget.onDisconnect != null) {
                          widget.onDisconnect!();
                        }
                      },
                      child: Text('Disconnect'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        await provider.switchNetwork(MetaMaskProvider.operatingChain);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                      ),
                      child: const Text('Switch to Base'),
                    ),
                  ],
                ),
              ],
            ),
          );
        } else if (provider.isEnabled) {
          // Not connected but can connect
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6851B).withOpacity(0.1), // MetaMask orange
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.pets, // Fox icon for MetaMask
                        color: Color(0xFFF6851B),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'MetaMask',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Connect with MetaMask to access your wallet',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: provider.isLoading 
                      ? null 
                      : () async {
                          final connected = await provider.connect();
                          if (connected && widget.onConnect != null) {
                            widget.onConnect!();
                          }
                        },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF6851B), // MetaMask orange
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      disabledBackgroundColor: const Color(0xFFF6851B).withOpacity(0.5),
                    ),
                    child: provider.isLoading
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
                            const Icon(Icons.link),
                            const SizedBox(width: 8),
                            Text('Connect MetaMask'),
                          ],
                        ),
                  ),
                ),
                if (provider.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      provider.error!,
                      style: TextStyle(color: Colors.red, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          );
        } else {
          // Not supported (e.g., not in a web browser)
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.error.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.error_outline,
                        color: theme.colorScheme.error,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Web3 Not Supported',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Please use a Web3 supported browser like Chrome or Firefox with MetaMask extension installed.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }
      },
    );
  }
}