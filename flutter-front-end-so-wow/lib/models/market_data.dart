class MarketData {
  final String id;
  final String title;
  final String description;
  final String category;
  final double yesPrice;
  final double noPrice;
  final double volume;
  final DateTime expiryDate;
  final String imageUrl;
  final List<PricePoint> priceHistory;
  final MarketStatus status;
  final String? avsVerificationId;
  final bool isAvsVerified;
  final DateTime? avsVerificationTimestamp;
  final String? outcomeResult;

  MarketData({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.yesPrice,
    required this.noPrice,
    required this.volume,
    required this.expiryDate,
    required this.imageUrl,
    required this.priceHistory,
    this.status = MarketStatus.open,
    this.avsVerificationId,
    this.isAvsVerified = false,
    this.avsVerificationTimestamp,
    this.outcomeResult,
  });

  static List<MarketData> getDummyData() {
    return [
      MarketData(
        id: '1',
        title: 'Will ETH reach \$5,000 by Q3 2023?',
        description: 'This market resolves to YES if the price of Ethereum (ETH) reaches or exceeds \$5,000 USD at any point before the end of Q3 2023.',
        category: 'Crypto',
        yesPrice: 0.65,
        noPrice: 0.35,
        volume: 1245000,
        expiryDate: DateTime(2023, 9, 30),
        imageUrl: 'assets/images/eth.png',
        priceHistory: _generateRandomPriceHistory(0.5, 0.65, 30),
      ),
      MarketData(
        id: '2',
        title: 'Will the Fed raise interest rates in July?',
        description: 'This market resolves to YES if the Federal Reserve announces an increase in the federal funds rate at its July 2023 meeting.',
        category: 'Economics',
        yesPrice: 0.72,
        noPrice: 0.28,
        volume: 890000,
        expiryDate: DateTime(2023, 7, 31),
        imageUrl: 'assets/images/fed.png',
        priceHistory: _generateRandomPriceHistory(0.6, 0.72, 30),
      ),
      MarketData(
        id: '3',
        title: 'Will SpaceX successfully launch Starship to orbit in 2023?',
        description: 'This market resolves to YES if SpaceX successfully launches Starship to orbit before the end of 2023.',
        category: 'Science',
        yesPrice: 0.58,
        noPrice: 0.42,
        volume: 750000,
        expiryDate: DateTime(2023, 12, 31),
        imageUrl: 'assets/images/spacex.png',
        priceHistory: _generateRandomPriceHistory(0.4, 0.58, 30),
      ),
      MarketData(
        id: '4',
        title: 'Will the S&P 500 close above 4,500 by end of August?',
        description: 'This market resolves to YES if the S&P 500 index closes above 4,500 points on any trading day before the end of August 2023.',
        category: 'Finance',
        yesPrice: 0.45,
        noPrice: 0.55,
        volume: 1120000,
        expiryDate: DateTime(2023, 8, 31),
        imageUrl: 'assets/images/sp500.png',
        priceHistory: _generateRandomPriceHistory(0.5, 0.45, 30),
      ),
      MarketData(
        id: '5',
        title: 'Will Apple announce a VR headset at WWDC 2023?',
        description: 'This market resolves to YES if Apple announces a virtual reality or augmented reality headset at the Worldwide Developers Conference (WWDC) in June 2023.',
        category: 'Technology',
        yesPrice: 0.82,
        noPrice: 0.18,
        volume: 980000,
        expiryDate: DateTime(2023, 6, 30),
        imageUrl: 'assets/images/apple.png',
        priceHistory: _generateRandomPriceHistory(0.7, 0.82, 30),
      ),
      MarketData(
        id: '6',
        title: 'Will the US unemployment rate fall below 3.5% in 2023?',
        description: 'This market resolves to YES if the US unemployment rate, as reported by the Bureau of Labor Statistics, falls below 3.5% at any point in 2023.',
        category: 'Economics',
        yesPrice: 0.38,
        noPrice: 0.62,
        volume: 675000,
        expiryDate: DateTime(2023, 12, 31),
        imageUrl: 'assets/images/unemployment.png',
        priceHistory: _generateRandomPriceHistory(0.4, 0.38, 30),
      ),
    ];
  }

  static List<PricePoint> _generateRandomPriceHistory(double startPrice, double endPrice, int days) {
    List<PricePoint> priceHistory = [];
    double currentPrice = startPrice;
    double dailyChange = (endPrice - startPrice) / days;
    
    for (int i = 0; i < days; i++) {
      // Add some randomness to the price movement
      double randomFactor = (0.5 - (DateTime.now().millisecond % 1000) / 1000) * 0.05;
      currentPrice += dailyChange + randomFactor;
      
      // Ensure price stays between 0 and 1
      currentPrice = currentPrice.clamp(0.01, 0.99);
      
      priceHistory.add(
        PricePoint(
          date: DateTime.now().subtract(Duration(days: days - i)),
          price: currentPrice,
        ),
      );
    }
    
    return priceHistory;
  }
}

class PricePoint {
  final DateTime date;
  final double price;

  PricePoint({
    required this.date,
    required this.price,
  });
}

enum MarketStatus {
  open,
  pending,
  closed,
  resolved
}
