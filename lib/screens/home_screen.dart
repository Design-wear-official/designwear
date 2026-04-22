import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/safe_network_image.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/cart_service.dart';
import '../services/auth_service.dart';
import '../services/demo_navigation.dart';
import '../services/demo_onboarding.dart';
import '../config/demo_config.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../styles/app_colors.dart';
import '../utils/responsive_utils.dart';
import 'product_detail_screen.dart';
import 'cart_screen.dart';
import 'login_screen.dart';
import 'design_studio_screen.dart';
import 'profile_screen.dart';
import 'search_results_screen.dart';
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
  late Future<List<Product>> _allProductsFuture;

  bool _showDemoWelcome = true;
  int _currentBannerPage = 0;
  int _selectedCategoryIndex = 0;
  String? _selectedCategoryId;   // null = show all
  int _bottomNavIndex = 0;
  final PageController _bannerPageController = PageController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  bool _searchFocused = false;

  // ─── Banner data ────────────────────────────────────────────────────────────
  static const _banners = [
    {
      'badge': 'NEW COLLECTION',
      'title': 'Signature Style,\nPremium Comfort',
      'sub': 'Explore handcrafted apparel for the modern wardrobe.',
      'cta': 'SHOP NOW',
      'image': 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?q=80&w=2070&auto=format&fit=crop',
      'ctaColor': 'purple',
    },
    {
      'badge': 'DESIGN STUDIO',
      'title': 'Design Your\nOwn Style',
      'sub': 'Create unique custom apparel that speaks for you.',
      'cta': 'START CREATING',
      'image': 'https://images.unsplash.com/photo-1503342394128-c104d54dba01?q=80&w=2069&auto=format&fit=crop',
      'ctaColor': 'blue',
    },
    {
      'badge': '🔥 FLASH SALE',
      'title': 'Up to 50% Off\nToday Only',
      'sub': 'Limited-time deals on premium collections.',
      'cta': 'GRAB DEAL',
      'image': 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?q=80&w=2069&auto=format&fit=crop',
      'ctaColor': 'orange',
    },
  ];

  // ─── Category tabs ───────────────────────────────────────────────────────────
  static const _navTabs = [
    'All', 'Collections', 'T-Shirts', 'Hoodies', 'Polo Shirts',
    'Design Studio', 'Trending', 'New Arrivals', 'Sale',
  ];

  // ─── Category icons (like Zepto) ─────────────────────────────────────────────
  static const _catIcons = [
    {'label': 'Design',    'icon': Icons.style,              'color': AppColors.accentBlue},
    {'label': 'Trending',  'icon': Icons.local_fire_department, 'color': Colors.orange},
    {'label': 'New In',    'icon': Icons.new_releases_outlined, 'color': AppColors.purple},
    {'label': 'Sale',      'icon': Icons.sell_outlined,        'color': Colors.red},
    {'label': 'T-Shirts',  'icon': Icons.checkroom_outlined,   'color': Colors.teal},
    {'label': 'Hoodies',   'icon': Icons.ac_unit,              'color': Colors.indigo},
    {'label': 'Polo',      'icon': Icons.sports_soccer,        'color': Colors.green},
    {'label': 'Premium',   'icon': Icons.diamond_outlined,     'color': AppColors.gold},
  ];

  @override
  void initState() {
    super.initState();
    _apiService = WebApiConfig.useWebApi
        ? ApiService.webApi(WebApiConfig.baseUrl)
        : ApiService.sanity();
    // Assign directly in initState — never use setState here.
    // _loadData() is reserved for pull-to-refresh rebuilds.
    _categoriesFuture = _apiService.fetchCategories();
    _featuredProductsFuture = _apiService.fetchFeaturedProducts();
    _allProductsFuture = _apiService.fetchProducts();
    _searchFocusNode.addListener(() {
      setState(() => _searchFocused = _searchFocusNode.hasFocus);
    });
    _startBannerAutoScroll();
    if (DemoConfig().isDemoMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showDemoOnboarding());
    }
  }

  void _showDemoOnboarding() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) DemoOnboarding.showAppIntroduction(context);
  }

  @override
  void dispose() {
    _bannerPageController.dispose();
    _scrollController.dispose();
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _startBannerAutoScroll() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _bannerPageController.hasClients) {
        final next = (_currentBannerPage + 1) % _banners.length;
        _bannerPageController.animateToPage(next,
            duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
        _startBannerAutoScroll();
      } else if (mounted) {
        Future.delayed(const Duration(milliseconds: 200), _startBannerAutoScroll);
      }
    });
  }

  void _goToSearch() {
    final query = _searchController.text.trim();
    _searchFocusNode.unfocus();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => SearchResultsScreen(initialQuery: query),
    ));
  }

  void _loadData() {
    setState(() {
      _categoriesFuture = _apiService.fetchCategories();
      _featuredProductsFuture = _apiService.fetchFeaturedProducts();
      _allProductsFuture = _apiService.fetchProducts();
    });
  }

  // ════════════════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final hp = ResponsiveSizes.horizontalPadding(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      bottomNavigationBar: isDesktop ? null : _buildBottomNav(),
      body: Column(
        children: [
          // ── AppBar ──────────────────────────────────────────────────────────
          _buildAppBar(isDesktop, hp),
          // ── Sub-nav tabs ────────────────────────────────────────────────────
          _buildSubNavBar(isDesktop, hp),
          // ── Scrollable body ─────────────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _loadData(),
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top section: banner + sidebar (desktop) or just banner (mobile)
                    if (isDesktop)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildBannerCarousel(isDesktop, hp),
                                _buildCategoryIconRow(isDesktop, hp),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 420,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_showDemoWelcome) _buildDemoWelcomeBanner(),
                                  _buildDesignStudioBanner(),
                                  _buildTrendingSection(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          if (_showDemoWelcome) _buildDemoWelcomeBanner(),
                          _buildBannerCarousel(isDesktop, hp),
                          _buildCategoryIconRow(isDesktop, hp),
                        ],
                      ),

                    // ── Today's Deals strip ─────────────────────────────────
                    _buildDealsSection(isDesktop, hp),

                    // ── Categories ─────────────────────────────────────────
                    _buildSectionTitle('Categories'),
                    _buildCategoryList(),

                    // ── Featured Products horizontal row ──────────────────
                    _buildSectionTitle('Featured Products'),
                    _buildFeaturedProductsRow(isDesktop, hp),

                    // ── All Products grid ──────────────────────────────────
                    _buildSectionTitle('All Products'),
                    _buildProductGrid(),

                    const SizedBox(height: 56),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // SEARCH BAR  (Chrome / Google address-bar style capsule)
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildSearchBar(bool isDesktop, bool isDark) {
    final double barH = isDesktop ? 46.0 : 44.0;
    // Google-style: pure white / dark-surface background, NO hard border,
    // depth comes entirely from layered shadows.
    final bgColor = isDark
        ? const Color(0xFF303134)   // Google dark search bg
        : Colors.white;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: barH,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(barH / 2),
        border: _searchFocused
            ? Border.all(color: AppColors.accentBlue, width: 1.8)
            : null,
        boxShadow: _searchFocused
            ? [
                BoxShadow(color: Colors.black.withOpacity(isDark ? 0.5 : 0.15),
                    blurRadius: 20, spreadRadius: 1, offset: const Offset(0, 4)),
                BoxShadow(color: AppColors.accentBlue.withOpacity(0.18),
                    blurRadius: 0, spreadRadius: 2),
              ]
            : [
                BoxShadow(color: Colors.black.withOpacity(isDark ? 0.45 : 0.10),
                    blurRadius: 10, offset: const Offset(0, 3)),
                BoxShadow(color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
                    blurRadius: 2, offset: const Offset(0, 1)),
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Search icon ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 10),
            child: Icon(
              Icons.search_rounded,
              size: 21,
              color: _searchFocused
                  ? AppColors.accentBlue
                  : (isDark ? const Color(0xFF9AA0A6) : const Color(0xFF70757A)),
            ),
          ),

          // ── Input ─────────────────────────────────────────────────────
          Expanded(
            child: TextField(
              focusNode: _searchFocusNode,
              controller: _searchController,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: isDark ? Colors.white : Colors.black87,
                height: 1.0,
              ),
              textAlignVertical: TextAlignVertical.center,
              textInputAction: TextInputAction.search,
              cursorColor: AppColors.accentBlue,
              decoration: InputDecoration(
                hintText: isDesktop
                    ? 'Search products, designs, categories…'
                    : 'Search products…',
                hintStyle: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: isDark ? const Color(0xFF9AA0A6) : const Color(0xFF70757A),
                  height: 1.0,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              onSubmitted: (_) => _goToSearch(),
              onChanged: (_) => setState(() {}),
            ),
          ),

          // ── Right actions ──────────────────────────────────────────────
          if (_searchController.text.isNotEmpty)
            GestureDetector(
              onTap: () { _searchController.clear(); setState(() {}); },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Icon(Icons.cancel_rounded,
                    size: 19,
                    color: isDark ? const Color(0xFF9AA0A6) : const Color(0xFF70757A)),
              ),
            ),

          // Thin vertical divider before mic/Search button
          if (_searchController.text.isEmpty)
            Container(
              width: 1,
              height: 22,
              color: isDark ? Colors.white12 : Colors.black12,
              margin: const EdgeInsets.symmetric(horizontal: 6),
            ),

          // Mic icon
          if (_searchController.text.isEmpty)
            Padding(
              padding: EdgeInsets.only(right: isDesktop ? 6 : 12),
              child: Icon(Icons.mic_none_rounded,
                  size: 21,
                  color: isDark ? const Color(0xFF9AA0A6) : const Color(0xFF70757A)),
            ),

          // Desktop: gradient "Search" pill (flush inside the capsule)
          if (isDesktop)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: GestureDetector(
                onTap: _goToSearch,
                child: Container(
                  height: barH - 8,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    gradient: AppColors.neonGradient,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Search',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ),

          // Mobile: lens/scan icon
          if (!isDesktop && _searchController.text.isEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Icon(Icons.document_scanner_outlined,
                  size: 20,
                  color: isDark ? const Color(0xFF9AA0A6) : const Color(0xFF70757A)),
            ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // APP BAR  (search-bar-centric, like Amazon/Flipkart)
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildAppBar(bool isDesktop, double hp) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final outerPad = isDesktop ? hp + 12 : hp;
    return SafeArea(
      child: Container(
        height: isDesktop ? 72 : 60,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(
            bottom: BorderSide(
              color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
            ),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: outerPad, vertical: 8),
          child: Row(
            children: [
              // ── Logo ───────────────────────────────────────────────────
              Container(
                width: isDesktop ? 38 : 32,
                height: isDesktop ? 38 : 32,
                decoration: BoxDecoration(
                  gradient: AppColors.neonGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.style, color: Colors.white, size: isDesktop ? 20 : 17),
              ),
              SizedBox(width: isDesktop ? 10 : 8),
              if (isDesktop)
                Text(
                  'Design Wear',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    letterSpacing: 0.3,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              SizedBox(width: isDesktop ? 20 : 10),

              // ── Search bar (Chrome-style capsule) ───────────────────────
              Expanded(child: _buildSearchBar(isDesktop, isDark)),
              const SizedBox(width: 8),

              // ── Icon buttons ────────────────────────────────────────────
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, _) => _buildIconBtn(
                  themeProvider.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  () => themeProvider.toggleTheme(!themeProvider.isDarkMode),
                  context,
                ),
              ),
              const SizedBox(width: 4),
              Consumer<AuthService>(
                builder: (context, authService, _) => _buildIconBtn(
                  authService.isLoggedIn ? Icons.person : Icons.person_outline,
                  () {
                    if (authService.isLoggedIn) {
                      DemoNavigation.pushWithTransition(context, const ProfileScreen(), routeName: '/profile');
                    } else {
                      DemoNavigation.pushWithTransition(context, const LoginScreen(), routeName: '/login');
                    }
                  },
                  context,
                ),
              ),
              const SizedBox(width: 4),
              Consumer<CartService>(
                builder: (context, cartService, _) => Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _buildIconBtn(
                      Icons.shopping_bag_outlined,
                      () => DemoNavigation.pushWithTransition(context, const CartScreen(), routeName: '/cart'),
                      context,
                    ),
                    if (cartService.itemCount > 0)
                      Positioned(
                        right: 2,
                        top: 2,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            gradient: AppColors.neonGradient,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${cartService.itemCount}',
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
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

  // ════════════════════════════════════════════════════════════════════════════
  // SUB-NAV  (sticky category tab bar, like Flipkart/Zepto)
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildSubNavBar(bool isDesktop, double hp) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).colorScheme.surface : Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05),
          ),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: isDesktop ? hp + 12 : hp),
        itemCount: _navTabs.length,
        itemBuilder: (context, i) {
          final selected = _selectedCategoryIndex == i;
          return GestureDetector(
            onTap: () {
              if (_navTabs[i] == 'Design Studio') {
                DemoNavigation.pushWithScale(context, const DesignStudioScreen(), routeName: '/design-studio');
              } else {
                setState(() => _selectedCategoryIndex = i);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: selected ? AppColors.accentBlue : Colors.transparent,
                    width: 2.5,
                  ),
                ),
              ),
              child: Center(
                child: Text(
                  _navTabs[i],
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? AppColors.accentBlue
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // BANNER CAROUSEL  (multi-slide with dot indicators)
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildBannerCarousel(bool isDesktop, double hp) {
    final bannerH = isDesktop ? 400.0 : 210.0;
    final margin = isDesktop
        ? EdgeInsets.fromLTRB(hp + 12, 14, 8, 0)
        : EdgeInsets.zero;

    return Column(
      children: [
        Container(
          margin: margin,
          height: bannerH,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(isDesktop ? 24 : 0),
            child: PageView.builder(
              controller: _bannerPageController,
              onPageChanged: (i) => setState(() => _currentBannerPage = i),
              itemCount: _banners.length,
              itemBuilder: (context, i) => _buildOneBanner(_banners[i], isDesktop),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Dot indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_banners.length, (i) {
            final active = _currentBannerPage == i;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: active ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                gradient: active ? AppColors.neonGradient : null,
                color: active ? null : Colors.grey.withOpacity(0.35),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  void _onBannerCtaTap(Map<String, Object> banner) {
    if (banner['ctaColor'] == 'blue') {
      // "Design Studio" banner — open Design Studio
      DemoNavigation.pushWithScale(context, const DesignStudioScreen(), routeName: '/design-studio');
    } else {
      // Other banners — scroll down to product section
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent * 0.35,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
  }

  Widget _buildOneBanner(Map<String, Object> banner, bool isDesktop) {
    final ctaColor = banner['ctaColor'] == 'blue'
        ? AppColors.accentBlue
        : banner['ctaColor'] == 'orange'
            ? Colors.orange
            : AppColors.purple;

    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: banner['image'] as String,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => Container(color: AppColors.backgroundLight),
          placeholder: (_, __) => Container(color: AppColors.backgroundLight),
        ),
        // Dark gradient overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              stops: const [0.0, 0.55, 1.0],
              colors: [Colors.black.withOpacity(0.92), Colors.black.withOpacity(0.4), Colors.black.withOpacity(0.05)],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(isDesktop ? 36 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: ctaColor.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  banner['badge'] as String,
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: isDesktop ? 14 : 8),
              // Title
              Text(
                banner['title'] as String,
                style: GoogleFonts.outfit(
                  fontSize: isDesktop ? 44 : 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
              SizedBox(height: isDesktop ? 10 : 6),
              // Sub
              Text(
                banner['sub'] as String,
                style: GoogleFonts.outfit(
                  fontSize: isDesktop ? 15 : 12,
                  color: Colors.white.withOpacity(0.75),
                ),
              ),
              SizedBox(height: isDesktop ? 24 : 14),
              // CTA button
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _onBannerCtaTap(banner),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 32 : 22,
                        vertical: isDesktop ? 14 : 10,
                      ),
                      decoration: BoxDecoration(
                        color: ctaColor,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [BoxShadow(color: ctaColor.withOpacity(0.45), blurRadius: 14, offset: const Offset(0, 5))],
                      ),
                      child: Text(
                        banner['cta'] as String,
                        style: GoogleFonts.outfit(
                          fontSize: isDesktop ? 14 : 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  if (isDesktop) ...[
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => _scrollController.animateTo(
                        _scrollController.position.maxScrollExtent * 0.35,
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeInOut,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white54, width: 1.5),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          'EXPLORE',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                  // Desktop stats strip
                  if (isDesktop) ...[
                    const Spacer(),
                    _buildBannerStatChip('50K+', 'Customers'),
                    const SizedBox(width: 8),
                    _buildBannerStatChip('1200+', 'Designs'),
                    const SizedBox(width: 8),
                    _buildBannerStatChip('4.9★', 'Rating'),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBannerStatChip(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
          Text(label, style: GoogleFonts.outfit(fontSize: 10, color: Colors.white.withOpacity(0.7))),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // CATEGORY ICON ROW  (like Zepto's quick-access icons)
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildCategoryIconRow(bool isDesktop, double hp) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final outerPad = isDesktop ? hp + 12 : hp;
    return Container(
      margin: EdgeInsets.fromLTRB(0, 16, 0, 4),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).colorScheme.surface : Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04)),
          bottom: BorderSide(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04)),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: SizedBox(
        height: 80,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: outerPad),
          itemCount: _catIcons.length,
          itemBuilder: (context, i) {
            final cat = _catIcons[i];
            final color = cat['color'] as Color;
            return GestureDetector(
              onTap: () {
                if (cat['label'] == 'Design') {
                  DemoNavigation.pushWithScale(context, const DesignStudioScreen(), routeName: '/design-studio');
                } else {
                  const labelToTab = {
                    'Trending': 6, 'New In': 7, 'Sale': 8,
                    'T-Shirts': 2, 'Hoodies': 3, 'Polo': 4,
                  };
                  final tabIdx = labelToTab[cat['label'] as String];
                  if (tabIdx != null) setState(() => _selectedCategoryIndex = tabIdx);
                }
              },
              child: SizedBox(
                width: isDesktop ? 96 : 78,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: isDesktop ? 54 : 46,
                      height: isDesktop ? 54 : 46,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        shape: BoxShape.circle,
                        border: Border.all(color: color.withOpacity(0.2)),
                      ),
                      child: Icon(cat['icon'] as IconData, color: color, size: isDesktop ? 26 : 22),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      cat['label'] as String,
                      style: GoogleFonts.outfit(
                        fontSize: isDesktop ? 12 : 11,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // TODAY'S DEALS  (horizontal scroll with discount badges, like Amazon deals)
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildDealsSection(bool isDesktop, double hp) {
    final outerPad = isDesktop ? hp + 12 : hp;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    const dealItems = [
      {'label': 'Graphic Tee', 'original': 1299, 'sale': 649, 'off': 50, 'color': AppColors.accentBlue},
      {'label': 'Classic Hoodie', 'original': 2499, 'sale': 1499, 'off': 40, 'color': AppColors.purple},
      {'label': 'Polo Shirt', 'original': 999, 'sale': 649, 'off': 35, 'color': Colors.teal},
      {'label': 'Jogger Pants', 'original': 1799, 'sale': 989, 'off': 45, 'color': Colors.orange},
      {'label': 'Tank Top', 'original': 799, 'sale': 559, 'off': 30, 'color': Colors.green},
      {'label': 'Oversized Tee', 'original': 1599, 'sale': 719, 'off': 55, 'color': Colors.red},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(outerPad, 20, outerPad, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'DEALS',
                  style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1.2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "Today's Deals",
                style: GoogleFonts.outfit(
                  fontSize: isDesktop ? 20 : 16,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Text(
                'Up to 55% off',
                style: GoogleFonts.outfit(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {},
                child: Text(
                  'See All →',
                  style: GoogleFonts.outfit(fontSize: 13, color: AppColors.accentBlue, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: isDesktop ? 200 : 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: outerPad),
            itemCount: dealItems.length,
            itemBuilder: (context, i) {
              final item = dealItems[i];
              final color = item['color'] as Color;
              final off = item['off'] as int;
              final sale = item['sale'] as int;
              final original = item['original'] as int;
              final label = item['label'] as String;
              return Container(
                width: isDesktop ? 160 : 140,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.07)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product image placeholder with gradient
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Container(
                        height: isDesktop ? 100 : 88,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Center(child: Icon(Icons.checkroom_outlined, color: color, size: isDesktop ? 40 : 34)),
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text('$off% OFF', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text('₹$sale',
                                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w900, color: color)),
                              const SizedBox(width: 6),
                              Text('₹$original',
                                  style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey, decoration: TextDecoration.lineThrough)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // FEATURED PRODUCTS  (horizontal scroll row, like Amazon "pick up where you left off")
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildFeaturedProductsRow(bool isDesktop, double hp) {
    final outerPad = isDesktop ? hp + 12 : hp;
    return FutureBuilder<List<Product>>(
      future: _featuredProductsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 180, child: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();

        final cardW = isDesktop ? 200.0 : 160.0;
        final cardH = isDesktop ? 280.0 : 230.0;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return SizedBox(
          height: cardH,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: outerPad),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final product = snapshot.data![index];
              final featuredHeroTag = 'featured_${product.id}';
              return GestureDetector(
                onTap: () => DemoNavigation.pushWithTransition(
                  context,
                  ProductDetailScreen(product: product, heroTag: featuredHeroTag),
                  routeName: '/product/${product.slug}',
                ),
                child: Container(
                  width: cardW,
                  margin: const EdgeInsets.only(right: 14),
                  decoration: BoxDecoration(
                    color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.07)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image
                        SizedBox(
                          height: cardH * 0.65,
                          width: double.infinity,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Hero(
                                tag: featuredHeroTag,
                                child: Container(
                                  color: AppColors.backgroundLight,
                                  child: product.imageUrl != null
                                      ? SafeNetworkImage(imageUrl: product.imageUrl!, fit: BoxFit.cover)
                                      : const Icon(Icons.image_not_supported, size: 36),
                                ),
                              ),
                              // NEW badge
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    gradient: AppColors.neonGradient,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('NEW', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Info
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    '₹${product.price.toStringAsFixed(0)}',
                                    style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.accentBlue),
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                                  Text(' 4.5', style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ICON BUTTON  (reusable small icon button)
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildIconBtn(IconData icon, VoidCallback onTap, BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withOpacity(0.07)
              : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurface),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // SECTION TITLE  (with accent strip)
  // ════════════════════════════════════════════════════════════════════════════

  void _onSeeAll(String title) {
    switch (title) {
      case 'Featured Products':
      case 'All Products':
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        break;
      case 'Categories':
        // Clear category filter to show all
        setState(() => _selectedCategoryId = null);
        break;
    }
  }

  Widget _buildSectionTitle(String title) {
    final hp = ResponsiveSizes.horizontalPadding(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = ResponsiveUtils.isDesktop(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isDesktop ? hp + 12 : hp,
        isDesktop ? 28 : 24,
        isDesktop ? hp + 12 : hp,
        isDesktop ? 14 : 12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: isDesktop ? 5 : 4,
            height: isDesktop ? 26 : 20,
            decoration: BoxDecoration(gradient: AppColors.neonGradient, borderRadius: BorderRadius.circular(4)),
          ),
          SizedBox(width: isDesktop ? 12 : 10),
          Text(
            title.toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: isDesktop ? 20 : 15,
              fontWeight: FontWeight.w800,
              letterSpacing: isDesktop ? 1.4 : 1.1,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _onSeeAll(title),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 16 : 12, vertical: isDesktop ? 7 : 5),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'See All →',
                style: GoogleFonts.outfit(fontSize: isDesktop ? 13 : 12, fontWeight: FontWeight.w600, color: AppColors.accentBlue),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // CATEGORY LIST  (horizontal chips)
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildCategoryList() {
    return FutureBuilder<List<Category>>(
      future: _categoriesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 52, child: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return InkWell(
            onTap: _loadData,
            child: Container(
              height: 52,
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
                  Text('No internet — tap to retry', style: GoogleFonts.outfit(color: Colors.orange.shade700, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          );
        }
        return SizedBox(
          height: 52,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: ResponsiveSizes.horizontalPadding(context)),
            scrollDirection: Axis.horizontal,
            itemCount: snapshot.data!.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final category = snapshot.data![index];
              final isSelected = _selectedCategoryId == category.id;
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedCategoryId = isSelected ? null : category.id;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppColors.neonGradient : null,
                    color: isSelected ? null : Theme.of(context).colorScheme.surface,
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : (Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.black.withOpacity(0.08)),
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: isSelected
                        ? [BoxShadow(color: AppColors.purple.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]
                        : null,
                  ),
                  child: Text(
                    category.title,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ALL PRODUCTS  (fluid responsive grid)
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildProductGrid() {
    return FutureBuilder<List<Product>>(
      future: _allProductsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          );
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
                  Text('No internet connection',
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.orange.shade700)),
                  const SizedBox(height: 4),
                  Text('Pull down to refresh or tap here to retry',
                      style: GoogleFonts.outfit(fontSize: 13, color: Colors.orange.shade600)),
                ],
              ),
            ),
          );
        }

        // ── Client-side filtering: search text + selected category ──────
        final query = _searchController.text.trim().toLowerCase();
        final filtered = snapshot.data!.where((p) {
          final matchesCategory = _selectedCategoryId == null || p.categoryId == _selectedCategoryId;
          final matchesSearch = query.isEmpty ||
              p.title.toLowerCase().contains(query) ||
              p.description.toLowerCase().contains(query);
          return matchesCategory && matchesSearch;
        }).toList();

        if (filtered.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            child: Column(
              children: [
                Icon(Icons.search_off_rounded, size: 48, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
                const SizedBox(height: 12),
                Text(
                  query.isNotEmpty ? 'No results for "$query"' : 'No products in this category',
                  style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                  textAlign: TextAlign.center,
                ),
                if (_selectedCategoryId != null || query.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() => _selectedCategoryId = null);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: AppColors.neonGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('Clear filters', style: GoogleFonts.outfit(
                          fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = ResponsiveUtils.isDesktop(context);
              final hPad = ResponsiveSizes.horizontalPadding(context);
              final outerPad = isDesktop ? hPad + 12 : hPad;
              final availableW = constraints.maxWidth - outerPad * 2;
              final cols = (availableW / 250).floor().clamp(2, 6);
              const spacing = 16.0;
              final cardW = (availableW - spacing * (cols - 1)) / cols;
              final cardH = cardW * 1.55;
              final borderR = isDesktop ? 18.0 : 14.0;

              return Padding(
                padding: EdgeInsets.fromLTRB(outerPad, 8, outerPad, 8),
                child: Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: filtered.map((product) {
                    final gridHeroTag = 'grid_${product.id}';
                    return SizedBox(
                      width: cardW,
                      height: cardH,
                      child: GestureDetector(
                        onTap: () => DemoNavigation.pushWithTransition(
                          context,
                          ProductDetailScreen(product: product, heroTag: gridHeroTag),
                          routeName: '/product/${product.slug}',
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(borderR),
                            border: Border.all(color: AppColors.border),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 14, offset: const Offset(0, 4))],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(borderR),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: Hero(
                                    tag: gridHeroTag,
                                    child: Container(
                                      color: AppColors.backgroundLight,
                                      child: product.imageUrl != null
                                          ? SafeNetworkImage(imageUrl: product.imageUrl!, fit: BoxFit.cover)
                                          : Icon(Icons.image_not_supported,
                                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), size: 36),
                                    ),
                                  ),
                                ),
                                // Wishlist
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
                                    child: const Icon(Icons.favorite_border, color: Colors.white, size: 14),
                                  ),
                                ),
                                // Bottom info
                                Positioned(
                                  bottom: 0, left: 0, right: 0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [Colors.black.withOpacity(0.9), Colors.transparent],
                                      ),
                                    ),
                                    padding: EdgeInsets.all(cols >= 4 ? 14 : 12),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(product.title,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: GoogleFonts.outfit(
                                                      fontSize: cols >= 4 ? 13 : 12,
                                                      fontWeight: FontWeight.w700,
                                                      color: Colors.white,
                                                      height: 1.3)),
                                              const SizedBox(height: 4),
                                              Text('₹${product.price.toStringAsFixed(0)}',
                                                  style: GoogleFonts.outfit(
                                                      fontSize: cols >= 4 ? 14 : 13,
                                                      fontWeight: FontWeight.w900,
                                                      color: AppColors.accentBlue)),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: cols >= 4 ? 10 : 8, vertical: cols >= 4 ? 7 : 6),
                                          decoration: BoxDecoration(
                                            gradient: AppColors.neonGradient,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Icon(Icons.add_shopping_cart, color: Colors.white, size: cols >= 4 ? 15 : 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // DESIGN STUDIO BANNER  (right sidebar)
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildDesignStudioBanner() {
    final hp = ResponsiveSizes.horizontalPadding(context);
    final isDesktop = ResponsiveUtils.isDesktop(context);
    return GestureDetector(
      onTap: () => DemoNavigation.pushWithScale(context, const DesignStudioScreen(), routeName: '/design-studio'),
      child: Container(
        margin: EdgeInsets.fromLTRB(isDesktop ? 8 : hp, 12, hp, 12),
        height: isDesktop ? 200 : ResponsiveSizes.bannerHeight(context),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: AppColors.purple.withOpacity(0.18), blurRadius: 20, offset: const Offset(0, 6))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: 'https://images.unsplash.com/photo-1503342394128-c104d54dba01?q=80&w=2069&auto=format&fit=crop',
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(color: AppColors.backgroundLight),
                  placeholder: (_, __) => Container(color: AppColors.backgroundLight),
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xCC8A2BE2), Color(0xCC00F0FF)],
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.brush_rounded, color: Colors.white, size: 32),
                    const SizedBox(height: 8),
                    Text('DESIGN YOUR OWN',
                        style: GoogleFonts.outfit(
                            color: Colors.white, fontWeight: FontWeight.w800, fontSize: isDesktop ? 20 : 18, letterSpacing: 2)),
                    const SizedBox(height: 4),
                    Text('Create your unique style',
                        style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.85), fontSize: 12)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 9),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8)],
                      ),
                      child: Text('START CREATING',
                          style: GoogleFonts.outfit(color: AppColors.purple, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.5)),
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

  // ════════════════════════════════════════════════════════════════════════════
  // TRENDING SECTION  (sidebar)
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildTrendingSection() {
    final hp = ResponsiveSizes.horizontalPadding(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        // Live stats mini-row
        Container(
          margin: EdgeInsets.fromLTRB(8, 0, hp, 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.purple.withOpacity(0.15), AppColors.accentBlue.withOpacity(0.1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : AppColors.purple.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSidebarStat('1.2K', 'Orders Today', AppColors.accentBlue),
              Container(width: 1, height: 32, color: isDark ? Colors.white12 : Colors.black12),
              _buildSidebarStat('38', 'New Designs', AppColors.purple),
              Container(width: 1, height: 32, color: isDark ? Colors.white12 : Colors.black12),
              _buildSidebarStat('4.9★', 'Rating', AppColors.gold),
            ],
          ),
        ),
        // Trending card
        Container(
          margin: EdgeInsets.fromLTRB(8, 0, hp, 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06)),
            boxShadow: [BoxShadow(color: AppColors.purple.withOpacity(0.08), blurRadius: 20, spreadRadius: 2)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: AppColors.accentBlue.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.trending_up_rounded, color: AppColors.accentBlue, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Text('TRENDING NOW',
                      style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: AppColors.accentBlue)),
                ],
              ),
              const SizedBox(height: 16),
              _buildTrendItem('Graphic Tees', '#1', Icons.trending_up, AppColors.accentBlue),
              _buildTrendItem('Hoodies', '#2', Icons.local_fire_department, Colors.orange),
              _buildTrendItem('Polo Shirts', '#3', Icons.star, AppColors.gold),
              _buildTrendItem('Tank Tops', '#4', Icons.bolt, AppColors.purple),
              const SizedBox(height: 18),
              Container(height: 1, color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06)),
              const SizedBox(height: 16),
              Text('WHY CHOOSE US',
                  style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
              const SizedBox(height: 12),
              _buildFeatureRow(Icons.local_shipping_outlined, 'Free shipping over ₹999'),
              _buildFeatureRow(Icons.replay, '30-day returns'),
              _buildFeatureRow(Icons.verified_outlined, 'Premium quality'),
              _buildFeatureRow(Icons.support_agent, '24/7 support'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 2),
        Text(label,
            style: GoogleFonts.outfit(
                fontSize: 10, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
      ],
    );
  }

  Widget _buildTrendItem(String label, String rank, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
          ),
          Text(rank, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.accentBlue),
          const SizedBox(width: 10),
          Text(text,
              style: GoogleFonts.outfit(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.75))),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // MOBILE BOTTOM NAV BAR
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildBottomNav() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = [
      {'icon': Icons.home_outlined,       'activeIcon': Icons.home_rounded,          'label': 'Home'},
      {'icon': Icons.search_outlined,     'activeIcon': Icons.search_rounded,        'label': 'Search'},
      {'icon': Icons.brush_outlined,      'activeIcon': Icons.brush_rounded,         'label': 'Design'},
      {'icon': Icons.shopping_bag_outlined,'activeIcon': Icons.shopping_bag_rounded,  'label': 'Cart'},
      {'icon': Icons.person_outline,      'activeIcon': Icons.person_rounded,        'label': 'Profile'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.07),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(items.length, (i) {
              final active = _bottomNavIndex == i;
              final icon = active
                  ? items[i]['activeIcon'] as IconData
                  : items[i]['icon'] as IconData;
              final label = items[i]['label'] as String;

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (i == 1) {
                      // Search — open search results screen
                      setState(() => _bottomNavIndex = i);
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const SearchResultsScreen(initialQuery: ''),
                      ));
                    } else if (i == 2) {
                      // Design Studio
                      DemoNavigation.pushWithScale(context, const DesignStudioScreen(),
                          routeName: '/design-studio');
                    } else if (i == 3) {
                      // Cart
                      DemoNavigation.pushWithTransition(context, const CartScreen(),
                          routeName: '/cart');
                    } else if (i == 4) {
                      // Profile
                      final auth = context.read<AuthService>();
                      DemoNavigation.pushWithTransition(
                        context,
                        auth.isLoggedIn ? const ProfileScreen() : const LoginScreen(),
                        routeName: auth.isLoggedIn ? '/profile' : '/login',
                      );
                    } else {
                      setState(() => _bottomNavIndex = i);
                    }
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: active ? AppColors.accentBlue.withOpacity(0.12) : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(icon,
                            size: 22,
                            color: active
                                ? AppColors.accentBlue
                                : Theme.of(context).colorScheme.onSurface.withOpacity(0.45)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                          color: active
                              ? AppColors.accentBlue
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // DEMO WELCOME BANNER
  // ════════════════════════════════════════════════════════════════════════════

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
            decoration: BoxDecoration(color: AppColors.accentBlue, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.star, color: Colors.black, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Demo Mode Active',
                    style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                Text('Explore all features with demo data',
                    style: GoogleFonts.outfit(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => setState(() => _showDemoWelcome = false)),
        ],
      ),
    );
  }
}
