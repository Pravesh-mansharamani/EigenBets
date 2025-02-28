import 'package:flutter/material.dart';
import '../models/transaction_data.dart';

class TransactionHistoryWidget extends StatefulWidget {
  final List<TransactionData> transactions;

  const TransactionHistoryWidget({
    Key? key,
    required this.transactions,
  }) : super(key: key);

  @override
  State<TransactionHistoryWidget> createState() => _TransactionHistoryWidgetState();
}

class _TransactionHistoryWidgetState extends State<TransactionHistoryWidget> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Bets', 'Deposits', 'Withdrawals', 'Swaps'];

  List<TransactionData> get _filteredTransactions {
    if (_selectedFilter == 'All') {
      return widget.transactions;
    }
    
    TransactionType? filterType;
    switch (_selectedFilter) {
      case 'Bets':
        filterType = TransactionType.bet;
        break;
      case 'Deposits':
        filterType = TransactionType.deposit;
        break;
      case 'Withdrawals':
        filterType = TransactionType.withdrawal;
        break;
      case 'Swaps':
        filterType = TransactionType.swap;
        break;
    }
    
    return widget.transactions.where((tx) => tx.type == filterType).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transaction History',
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        _buildFilterChips(context),
        const SizedBox(height: 16),
        _filteredTransactions.isEmpty
            ? _buildEmptyState(context)
            : _buildTransactionList(context),
      ],
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filters.map((filter) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: Text(filter),
              selected: _selectedFilter == filter,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: theme.colorScheme.onBackground.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No transactions found',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Try selecting a different filter',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onBackground.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: _filteredTransactions.map((transaction) {
        return Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getTransactionColor(transaction.type, theme).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getTransactionIcon(transaction.type),
                  color: _getTransactionColor(transaction.type, theme),
                  size: 20,
                ),
              ),
              title: Text(
                transaction.description,
                style: theme.textTheme.titleSmall,
              ),
              subtitle: Text(
                _formatDate(transaction.timestamp),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onBackground.withOpacity(0.6),
                ),
              ),
              trailing: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${_getTransactionPrefix(transaction.type)}${transaction.amount} ${transaction.token}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: _getTransactionColor(transaction.type, theme),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getStatusColor(transaction.status, theme).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      transaction.status,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _getStatusColor(transaction.status, theme),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              onTap: () {
                _showTransactionDetails(context, transaction);
              },
            ),
            const Divider(),
          ],
        );
      }).toList(),
    );
  }

  IconData _getTransactionIcon(TransactionType type) {
    switch (type) {
      case TransactionType.bet:
        return Icons.casino;
      case TransactionType.deposit:
        return Icons.arrow_downward;
      case TransactionType.withdrawal:
        return Icons.arrow_upward;
      case TransactionType.swap:
        return Icons.swap_horiz;
    }
  }

  Color _getTransactionColor(TransactionType type, ThemeData theme) {
    switch (type) {
      case TransactionType.bet:
        return theme.colorScheme.primary;
      case TransactionType.deposit:
        return theme.colorScheme.secondary;
      case TransactionType.withdrawal:
        return theme.colorScheme.error;
      case TransactionType.swap:
        return Colors.purple;
    }
  }

  String _getTransactionPrefix(TransactionType type) {
    switch (type) {
      case TransactionType.bet:
        return '-';
      case TransactionType.deposit:
        return '+';
      case TransactionType.withdrawal:
        return '-';
      case TransactionType.swap:
        return '';
    }
  }

  Color _getStatusColor(String status, ThemeData theme) {
    switch (status) {
      case 'Confirmed':
        return theme.colorScheme.secondary;
      case 'Pending':
        return Colors.orange;
      case 'Failed':
        return theme.colorScheme.error;
      default:
        return theme.colorScheme.onBackground;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showTransactionDetails(BuildContext context, TransactionData transaction) {
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Transaction Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(context, 'Type', _getTransactionTypeName(transaction.type)),
              _buildDetailRow(context, 'Description', transaction.description),
              _buildDetailRow(context, 'Amount', '${transaction.amount} ${transaction.token}'),
              _buildDetailRow(context, 'Date', _formatDate(transaction.timestamp)),
              _buildDetailRow(context, 'Status', transaction.status),
              if (transaction.txHash != null)
                _buildDetailRow(context, 'Transaction Hash', transaction.txHash!),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
            if (transaction.txHash != null)
              ElevatedButton(
                onPressed: () {
                  // Open explorer
                  Navigator.of(context).pop();
                },
                child: const Text('View on Explorer'),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onBackground.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  String _getTransactionTypeName(TransactionType type) {
    switch (type) {
      case TransactionType.bet:
        return 'Bet';
      case TransactionType.deposit:
        return 'Deposit';
      case TransactionType.withdrawal:
        return 'Withdrawal';
      case TransactionType.swap:
        return 'Swap';
    }
  }
}

