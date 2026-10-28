import 'package:designwear/models/product.dart';
import 'package:flutter_test/flutter_test.dart';

Product withStock(int n) => Product.fromRecord({
  'id': 'p',
  'title': 'Tee',
  'price': 500,
  'stockCount': n,
});

void main() {
  test('stock labels: plenty, low, and none', () {
    expect(withStock(40).stockLabel, 'In stock');
    expect(withStock(5).stockLabel, 'Only 5 left');
    expect(withStock(1).isLowStock, isTrue);
    expect(withStock(0).stockLabel, 'Out of stock');
    expect(withStock(0).isLowStock, isFalse);
  });
}
