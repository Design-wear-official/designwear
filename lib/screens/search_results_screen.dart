import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:designwear/models/models.dart';
import 'package:designwear/domain/usecases/product_use_cases.dart';
import 'package:designwear/presentation/styles/styles.dart';
import 'package:designwear/presentation/widgets/widgets.dart';
import 'product_detail_screen.dart';

enum _SortOption { relevance, priceLowHigh, priceHighLow, newest }

enum _AvailabilityFilter { all, inStock, outOfStock }

class SearchResultsScreen extends StatefulWidget {
  final String initialQuery;

  const SearchResultsScreen({super.key, required this.initialQuery});

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;
  bool _searchFocused = false;
  Timer? _debounce;
  String _liveQuery = '';

  late Future<List<Product>> _productsFuture;
  late GetProductsUseCase _getProductsUseCase;

  _SortOption _sortOption = _SortOption.relevance;
  _AvailabilityFilter _availabilityFilter = _AvailabilityFilter.all;
  double? _maxPrice;

  @override
  void initState() {
    super.initState();
    _liveQuery = widget.initialQuery;
    _searchController = TextEditingController(text: widget.initialQuery);
    _searchFocusNode = FocusNode()
      ..addListener(() => setState(() => _searchFocused = _searchFocusNode.hasFocus));
    _getProductsUseCase = Provider.of<GetProductsUseCase>(context, listen: false);
    _productsFuture = _getProductsUseCase();
    // Auto-focus the field so keyboard is ready
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => _searchFocusNode.requestFocus());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _doSearch() {
    _debounce?.cancel();
    _searchFocusNode.unfocus();
    setState(() => _liveQuery = _searchController.text.trim());
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _liveQuery = value.trim());
    });
  }

  List<Product> _applyFilters(List<Product> all) {
    final q = _liveQuery.toLowerCase();

    var results = all.where((p) {
      // Search match
      final matchesQuery = q.isEmpty ||
          p.title.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q);

      // Availability filter
      final matchesAvail = _availabilityFilter == _AvailabilityFilter.all ||
          (_availabilityFilter == _AvailabilityFilter.inStock &&
              p.stockStatus == 'inStock') ||
          (_availabilityFilter == _AvailabilityFilter.outOfStock &&
              p.stockStatus == 'outOfStock');

      // Price filter
      final matchesPrice = _maxPrice == null || p.price <= _maxPrice!;

      return matchesQuery && matchesAvail && matchesPrice;
    }).toList();

    // Sort
    switch (_sortOption) {
      case _SortOption.priceLowHigh:
        results.sort((a, b) => a.price.compareTo(b.price));
        break;
      case _SortOption.priceHighLow:
        results.sort((a, b) => b.price.compareTo(a.price));
        break;
      case _SortOption.newest:
        results = results.reversed.toList();
        break;
      case _SortOption.relevance:
        break;
    }

    return results;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final hp = ResponsiveSizes.horizontalPadding(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top bar with search input ──────────────────────────────
            _buildTopBar(isDark, isDesktop, hp),
            const Divider(height: 1),

            // ── Results body ──────────────────────────────────────────
            Expanded(
              child: FutureBuilder<List<Product>>(
                future: _productsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return _buildError();
                  }

                  final filtered = _applyFilters(snapshot.data!);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFilterBar(isDark, isDesktop, hp, snapshot.data!, filtered.length),
                      Expanded(child: _buildResultsGrid(filtered, isDark, isDesktop, hp)),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // TOP BAR
  // ────────────────────────────────────────────────────────────────────────────

  Widget _buildTopBar(bool isDark, bool isDesktop, double hp) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hp, vertical: 12),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 38,
              height: 38,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.arrow_back_rounded,
                  size: 20, color: Theme.of(context).colorScheme.onSurface),
            ),
          ),

          // Search input – matches home bar style
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF1F3F6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _searchFocused
                      ? AppColors.accentBlue
                      : (isDark
                          ? Colors.white.withOpacity(0.08)
                          : Colors.black.withOpacity(0.08)),
                  width: _searchFocused ? 1.8 : 1.2,
                ),
                boxShadow: _searchFocused
                    ? [
                        BoxShadow(
                          color: AppColors.accentBlue.withOpacity(0.18),
                          blurRadius: 16,
                          spreadRadius: 1,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 14, right: 8),
                    child: Icon(Icons.search_rounded,
                        size: 20,
                        color: _searchFocused
                            ? AppColors.accentBlue
                            : (isDark
                                ? const Color(0xFF9AA0A6)
                                : const Color(0xFF9E9E9E))),
                  ),
                  Expanded(
                    child: TextField(
                      focusNode: _searchFocusNode,
                      controller: _searchController,
                      style: GoogleFonts.outfit(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black87,
                        height: 1.2,
                      ),
                      textAlignVertical: TextAlignVertical.center,
                      textInputAction: TextInputAction.search,
                      cursorColor: AppColors.accentBlue,
                      cursorWidth: 2,
                      cursorHeight: 18,
                      decoration: InputDecoration(
                        hintText: 'Search products, designs…',
                        hintStyle: GoogleFonts.outfit(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w400,
                          color: isDark
                              ? const Color(0xFF6B7280)
                              : const Color(0xFF9CA3AF),
                          height: 1.2,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.only(bottom: 1),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _doSearch(),
                      onChanged: _onSearchChanged,
                    ),
                  ),
                  // Clear button
                  if (_searchController.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.15)
                                : Colors.black.withOpacity(0.10),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.close_rounded,
                              size: 13,
                              color: isDark ? Colors.white70 : Colors.black54),
                        ),
                      ),
                    ),
                  // Search button
                  Padding(
                    padding: const EdgeInsets.only(right: 5),
                    child: GestureDetector(
                      onTap: _doSearch,
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        decoration: BoxDecoration(
                          gradient: AppColors.neonGradient,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accentBlue.withOpacity(0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Search',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // FILTER + SORT BAR
  // ────────────────────────────────────────────────────────────────────────────

  Widget _buildFilterBar(bool isDark, bool isDesktop, double hp,
      List<Product> all, int resultCount) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: hp, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.07),
          ),
        ),
      ),
      child: Row(
        children: [
          // "Filter:" label
          Text(
            'Filter:',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: onSurface.withOpacity(0.55),
            ),
          ),
          const SizedBox(width: 10),

          // Availability dropdown
          _buildDropdown<_AvailabilityFilter>(
            isDark: isDark,
            label: _availabilityFilter == _AvailabilityFilter.all
                ? 'Availability'
                : _availabilityFilter == _AvailabilityFilter.inStock
                    ? 'In Stock'
                    : 'Out of Stock',
            items: const [
              DropdownMenuItem(value: _AvailabilityFilter.all, child: Text('All')),
              DropdownMenuItem(value: _AvailabilityFilter.inStock, child: Text('In Stock')),
              DropdownMenuItem(
                  value: _AvailabilityFilter.outOfStock, child: Text('Out of Stock')),
            ],
            value: _availabilityFilter,
            onChanged: (v) => setState(() => _availabilityFilter = v!),
          ),
          const SizedBox(width: 8),

          // Price dropdown
          _buildDropdown<String>(
            isDark: isDark,
            label: _maxPrice == null
                ? 'Price'
                : 'Under ₹${_maxPrice!.toStringAsFixed(0)}',
            items: [
              const DropdownMenuItem(value: 'all', child: Text('All Prices')),
              DropdownMenuItem(value: '500', child: Text('Under ₹500')),
              DropdownMenuItem(value: '1000', child: Text('Under ₹1,000')),
              DropdownMenuItem(value: '2000', child: Text('Under ₹2,000')),
              DropdownMenuItem(value: '5000', child: Text('Under ₹5,000')),
            ],
            value: _maxPrice == null ? 'all' : _maxPrice!.toStringAsFixed(0),
            onChanged: (v) => setState(() {
              _maxPrice = v == 'all' ? null : double.tryParse(v!);
            }),
          ),

          const Spacer(),

          // Sort by
          Text(
            'Sort by:',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: onSurface.withOpacity(0.55),
            ),
          ),
          const SizedBox(width: 8),
          _buildDropdown<_SortOption>(
            isDark: isDark,
            label: _sortLabel(_sortOption),
            items: const [
              DropdownMenuItem(value: _SortOption.relevance, child: Text('Relevance')),
              DropdownMenuItem(value: _SortOption.priceLowHigh, child: Text('Price: Low → High')),
              DropdownMenuItem(value: _SortOption.priceHighLow, child: Text('Price: High → Low')),
              DropdownMenuItem(value: _SortOption.newest, child: Text('Newest')),
            ],
            value: _sortOption,
            onChanged: (v) => setState(() => _sortOption = v!),
          ),
          const SizedBox(width: 16),

          // Result count
          Text(
            '$resultCount result${resultCount == 1 ? '' : 's'}',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: onSurface.withOpacity(0.45),
            ),
          ),
        ],
      ),
    );
  }

  String _sortLabel(_SortOption o) {
    switch (o) {
      case _SortOption.relevance:    return 'Relevance';
      case _SortOption.priceLowHigh: return 'Price: Low → High';
      case _SortOption.priceHighLow: return 'Price: High → Low';
      case _SortOption.newest:       return 'Newest';
    }
  }

  Widget _buildDropdown<T>({
    required bool isDark,
    required String label,
    required List<DropdownMenuItem<T>> items,
    required T value,
    required ValueChanged<T?> onChanged,
  }) {
    return GestureDetector(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.07) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.12),
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            isDense: true,
            icon: Icon(Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: isDark ? Colors.white54 : Colors.black45),
            dropdownColor: isDark ? const Color(0xFF2A2A35) : Colors.white,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
            items: items,
            onChanged: onChanged,
            // Show the label text instead of the actual selected value text
            selectedItemBuilder: (_) => items
                .map((_) => Align(
                      alignment: Alignment.centerLeft,
                      child: Text(label,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          )),
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // RESULTS GRID
  // ────────────────────────────────────────────────────────────────────────────

  Widget _buildResultsGrid(
      List<Product> products, bool isDark, bool isDesktop, double hp) {
    if (products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded,
                  size: 56,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.25)),
              const SizedBox(height: 16),
              Text(
                'No results for\n"${_searchController.text}"',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try different keywords or clear filters.',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.35),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final availW = constraints.maxWidth - hp * 2;
        final cols = (availW / 200).floor().clamp(2, 5);
        const spacing = 14.0;
        final cardW = (availW - spacing * (cols - 1)) / cols;
        final cardH = cardW * 1.6;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(hp, 16, hp, 80),
          child: Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: products.map((product) {
              final heroTag = 'search_${product.id}';
              return GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ProductDetailScreen(product: product, heroTag: heroTag),
                  settings: RouteSettings(name: '/product/${product.slug}'),
                )),
                child: SizedBox(
                  width: cardW,
                  height: cardH,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Theme.of(context).colorScheme.surface
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.black.withOpacity(0.08),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          // Product image
                          Positioned.fill(
                            child: Hero(
                              tag: heroTag,
                              child: Container(
                                color: AppColors.backgroundLight,
                                child: product.imageUrl != null
                                    ? SafeNetworkImage(
                                        imageUrl: product.imageUrl!,
                                        fit: BoxFit.cover,
                                      )
                                    : Icon(Icons.image_not_supported,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.3),
                                        size: 36),
                              ),
                            ),
                          ),
                          // Out of stock overlay
                          if (product.stockStatus == 'outOfStock')
                            Positioned.fill(
                              child: Container(
                                color: Colors.black.withOpacity(0.45),
                                alignment: Alignment.center,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.black87,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text('Out of Stock',
                                      style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ),
                          // Bottom info overlay
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
                                    Colors.black.withOpacity(0.88),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                              padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    product.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₹${product.price.toStringAsFixed(0)}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.accentBlue,
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
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off, color: Colors.orange, size: 48),
          const SizedBox(height: 12),
          Text('Could not load results',
              style: GoogleFonts.outfit(
                  fontSize: 16, fontWeight: FontWeight.w700, color: Colors.orange)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() {
              _productsFuture = _getProductsUseCase();
            }),
            child: Text('Tap to retry',
                style: GoogleFonts.outfit(
                    fontSize: 13, color: AppColors.accentBlue, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

