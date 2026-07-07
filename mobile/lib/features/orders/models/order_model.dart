class OrderTimelineStep {
  const OrderTimelineStep({
    required this.status,
    required this.label,
    required this.completed,
  });

  final String status;
  final String label;
  final bool completed;

  factory OrderTimelineStep.fromJson(Map<String, dynamic> json) {
    return OrderTimelineStep(
      status: json['status'] as String,
      label: json['label'] as String,
      completed: json['completed'] as bool? ?? false,
    );
  }
}

class OrderItemModel {
  const OrderItemModel({
    required this.id,
    required this.productName,
    required this.productSlug,
    required this.productImageUrl,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    required this.customisation,
  });

  final int id;
  final String productName;
  final String productSlug;
  final String productImageUrl;
  final int quantity;
  final String unitPrice;
  final String lineTotal;
  final Map<String, dynamic> customisation;

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] as int,
      productName: json['product_name'] as String,
      productSlug: json['product_slug'] as String? ?? '',
      productImageUrl: json['product_image_url'] as String? ?? '',
      quantity: json['quantity'] as int,
      unitPrice: json['unit_price'].toString(),
      lineTotal: json['line_total'].toString(),
      customisation: json['customisation_details'] as Map<String, dynamic>? ?? {},
    );
  }
}

class OrderModel {
  const OrderModel({
    required this.id,
    required this.status,
    required this.statusLabel,
    required this.totalAmount,
    required this.deliveryDate,
    required this.deliveryType,
    required this.createdAt,
    this.itemCount = 0,
    this.items = const [],
    this.timeline = const [],
    this.deliveryAddress = const {},
    this.subtotal = '0',
    this.paystackReference = '',
    this.promoCode,
  });

  final int id;
  final String status;
  final String statusLabel;
  final String totalAmount;
  final String deliveryDate;
  final String deliveryType;
  final String createdAt;
  final int itemCount;
  final List<OrderItemModel> items;
  final List<OrderTimelineStep> timeline;
  final Map<String, dynamic> deliveryAddress;
  final String subtotal;
  final String paystackReference;
  final String? promoCode;

  bool get isPaid => status == 'paid' || status == 'processing' || status == 'shipped' || status == 'delivered';

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as int,
      status: json['status'] as String,
      statusLabel: json['status_label'] as String? ?? json['status'] as String,
      totalAmount: json['total_amount'].toString(),
      deliveryDate: json['delivery_date'] as String,
      deliveryType: json['delivery_type'] as String? ?? 'standard',
      createdAt: json['created_at'] as String,
      itemCount: json['item_count'] as int? ?? 0,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      timeline: (json['timeline'] as List<dynamic>?)
              ?.map((e) => OrderTimelineStep.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      deliveryAddress: json['delivery_address'] as Map<String, dynamic>? ?? {},
      subtotal: json['subtotal']?.toString() ?? '0',
      paystackReference: json['paystack_reference'] as String? ?? '',
      promoCode: json['promo_code'] as String?,
    );
  }
}

class CheckoutPreview {
  const CheckoutPreview({
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    required this.total,
    required this.demoMode,
    this.pointsDiscount = '0',
    this.pointsToRedeem = 0,
  });

  final String subtotal;
  final String deliveryFee;
  final String discount;
  final String total;
  final bool demoMode;
  final String pointsDiscount;
  final int pointsToRedeem;

  factory CheckoutPreview.fromJson(Map<String, dynamic> json) {
    return CheckoutPreview(
      subtotal: json['subtotal'].toString(),
      deliveryFee: json['delivery_fee'].toString(),
      discount: json['discount'].toString(),
      total: json['total'].toString(),
      demoMode: json['demo_mode'] as bool? ?? false,
      pointsDiscount: json['points_discount']?.toString() ?? '0',
      pointsToRedeem: json['points_to_redeem'] as int? ?? 0,
    );
  }
}

class ReceiptData {
  const ReceiptData({
    required this.order,
    required this.receiptTitle,
    required this.tagline,
    this.customerEmail = '',
    this.customerName = '',
  });

  final OrderModel order;
  final String receiptTitle;
  final String tagline;
  final String customerEmail;
  final String customerName;

  factory ReceiptData.fromJson(Map<String, dynamic> json) {
    return ReceiptData(
      order: OrderModel.fromJson(json),
      receiptTitle: json['receipt_title'] as String? ?? 'Receipt',
      tagline: json['tagline'] as String? ?? 'Spoil them properly.',
      customerEmail: json['customer_email'] as String? ?? '',
      customerName: json['customer_name'] as String? ?? '',
    );
  }
}

class PaymentInitResult {
  const PaymentInitResult({
    required this.orderId,
    required this.reference,
    required this.amount,
    required this.demoMode,
    this.authorizationUrl,
    this.publicKey,
    this.order,
  });

  final int orderId;
  final String reference;
  final String amount;
  final bool demoMode;
  final String? authorizationUrl;
  final String? publicKey;
  final OrderModel? order;

  factory PaymentInitResult.fromJson(Map<String, dynamic> json) {
    return PaymentInitResult(
      orderId: json['order_id'] as int,
      reference: json['reference'] as String,
      amount: json['amount'].toString(),
      demoMode: json['demo_mode'] as bool? ?? false,
      authorizationUrl: json['authorization_url'] as String?,
      publicKey: json['public_key'] as String?,
      order: json['order'] != null
          ? OrderModel.fromJson(json['order'] as Map<String, dynamic>)
          : null,
    );
  }
}