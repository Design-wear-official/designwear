import '../../data/repositories/product_repository.dart';
import '../../models/category.dart';
import '../../models/product.dart';

class GetProductsUseCase {
  final ProductRepository _productRepository;

  GetProductsUseCase(this._productRepository);

  Future<List<Product>> call() {
    return _productRepository.fetchProducts();
  }
}

class GetFeaturedProductsUseCase {
  final ProductRepository _productRepository;

  GetFeaturedProductsUseCase(this._productRepository);

  Future<List<Product>> call() {
    return _productRepository.fetchFeaturedProducts();
  }
}

class GetCategoriesUseCase {
  final ProductRepository _productRepository;

  GetCategoriesUseCase(this._productRepository);

  Future<List<Category>> call() {
    return _productRepository.fetchCategories();
  }
}

class GetProductsByCategoryUseCase {
  final ProductRepository _productRepository;

  GetProductsByCategoryUseCase(this._productRepository);

  Future<List<Product>> call(String categoryId) {
    return _productRepository.fetchProductsByCategory(categoryId);
  }
}

class GetProductByIdUseCase {
  final ProductRepository _productRepository;

  GetProductByIdUseCase(this._productRepository);

  Future<Product?> call(String productId) {
    return _productRepository.fetchProductById(productId);
  }
}

class GetTaxRateUseCase {
  final ProductRepository _productRepository;

  GetTaxRateUseCase(this._productRepository);

  Future<double> call() {
    return _productRepository.fetchTaxRate();
  }
}
