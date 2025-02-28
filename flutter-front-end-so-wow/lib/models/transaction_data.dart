enum TransactionType {
  bet,
  deposit,
  withdrawal,
  swap,
  avsVerification,
  marketResolution,
}

enum VerificationStatus {
  pending,
  verified,
  rejected
}

class TransactionData {
  final String? txHash;
  final TransactionType type;
  final String description;
  final double amount;
  final String token;
  final DateTime timestamp;
  final String status;
  final String id;
  final String? marketId;
  final VerificationStatus? verificationStatus;
  final String? avsVerificationId;

  TransactionData({
    this.txHash,
    required this.type,
    required this.description,
    required this.amount,
    required this.token,
    required this.timestamp,
    required this.status,
    String? id,
    this.marketId,
    this.verificationStatus,
    this.avsVerificationId,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  static List<TransactionData> getDummyData() {
    return [
      TransactionData(
        txHash: '0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef',
        type: TransactionType.bet,
        description: 'Bet on "Bitcoin >\$50K by EOY"',
        amount: 100.0,
        token: 'USDC',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        status: 'Confirmed',
      ),
      TransactionData(
        txHash: '0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890',
        type: TransactionType.deposit,
        description: 'Deposit from Coinbase',
        amount: 500.0,
        token: 'USDC',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        status: 'Confirmed',
      ),
      TransactionData(
        txHash: '0x7890abcdef1234567890abcdef1234567890abcdef1234567890abcdef123456',
        type: TransactionType.swap,
        description: 'Swap ETH for USDC',
        amount: 0.25,
        token: 'ETH',
        timestamp: DateTime.now().subtract(const Duration(days: 5)),
        status: 'Confirmed',
      ),
      TransactionData(
        txHash: '0xdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abc',
        type: TransactionType.withdrawal,
        description: 'Withdrawal to bank account',
        amount: 200.0,
        token: 'USDC',
        timestamp: DateTime.now().subtract(const Duration(days: 7)),
        status: 'Processing',
      ),
      TransactionData(
        txHash: '0x567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234',
        type: TransactionType.bet,
        description: 'Bet on "Apple releases VR headset"',
        amount: 50.0,
        token: 'PRED',
        timestamp: DateTime.now().subtract(const Duration(days: 10)),
        status: 'Confirmed',
      ),
    ];
  }
}
