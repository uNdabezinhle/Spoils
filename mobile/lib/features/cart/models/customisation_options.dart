class WrappingOptionModel {
  const WrappingOptionModel({
    required this.id,
    required this.name,
    required this.ribbonColor,
    required this.price,
    required this.imageUrl,
  });

  final int id;
  final String name;
  final String ribbonColor;
  final String price;
  final String imageUrl;

  factory WrappingOptionModel.fromJson(Map<String, dynamic> json) {
    return WrappingOptionModel(
      id: json['id'] as int,
      name: json['name'] as String,
      ribbonColor: json['ribbon_color'] as String,
      price: json['price'].toString(),
      imageUrl: json['image_url'] as String? ?? '',
    );
  }
}

class MessageTemplateModel {
  const MessageTemplateModel({
    required this.id,
    required this.occasion,
    required this.title,
    required this.message,
  });

  final int id;
  final String occasion;
  final String title;
  final String message;

  factory MessageTemplateModel.fromJson(Map<String, dynamic> json) {
    return MessageTemplateModel(
      id: json['id'] as int,
      occasion: json['occasion'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
    );
  }
}