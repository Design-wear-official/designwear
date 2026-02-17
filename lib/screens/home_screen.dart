import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';
import '../widgets/safe_network_image.dart';
import 'package:provider/provider.dart';
import '../services/sanity_service.dart';
import '../services/cart_service.dart';
import '../services/auth_service.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../patterns/responsive_grid_pattern.dart';
import '../patterns/responsive_typography_pattern.dart';
import '../utils/responsive_utils.dart';
import '../styles/app_colors.dart';
import 'product_detail_screen.dart';
import 'cart_screen.dart';
import 'login_screen.dart';
import 'design_studio_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SanityService _sanityService = SanityService();
  late Future<List<Category>> _categoriesFuture;
  late Future<List<Product>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = _sanityService.fetchCategories();
    _productsFuture = _sanityService.fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Text(
          'Design Wear',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          // Login/Profile Button
          Consumer<AuthService>(
            builder: (context, authService, child) {
              return IconButton(
                onPressed: () {
                  if (authService.isLoggedIn) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  }
                },
                icon: Icon(
                  authService.isLoggedIn ? Icons.person : Icons.person_outline,
                  color: AppColors.black,
                ),
              );
            },
          ),
          // Cart Button with Badge
          Consumer<CartService>(
            builder: (context, cartService, child) {
              return Stack(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CartScreen()),
                      );
                    },
                    icon: const Icon(
                      Icons.shopping_bag_outlined,
                      color: AppColors.black,
                    ),
                  ),
                  if (cartService.itemCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.gold,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${cartService.itemCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroSection(),
            _buildDesignStudioBanner(), // New entry point
            _buildSectionTitle('Categories'),
            _buildCategoryList(),
            _buildSectionTitle('Featured Products'),
            _buildProductGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      height: 240,
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.circular(
          0,
        ), // Sharp edges or minimal radius for modern look
        image: const DecorationImage(
          image: NetworkImage(
            'https://images.unsplash.com/photo-1441986300917-64674bd600d8?q=80&w=2070&auto=format&fit=crop',
          ),
          fit: BoxFit.cover,
          opacity: 0.7,
        ),
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withOpacity(0.8), Colors.transparent],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'NEW COLLECTION',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Signature Style,\nPremium Comfort',
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(0),
                    ),
                  ),
                  child: Text(
                    'SHOP NOW',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesignStudioBanner() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DesignStudioScreen()),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        height: 140,
        decoration: BoxDecoration(
          color: Colors.black,
          image: const DecorationImage(
            image: NetworkImage(
              'https://images.unsplash.com/photo-1503342394128-c104d54dba01?q=80&w=2069&auto=format&fit=crop',
            ), // Fashion/Design related image
            fit: BoxFit.cover,
            opacity: 0.4,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'DESIGN YOUR OWN',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.gold, width: 2),
                ),
                child: Text(
                  'START CREATING',
                  style: GoogleFonts.outfit(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'See All',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.gold,
              decoration: TextDecoration.underline,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildCategoryList() {
    return FutureBuilder<List<Category>>(
      future: _categoriesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox(
            height: 100,
            child: Center(child: Text('No categories found')),
          );
        }
        return SizedBox(
          height: 50,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: snapshot.data!.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final category = snapshot.data![index];
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  category.title,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildProductGrid() {
    return FutureBuilder<List<Product>>(
      future: _productsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No products found'));
        }
        return ResponsiveGridBuilder(
          itemCount: snapshot.data!.length,
          config: ResponsiveGridConfig(
            mobileColumns: 2,
            tabletColumns: 3,
            desktopColumns:
                ResponsiveUtils.isWidthGreaterThan(
                  context,
                  ResponsiveBreakpoints.largeDesktop,
                )
                ? 5
                : 4,
            mobileAspectRatio: 0.75,
            tabletAspectRatio: 0.65,
            desktopAspectRatio: 0.60,
            crossAxisSpacing: 20,
            mainAxisSpacing: 32,
          ),
          itemBuilder: (context, index) {
            final product = snapshot.data![index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetailScreen(product: product),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Hero(
                      tag: product.id,
                      child: Container(
                        width: double.infinity,
                        color: Colors.grey.shade50,
                        child: product.imageUrl != null
                            ? SafeNetworkImage(
                                imageUrl: product.imageUrl!,
                                fit: BoxFit.cover,
                              )
                            : const Icon(Icons.image_not_supported),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: ResponsiveTypography.body(
                      context,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ).copyWith(height: 1.3),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '₹${product.price.toStringAsFixed(2)}',
                    style: ResponsiveTypography.price(context),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
