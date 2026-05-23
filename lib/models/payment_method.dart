enum PaymentMethodType { card, upi, netBanking, wallet, cod }

class PaymentMethod {
  final String id;
  final PaymentMethodType type;
  final String displayName;
  final String? last4; // last 4 digits for cards
  final String? brand; // 'Visa', 'Mastercard', etc.
  final String? upiId;
  final String? walletName; // 'Paytm', 'PhonePe', etc.
  final bool isDefault;
  final String? expiryMonth;
  final String? expiryYear;

  const PaymentMethod({
    required this.id,
    required this.type,
    required this.displayName,
    this.last4,
    this.brand,
    this.upiId,
    this.walletName,
    this.isDefault = false,
    this.expiryMonth,
    this.expiryYear,
  });

  bool get isExpired {
    if (expiryMonth == null || expiryYear == null) return false;
    final now = DateTime.now();
    final expiry = DateTime(
      int.tryParse('20${expiryYear!}') ?? 0,
      int.tryParse(expiryMonth!) ?? 0,
    );
    return now.isAfter(expiry);
  }

  String get maskedDisplay {
    switch (type) {
      case PaymentMethodType.card:
        return '${brand ?? 'Card'} •••• ${last4 ?? '????'}';
      case PaymentMethodType.upi:
        return upiId ?? displayName;
      case PaymentMethodType.wallet:
        return walletName ?? displayName;
      case PaymentMethodType.netBanking:
        return displayName;
      case PaymentMethodType.cod:
        return 'Cash on Delivery';
    }
  }

  PaymentMethod copyWith({
    String? id,
    PaymentMethodType? type,
    String? displayName,
    String? last4,
    String? brand,
    String? upiId,
    String? walletName,
    bool? isDefault,
    String? expiryMonth,
    String? expiryYear,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      type: type ?? this.type,
      displayName: displayName ?? this.displayName,
      last4: last4 ?? this.last4,
      brand: brand ?? this.brand,
      upiId: upiId ?? this.upiId,
      walletName: walletName ?? this.walletName,
      isDefault: isDefault ?? this.isDefault,
      expiryMonth: expiryMonth ?? this.expiryMonth,
      expiryYear: expiryYear ?? this.expiryYear,
    );
  }

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] ?? '',
      type: _typeFromString(json['type'] ?? 'card'),
      displayName: json['displayName'] ?? '',
      last4: json['last4'],
      brand: json['brand'],
      upiId: json['upiId'],
      walletName: json['walletName'],
      isDefault: json['isDefault'] == true,
      expiryMonth: json['expiryMonth'],
      expiryYear: json['expiryYear'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'displayName': displayName,
      'last4': last4,
      'brand': brand,
      'upiId': upiId,
      'walletName': walletName,
      'isDefault': isDefault,
      'expiryMonth': expiryMonth,
      'expiryYear': expiryYear,
    };
  }

  static PaymentMethodType _typeFromString(String s) {
    return PaymentMethodType.values.firstWhere(
      (e) => e.name == s,
      orElse: () => PaymentMethodType.card,
    );
  }
}
