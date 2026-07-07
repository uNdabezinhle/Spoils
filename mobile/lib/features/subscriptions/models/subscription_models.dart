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

  bool get isPendingPayment => status == 'pending_payment';

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

class SubscriptionFulfillmentModel {
  const SubscriptionFulfillmentModel({
    required this.orderId,
    required this.subscriptionId,
    required this.status,
    required this.deliveryDate,
    required this.totalAmount,
    required this.createdAt,
    required this.productName,
    this.productImageUrl = '',
  });

  final int orderId;
  final int subscriptionId;
  final String status;
  final String deliveryDate;
  final String totalAmount;
  final String createdAt;
  final String productName;
  final String productImageUrl;

  factory SubscriptionFulfillmentModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionFulfillmentModel(
      orderId: json['order_id'] as int,
      subscriptionId: json['subscription_id'] as int,
      status: json['status'] as String,
      deliveryDate: json['delivery_date'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      totalAmount: json['total_amount']?.toString() ?? '0',
      productName: json['product_name'] as String? ?? 'Spoil Box',
      productImageUrl: json['product_image_url'] as String? ?? '',
    );
  }
}

class SubscriptionPaymentInitResult {
  const SubscriptionPaymentInitResult({
    required this.subscriptionId,
    required this.reference,
    required this.amount,
    required this.demoMode,
    this.authorizationUrl,
    this.subscription,
  });

  final int subscriptionId;
  final String reference;
  final String amount;
  final bool demoMode;
  final String? authorizationUrl;
  final UserSubscriptionModel? subscription;

  factory SubscriptionPaymentInitResult.fromJson(Map<String, dynamic> json) {
    final sub = json['subscription'] as Map<String, dynamic>?;
    return SubscriptionPaymentInitResult(
      subscriptionId: sub?['id'] as int? ?? json['subscription_id'] as int,
      reference: json['reference'] as String,
      amount: json['amount']?.toString() ?? '0',
      demoMode: json['demo_mode'] as bool? ?? false,
      authorizationUrl: json['authorization_url'] as String?,
      subscription: sub != null ? UserSubscriptionModel.fromJson(sub) : null,
    );
  }
}