import 'address.dart';
import 'payment_method.dart';

class AppUser {
  final String id;
  final String? name;
  final String? email;
  final String? phone;
  final String? photoUrl;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final String authProvider; // 'email', 'google', 'phone'
  final List<Address> addresses;
  final List<PaymentMethod> paymentMethods;
  final int loyaltyPoints;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;
  final Map<String, dynamic> preferences;

  const AppUser({
    required this.id,
    this.name,
    this.email,
    this.phone,
    this.photoUrl,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    this.authProvider = 'email',
    this.addresses = const [],
    this.paymentMethods = const [],
    this.loyaltyPoints = 0,
    this.createdAt,
    this.lastLoginAt,
    this.preferences = const {},
  });

  String get displayName => name ?? email?.split('@').first ?? 'User';
  String get initials {
    if (name == null || name!.isEmpty) return 'U';
    final parts = name!.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }

  Address? get defaultAddress {
    if (addresses.isEmpty) return null;
    return addresses.firstWhere(
      (a) => a.isDefault,
      orElse: () => addresses.first,
    );
  }

  PaymentMethod? get defaultPaymentMethod {
    if (paymentMethods.isEmpty) return null;
    return paymentMethods.firstWhere(
      (p) => p.isDefault,
      orElse: () => paymentMethods.first,
    );
  }

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? photoUrl,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    String? authProvider,
    List<Address>? addresses,
    List<PaymentMethod>? paymentMethods,
    int? loyaltyPoints,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    Map<String, dynamic>? preferences,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      authProvider: authProvider ?? this.authProvider,
      addresses: addresses ?? List.from(this.addresses),
      paymentMethods: paymentMethods ?? List.from(this.paymentMethods),
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      preferences: preferences ?? Map.from(this.preferences),
    );
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] ?? json['uid'] ?? '',
      name: json['name'] ?? json['displayName'],
      email: json['email'],
      phone: json['phone'] ?? json['phoneNumber'],
      photoUrl: json['photoUrl'] ?? json['photoURL'],
      isEmailVerified: json['isEmailVerified'] == true,
      isPhoneVerified: json['isPhoneVerified'] == true,
      authProvider: json['authProvider'] ?? 'email',
      addresses: (json['addresses'] as List<dynamic>?)
              ?.map((e) => Address.fromJson(e))
              .toList() ??
          [],
      paymentMethods: (json['paymentMethods'] as List<dynamic>?)
              ?.map((e) => PaymentMethod.fromJson(e))
              .toList() ??
          [],
      loyaltyPoints: (json['loyaltyPoints'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.tryParse(json['lastLoginAt'])
          : null,
      preferences: Map<String, dynamic>.from(json['preferences'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'photoUrl': photoUrl,
      'isEmailVerified': isEmailVerified,
      'isPhoneVerified': isPhoneVerified,
      'authProvider': authProvider,
      'addresses': addresses.map((a) => a.toJson()).toList(),
      'paymentMethods': paymentMethods.map((p) => p.toJson()).toList(),
      'loyaltyPoints': loyaltyPoints,
      'createdAt': createdAt?.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'preferences': preferences,
    };
  }
}
