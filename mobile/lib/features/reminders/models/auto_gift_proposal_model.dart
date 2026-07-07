class AutoGiftProposalModel {
  const AutoGiftProposalModel({
    required this.id,
    required this.occasionId,
    required this.status,
    required this.deliveryDate,
    required this.expiresAt,
    required this.recipientName,
    required this.occasionType,
    required this.occasionTypeLabel,
    required this.product,
    this.orderId,
  });

  final int id;
  final int occasionId;
  final String status;
  final String deliveryDate;
  final String expiresAt;
  final String recipientName;
  final String occasionType;
  final String occasionTypeLabel;
  final AutoGiftProductModel product;
  final int? orderId;

  factory AutoGiftProposalModel.fromJson(Map<String, dynamic> json) {
    return AutoGiftProposalModel(
      id: json['id'] as int,
      occasionId: json['occasion_id'] as int,
      status: json['status'] as String,
      deliveryDate: json['delivery_date'] as String,
      expiresAt: json['expires_at'] as String,
      recipientName: json['recipient_name'] as String,
      occasionType: json['occasion_type'] as String,
      occasionTypeLabel: json['occasion_type_label'] as String? ?? json['occasion_type'] as String,
      product: AutoGiftProductModel.fromJson(json['product'] as Map<String, dynamic>),
      orderId: json['order_id'] as int?,
    );
  }
}

class AutoGiftProductModel {
  const AutoGiftProductModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.basePrice,
    this.imageUrl = '',
  });

  final int id;
  final String name;
  final String slug;
  final String basePrice;
  final String imageUrl;

  factory AutoGiftProductModel.fromJson(Map<String, dynamic> json) {
    return AutoGiftProductModel(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
      basePrice: json['base_price'].toString(),
      imageUrl: json['image_url'] as String? ?? '',
    );
  }
}