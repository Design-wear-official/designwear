import 'package:flutter/material.dart';

import '../../../models/models.dart';
import '../../../presentation/styles/styles.dart';
import '../../../services/studio/design_storage_service.dart';
import '../shared/design_preview.dart';
import '../editor/design_studio_screen.dart';

/// Designs saved from the Design Studio (kept on this device).
class SavedDesignsScreen extends StatefulWidget {
  const SavedDesignsScreen({super.key});

  @override
  State<SavedDesignsScreen> createState() => _SavedDesignsScreenState();
}

class _SavedDesignsScreenState extends State<SavedDesignsScreen> {
  final _storage = DesignStorageService();
  late Future<List<SavedDesign>> _designs = _storage.getSavedDesigns();

  void _reload() => setState(() => _designs = _storage.getSavedDesigns());

  Future<void> _open([CustomDesign? design]) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DesignStudioScreen(initialDesign: design),
      ),
    );
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('Saved designs')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _open,
        backgroundColor: AppColors.marigold,
        foregroundColor: AppColors.marigoldInk,
        icon: const Icon(Icons.add),
        label: const Text('New design'),
      ),
      body: FutureBuilder<List<SavedDesign>>(
        future: _designs,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final designs = snap.data ?? const <SavedDesign>[];
          if (designs.isEmpty) {
            return const Center(child: Text('No saved designs yet'));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 260,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.85,
            ),
            itemCount: designs.length,
            itemBuilder: (_, i) {
              final d = designs[i];
              return Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.cardLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.hairDark : AppColors.hairLight,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _open(d.design),
                  child: Column(
                    children: [
                      Expanded(
                        child: DesignPreview(baseColor: d.design.baseColor),
                      ),
                      ListTile(
                        dense: true,
                        title: Text(d.name, overflow: TextOverflow.ellipsis),
                        subtitle: Text(d.design.productType),
                        trailing: IconButton(
                          tooltip: 'Delete',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            await _storage.deleteDesign(d.id);
                            _reload();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
