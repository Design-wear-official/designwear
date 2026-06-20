import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:designwear/models/models.dart';
import 'package:designwear/services/services.dart';
import 'package:designwear/domain/usecases/product_use_cases.dart';
import 'package:designwear/presentation/styles/styles.dart';
import 'package:designwear/screens/home/home.dart';
import 'package:designwear/screens/design_studio_screen.dart';
import 'search_results_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ── Services ──────────────────────────────────────────────────────────────
  late GetFeaturedProductsUseCase _getFeaturedProductsUseCase;
  late GetProductsUseCase _getProductsUseCase;

  // ── Futures ───────────────────────────────────────────────────────────────
  late Future<List<Product>> _featuredProductsFuture;
  late Future<List<Product>> _allProductsFuture;

  // ── State ─────────────────────────────────────────────────────────────────
  String? _selectedCategoryId;

  // ── Layout + theme ────────────────────────────────────────────────────────
  FeedLayout _feedLayout = FeedLayout.grid;

  // ── Controllers ───────────────────────────────────────────────────────────
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  bool _searchFocused = false;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _getFeaturedProductsUseCase = Provider.of<GetFeaturedProductsUseCase>(context, listen: false);
    _getProductsUseCase = Provider.of<GetProductsUseCase>(context, listen: false);

    _featuredProductsFuture = _getFeaturedProductsUseCase();
    _allProductsFuture = _getProductsUseCase();

    _searchFocusNode.addListener(() {
      setState(() => _searchFocused = _searchFocusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────



  void _goToSearch() {
    _searchFocusNode.unfocus();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => SearchResultsScreen(initialQuery: _searchController.text.trim()),
    ));
  }

  void _loadData() {
    setState(() {
      _featuredProductsFuture = _getFeaturedProductsUseCase();
      _allProductsFuture = _getProductsUseCase();
    });
  }

  void _openSettings() {
    final tp = context.read<ThemeProvider>();
    HomeSettingsSheet.show(
      context,
      isDarkMode: tp.isDarkMode,
      isDetailLayout: _feedLayout == FeedLayout.detail,
      onThemeChanged: (isDark) => tp.toggleTheme(isDark),
      onLayoutChanged: (isDetail) {
        setState(() => _feedLayout = isDetail ? FeedLayout.detail : FeedLayout.grid);
      },
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final hp = ResponsiveSizes.horizontalPadding(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Sticky top bar
          HomeAppBar(
            isDesktop: isDesktop,
            hp: hp,
            searchFocused: _searchFocused,
            searchController: _searchController,
            searchFocusNode: _searchFocusNode,
            onSearch: _goToSearch,
            onOpenSettings: _openSettings,
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

                    // Weekly challenge banner
                    HomeChallengeBanner(
                      isDesktop: isDesktop,
                      hp: hp,
                      onRemix: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const DesignStudioScreen(),
                        settings: const RouteSettings(name: '/design-studio'),
                      )),
                    ),

                    const SizedBox(height: 20),

                    // Featured products
                    HomeSectionTitle(
                      title: 'Featured Products',
                      onSeeAll: () => _scrollController.animateTo(
                        _scrollController.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      ),
                    ),
                    HomeFeaturedProductsRow(
                      future: _featuredProductsFuture,
                      isDesktop: isDesktop,
                      hp: hp,
                    ),

                    // All products
                    HomeSectionTitle(
                      title: 'All Products',
                      onSeeAll: () => _scrollController.animateTo(
                        _scrollController.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      ),
                    ),
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
