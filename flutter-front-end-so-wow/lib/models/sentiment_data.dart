class SentimentData {
  final String source;
  final String sourceIcon;
  final double bullishScore;
  final double bearishScore;
  final double neutralScore;
  final double weight;
  final DateTime timestamp;

  SentimentData({
    required this.source,
    required this.sourceIcon,
    required this.bullishScore,
    required this.bearishScore,
    required this.neutralScore,
    required this.weight,
    required this.timestamp,
  });

  static List<SentimentData> getDummyData() {
    return [
      SentimentData(
        source: 'Gaia AI',
        sourceIcon: 'assets/icons/gaia.png',
        bullishScore: 0.72,
        bearishScore: 0.18,
        neutralScore: 0.10,
        weight: 0.35,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      SentimentData(
        source: 'Autonome',
        sourceIcon: 'assets/icons/autonome.png',
        bullishScore: 0.65,
        bearishScore: 0.25,
        neutralScore: 0.10,
        weight: 0.25,
        timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
      ),
      SentimentData(
        source: 'Coinbase AI',
        sourceIcon: 'assets/icons/coinbase.png',
        bullishScore: 0.58,
        bearishScore: 0.32,
        neutralScore: 0.10,
        weight: 0.20,
        timestamp: DateTime.now().subtract(const Duration(minutes: 12)),
      ),
      SentimentData(
        source: 'Kite AI',
        sourceIcon: 'assets/icons/kite.png',
        bullishScore: 0.68,
        bearishScore: 0.22,
        neutralScore: 0.10,
        weight: 0.20,
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
    ];
  }

  static Map<String, double> getWeightedAverage(List<SentimentData> data) {
    double totalWeight = data.fold(0.0, (sum, item) => sum + item.weight);
    double weightedBullish = data.fold(0.0, (sum, item) => sum + (item.bullishScore * item.weight)) / totalWeight;
    double weightedBearish = data.fold(0.0, (sum, item) => sum + (item.bearishScore * item.weight)) / totalWeight;
    double weightedNeutral = data.fold(0.0, (sum, item) => sum + (item.neutralScore * item.weight)) / totalWeight;

    return {
      'bullish': weightedBullish,
      'bearish': weightedBearish,
      'neutral': weightedNeutral,
    };
  }
}
