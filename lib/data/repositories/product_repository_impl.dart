import 'package:designwear/models/models.dart';
import 'package:designwear/services/services.dart';
import 'product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ApiService _apiService;

  ProductRepositoryImpl(this._apiService);

  @override
  Future<List<Category>> fetchCategories() async {
    return _apiService.fetchCategories();
  }

  @override
  Future<List<Product>> fetchFeaturedProducts() async {
    return _apiService.fetchFeaturedProducts();
  }

  @override
  Future<Product?> fetchProductById(String productId) async {
    return _apiService.fetchProductById(productId);
  }

  @override
  Future<double> fetchTaxRate() async {
    return _apiService.fetchTaxRate();
  }

  @override
  Future<List<Product>> fetchProducts() async {
    return _apiService.fetchProducts();
  }

  @override
  Future<List<Product>> fetchProductsByCategory(String categoryId) async {
    return _apiService.fetchProductsByCategory(categoryId);
  }
}
