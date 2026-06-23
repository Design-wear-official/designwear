import 'package:designwear/models/models.dart';

/// Declarative descriptor for a garment the studio can render. Adding a garment
/// (or a back asset) is data here, not code in the canvas.
///
/// `frontAsset`/`backAsset` are bundled image paths; `null` means "no artwork
/// yet" — the canvas shows a placeholder but still lets the user design that
/// face (elements are stored per [DesignSide]).
class Garment {
  final String id;
  final String label;
  final String? frontAsset;
  final String? backAsset;

  const Garment({
    required this.id,
    required this.label,
    this.frontAsset,
    this.backAsset,
  });

  String? asset(DesignSide side) =>
      side == DesignSide.back ? backAsset : frontAsset;

  bool hasAsset(DesignSide side) => asset(side) != null;

  /// True for garments whose front art uses the calibrated collar/pocket overlay.
  bool get supportsCollarPocketOverlay => id == 'tshirt';
}

class GarmentRegistry {
  GarmentRegistry._();

  static const List<Garment> all = [
    Garment(
      id: 'tshirt',
      label: 'T-Shirt',
      frontAsset: 'assets/images/tshirt_white.png',
      // backAsset: add 'assets/images/tshirt_white_back.png' when available.
    ),
    Garment(id: 'hoodie', label: 'Hoodie'),
    Garment(id: 'polo', label: 'Polo Shirt'),
    Garment(id: 'cap', label: 'Cap'),
    Garment(id: 'totebag', label: 'Tote Bag'),
  ];

  /// Maps Sanity category slugs / variants onto canonical garment ids.
  static const Map<String, String> _aliases = {
    'shirt': 'tshirt',
    't-shirt': 'tshirt',
    'tshirts': 'tshirt',
    'tee': 'tshirt',
    'hoodies': 'hoodie',
    'polo-shirt': 'polo',
    'polos': 'polo',
    'caps': 'cap',
    'tote': 'totebag',
    'tote-bag': 'totebag',
    'totebags': 'totebag',
  };

  static Garment byId(String id) {
    final key = _aliases[id] ?? id;
    return all.firstWhere(
      (g) => g.id == key,
      orElse: () => Garment(id: id, label: id),
    );
  }
}
