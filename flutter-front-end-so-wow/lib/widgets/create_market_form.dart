import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/wallet_service.dart';

class CreateMarketForm extends StatefulWidget {
  const CreateMarketForm({Key? key}) : super(key: key);

  @override
  State<CreateMarketForm> createState() => _CreateMarketFormState();
}

class _CreateMarketFormState extends State<CreateMarketForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _resolutionCriteriaController = TextEditingController();
  final TextEditingController _dataSourceController = TextEditingController();
  final TextEditingController _initialFundingController = TextEditingController(text: '100');
  bool _isCreating = false;
  
  String _selectedDataSourceType = 'Twitter';
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _endTime = TimeOfDay.now();
  
  final List<String> _dataSourceTypes = [
    'Twitter',
    'Chainlink Oracle',
    'Manual Resolution',
    'API Endpoint',
  ];
  
  // Market categories
  final List<String> _categories = [
    'Crypto',
    'Economics',
    'Finance',
    'Technology',
    'Science',
    'Politics',
    'Sports',
    'Entertainment',
    'Other',
  ];
  String _selectedCategory = 'Crypto';

  @override
  void dispose() {
    _questionController.dispose();
    _resolutionCriteriaController.dispose();
    _dataSourceController.dispose();
    _initialFundingController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final walletService = Provider.of<WalletService>(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create a New Prediction Market',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Fill out the details below to create your prediction market',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onBackground.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 32),
              
              // Connection Status
              if (!walletService.isConnected)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Wallet Not Connected',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'You need to connect your wallet to create a market',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/wallet');
                        },
                        child: const Text('Connect'),
                      ),
                    ],
                  ),
                ),
              
              // Market Question
              _buildSectionTitle(context, 'Market Question'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _questionController,
                decoration: const InputDecoration(
                  hintText: 'e.g., "Will Bitcoin exceed \$50,000 by the end of 2023?"',
                  helperText: 'Your question should have a clear Yes/No outcome',
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a question';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // Market Category
              _buildSectionTitle(context, 'Category'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  hintText: 'Select a category',
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a category';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // Resolution Criteria
              _buildSectionTitle(context, 'Resolution Criteria'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _resolutionCriteriaController,
                decoration: const InputDecoration(
                  hintText: 'e.g., "Market resolves to YES if Bitcoin price exceeds \$50,000 on CoinGecko at any point before the end date."',
                  helperText: 'Provide clear criteria for how the market will be resolved',
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter resolution criteria';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // Data Source
              _buildSectionTitle(context, 'Data Source'),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _selectedDataSourceType,
                      decoration: const InputDecoration(
                        hintText: 'Source type',
                      ),
                      items: _dataSourceTypes.map((sourceType) {
                        return DropdownMenuItem<String>(
                          value: sourceType,
                          child: Text(sourceType),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedDataSourceType = value;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _dataSourceController,
                      decoration: InputDecoration(
                        hintText: _getDataSourceHint(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a data source';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // End Date
              _buildSectionTitle(context, 'End Date & Time'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectDate(context),
                      child: AbsorbPointer(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            hintText: 'Select end date',
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          controller: TextEditingController(
                            text: DateFormat('MMM d, yyyy').format(_endDate),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select an end date';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectTime(context),
                      child: AbsorbPointer(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            hintText: 'Select end time',
                            prefixIcon: Icon(Icons.access_time),
                          ),
                          controller: TextEditingController(
                            text: _endTime.format(context),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select an end time';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Initial Funding
              _buildSectionTitle(context, 'Initial Funding (USDC)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _initialFundingController,
                decoration: const InputDecoration(
                  hintText: 'Enter funding amount',
                  prefixText: '\$ ',
                  suffixText: 'USDC',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter funding amount';
                  }
                  
                  final amount = double.tryParse(value) ?? 0;
                  if (amount <= 0) {
                    return 'Amount must be greater than zero';
                  }
                  
                  if (amount > walletService.usdcBalance) {
                    return 'Insufficient USDC balance';
                  }
                  
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Creation Fee: 10 PRED',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: walletService.predBalance >= 10 
                      ? theme.colorScheme.onBackground.withOpacity(0.6)
                      : theme.colorScheme.error,
                ),
              ),
              if (walletService.predBalance < 10)
                Text(
                  'Insufficient PRED balance',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              const SizedBox(height: 32),
              
              // Create Market Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: !walletService.isConnected || _isCreating ||
                          walletService.predBalance < 10
                      ? null
                      : () => _submitForm(walletService),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isCreating
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create Market'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium,
    );
  }

  String _getDataSourceHint() {
    switch (_selectedDataSourceType) {
      case 'Twitter':
        return '@username or twitter URL';
      case 'Chainlink Oracle':
        return 'Oracle contract address';
      case 'API Endpoint':
        return 'API URL';
      case 'Manual Resolution':
        return 'Resolver: username or address';
      default:
        return 'Enter source';
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    
    if (picked != null && picked != _endTime) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  Future<void> _submitForm(WalletService walletService) async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isCreating = true;
      });
      
      try {
        // Confirm user wants to create the market
        final confirmed = await _showConfirmationDialog();
        
        if (confirmed != true) {
          setState(() {
            _isCreating = false;
          });
          return;
        }
        
        // Get the combined end date and time
        final endDateTime = DateTime(
          _endDate.year,
          _endDate.month,
          _endDate.day,
          _endTime.hour,
          _endTime.minute,
        );
        
        // Get the initial funding amount
        final initialFunding = double.tryParse(_initialFundingController.text) ?? 0;
        
        // Create the market using the wallet service
        final result = await walletService.createMarket(
          question: _questionController.text,
          category: _selectedCategory,
          resolutionCriteria: _resolutionCriteriaController.text,
          dataSource: '$_selectedDataSourceType: ${_dataSourceController.text}',
          endDate: endDateTime,
          initialFunding: initialFunding,
        );
        
        if (result != null && result['success'] == true) {
          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Market created successfully!'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Theme.of(context).colorScheme.secondary,
              ),
            );
            
            // Navigate back to markets screen
            Navigator.of(context).pop();
          }
        } else {
          // Show error message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${result?['error'] ?? 'Unknown error'}'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isCreating = false;
          });
        }
      }
    }
  }

  Future<bool?> _showConfirmationDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Market Creation'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Please confirm the market details:',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              _buildDetailRow(
                context,
                'Question',
                _questionController.text,
              ),
              _buildDetailRow(
                context,
                'Category',
                _selectedCategory,
              ),
              _buildDetailRow(
                context,
                'Resolution Criteria',
                _resolutionCriteriaController.text,
              ),
              _buildDetailRow(
                context,
                'Data Source',
                '$_selectedDataSourceType: ${_dataSourceController.text}',
              ),
              _buildDetailRow(
                context,
                'End Date',
                '${DateFormat('MMM d, yyyy').format(_endDate)} at ${_endTime.format(context)}',
              ),
              _buildDetailRow(
                context,
                'Initial Funding',
                '\$${_initialFundingController.text} USDC',
              ),
              _buildDetailRow(
                context,
                'Creation Fee',
                '10 PRED',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Important Notice',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Once created, market parameters cannot be changed.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Back to Edit'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm & Create'),
          ),
        ],
      ),
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
              color: theme.colorScheme.onSurface.withOpacity(0.6),
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
}
