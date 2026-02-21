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
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 20,
        title: Text(
          'Design Wear',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            letterSpacing: 0.5,
          ),
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
                  color: AppColors.textPrimary,
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
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (cartService.itemCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.accentBlue,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${cartService.itemCount}',
                          style: const TextStyle(
                            color: Colors.black,
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
      height: 260,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        image: const DecorationImage(
          image: NetworkImage(
            'https://images.unsplash.com/photo-1441986300917-64674bd600d8?q=80&w=2070&auto=format&fit=crop',
          ),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomRight,
                  end: Alignment.topLeft,
                  colors: [
                    AppColors.background.withOpacity(0.9),
                    AppColors.background.withOpacity(0.2),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      'NEW COLLECTION',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentBlue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Signature Style,\nPremium Comfort',
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: AppColors.neonGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.purple.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        'SHOP NOW',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 1.5,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          color: AppColors.surface,
          image: const DecorationImage(
            image: NetworkImage(
              'https://images.unsplash.com/photo-1503342394128-c104d54dba01?q=80&w=2069&auto=format&fit=crop',
            ),
            fit: BoxFit.cover,
            opacity: 0.3,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentBlue.withOpacity(0.1),
              blurRadius: 15,
              spreadRadius: 1,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.background.withOpacity(0.4),
                      AppColors.purple.withOpacity(0.2),
                    ],
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'DESIGN YOUR OWN',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: AppColors.borderFocus),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentBlue.withOpacity(0.3),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Text(
                        'START CREATING',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
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
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'See All',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
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
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  category.title,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
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
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Hero(
                          tag: product.id,
                          child: Container(
                            width: double.infinity,
                            color: AppColors.backgroundLight,
                            child: product.imageUrl != null
                                ? SafeNetworkImage(
                                    imageUrl: product.imageUrl!,
                                    fit: BoxFit.cover,
                                  )
                                : Icon(
                                    Icons.image_not_supported,
                                    color: AppColors.textSecondary,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: ResponsiveTypography.body(
                      context,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ).copyWith(height: 1.3),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${product.price.toStringAsFixed(2)}',
                    style: ResponsiveTypography.price(
                      context,
                    ).copyWith(color: AppColors.accentBlue, fontSize: 16),
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
