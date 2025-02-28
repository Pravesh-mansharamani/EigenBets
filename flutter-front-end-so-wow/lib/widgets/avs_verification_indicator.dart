import 'package:flutter/material.dart';
import '../models/market_data.dart';
import '../services/avs_service.dart';

class AvsVerificationIndicator extends StatefulWidget {
  final MarketData market;
  final Function(Map<String, dynamic> result)? onVerificationComplete;

  const AvsVerificationIndicator({
    Key? key,
    required this.market,
    this.onVerificationComplete,
  }) : super(key: key);

  @override
  State<AvsVerificationIndicator> createState() => _AvsVerificationIndicatorState();
}

class _AvsVerificationIndicatorState extends State<AvsVerificationIndicator> {
  final AvsService _avsService = AvsService();
  bool _isVerifying = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPastExpiry = widget.market.expiryDate.isBefore(DateTime.now());
    
    // If not past expiry date and not already verified, don't show verification button
    if (!isPastExpiry && !widget.market.isAvsVerified) {
      return const SizedBox.shrink();
    }
    
    // If already verified, show verification badge and outcome
    if (widget.market.isAvsVerified) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.verified,
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                Text(
                  'AVS Verified Outcome',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              widget.market.outcomeResult ?? 'Unknown',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: widget.market.outcomeResult == 'Yes' 
                    ? Colors.green 
                    : (widget.market.outcomeResult == 'No' ? Colors.red : Colors.grey),
              ),
            ),
            if (widget.market.avsVerificationTimestamp != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Verified on: ${_formatDateTime(widget.market.avsVerificationTimestamp!)}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
          ],
        ),
      );
    }
    
    // Market needs verification
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            'Market Expired - Awaiting AVS Verification',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (_isVerifying)
            const Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 8),
                Text('Requesting Verification from AVS...'),
              ],
            )
          else
            ElevatedButton.icon(
              onPressed: _requestVerification,
              icon: const Icon(Icons.verified_user),
              label: const Text('Request AVS Verification'),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                _error!,
                style: TextStyle(color: Colors.red[700]),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _requestVerification() async {
    setState(() {
      _isVerifying = true;
      _error = null;
    });
    
    try {
      // For demo purposes, use the simulation function
      final result = await _avsService.simulateAvsVerification(widget.market);
      
      if (widget.onVerificationComplete != null) {
        widget.onVerificationComplete!(result);
      }
      
      setState(() {
        _isVerifying = false;
      });
    } catch (e) {
      setState(() {
        _isVerifying = false;
        _error = 'Verification failed: $e';
      });
    }
  }
  
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}';
  }
}