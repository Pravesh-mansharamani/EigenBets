import 'package:flutter/material.dart';
import '../widgets/create_market_form.dart';

class CreateMarketScreen extends StatelessWidget {
  const CreateMarketScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Prediction Market'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Help',
            onPressed: () {
              _showHelpDialog(context);
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: const CreateMarketForm(),
            ),
          ),
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Creating a Prediction Market'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How it works',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'When you create a prediction market, you\'re asking a question about a future event that has an objectively verifiable outcome. Users can buy shares in either "Yes" or "No" outcomes.',
              ),
              const SizedBox(height: 16),
              Text(
                'Best practices',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                '• Make the question specific and objective\n'
                '• Provide clear resolution criteria\n'
                '• Set realistic end dates\n'
                '• Choose reliable data sources\n'
                '• Provide sufficient initial liquidity',
              ),
              const SizedBox(height: 16),
              Text(
                'Market creation fee',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'Creating a market requires a small fee of 10 PRED tokens to discourage spam. You also need to provide initial liquidity to enable trading.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
