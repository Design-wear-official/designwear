import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../api/api_client.dart';
import '../../cms/cms_service.dart';
import '../../data/product_repository.dart';
import '../../models/challenge.dart';
import '../../models/product.dart';
import '../../presentation/styles/styles.dart';
import '../../theme/app_theme.dart' show AppThemeColors;
import '../../services/community/community_service.dart';
import 'home_app_bar.dart';
import 'home_challenge_banner.dart';
import 'home_menu.dart';
import 'home_sections.dart';
import '../catalog/search_screen.dart';
import '../studio/community/challenge_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.repository});

  /// Injectable for tests; defaults to the app-wide CMS connection.
  final ProductRepository? repository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ProductRepository? _repo;
  late Future<List<Product>> _products;
  Future<Challenge?>? _challenge;
  final _scroll = ScrollController();
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  bool _searchFocused = false;
  final _allKey = GlobalKey();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    final cms = CmsService.instance;
    _repo =
        widget.repository ??
        ProductRepository.resolve(api: context.read<ApiClient?>(), cms: cms);
    _load();
    _challenge = context
        .read<CommunityService?>()
        ?.currentChallenge()
        .then<Challenge?>((c) => c)
        .catchError((_) => null);
    _searchFocus.addListener(
      () => setState(() => _searchFocused = _searchFocus.hasFocus),
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _load() {
    final repo = _repo;
    _products = repo == null
        ? Future.error(StateError('not-configured'))
        : repo.list().then((items) {
            if (mounted) {
              setState(
                () => _suggestionPool = [
                  for (final p in items) ...[
                    p.title,
                    if ((p.productType ?? '').isNotEmpty) p.productType!,
                    ...p.tags,
                  ],
                ],
              );
            }
            return items;
          });
  }

  /// Titles, product types and tags from the loaded catalog, for the search
  /// field's suggestions. Empty until products have loaded.
  List<String> _suggestionPool = const [];

  void _retry() => setState(_load);

  void _goToSearch() {
    _searchFocus.unfocus();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            SearchScreen(initialQuery: _searchController.text.trim()),
      ),
    );
  }

  /// Ctrl+K or Cmd+K: jump to the search field from anywhere on the page.
  void _focusSearch() {
    _scroll.hasClients ? _scroll.jumpTo(0) : null;
    _searchFocus.requestFocus();
  }

  void _scrollToAll() {
    final ctx = _allKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final hp = ResponsiveSizes.horizontalPadding(context);

    // `Focus` gives the page keyboard focus on arrival, so the shortcut works
    // before anything has been clicked.
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, control: true):
            _focusSearch,
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true):
            _focusSearch,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          key: _scaffoldKey,
          drawer: HomeMenuDrawer(onSearch: _goToSearch),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Column(
            children: [
              HomeAppBar(
                isDesktop: isDesktop,
                hp: hp,
                searchFocused: _searchFocused,
                searchController: _searchController,
                searchFocusNode: _searchFocus,
                onSearch: _goToSearch,
                onMenu: () => _scaffoldKey.currentState?.openDrawer(),
                suggestionPool: _suggestionPool,
              ),
              Expanded(
                child: FutureBuilder<List<Product>>(
                  future: _products,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      final notConfigured =
                          snapshot.error is StateError &&
                          '${snapshot.error}'.contains('not-configured');
                      return _Message(
                        icon: notConfigured
                            ? Icons.settings_outlined
                            : Icons.cloud_off,
                        title: notConfigured
                            ? 'Catalog not connected'
                            : "Couldn't load products",
                        body: notConfigured
                            ? 'Set DESIGNWEAR_API_URL in .env (the address of '
                                  'the DesignWear API) and rebuild.'
                            : 'Check your connection and try again.',
                        onRetry: notConfigured ? null : _retry,
                      );
                    }
                    final products = snapshot.data!;
                    if (products.isEmpty) {
                      return const _Message(
                        icon: Icons.checkroom_outlined,
                        title: 'No products yet',
                        body: 'Published products will show up here.',
                      );
                    }
                    final featured = products.where((p) => p.featured).toList();
                    return RefreshIndicator(
                      onRefresh: () async {
                        _retry();
                        await _products;
                      },
                      child: SingleChildScrollView(
                        controller: _scroll,
                        physics: const AlwaysScrollableScrollPhysics(),
                        // Content stops at 1440px and sits in the middle on wide
                        // screens, matching the bar above it.
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1440),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // The running weekly challenge, if there is one. Hidden when
                                // the API is off or no challenge is open.
                                FutureBuilder<Challenge?>(
                                  future: _challenge,
                                  builder: (context, snap) {
                                    final challenge = snap.data;
                                    if (challenge == null) {
                                      return const SizedBox.shrink();
                                    }
                                    return HomeChallengeBanner(
                                      challenge: challenge,
                                      isDesktop: isDesktop,
                                      hp: hp,
                                      onRemix: () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => ChallengeScreen(
                                            challenge: challenge,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 20),
                                // Only worth a row of its own when it picks some products
                                // out; if every product is featured it would just repeat
                                // the list below.
                                if (featured.isNotEmpty &&
                                    featured.length < products.length) ...[
                                  HomeSectionTitle(
                                    title: 'Featured Products',
                                    onSeeAll: _scrollToAll,
                                  ),
                                  HomeFeaturedProductsRow(
                                    future: Future.value(featured),
                                    isDesktop: isDesktop,
                                    hp: hp,
                                  ),
                                ],
                                HomeSectionTitle(
                                  key: _allKey,
                                  title: 'All Products',
                                  onSeeAll: _scrollToAll,
                                ),
                                HomeProductGrid(
                                  future: Future.value(products),
                                  searchQuery: '',
                                  selectedCategoryId: null,
                                  onRetry: _retry,
                                  onClearFilters: _retry,
                                ),
                                const SizedBox(height: 32),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.body,
    this.onRetry,
  });
  final IconData icon;
  final String title;
  final String body;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: context.muted),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.muted),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ],
      ),
    ),
  );
}

String formatPrice(double value) =>
    '₹${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2)}';
