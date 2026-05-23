import '../../models/product.dart';
import '../../models/category.dart';

abstract class ProductRepository {
  Future<List<Product>> fetchProducts();
  Future<List<Product>> fetchFeaturedProducts();
  Future<List<Category>> fetchCategories();
  Future<List<Product>> fetchProductsByCategory(String categoryId);
  Future<Product?> fetchProductById(String productId);
  Future<double> fetchTaxRate();
}
