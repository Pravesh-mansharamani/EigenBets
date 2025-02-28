import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/sentiment_data.dart';

class SentimentAnalysisWidget extends StatelessWidget {
  final List<SentimentData> sentimentData;

  const SentimentAnalysisWidget({
    Key? key,
    required this.sentimentData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weightedAverage = SentimentData.getWeightedAverage(sentimentData);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weighted Sentiment',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Aggregated from ${sentimentData.length} AI sources',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onBackground.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildRefreshButton(context),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildSentimentChart(context, weightedAverage),
                  ),
                  Expanded(
                    flex: 2,
                    child: _buildSentimentLegend(context, weightedAverage),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Source Breakdown',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ...sentimentData.map((data) => _buildSourceItem(context, data)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRefreshButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.refresh),
      tooltip: 'Refresh data',
      onPressed: () {
        // Refresh data logic would go here
      },
    );
  }

  Widget _buildSentimentChart(BuildContext context, Map<String, double> weightedAverage) {
    final theme = Theme.of(context);
    
    return PieChart(
      PieChartData(
        sectionsSpace: 0,
        centerSpaceRadius: 40,
        sections: [
          PieChartSectionData(
            value: weightedAverage['bullish']! * 100,
            title: '${(weightedAverage['bullish']! * 100).toStringAsFixed(0)}%',
            color: theme.colorScheme.primary,
            radius: 60,
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          PieChartSectionData(
            value: weightedAverage['bearish']! * 100,
            title: '${(weightedAverage['bearish']! * 100).toStringAsFixed(0)}%',
            color: theme.colorScheme.error,
            radius: 60,
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          PieChartSectionData(
            value: weightedAverage['neutral']! * 100,
            title: '${(weightedAverage['neutral']! * 100).toStringAsFixed(0)}%',
            color: theme.colorScheme.secondary,
            radius: 60,
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSentimentLegend(BuildContext context, Map<String, double> weightedAverage) {
    final theme = Theme.of(context);
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLegendItem(
          context,
          'Bullish',
          weightedAverage['bullish']!,
          theme.colorScheme.primary,
        ),
        const SizedBox(height: 16),
        _buildLegendItem(
          context,
          'Bearish',
          weightedAverage['bearish']!,
          theme.colorScheme.error,
        ),
        const SizedBox(height: 16),
        _buildLegendItem(
          context,
          'Neutral',
          weightedAverage['neutral']!,
          theme.colorScheme.secondary,
        ),
      ],
    );
  }

  Widget _buildLegendItem(
    BuildContext context,
    String label,
    double value,
    Color color,
  ) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.bodyMedium,
        ),
        const Spacer(),
        Text(
          '${(value * 100).toStringAsFixed(1)}%',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSourceItem(BuildContext context, SentimentData data) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                data.source.substring(0, 1),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.source,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Weight: ${(data.weight * 100).toStringAsFixed(0)}% • Updated ${_getTimeAgo(data.timestamp)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onBackground.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(data.bullishScore * 100).toStringAsFixed(0)}% Bull',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${(data.bearishScore * 100).toStringAsFixed(0)}% Bear',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
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

