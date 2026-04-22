import '../models/product.dart';
import '../models/category.dart';

/// Service that provides demo data for showcase purposes
/// This ensures the app always has content to display even without backend connectivity
class DemoDataService {
  static final DemoDataService _instance = DemoDataService._internal();
  factory DemoDataService() => _instance;
  DemoDataService._internal();

  /// Demo categories for the app
  List<Category> get demoCategories => [
        Category(
          id: 'demo-cat-1',
          title: 'T-Shirts',
          slug: 't-shirts',
          description: 'Comfortable cotton t-shirts for every occasion',
          imageUrl: 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=400&fit=crop',
        ),
        Category(
          id: 'demo-cat-2',
          title: 'Hoodies',
          slug: 'hoodies',
          description: 'Cozy hoodies perfect for cool weather',
          imageUrl: 'https://images.unsplash.com/photo-1556821840-3a9c6ee6c95e?w=400&fit=crop',
        ),
        Category(
          id: 'demo-cat-3',
          title: 'Tank Tops',
          slug: 'tank-tops',
          description: 'Breathable tank tops for summer vibes',
          imageUrl: 'https://images.unsplash.com/photo-1618354691373-d851c5c3a990?w=400&fit=crop',
        ),
        Category(
          id: 'demo-cat-4',
          title: 'Long Sleeve',
          slug: 'long-sleeve',
          description: 'Stylish long sleeve shirts for layering',
          imageUrl: 'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?w=400&fit=crop',
        ),
        Category(
          id: 'demo-cat-5',
          title: 'Polo Shirts',
          slug: 'polo-shirts',
          description: 'Classic polo shirts for a smart casual look',
          imageUrl: 'https://images.unsplash.com/photo-1586790170083-2f9ceadc732d?w=400&fit=crop',
        ),
      ];

  /// Demo products for the app
  List<Product> get demoProducts => [
        Product(
          id: 'demo-prod-1',
          title: 'Classic Cotton T-Shirt',
          slug: 'classic-cotton-tee',
          description: 'Soft, comfortable 100% cotton t-shirt perfect for everyday wear. Available in multiple colors.',
          price: 24.99,
          imageUrl: 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=500&fit=crop',
          categoryId: 'demo-cat-1',
          stockStatus: 'inStock',

        ),
        Product(
          id: 'demo-prod-2',
          title: 'Premium Hoodie',
          slug: 'premium-hoodie',
          description: 'Ultra-soft fleece hoodie with kangaroo pocket and drawstring hood. Perfect for layering.',
          price: 59.99,
          imageUrl: 'https://images.unsplash.com/photo-1556821840-3a9c6ee6c95e?w=500&fit=crop',
          categoryId: 'demo-cat-2',
          stockStatus: 'inStock',
          featured: true,
        ),
        Product(
          id: 'demo-prod-3',
          title: 'Vintage Graphic Tee',
          slug: 'vintage-graphic-tee',
          description: 'Retro-inspired graphic t-shirt with vintage wash finish. Made from organic cotton.',
          price: 32.99,
          imageUrl: 'https://images.unsplash.com/photo-1503341504253-dff4815485f1?w=500&fit=crop',
          categoryId: 'demo-cat-1',
          stockStatus: 'inStock',
          featured: true,
        ),
        Product(
          id: 'demo-prod-4',
          title: 'Workout Tank Top',
          slug: 'workout-tank-top',
          description: 'Moisture-wicking tank top designed for active wear. Lightweight and breathable fabric.',
          price: 19.99,
          imageUrl: 'https://images.unsplash.com/photo-1618354691373-d851c5c3a990?w=500&fit=crop',
          categoryId: 'demo-cat-3',
          stockStatus: 'inStock',
          featured: false,
        ),
        Product(
          id: 'demo-prod-5',
          title: 'Cozy Pullover Hoodie',
          slug: 'cozy-pullover-hoodie',
          description: 'Oversized pullover hoodie with ribbed cuffs and hem. Perfect for lounging in comfort.',
          price: 49.99,
          imageUrl: 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=500&fit=crop',
          categoryId: 'demo-cat-2',
          stockStatus: 'inStock',
          featured: true,
        ),
        Product(
          id: 'demo-prod-6',
          title: 'Minimalist Long Sleeve',
          slug: 'minimalist-long-sleeve',
          description: 'Clean, minimalist long sleeve shirt in premium cotton. Timeless design meets modern comfort.',
          price: 39.99,
          imageUrl: 'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?w=500&fit=crop',
          categoryId: 'demo-cat-4',
          stockStatus: 'inStock',
          featured: false,
        ),
        Product(
          id: 'demo-prod-7',
          title: 'Designer Polo Shirt',
          slug: 'designer-polo-shirt',
          description: 'Sophisticated polo shirt with contrast trim. Made from premium pique cotton fabric.',
          price: 45.99,
          imageUrl: 'https://images.unsplash.com/photo-1586790170083-2f9ceadc732d?w=500&fit=crop',
          categoryId: 'demo-cat-5',
          stockStatus: 'inStock',
        ),
        Product(
          id: 'demo-prod-8',
          title: 'Striped Summer Tank',
          slug: 'striped-summer-tank',
          description: 'Breezy striped tank top perfect for summer days. Lightweight cotton blend material.',
          price: 22.99,
          imageUrl: 'https://images.unsplash.com/photo-1469334031218-e382a71b716b?w=500&fit=crop',
          categoryId: 'demo-cat-3',
          stockStatus: 'inStock',
          featured: false,
        ),
        Product(
          id: 'demo-prod-9',
          title: 'Urban Streetwear Hoodie',
          slug: 'urban-streetwear-hoodie',
          description: 'Bold streetwear hoodie with contemporary graphics. Heavy-weight cotton for durability.',
          price: 65.99,
          imageUrl: 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=500&fit=crop',
          categoryId: 'demo-cat-2',
          stockStatus: 'lowStock',
          featured: true,
        ),
        Product(
          id: 'demo-prod-10',
          title: 'Artisan Crafted Tee',
          slug: 'artisan-crafted-tee',
          description: 'Hand-crafted t-shirt featuring unique local artwork. Each piece tells a story.',
          price: 34.99,
          imageUrl: 'https://images.unsplash.com/photo-1503341504253-dff4815485f1?w=500&fit=crop',
          categoryId: 'demo-cat-1',
          stockStatus: 'inStock',
          featured: false,
        ),
      ];

