class GroupGiftModel {
  const GroupGiftModel({
    required this.id,
    required this.shareToken,
    required this.title,
    required this.recipientName,
    required this.message,
    required this.targetAmount,
    required this.amountCollected,
    required this.remainingAmount,
    required this.progressPercent,
    required this.status,
    required this.cartSnapshot,
    this.deliveryDate,
    this.contributions = const [],
    this.orderId,
  });

  final int id;
  final String shareToken;
  final String title;
  final String recipientName;
  final String message;
  final String targetAmount;
  final String amountCollected;
  final String remainingAmount;
  final int progressPercent;
  final String status;
  final List<Map<String, dynamic>> cartSnapshot;
  final String? deliveryDate;
  final List<GroupGiftContributionModel> contributions;
  final int? orderId;

  bool get isOpen => status == 'open';

  factory GroupGiftModel.fromJson(Map<String, dynamic> json) {
    return GroupGiftModel(
      id: json['id'] as int,
      shareToken: json['share_token'] as String,
      title: json['title'] as String,
      recipientName: json['recipient_name'] as String? ?? '',
      message: json['message'] as String? ?? '',
      targetAmount: json['target_amount'].toString(),
      amountCollected: json['amount_collected'].toString(),
      remainingAmount: json['remaining_amount']?.toString() ?? '0',
      progressPercent: json['progress_percent'] as int? ?? 0,
      status: json['status'] as String,
      cartSnapshot: (json['cart_snapshot'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
      deliveryDate: json['delivery_date'] as String?,
      orderId: json['order'] as int?,
      contributions: (json['contributions'] as List<dynamic>?)
              ?.map((e) => GroupGiftContributionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class GroupGiftContributionModel {
  const GroupGiftContributionModel({
    required this.id,
    required this.contributorName,
    required this.amount,
    required this.status,
    this.message = '',
    this.createdAt = '',
  });

  final int id;
  final String contributorName;
  final String amount;
  final String status;
  final String message;
  final String createdAt;

  factory GroupGiftContributionModel.fromJson(Map<String, dynamic> json) {
    return GroupGiftContributionModel(
      id: json['id'] as int,
      contributorName: json['contributor_name'] as String,
      amount: json['amount'].toString(),
      status: json['status'] as String,
      message: json['message'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

class GroupGiftPaymentInitResult {
  const GroupGiftPaymentInitResult({
    required this.contributionId,
    required this.reference,
    required this.amount,
    required this.demoMode,
    this.authorizationUrl,
  });

  final int contributionId;
  final String reference;
  final String amount;
  final bool demoMode;
  final String? authorizationUrl;

  factory GroupGiftPaymentInitResult.fromJson(Map<String, dynamic> json) {
    return GroupGiftPaymentInitResult(
      contributionId: json['contribution_id'] as int,
      reference: json['reference'] as String,
      amount: json['amount'].toString(),
      demoMode: json['demo_mode'] as bool? ?? false,
      authorizationUrl: json['authorization_url'] as String?,
    );
  }
}