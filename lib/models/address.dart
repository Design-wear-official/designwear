class Address {
  final String id;
  final String fullName;
  final String phone;
  final String line1;
  final String? line2;
  final String city;
  final String state;
  final String pincode;
  final String country;
  final bool isDefault;
  final String? label; // 'Home', 'Work', 'Other'

  const Address({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.line1,
    this.line2,
    required this.city,
    required this.state,
    required this.pincode,
    this.country = 'India',
    this.isDefault = false,
    this.label,
  });

  String get formatted =>
      '$line1${line2 != null ? ', $line2' : ''}, $city, $state $pincode, $country';

  Address copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? line1,
    String? line2,
    String? city,
    String? state,
    String? pincode,
    String? country,
    bool? isDefault,
    String? label,
  }) {
    return Address(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      line1: line1 ?? this.line1,
      line2: line2 ?? this.line2,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      country: country ?? this.country,
      isDefault: isDefault ?? this.isDefault,
      label: label ?? this.label,
    );
  }

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] ?? '',
      fullName: json['fullName'] ?? '',
      phone: json['phone'] ?? '',
      line1: json['line1'] ?? '',
      line2: json['line2'],
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? '',
      country: json['country'] ?? 'India',
      isDefault: json['isDefault'] == true,
      label: json['label'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'phone': phone,
      'line1': line1,
      'line2': line2,
      'city': city,
      'state': state,
      'pincode': pincode,
      'country': country,
      'isDefault': isDefault,
      'label': label,
    };
  }
}