  /// Get featured products for demo
  List<Product> get featuredProducts => 
    demoProducts.where((product) => product.featured).toList();

  /// Get products by category for demo
  List<Product> getProductsByCategory(String categoryId) => 
    demoProducts.where((product) => product.categoryId == categoryId).toList();

  /// Find product by ID
  Product? getProductById(String productId) => 
    demoProducts.cast<Product?>().firstWhere(
      (product) => product?.id == productId,
      orElse: () => null,
    );

  /// Demo banner content for hero section
  List<Map<String, String>> get demoBanners => [
        {
          'title': 'New Spring Collection',
          'subtitle': 'Fresh designs for the season',
          'imageUrl': 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=800&fit=crop',
          'badge': 'NEW ARRIVAL'
        },
        {
          'title': 'Design Your Own Style',
          'subtitle': 'Unlimited creativity awaits',
          'imageUrl': 'https://images.unsplash.com/photo-1523380744952-b4a7ee58b2aa?w=800&fit=crop',
          'badge': 'CUSTOM DESIGN'
        },
        {
          'title': 'Premium Quality Fabrics',
          'subtitle': 'Comfort meets durability',
          'imageUrl': 'https://images.unsplash.com/photo-1556821840-3a9c6ee6c95e?w=800&fit=crop',
          'badge': 'QUALITY PROMISE'
        },
      ];

  /// Demo notifications for user engagement
  List<Map<String, dynamic>> get demoNotifications => [
        {
          'title': '🎉 Welcome to Design Wear!',
          'message': 'Explore our custom design studio and create your perfect look.',
          'type': 'welcome',
          'timestamp': DateTime.now().subtract(const Duration(minutes: 5)),
        },
        {
          'title': '🆕 New Products Added',
          'message': 'Check out our latest collection of premium apparel.',
          'type': 'product',
          'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
        },
        {
          'title': '💡 Design Tip',
          'message': 'Try using our AI design assistant for creative inspiration!',
          'type': 'tip',
          'timestamp': DateTime.now().subtract(const Duration(days: 1)),
        },
      ];

  /// Demo user profile for logged-in experience
  Map<String, dynamic> get demoUserProfile => {
        'name': 'Demo User',
        'email': 'demo@designwear.com',
        'avatar': 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=200&fit=crop&crop=face',
        'joinDate': DateTime.now().subtract(const Duration(days: 30)),
        'ordersCount': 5,
        'favoriteCategory': 'T-Shirts',
        'lastOrderDate': DateTime.now().subtract(const Duration(days: 7)),
      };

  /// Demo order history
  List<Map<String, dynamic>> get demoOrders => [
        {
          'id': 'ORD-001',
          'date': DateTime.now().subtract(const Duration(days: 7)),
          'status': 'Delivered',
          'total': 78.97,
          'items': [
            {'product': demoProducts[0], 'quantity': 2},
            {'product': demoProducts[1], 'quantity': 1},
          ],
        },
        {
          'id': 'ORD-002',
          'date': DateTime.now().subtract(const Duration(days: 14)),
          'status': 'Delivered',
          'total': 45.99,
          'items': [
            {'product': demoProducts[6], 'quantity': 1},
          ],
        },
      ];
}