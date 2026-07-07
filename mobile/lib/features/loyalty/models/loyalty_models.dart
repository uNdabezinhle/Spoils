class LoyaltyAccountModel {
  const LoyaltyAccountModel({required this.balance, required this.lifetimeEarned});

  final int balance;
  final int lifetimeEarned;

  factory LoyaltyAccountModel.fromJson(Map<String, dynamic> json) {
    return LoyaltyAccountModel(
      balance: json['balance'] as int? ?? 0,
      lifetimeEarned: json['lifetime_earned'] as int? ?? 0,
    );
  }
}

class PointsLedgerEntryModel {
  const PointsLedgerEntryModel({
    required this.id,
    required this.entryType,
    required this.points,
    required this.balanceAfter,
    required this.description,
    required this.createdAt,
  });

  final int id;
  final String entryType;
  final int points;
  final int balanceAfter;
  final String description;
  final String createdAt;

  factory PointsLedgerEntryModel.fromJson(Map<String, dynamic> json) {
    return PointsLedgerEntryModel(
      id: json['id'] as int,
      entryType: json['entry_type'] as String,
      points: json['points'] as int,
      balanceAfter: json['balance_after'] as int,
      description: json['description'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}