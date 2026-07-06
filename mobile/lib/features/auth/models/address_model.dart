class AddressModel {
  const AddressModel({
    required this.id,
    required this.label,
    required this.recipientName,
    required this.phone,
    required this.streetAddress,
    required this.suburb,
    required this.city,
    required this.province,
    required this.postalCode,
    required this.isDefault,
  });

  final int? id;
  final String label;
  final String recipientName;
  final String phone;
  final String streetAddress;
  final String suburb;
  final String city;
  final String province;
  final String postalCode;
  final bool isDefault;

  String get shortSummary => '$streetAddress, $city';

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] as int?,
      label: json['label'] as String? ?? 'Home',
      recipientName: json['recipient_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      streetAddress: json['street_address'] as String? ?? '',
      suburb: json['suburb'] as String? ?? '',
      city: json['city'] as String? ?? '',
      province: json['province'] as String? ?? '',
      postalCode: json['postal_code'] as String? ?? '',
      isDefault: json['is_default'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'recipient_name': recipientName,
        'phone': phone,
        'street_address': streetAddress,
        'suburb': suburb,
        'city': city,
        'province': province,
        'postal_code': postalCode,
        'is_default': isDefault,
      };
}