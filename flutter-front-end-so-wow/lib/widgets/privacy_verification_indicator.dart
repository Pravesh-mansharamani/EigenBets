import 'package:flutter/material.dart';

class PrivacyVerificationIndicator extends StatefulWidget {
  const PrivacyVerificationIndicator({Key? key}) : super(key: key);

  @override
  State<PrivacyVerificationIndicator> createState() => _PrivacyVerificationIndicatorState();
}

class _PrivacyVerificationIndicatorState extends State<PrivacyVerificationIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isVerified = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: () {
        _showVerificationDialog(context);
      },
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isVerified
                        ? theme.colorScheme.primary.withOpacity(_animation.value)
                        : theme.colorScheme.error,
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            Text(
              'ZK-Verified',
              style: theme.textTheme.bodySmall?.copyWith(
                color: _isVerified
                    ? theme.colorScheme.primary
                    : theme.colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVerificationDialog(BuildContext context) {
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.verified,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Text('Zero-Knowledge Proof Verification'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This platform uses zero-knowledge proofs to verify the accuracy of market outcomes without revealing proprietary computation details.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verification Status',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isVerified
                                ? theme.colorScheme.primary
                                : theme.colorScheme.error,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isVerified ? 'Verified' : 'Not Verified',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _isVerified
                                ? theme.colorScheme.primary
                                : theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Last Verification: 2 minutes ago',
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      'Verification Hash: 0x7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('View Details'),
            ),
          ],
        );
      },
    );
  }
}

