class ProductModel {
  const ProductModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.basePrice,
    required this.imageUrl,
    required this.categoryName,
    required this.categorySlug,
    this.description = '',
    this.deliveryInfo = '',
    this.isFeatured = false,
    this.isPopular = false,
    this.arEnabled = true,
    this.previewMode = 'image',
    this.model3dUrl = '',
    this.previewScale = '1.0',
  });

  final int id;
  final String name;
  final String slug;
  final String basePrice;
  final String imageUrl;
  final String categoryName;
  final String categorySlug;
  final String description;
  final String deliveryInfo;
  final bool isFeatured;
  final bool isPopular;
  final bool arEnabled;
  final String previewMode;
  final String model3dUrl;
  final String previewScale;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
      basePrice: json['base_price'].toString(),
      imageUrl: json['image_url'] as String? ?? '',
      categoryName: json['category_name'] as String? ?? json['category']?['name'] as String? ?? '',
      categorySlug: json['category_slug'] as String? ?? json['category']?['slug'] as String? ?? '',
      description: json['description'] as String? ?? '',
      deliveryInfo: json['delivery_info'] as String? ?? '',
      isFeatured: json['is_featured'] as bool? ?? false,
      isPopular: json['is_popular'] as bool? ?? false,
      arEnabled: json['ar_enabled'] as bool? ?? true,
      previewMode: json['preview_mode'] as String? ?? 'image',
      model3dUrl: json['model_3d_url'] as String? ?? '',
      previewScale: json['preview_scale']?.toString() ?? '1.0',
    );
  }
}