// API Configuration for secure credential storage
class ApiConfig {
  // Coinbase CDK Configuration
  static const String cdkApiKey = String.fromEnvironment('COINBASE_API_KEY', 
      defaultValue: 'cdk_api_key_123456789'); // Replace with env variables
  static const String cdkClientId = String.fromEnvironment('COINBASE_CLIENT_ID',
      defaultValue: 'eigenbet_app_12345');
  static const String cdkClientSecret = String.fromEnvironment('COINBASE_CLIENT_SECRET',
      defaultValue: 'eigenbet_secret_12345');
  static const String cdkRedirectUri = 'com.eigenbet.app://oauth';
  
  // API endpoints
  static const String cdkApiBaseUrl = 'https://cdk.coinbase.com/api/v1';
  static const String cdkAuthBaseUrl = 'https://www.coinbase.com/oauth';
  
  // Coinbase Onramp Configuration
  static const String onrampClientId = String.fromEnvironment('COINBASE_ONRAMP_CLIENT_ID',
      defaultValue: 'eigenbet_onramp_12345');
  static const String onrampAppName = 'EigenBet Predictions';
  static const String onrampBaseUrl = 'https://pay.coinbase.com';
  
  // Wallet configuration
  static const List<String> cdkOAuthScopes = [
    'wallet:user:read',
    'wallet:accounts:read',
    'wallet:transactions:read',
    'wallet:buys:create',
    'wallet:payment-methods:read'
  ];
  
  // Networks supported
  static const Map<String, String> supportedNetworks = {
    'base': 'Base',
    'ethereum': 'Ethereum',
    'polygon': 'Polygon',
  };
  
  // Default network
  static const String defaultNetwork = 'base';
} 