import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/market_data.dart';

class MarketOddsDisplay extends StatelessWidget {
  final MarketData market;

  const MarketOddsDisplay({
    Key? key,
    required this.market,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Market Odds',
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Historical price movement',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onBackground.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 0.2,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: theme.colorScheme.onBackground.withOpacity(0.1),
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: 5,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= market.priceHistory.length || index < 0 || index % 5 != 0) {
                        return const SizedBox.shrink();
                      }
                      final date = market.priceHistory[index].date;
                      return Text(
                        '${date.month}/${date.day}',
                        style: TextStyle(
                          color: theme.colorScheme.onBackground.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 0.2,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${(value * 100).toInt()}%',
                        style: TextStyle(
                          color: theme.colorScheme.onBackground.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: market.priceHistory
                      .asMap()
                      .entries
                      .map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          entry.value.price,
                        );
                      })
                      .toList(),
                  isCurved: true,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary.withOpacity(0.1),
                        theme.colorScheme.primary.withOpacity(0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  color: theme.colorScheme.primary, // Changed from 'colors'
                ),
              ],
              minY: 0,
              maxY: 1,
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  tooltipRoundedRadius: 8, // Removed 'tooltipBgColor'
                  getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                    return touchedBarSpots.map((barSpot) {
                      final index = barSpot.x.toInt();
                      if (index >= market.priceHistory.length || index < 0) {
                        return null;
                      }
                      
                      final date = market.priceHistory[index].date;
                      final price = barSpot.y;
                      
                      return LineTooltipItem(
                        '${date.month}/${date.day}: ${(price * 100).toStringAsFixed(1)}%',
                        TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _buildOddsCard(
                context,
                'Current Yes Price',
                '${(market.yesPrice * 100).toStringAsFixed(1)}%',
                theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildOddsCard(
                context,
                'Current No Price',
                '${(market.noPrice * 100).toStringAsFixed(1)}%',
                theme.colorScheme.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildOddsCard(
                context,
                'Volume',
                '\$${_formatNumber(market.volume)}',
                theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildOddsCard(
                context,
                'Expiry Date',
                _formatDate(market.expiryDate),
                theme.colorScheme.onBackground.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOddsCard(
    BuildContext context,
    String label,
    String value,
    Color valueColor,
  ) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onBackground.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: valueColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toString();
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
