class TwitterData {
  final String username;
  final String handle;
  final String avatarUrl;
  final String content;
  final DateTime timestamp;
  final int likes;
  final int retweets;
  final bool isVerified;
  final double sentimentScore; // -1.0 to 1.0 (negative to positive)

  TwitterData({
    required this.username,
    required this.handle,
    required this.avatarUrl,
    required this.content,
    required this.timestamp,
    required this.likes,
    required this.retweets,
    required this.isVerified,
    required this.sentimentScore,
  });

  static List<TwitterData> getDummyData() {
    return [
      TwitterData(
        username: 'Crypto Analyst',
        handle: '@crypto_analyst',
        avatarUrl: 'assets/avatars/analyst1.png',
        content: 'ETH looking bullish with the upcoming protocol upgrade. Expecting a strong move above \$2,500 in the next few weeks. #Ethereum #Crypto',
        timestamp: DateTime.now().subtract(const Duration(minutes: 12)),
        likes: 342,
        retweets: 87,
        isVerified: true,
        sentimentScore: 0.85,
      ),
      TwitterData(
        username: 'Market Watcher',
        handle: '@market_watch',
        avatarUrl: 'assets/avatars/analyst2.png',
        content: 'Fed meeting minutes suggest a more hawkish stance than expected. This could put pressure on risk assets in the short term. #Economics #Markets',
        timestamp: DateTime.now().subtract(const Duration(minutes: 28)),
        likes: 215,
        retweets: 63,
        isVerified: true,
        sentimentScore: -0.45,
      ),
      TwitterData(
        username: 'Tech Insider',
        handle: '@tech_insider',
        avatarUrl: 'assets/avatars/analyst3.png',
        content: 'Sources confirm Apple\'s VR headset is ready for production. Announcement at WWDC looking increasingly likely. #Apple #VR #Tech',
        timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
        likes: 528,
        retweets: 142,
        isVerified: true,
        sentimentScore: 0.72,
      ),
      TwitterData(
        username: 'Space Explorer',
        handle: '@space_x_fan',
        avatarUrl: 'assets/avatars/analyst4.png',
        content: 'SpaceX making significant progress on Starship. Latest test showed promising results. Orbital launch this year is definitely on the table. #SpaceX #Starship',
        timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 15)),
        likes: 412,
        retweets: 98,
        isVerified: false,
        sentimentScore: 0.65,
      ),
      TwitterData(
        username: 'Wall Street Pro',
        handle: '@wallst_pro',
        avatarUrl: 'assets/avatars/analyst5.png',
        content: 'S&P 500 facing resistance at 4,300. Need to see more volume to break through. Cautiously optimistic but watching macro indicators closely. #Stocks #Trading',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        likes: 187,
        retweets: 42,
        isVerified: true,
        sentimentScore: 0.25,
      ),
    ];
  }
}
