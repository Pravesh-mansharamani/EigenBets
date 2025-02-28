import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/market_data.dart';
import '../models/transaction_data.dart';

class AvsService {
  static const String baseUrl = 'http://localhost:4003';
  static const String taskEndpoint = '/task/execute';

  /// Submits a market outcome verification request to the AVS service
  /// Returns the verification ID if successful
  Future<String?> submitMarketVerification(MarketData market) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$taskEndpoint'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'marketId': market.id,
          'title': market.title,
          'description': market.description,
          'expiryDate': market.expiryDate.toIso8601String(),
          'requestType': 'marketVerification',
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data['verificationId'];
      } else {
        print('Failed to submit market verification: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error submitting market verification: $e');
      return null;
    }
  }

  /// Checks the status of a market outcome verification
  /// Returns the verification result including the outcome (Yes/No)
  Future<Map<String, dynamic>?> checkVerificationStatus(String verificationId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$taskEndpoint/$verificationId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Failed to check verification status: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error checking verification status: $e');
      return null;
    }
  }

  /// Marks a market as resolved based on AVS verification
  /// Returns true if successful
  Future<bool> finalizeMarketOutcome(String marketId, String verificationId, String outcome) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$taskEndpoint/finalize'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'marketId': marketId,
          'verificationId': verificationId,
          'outcome': outcome,
          'requestType': 'finalizeMarket',
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error finalizing market outcome: $e');
      return false;
    }
  }

  /// Mock function to simulate AVS verification for demo purposes
  Future<Map<String, dynamic>> simulateAvsVerification(MarketData market) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));
    
    // For demonstration, we'll determine outcome based on market title
    final outcomeResult = market.title.toLowerCase().contains('eth') ? 'Yes' : 'No';
    
    return {
      'verificationId': 'avs_${DateTime.now().millisecondsSinceEpoch}',
      'marketId': market.id,
      'status': VerificationStatus.verified.toString(),
      'outcome': outcomeResult,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}