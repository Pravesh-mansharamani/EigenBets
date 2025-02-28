import 'package:flutter/material.dart';

class MarketFilterWidget extends StatelessWidget {
  final String selectedCategory;
  final Function(String) onCategoryChanged;

  const MarketFilterWidget({
    Key? key,
    required this.selectedCategory,
    required this.onCategoryChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categories',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        _buildCategoryItem(context, 'All', Icons.all_inclusive),
        _buildCategoryItem(context, 'Crypto', Icons.currency_bitcoin),
        _buildCategoryItem(context, 'Economics', Icons.attach_money),
        _buildCategoryItem(context, 'Finance', Icons.trending_up),
        _buildCategoryItem(context, 'Technology', Icons.devices),
        _buildCategoryItem(context, 'Science', Icons.science),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 24),
        Text(
          'Market Status',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        _buildStatusFilter(context),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 24),
        Text(
          'Volume',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        _buildVolumeSlider(context),
      ],
    );
  }

  Widget _buildCategoryItem(BuildContext context, String category, IconData icon) {
    final theme = Theme.of(context);
    final isSelected = selectedCategory == category;
    
    return InkWell(
      onTap: () {
        onCategoryChanged(category);
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary.withOpacity(0.1)
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 16,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onBackground.withOpacity(0.6),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              category,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onBackground,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(
                Icons.check,
                size: 16,
                color: theme.colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilter(BuildContext context) {
    final theme = Theme.of(context);
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildStatusChip(context, 'Active', true),
        _buildStatusChip(context, 'Resolved', false),
        _buildStatusChip(context, 'Expiring Soon', false),
      ],
    );
  }

  Widget _buildStatusChip(BuildContext context, String label, bool isSelected) {
    final theme = Theme.of(context);
    
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (selected) {
        // Handle status filter
      },
      backgroundColor: theme.colorScheme.surface,
      selectedColor: theme.colorScheme.primary.withOpacity(0.1),
      checkmarkColor: theme.colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.onBackground,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildVolumeSlider(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            activeTrackColor: theme.colorScheme.primary,
            inactiveTrackColor: theme.colorScheme.surface,
            thumbColor: theme.colorScheme.primary,
            overlayColor: theme.colorScheme.primary.withOpacity(0.1),
            valueIndicatorColor: theme.colorScheme.primary,
            valueIndicatorTextStyle: TextStyle(
              color: theme.colorScheme.onPrimary,
            ),
          ),
          child: Slider(
            value: 500000,
            min: 0,
            max: 1000000,
            divisions: 10,
            label: '\$500K+',
            onChanged: (value) {
              // Handle volume filter
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '\$0',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onBackground.withOpacity(0.6),
              ),
            ),
            Text(
              '\$1M+',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onBackground.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

