import 'dart:math' as math;

// Global list to store all markets, including newly created ones
List<MarketData> globalMarketsList = [];

// Function to add a new market to the global list
void addMarketToGlobalList(MarketData market) {
  // Add to the beginning of the list to show newest markets first
  globalMarketsList.insert(0, market);
}

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
    // If we already have markets in the global list (including created ones),
    // return that list instead of recreating the default markets
    if (globalMarketsList.isNotEmpty) {
      return globalMarketsList;
    }
    
    // Get current year and create one expired market for demo
    final currentYear = DateTime.now().year;
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    
    // Create initial dummy markets
    final markets = [
      // Add an expired market for AVS verification demo
      MarketData(
        id: '1',
        title: 'Are @coledermo & @ImTheBigP tributes for @BuildOnEigen EigenGames?',
        description: 'This market resolves to YES if the @BuildOnEigen Twitter account mentions both usernames as tributes for the EigenGames.',
        category: 'Crypto',
        yesPrice: 0.78,
        noPrice: 0.22,
        volume: 1750000,
        expiryDate: yesterday, // Expired market for demo
        imageUrl: 'assets/images/eth.png',
        priceHistory: _generateRandomPriceHistory(0.65, 0.78, 30),
        status: MarketStatus.closed,
      ),
      MarketData(
        id: '2',
        title: 'Will the EigenBet Project by @coledermo and @ImTheBigP reach top 6 in EigenGames by @BuildOnEigen?',
        description: 'This market resolves to YES if the EigenBet project, developed by Cole Dermott and Paul Baldwin, places in the top 6 projects in the EigenGames hackathon organized by EigenLayer.',
        category: 'Hackathon',
        yesPrice: 1.0,
        noPrice: 0.0,
        volume: 2500000,
        expiryDate: DateTime(currentYear, 3, 15),
        imageUrl: 'assets/images/eigenlayer.png',
        // Special pattern for this market - steadily increasing price history
        priceHistory: _generateEigenBetSpecialPriceHistory(0.55, 1.0, 30),
        status: MarketStatus.open,
      ),
      MarketData(
        id: '3',
        title: 'Will ETH reach \$4,000 by end of Q2 ${currentYear}?',
        description: 'This market resolves to YES if the price of Ethereum (ETH) reaches or exceeds \$4,000 USD at any point before the end of Q2 ${currentYear}.',
        category: 'Crypto',
        yesPrice: 0.65,
        noPrice: 0.35,
        volume: 1245000,
        expiryDate: DateTime(currentYear, 6, 30),
        imageUrl: 'assets/images/eth.png',
        priceHistory: _generateRandomPriceHistory(0.5, 0.65, 30),
      ),
      MarketData(
        id: '4',
        title: 'Will the Fed cut interest rates in July ${currentYear}?',
        description: 'This market resolves to YES if the Federal Reserve announces a decrease in the federal funds rate at its July ${currentYear} meeting.',
        category: 'Economics',
        yesPrice: 0.72,
        noPrice: 0.28,
        volume: 890000,
        expiryDate: DateTime(currentYear, 7, 31),
        imageUrl: 'assets/images/fed.png',
        priceHistory: _generateRandomPriceHistory(0.6, 0.72, 30),
      ),
      MarketData(
        id: '5',
        title: 'Will SpaceX successfully land Starship on Mars in ${currentYear}?',
        description: 'This market resolves to YES if SpaceX successfully lands a Starship spacecraft on Mars before the end of ${currentYear}.',
        category: 'Science',
        yesPrice: 0.18,
        noPrice: 0.82,
        volume: 750000,
        expiryDate: DateTime(currentYear, 12, 31),
        imageUrl: 'assets/images/spacex.png',
        priceHistory: _generateRandomPriceHistory(0.2, 0.18, 30),
      ),
      MarketData(
        id: '6',
        title: 'Will the S&P 500 close above 5,200 by Q3 ${currentYear}?',
        description: 'This market resolves to YES if the S&P 500 index closes above 5,200 points on any trading day before the end of Q3 ${currentYear}.',
        category: 'Finance',
        yesPrice: 0.45,
        noPrice: 0.55,
        volume: 1120000,
        expiryDate: DateTime(currentYear, 9, 30),
        imageUrl: 'assets/images/sp500.png',
        priceHistory: _generateRandomPriceHistory(0.5, 0.45, 30),
      ),
      MarketData(
        id: '7',
        title: 'Will Apple release an AI-focused product in ${currentYear}?',
        description: 'This market resolves to YES if Apple announces and releases a consumer product where AI capabilities are the primary selling point during ${currentYear}.',
        category: 'Technology',
        yesPrice: 0.82,
        noPrice: 0.18,
        volume: 980000,
        expiryDate: DateTime(currentYear, 12, 31),
        imageUrl: 'assets/images/apple.png',
        priceHistory: _generateRandomPriceHistory(0.7, 0.82, 30),
      ),
    ];
    
    // Store in global list for future use
    globalMarketsList = markets;
    
    return markets;
  }

  static List<PricePoint> _generateRandomPriceHistory(double startPrice, double endPrice, int days) {
    List<PricePoint> priceHistory = [];
    double currentPrice = startPrice;
    
    // Create unique seed for each market based on inputs and a randomizing factor to ensure diversity
    final seed = startPrice.toInt() * 1000 + endPrice.toInt() * 100 + days;
    final uniqueSeed = seed ^ DateTime.now().microsecond;
    final random = math.Random(uniqueSeed);
    
    // Generate different pattern arrays for each market
    // This ensures each chart has its own unique rhythm and appearance
    List<double> volatilityPatterns = List.generate(10, (_) => random.nextDouble() * 1.5 + 0.3);
    
    // Create a unique trend pattern for each chart with different up/down sequences
    List<double> trendPatterns = List.generate(14, (_) => random.nextDouble() > 0.5 ? 1.0 : -1.0);
    
    // Calculate overall trend but add some randomness to the path to get there
    double overallTrend = (endPrice - startPrice) / days;
    
    // Vary volatility for each market to create unique chart patterns
    double volatility = 0.01 + (random.nextDouble() * 0.03); // Base volatility varies between 0.01 and 0.04
    
    for (int i = 0; i < days; i++) {
      // Calculate day's movement based on trend, volatility pattern, and market sentiment cycle
      int patternIndex = (i % volatilityPatterns.length);
      int trendIndex = (i % trendPatterns.length);
      
      // Apply pattern-based volatility
      double dayVolatility = volatility * volatilityPatterns[patternIndex];
      
      // Add some randomness to the price movement
      double randomFactor = (random.nextDouble() - 0.5) * dayVolatility;
      
      // Apply both trend and pattern-based direction
      double trendFactor = overallTrend * trendPatterns[trendIndex];
      
      // Calculate new price with all factors
      currentPrice += trendFactor + randomFactor;
      
      // Add occasional market events (news, etc.)
      // Vary event frequency and impact for each chart
      int eventChance = 4 + random.nextInt(7); // 4-10% chance of an event 
      if (random.nextInt(100) < eventChance) {
        // Create different event magnitude profiles for each chart
        double eventMultiplier = 0.1 + (random.nextDouble() * 0.2); // 0.1 to 0.3
        double eventBias = random.nextDouble() * 0.4 - 0.2; // -0.2 to 0.2 (controls if chart has more positive or negative events)
        double eventImpact = (random.nextDouble() - 0.3 + eventBias) * eventMultiplier;
        currentPrice += eventImpact;
      }
      
      // Ensure price stays between 0.01 and 0.99
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
  
  // Special method for generating the EigenBet price history
  // Shows strong confidence with consistent uptrend
  static List<PricePoint> _generateEigenBetSpecialPriceHistory(double startPrice, double endPrice, int days) {
    List<PricePoint> priceHistory = [];
    double currentPrice = startPrice;
    
    // Create a confidence-increasing curve
    for (int i = 0; i < days; i++) {
      // Use a sigmoid-like function for S-curve growth
      double progress = i / (days - 1.0);
      double targetPrice;
      
      if (progress < 0.3) {
        // Initial discovery phase - slow growth
        targetPrice = startPrice + ((endPrice - startPrice) * 0.2 * (progress / 0.3));
      } else if (progress < 0.7) {
        // Rapid adoption phase - accelerated growth
        double normalizedProgress = (progress - 0.3) / 0.4;
        targetPrice = startPrice + ((endPrice - startPrice) * (0.2 + 0.6 * normalizedProgress));
      } else {
        // Final consensus phase - slowing growth toward 100%
        double normalizedProgress = (progress - 0.7) / 0.3;
        targetPrice = startPrice + ((endPrice - startPrice) * (0.8 + 0.2 * normalizedProgress));
      }
      
      // Add minor oscillations (smaller than normal markets to show confidence)
      double oscillation = math.sin(progress * math.pi * 2 * 1.5) * 0.01;
      
      // Add very small random noise (much less than regular markets)
      final random = math.Random(42 + i);
      double noise = (random.nextDouble() - 0.5) * 0.01;
      
      // Combine all factors
      currentPrice = targetPrice + oscillation + noise;
      
      // Ensure value stays within bounds (but it should never go below start price)
      currentPrice = math.max(startPrice, math.min(endPrice, currentPrice));
      
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
