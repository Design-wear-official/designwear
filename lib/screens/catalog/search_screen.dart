import 'dart:async';

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../api/api_client.dart';
import '../../cms/cms_service.dart';
import '../../data/product_repository.dart';
import '../../models/product.dart';
import '../../theme/app_theme.dart' show AppThemeColors;
import '../home/home_screen.dart' show formatPrice;
import 'product_detail_screen.dart';
import 'product_image.dart';

/// Searches the loaded catalog. The CMS has no full-text search for Firestore,
/// so products are fetched once and filtered on the device.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.repository, this.initialQuery = ''});
  final ProductRepository? repository;
  final String initialQuery;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  Future<List<Product>>? _all;
  ApiClient? _api;
  List<Product>? _remote;
  bool _searching = false;
  String _query = '';
  bool _inStockOnly = false;
  String _sort = 'relevance';

  @override
  void initState() {
    super.initState();
    final cms = CmsService.instance;
    final repo =
        widget.repository ??
        ProductRepository.resolve(api: context.read<ApiClient?>(), cms: cms);
    _all = repo?.list(limit: 200);
    _controller.text = widget.initialQuery;
    _query = widget.initialQuery;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _api ??= context.read<ApiClient?>();
  }

  /// Ranked search on the server (title, tags, type, description). Falls back
  /// to the on-device filter if the server can't be reached.
  Future<void> _runRemote() async {
    final api = _api;
    if (api == null) return;
    setState(() => _searching = true);
    try {
      final j = await api.get(
        '/v1/search',
        query: {'q': _query, if (_inStockOnly) 'inStock': '1'},
      );
      final results = [
        for (final r in (j['results'] as List))
          if (Product.fromRecord((r as Map).cast()) case final p
              when p.isListable)
            p,
      ];
      if (mounted) setState(() => _remote = results);
    } on ApiException catch (_) {
      if (mounted) setState(() => _remote = null);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  List<Product> _filter(List<Product> all) {
    final q = _query.toLowerCase();
    var out = all.where((p) {
      if (_inStockOnly && !p.isInStock) return false;
      if (q.isEmpty) return true;
      return p.title.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q) ||
          p.tags.any((t) => t.toLowerCase().contains(q)) ||
          (p.productType ?? '').toLowerCase().contains(q);
    }).toList();
    switch (_sort) {
      case 'low':
        out.sort((a, b) => a.price.compareTo(b.price));
      case 'high':
        out.sort((a, b) => b.price.compareTo(a.price));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search products',
            border: InputBorder.none,
          ),
          onChanged: (v) {
            _debounce?.cancel();
            _debounce = Timer(const Duration(milliseconds: 250), () {
              if (!mounted) return;
              setState(() => _query = v.trim());
              _runRemote();
            });
          },
        ),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('In stock'),
                  selected: _inStockOnly,
                  onSelected: (v) {
                    setState(() => _inStockOnly = v);
                    _runRemote();
                  },
                ),
                const SizedBox(width: 8),
                for (final (id, label) in [
                  ('relevance', 'Relevance'),
                  ('low', 'Price ↑'),
                  ('high', 'Price ↓'),
                ]) ...[
                  ChoiceChip(
                    label: Text(label),
                    selected: _sort == id,
                    onSelected: (_) => setState(() => _sort = id),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          Expanded(
            child: _remote != null
                ? _results(_sortRemote(_remote!))
                : _all == null
                ? const Center(child: Text('Catalog not connected'))
                : FutureBuilder<List<Product>>(
                    future: _all,
                    builder: (context, s) {
                      if (s.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (s.hasError) {
                        return const Center(
                          child: Text("Couldn't load products"),
                        );
                      }
                      return _results(_filter(s.data!));
                    },
                  ),
          ),
        ],
      ),
    );
  }

  List<Product> _sortRemote(List<Product> list) {
    final out = [...list];
    switch (_sort) {
      case 'low':
        out.sort((a, b) => a.price.compareTo(b.price));
      case 'high':
        out.sort((a, b) => b.price.compareTo(a.price));
    }
    return out;
  }

  Widget _results(List<Product> results) {
    if (_searching && results.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (results.isEmpty) return const Center(child: Text('No matches'));
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (_, i) {
        final p = results[i];
        return ListTile(
          leading: SizedBox(
            width: 56,
            height: 56,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ProductImage(url: p.displayImageUrl),
            ),
          ),
          title: Text(p.title),
          subtitle: Text(p.isInStock ? 'In stock' : 'Out of stock'),
          trailing: Text(
            formatPrice(p.price),
            style: TextStyle(
              color: context.accent,
              fontWeight: FontWeight.w700,
            ),
          ),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p)),
          ),
        );
      },
    );
  }
}
