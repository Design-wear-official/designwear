import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/demo_navigation.dart';
import '../services/demo_onboarding.dart';
import '../config/demo_config.dart';
import '../config/app_config.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../domain/usecases/product_use_cases.dart';
import '../presentation/utils/responsive_utils.dart';
import 'home/home_app_bar.dart';
import 'home/home_banner_carousel.dart';
import 'home/home_constants.dart';
import 'home/home_nav_widgets.dart';
import 'home/home_sections.dart';
import 'home/home_sidebar_widgets.dart';
import 'search_results_screen.dart';
import 'design_studio_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ── Services ──────────────────────────────────────────────────────────────
  late GetCategoriesUseCase _getCategoriesUseCase;
  late GetFeaturedProductsUseCase _getFeaturedProductsUseCase;
  late GetProductsUseCase _getProductsUseCase;

  // ── Futures ───────────────────────────────────────────────────────────────
  late Future<List<Category>> _categoriesFuture;
  late Future<List<Product>> _featuredProductsFuture;
  late Future<List<Product>> _allProductsFuture;

  // ── State ─────────────────────────────────────────────────────────────────
  bool _showDemoWelcome = true;
  int _currentBannerPage = 0;
  int _selectedCategoryIndex = 0;
  String? _selectedCategoryId;
  int _bottomNavIndex = 0;

  // ── Controllers ───────────────────────────────────────────────────────────
  final PageController _bannerPageController = PageController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  bool _searchFocused = false;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _getCategoriesUseCase = Provider.of<GetCategoriesUseCase>(context, listen: false);
    _getFeaturedProductsUseCase = Provider.of<GetFeaturedProductsUseCase>(context, listen: false);
    _getProductsUseCase = Provider.of<GetProductsUseCase>(context, listen: false);
    _categoriesFuture = _getCategoriesUseCase();
    _featuredProductsFuture = _getFeaturedProductsUseCase();
    _allProductsFuture = _getProductsUseCase();

    _searchFocusNode.addListener(() {
      setState(() => _searchFocused = _searchFocusNode.hasFocus);
    });
    _startBannerAutoScroll();

    if (DemoConfig().isDemoMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) => DemoOnboarding.showAppIntroduction(context));
    }
  }

  @override
  void dispose() {
    _bannerPageController.dispose();
    _scrollController.dispose();
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _startBannerAutoScroll() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _bannerPageController.hasClients) {
        final next = (_currentBannerPage + 1) % HomeConstants.banners.length;
        _bannerPageController.animateToPage(next,
            duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
        _startBannerAutoScroll();
      } else if (mounted) {
        Future.delayed(const Duration(milliseconds: 200), _startBannerAutoScroll);
      }
    });
  }

  void _goToSearch() {
    _searchFocusNode.unfocus();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => SearchResultsScreen(initialQuery: _searchController.text.trim()),
    ));
  }

  void _loadData() {
    setState(() {
      _categoriesFuture = _getCategoriesUseCase();
      _featuredProductsFuture = _getFeaturedProductsUseCase();
      _allProductsFuture = _getProductsUseCase();
    });
  }

  void _onNavTabTap(int i) {
    if (HomeConstants.navTabs[i] == 'Design Studio') {
      DemoNavigation.pushWithScale(context, const DesignStudioScreen(), routeName: '/design-studio');
    } else {
      setState(() => _selectedCategoryIndex = i);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final hp = ResponsiveSizes.horizontalPadding(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      bottomNavigationBar: isDesktop
          ? null
          : HomeBottomNav(
              currentIndex: _bottomNavIndex,
              onTap: (i) => setState(() => _bottomNavIndex = i),
            ),
      body: Column(
        children: [
          // App bar
          HomeAppBar(
            isDesktop: isDesktop,
            hp: hp,
            searchFocused: _searchFocused,
            searchController: _searchController,
            searchFocusNode: _searchFocusNode,
            onSearch: _goToSearch,
          ),

          // Sub-nav tabs
          HomeSubNavBar(
            isDesktop: isDesktop,
            hp: hp,
            selectedIndex: _selectedCategoryIndex,
            onTabTap: _onNavTabTap,
            tabs: HomeConstants.navTabs,
          ),

          // Scrollable body
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
                                HomeBannerCarousel(
                                  controller: _bannerPageController,
                                  currentPage: _currentBannerPage,
                                  isDesktop: isDesktop,
                                  hp: hp,
                                  scrollController: _scrollController,
                                  onPageChanged: (i) => setState(() => _currentBannerPage = i),
                                ),
                                HomeCategoryIconRow(
                                  isDesktop: isDesktop,
                                  hp: hp,
                                  onCategoryTap: (i) => setState(() => _selectedCategoryIndex = i),
                                ),
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
                                  if (_showDemoWelcome)
                                    HomeDemoWelcomeBanner(onDismiss: () => setState(() => _showDemoWelcome = false)),
                                  const HomeDesignStudioBanner(),
                                  const HomeTrendingSection(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          if (_showDemoWelcome)
                            HomeDemoWelcomeBanner(onDismiss: () => setState(() => _showDemoWelcome = false)),
                          HomeBannerCarousel(
                            controller: _bannerPageController,
                            currentPage: _currentBannerPage,
                            isDesktop: isDesktop,
                            hp: hp,
                            scrollController: _scrollController,
                            onPageChanged: (i) => setState(() => _currentBannerPage = i),
                          ),
                          HomeCategoryIconRow(
                            isDesktop: isDesktop,
                            hp: hp,
                            onCategoryTap: (i) => setState(() => _selectedCategoryIndex = i),
                          ),
                        ],
                      ),

                    // Deals
                    HomeDealsSection(isDesktop: isDesktop, hp: hp),

                    // Categories
                    HomeSectionTitle(title: 'Categories', onSeeAll: () => setState(() => _selectedCategoryId = null)),
                    HomeCategoryList(
                      future: _categoriesFuture,
                      selectedId: _selectedCategoryId,
                      onSelect: (id) => setState(() => _selectedCategoryId = id),
                      onRetry: _loadData,
                    ),

                    // Featured products
                    HomeSectionTitle(title: 'Featured Products', onSeeAll: () => _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 500), curve: Curves.easeInOut,
                    )),
                    HomeFeaturedProductsRow(future: _featuredProductsFuture, isDesktop: isDesktop, hp: hp),

                    // All products
                    HomeSectionTitle(title: 'All Products', onSeeAll: () => _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 500), curve: Curves.easeInOut,
                    )),
                    HomeProductGrid(
                      future: _allProductsFuture,
                      searchQuery: _searchController.text.trim(),
                      selectedCategoryId: _selectedCategoryId,
                      onRetry: _loadData,
                      onClearFilters: () {
                        _searchController.clear();
                        setState(() => _selectedCategoryId = null);
                      },
                    ),

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
}

