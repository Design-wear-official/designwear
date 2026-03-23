import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/safe_network_image.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/cart_service.dart';
import '../services/auth_service.dart';
import '../services/demo_data_service.dart';
import '../services/demo_navigation.dart';
import '../services/demo_onboarding.dart';
import '../config/demo_config.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../patterns/responsive_typography_pattern.dart';
import '../styles/app_colors.dart';
import '../utils/responsive_utils.dart';
import 'product_detail_screen.dart';
import 'cart_screen.dart';
import 'login_screen.dart';
import 'design_studio_screen.dart';
import 'profile_screen.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../services/theme_provider.dart';
import '../config/app_config.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ApiService _apiService;
  late Future<List<Category>> _categoriesFuture;
  late Future<List<Product>> _featuredProductsFuture;
  final CarouselSliderController _carouselController =
      CarouselSliderController();

  // Demo-specific variables  
  bool _showDemoWelcome = true;
  final PageController _bannerPageController = PageController();
  final int _currentBannerIndex = 0;

  @override
  void initState() {
    super.initState();
    _apiService = WebApiConfig.useWebApi
        ? ApiService.webApi(WebApiConfig.baseUrl)
        : ApiService.sanity();
    _loadData();
    
    // Demo banner auto-scroll
    _startBannerAutoScroll();
    
    // Show demo onboarding if in demo mode
    if (DemoConfig().isDemoMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showDemoOnboarding();
      });
    }
  }

  void _showDemoOnboarding() async {
    // Show onboarding after a brief delay
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      DemoOnboarding.showAppIntroduction(context);
    }
  }

  @override
  void dispose() {
    _bannerPageController.dispose();
    super.dispose();
  }

  void _startBannerAutoScroll() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _bannerPageController.hasClients) {
        final nextIndex = (_currentBannerIndex + 1) % DemoDataService().demoBanners.length;
        _bannerPageController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        _startBannerAutoScroll();
      } else if (mounted) {
        // PageView not yet attached — retry after a short delay
        Future.delayed(const Duration(milliseconds: 200), _startBannerAutoScroll);
      }
    });
  }

  void _loadData() {
    setState(() {
      _categoriesFuture = _apiService.fetchCategories();
      _featuredProductsFuture = _apiService.fetchFeaturedProducts();
    });
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
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        actions: [
          // Theme Toggle Button
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return IconButton(
                onPressed: () {
                  themeProvider.toggleTheme(!themeProvider.isDarkMode);
                },
                icon: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              );
            },
          ),
          // Login/Profile Button
          Consumer<AuthService>(
            builder: (context, authService, child) {
              return IconButton(
                onPressed: () {
                  if (authService.isLoggedIn) {
                    DemoNavigation.pushWithTransition(
                      context,
                      const ProfileScreen(),
                      routeName: '/profile',
                    );
                  } else {
                    DemoNavigation.pushWithTransition(
                      context,
                      const LoginScreen(),
                      routeName: '/login',
                    );
                  }
                },
                icon: Icon(
                  authService.isLoggedIn ? Icons.person : Icons.person_outline,
                  color: Theme.of(context).colorScheme.onSurface,
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
                      DemoNavigation.pushWithTransition(
                        context,
                        const CartScreen(),
                        routeName: '/cart',
                      );
                    },
                    icon: Icon(
                      Icons.shopping_bag_outlined,
                      color: Theme.of(context).colorScheme.onSurface,
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
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_showDemoWelcome) _buildDemoWelcomeBanner(),
              _buildHeroSection(),
              _buildQuickActionsSection(),
              _buildDesignStudioBanner(),
              _buildSectionTitle('Categories'),
              _buildCategoryList(),
              _buildSectionTitle('Featured Products'),
              _buildProductGrid(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      height: ResponsiveSizes.heroHeight(context),
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveSizes.horizontalPadding(context),
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
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
            // Background image with offline-safe error handling
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl:
                    'https://images.unsplash.com/photo-1441986300917-64674bd600d8?q=80&w=2070&auto=format&fit=crop',
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) =>
                    Container(color: AppColors.backgroundLight),
                placeholder: (_, __) =>
                    Container(color: AppColors.backgroundLight),
              ),
            ),
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
                      color: Theme.of(context).colorScheme.surface,
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
        DemoNavigation.pushWithScale(
          context,
          const DesignStudioScreen(),
          routeName: '/design-studio',
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: ResponsiveSizes.horizontalPadding(context),
          vertical: 12,
        ),
        height: ResponsiveSizes.bannerHeight(context),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          color: Theme.of(context).colorScheme.surface,
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
              Positioned.fill(
                child: Opacity(
                  opacity: 0.3,
                  child: CachedNetworkImage(
                    imageUrl:
                        'https://images.unsplash.com/photo-1503342394128-c104d54dba01?q=80&w=2069&auto=format&fit=crop',
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const SizedBox.shrink(),
                    placeholder: (_, __) => const SizedBox.shrink(),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.surface.withOpacity(0.4),
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
                        color: Theme.of(context).colorScheme.onSurface,
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
                        color: Theme.of(context).colorScheme.surface,
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
                          color: Theme.of(context).colorScheme.onSurface,
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
    final h = ResponsiveSizes.horizontalPadding(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(h, 32, h, 16),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'See All',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
          return InkWell(
            onTap: _loadData,
            child: Container(
              height: 60,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off, color: Colors.orange, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'No internet — tap to retry',
                    style: GoogleFonts.outfit(
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return SizedBox(
          height: 50,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveSizes.horizontalPadding(context),
            ),
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
                  color: Theme.of(context).colorScheme.surface,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  category.title,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
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
      future: _featuredProductsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return InkWell(
            onTap: _loadData,
            child: Container(
              height: 200,
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off, color: Colors.orange, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    'No internet connection',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pull down to refresh or tap here to retry',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: Colors.orange.shade600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            children: [
              CarouselSlider.builder(
                carouselController: _carouselController,
                itemCount: snapshot.data!.length,
                options: CarouselOptions(
                  height: ResponsiveSizes.carouselHeight(context),
                  enlargeCenterPage: true,
                  viewportFraction: 0.8,
                  enableInfiniteScroll:
                      false, // Disabled to prevent duplicate Hero tags
                  autoPlay: true,
                  autoPlayInterval: const Duration(seconds: 5),
                ),
                itemBuilder: (context, index, realIndex) {
                  final product = snapshot.data![index];
                  return GestureDetector(
                    onTap: () {
                      DemoNavigation.pushWithTransition(
                        context,
                        ProductDetailScreen(product: product),
                        routeName: '/product/${product.slug}',
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 5.0,
                        vertical: 10.0,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Hero(
                                tag: product.id,
                                child: Container(
                                  color: AppColors.backgroundLight,
                                  child: product.imageUrl != null
                                      ? SafeNetworkImage(
                                          imageUrl: product.imageUrl!,
                                          fit: BoxFit.cover,
                                        )
                                      : Icon(
                                          Icons.image_not_supported,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.7),
                                          size: 50,
                                        ),
                                ),
                              ),
                            ),
                            // Gradient overlay and details at the bottom
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.9),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      product.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: ResponsiveTypography.h4(
                                        context,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '₹${product.price.toStringAsFixed(2)}',
                                      style: ResponsiveTypography.price(context)
                                          .copyWith(
                                            color: AppColors.accentBlue,
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              // Navigation controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.surface,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.chevron_left,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      onPressed: () => _carouselController.previousPage(),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.surface,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.chevron_right,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      onPressed: () => _carouselController.nextPage(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDemoWelcomeBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.accentBlue.withOpacity(0.1), AppColors.purple.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accentBlue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accentBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.star, color: Colors.black, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Demo Mode Active',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Explore all features with demo data',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => setState(() => _showDemoWelcome = false),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'QUICK ACTIONS',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  'Design Studio',
                  Icons.create,
                  AppColors.accentBlue,
                  () => DemoNavigation.pushWithScale(
                    context,
                    const DesignStudioScreen(),
                    routeName: '/design-studio',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  'My Cart',
                  Icons.shopping_cart,
                  AppColors.purple,
                  () => DemoNavigation.pushWithTransition(
                    context,
                    const CartScreen(),
                    routeName: '/cart',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  'Profile',
                  Icons.person,
                  Colors.orange,
                  () => DemoNavigation.pushWithFade(
                    context,
                    const ProfileScreen(),
                    routeName: '/profile',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
