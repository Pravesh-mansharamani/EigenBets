import 'package:flutter/material.dart';
import '../models/twitter_data.dart';

class LiveTwitterFeed extends StatelessWidget {
  final List<TwitterData> twitterData;

  const LiveTwitterFeed({
    Key? key,
    required this.twitterData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.verified,
                  color: theme.colorScheme.primary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Verified by Chainlink',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...twitterData.map((tweet) => _buildTweetItem(context, tweet)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTweetItem(BuildContext context, TwitterData tweet) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                child: Text(
                  tweet.username.substring(0, 1),
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        tweet.username,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (tweet.isVerified) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.verified,
                          color: theme.colorScheme.primary,
                          size: 14,
                        ),
                      ],
                    ],
                  ),
                  Text(
                    tweet.handle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onBackground.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getSentimentColor(tweet.sentimentScore, theme).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getSentimentLabel(tweet.sentimentScore),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _getSentimentColor(tweet.sentimentScore, theme),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            tweet.content,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.favorite_border,
                size: 16,
                color: theme.colorScheme.onBackground.withOpacity(0.6),
              ),
              const SizedBox(width: 4),
              Text(
                tweet.likes.toString(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onBackground.withOpacity(0.6),
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.repeat,
                size: 16,
                color: theme.colorScheme.onBackground.withOpacity(0.6),
              ),
              const SizedBox(width: 4),
              Text(
                tweet.retweets.toString(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onBackground.withOpacity(0.6),
                ),
              ),
              const Spacer(),
              Text(
                _getTimeAgo(tweet.timestamp),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onBackground.withOpacity(0.6),
                ),
              ),
            ],
          ),
          if (twitterData.indexOf(tweet) < twitterData.length - 1)
            const Padding(
              padding: EdgeInsets.only(top: 16.0),
              child: Divider(),
            ),
        ],
      ),
    );
  }

  Color _getSentimentColor(double sentiment, ThemeData theme) {
    if (sentiment > 0.3) {
      return theme.colorScheme.primary;
    } else if (sentiment < -0.3) {
      return theme.colorScheme.error;
    } else {
      return theme.colorScheme.secondary;
    }
  }

  String _getSentimentLabel(double sentiment) {
    if (sentiment > 0.3) {
      return 'Bullish';
    } else if (sentiment < -0.3) {
      return 'Bearish';
    } else {
      return 'Neutral';
    }
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

