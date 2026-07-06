class SubscriptionPlanModel {
  const SubscriptionPlanModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.modelType,
    this.tagline = '',
    this.description = '',
    required this.priceMonthly,
    this.imageUrl = '',
    this.features = const [],
  });

  final int id;
  final String name;
  final String slug;
  final String modelType;
  final String tagline;
  final String description;
  final String priceMonthly;
  final String imageUrl;
  final List<String> features;

  bool get needsRecipient =>
      modelType == 'someone_to_spoil' || modelType == 'occasion_auto';

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlanModel(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
      modelType: json['model_type'] as String,
      tagline: json['tagline'] as String? ?? '',
      description: json['description'] as String? ?? '',
      priceMonthly: json['price_monthly'].toString(),
      imageUrl: json['image_url'] as String? ?? '',
      features: (json['features'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

class UserSubscriptionModel {
  const UserSubscriptionModel({
    required this.id,
    required this.plan,
    required this.status,
    this.recipientName = '',
    this.startedAt = '',
    this.nextBillingDate,
    this.notes = '',
  });

  final int id;
  final SubscriptionPlanModel plan;
  final String status;
  final String recipientName;
  final String startedAt;
  final String? nextBillingDate;
  final String notes;

  bool get isActive => status == 'active';

  factory UserSubscriptionModel.fromJson(Map<String, dynamic> json) {
    return UserSubscriptionModel(
      id: json['id'] as int,
      plan: SubscriptionPlanModel.fromJson(json['plan'] as Map<String, dynamic>),
      status: json['status'] as String,
      recipientName: json['recipient_name'] as String? ?? '',
      startedAt: json['started_at'] as String? ?? '',
      nextBillingDate: json['next_billing_date'] as String?,
      notes: json['notes'] as String? ?? '',
    );
  }
}