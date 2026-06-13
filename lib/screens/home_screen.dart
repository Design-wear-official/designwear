import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:designwear/models/models.dart';
import 'package:designwear/config/config.dart';
import 'package:designwear/services/services.dart';
import 'package:designwear/domain/usecases/product_use_cases.dart';
import 'package:designwear/presentation/utils/responsive_utils.dart';
import 'package:designwear/screens/home/home.dart';
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
  late final ApiService _apiService;

  // ── Futures ───────────────────────────────────────────────────────────────
  late Future<List<Category>> _categoriesFuture;
  late Future<List<Product>> _featuredProductsFuture;
  late Future<List<Product>> _allProductsFuture;
  late Future<List<Deal>> _dealsFuture;

  // ── State ─────────────────────────────────────────────────────────────────
  List<HomeBanner> _banners = HomeBanner.fallbacks;
  List<CategoryQuickLink> _quickLinks = const [];
  int _currentBannerPage = 0;
  int _selectedCategoryIndex = 0;
  String? _selectedCategoryId;

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
    _apiService = WebApiConfig.useWebApi
        ? ApiService.webApi(WebApiConfig.baseUrl)
        : ApiService.sanity();

    _categoriesFuture = _getCategoriesUseCase();
    _featuredProductsFuture = _getFeaturedProductsUseCase();
    _allProductsFuture = _getProductsUseCase();
    _dealsFuture = _apiService.fetchDeals();
    _loadBanners();
    _loadQuickLinks();

    _searchFocusNode.addListener(() {
      setState(() => _searchFocused = _searchFocusNode.hasFocus);
    });
    _startBannerAutoScroll();
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

  Future<void> _loadBanners() async {
    final banners = await _apiService.fetchBanners();
    if (mounted) setState(() => _banners = banners);
  }

  Future<void> _loadQuickLinks() async {
    final links = await _apiService.fetchCategoryQuickLinks();
    if (mounted && links.isNotEmpty) setState(() => _quickLinks = links);
  }

  void _startBannerAutoScroll() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _bannerPageController.hasClients && _banners.isNotEmpty) {
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
      _dealsFuture = _apiService.fetchDeals();
    });
    _loadBanners();
  }

  void _onNavTabTap(int i) {
    if (HomeConstants.navTabs[i] == 'Design Studio') {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DesignStudioScreen(), settings: const RouteSettings(name: '/design-studio')));
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
      bottomNavigationBar: null,
      body: Column(
        children: [
          // Internal-flavor debug strip (zero height for external builds)
          const HomeDebugBanner(),

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
                                  banners: _banners,
                                ),
                                HomeCategoryIconRow(
                                  isDesktop: isDesktop,
                                  hp: hp,
                                  onCategoryTap: (i) => setState(() => _selectedCategoryIndex = i),
                                  quickLinks: _quickLinks,
                                ),
                              ],
                            ),
                          ),
                          Builder(
                            builder: (ctx) {
                              final sw = MediaQuery.sizeOf(ctx).width;
                              final sidebarW = (sw * 0.32).clamp(280.0, 420.0);
                              return SizedBox(
                                width: sidebarW,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const HomeDesignStudioBanner(),
                                      const HomeTrendingSection(),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          HomeBannerCarousel(
                            controller: _bannerPageController,
                            currentPage: _currentBannerPage,
                            isDesktop: isDesktop,
                            hp: hp,
                            scrollController: _scrollController,
                            onPageChanged: (i) => setState(() => _currentBannerPage = i),
                            banners: _banners,
                          ),
                          HomeCategoryIconRow(
                            isDesktop: isDesktop,
                            hp: hp,
                            onCategoryTap: (i) => setState(() => _selectedCategoryIndex = i),
                          ),
                        ],
                      ),

                    // Deals
                    HomeDealsSection(isDesktop: isDesktop, hp: hp, dealsFuture: _dealsFuture),

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

