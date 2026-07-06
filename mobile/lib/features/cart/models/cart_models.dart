class CustomisationDetails {
  const CustomisationDetails({
    this.message = '',
    this.photoUrl = '',
    this.wrappingOptionId,
    this.wrappingName = '',
    this.ribbonColor = '',
    this.wrappingPrice = '0',
  });

  final String message;
  final String photoUrl;
  final int? wrappingOptionId;
  final String wrappingName;
  final String ribbonColor;
  final String wrappingPrice;

  factory CustomisationDetails.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const CustomisationDetails();
    return CustomisationDetails(
      message: json['message'] as String? ?? '',
      photoUrl: json['photo_url'] as String? ?? '',
      wrappingOptionId: json['wrapping_option_id'] as int?,
      wrappingName: json['wrapping_name'] as String? ?? '',
      ribbonColor: json['ribbon_color'] as String? ?? '',
      wrappingPrice: json['wrapping_price']?.toString() ?? '0',
    );
  }

  Map<String, dynamic> toJson() => {
        if (message.isNotEmpty) 'message': message,
        if (photoUrl.isNotEmpty) 'photo_url': photoUrl,
        if (wrappingOptionId != null) 'wrapping_option_id': wrappingOptionId,
        if (wrappingName.isNotEmpty) 'wrapping_name': wrappingName,
        if (ribbonColor.isNotEmpty) 'ribbon_color': ribbonColor,
        if (wrappingPrice.isNotEmpty) 'wrapping_price': wrappingPrice,
      };

  CustomisationDetails copyWith({
    String? message,
    String? photoUrl,
    int? wrappingOptionId,
    String? wrappingName,
    String? ribbonColor,
    String? wrappingPrice,
    bool clearPhoto = false,
    bool clearWrapping = false,
  }) {
    return CustomisationDetails(
      message: message ?? this.message,
      photoUrl: clearPhoto ? '' : (photoUrl ?? this.photoUrl),
      wrappingOptionId: clearWrapping ? null : (wrappingOptionId ?? this.wrappingOptionId),
      wrappingName: clearWrapping ? '' : (wrappingName ?? this.wrappingName),
      ribbonColor: clearWrapping ? '' : (ribbonColor ?? this.ribbonColor),
      wrappingPrice: clearWrapping ? '0' : (wrappingPrice ?? this.wrappingPrice),
    );
  }
}

class CartItemModel {
  const CartItemModel({
    required this.id,
    required this.productId,
    required this.productSlug,
    required this.productName,
    required this.productImageUrl,
    required this.quantity,
    required this.unitPrice,
    required this.lineUnitTotal,
    required this.lineTotal,
    required this.customisation,
  });

  final int id;
  final int productId;
  final String productSlug;
  final String productName;
  final String productImageUrl;
  final int quantity;
  final String unitPrice;
  final String lineUnitTotal;
  final String lineTotal;
  final CustomisationDetails customisation;

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id'] as int,
      productId: json['product_id'] as int,
      productSlug: json['product_slug'] as String? ?? '',
      productName: json['product_name'] as String,
      productImageUrl: json['product_image_url'] as String? ?? '',
      quantity: json['quantity'] as int,
      unitPrice: json['unit_price'].toString(),
      lineUnitTotal: json['line_unit_total'].toString(),
      lineTotal: json['line_total'].toString(),
      customisation: CustomisationDetails.fromJson(
        json['customisation_details'] as Map<String, dynamic>?,
      ),
    );
  }
}

class CartModel {
  const CartModel({
    required this.id,
    required this.items,
    required this.itemCount,
    required this.subtotal,
  });

  final int id;
  final List<CartItemModel> items;
  final int itemCount;
  final String subtotal;

  factory CartModel.fromJson(Map<String, dynamic> json) {
    return CartModel(
      id: json['id'] as int,
      items: (json['items'] as List<dynamic>)
          .map((e) => CartItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      itemCount: json['item_count'] as int? ?? 0,
      subtotal: json['subtotal'].toString(),
    );
  }

  bool get isEmpty => items.isEmpty;
}