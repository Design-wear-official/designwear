import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../api/api_client.dart';
import '../../../models/design.dart';
import '../../../services/community/community_service.dart';
import 'design_detail_screen.dart';
import '../library/saved_designs_screen.dart';
import '../editor/design_studio_screen.dart';
import '../shared/design_preview.dart';

/// The Studio tab: community designs to browse and remix, plus your own.
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});
  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  bool _popular = false;
  Future<List<CommunityDesign>>? _feed;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final service = context.read<CommunityService?>();
    _feed = service?.feed(popular: _popular);
  }

  void _openStudio() =>
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const DesignStudioScreen()));

  @override
  Widget build(BuildContext context) {
    final service = context.read<CommunityService?>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Studio'),
        actions: [
          IconButton(
            tooltip: 'My designs',
            icon: const Icon(Icons.folder_open_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SavedDesignsScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openStudio,
        icon: const Icon(Icons.brush),
        label: const Text('New design'),
      ),
      body: service == null
          ? _Offline(onCreate: _openStudio)
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('Recent')),
                      ButtonSegment(value: true, label: Text('Popular')),
                    ],
                    selected: {_popular},
                    onSelectionChanged: (s) => setState(() {
                      _popular = s.first;
                      _load();
                    }),
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<CommunityDesign>>(
                    future: _feed,
                    builder: (context, snap) {
                      if (snap.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snap.hasError) {
                        final msg = snap.error is ApiException
                            ? '${snap.error}'
                            : "Couldn't load designs";
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(msg),
                              TextButton(
                                onPressed: () => setState(_load),
                                child: const Text('Try again'),
                              ),
                            ],
                          ),
                        );
                      }
                      final designs = snap.data!;
                      if (designs.isEmpty) {
                        return const Center(
                          child: Text(
                            'No community designs yet. Publish the first one!',
                          ),
                        );
                      }
                      return RefreshIndicator(
                        onRefresh: () async {
                          setState(_load);
                          await _feed;
                        },
                        child: GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 260,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.82,
                              ),
                          itemCount: designs.length,
                          itemBuilder: (_, i) =>
                              _DesignCard(design: designs[i]),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _DesignCard extends StatelessWidget {
  const _DesignCard({required this.design});
  final CommunityDesign design;

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => DesignDetailScreen(design: design)),
      ),
      child: Column(
        children: [
          Expanded(
            child: DesignPreview(
              base64Png: design.previewImage,
              baseColor: design.designJson?['baseColor'] as String?,
            ),
          ),
          ListTile(
            dense: true,
            title: Text(
              design.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text('@${design.creatorHandle}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  design.liked ? Icons.favorite : Icons.favorite_border,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text('${design.likeCount}'),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _Offline extends StatelessWidget {
  const _Offline({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.groups_outlined, size: 48),
          const SizedBox(height: 12),
          const Text('The community needs the DesignWear API.'),
          const SizedBox(height: 4),
          const Text(
            'Set DESIGNWEAR_API_URL in .env. You can still design and save locally.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onCreate,
            child: const Text('Open the studio'),
          ),
        ],
      ),
    ),
  );
}
