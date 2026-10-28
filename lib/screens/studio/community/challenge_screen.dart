import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../api/api_client.dart';
import '../../../models/challenge.dart';
import '../../../models/design.dart';
import '../../../presentation/styles/styles.dart';
import '../../../services/community/community_service.dart';
import 'design_detail_screen.dart';
import '../shared/design_preview.dart';
import '../editor/design_studio_screen.dart';

/// A weekly challenge: what it is, how long is left, a button to join, and the
/// entries so far, most liked first.
class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key, required this.challenge});
  final Challenge challenge;

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  late Challenge _challenge = widget.challenge;
  Future<(Challenge, List<CommunityDesign>)>? _entries;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _entries = context
        .read<CommunityService?>()
        ?.challengeEntries(widget.challenge.id)
        .then((r) {
          if (mounted) setState(() => _challenge = r.$1);
          return r;
        });
  }

  void _join() => Navigator.of(context)
      .push(
        MaterialPageRoute(
          builder: (_) => DesignStudioScreen(challenge: _challenge),
        ),
      )
      .then((_) {
        if (mounted) setState(_load);
      });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = _challenge;
    return Scaffold(
      appBar: AppBar(title: const Text('Weekly challenge')),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(_load);
          await _entries;
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF202436) : AppColors.inkLight,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.title,
                    style: GoogleFonts.archivo(
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                      height: 1.1,
                      color: Colors.white,
                    ),
                  ),
                  if (c.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      c.description,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        height: 1.4,
                        color: const Color(0xFFAAB0CF),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Text(
                    c.summary(DateTime.now()),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: AppColors.marigold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (c.open)
                    ElevatedButton.icon(
                      onPressed: _join,
                      icon: const Icon(
                        Icons.fork_right,
                        color: AppColors.marigoldInk,
                      ),
                      label: Text(
                        'Join & remix',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          color: AppColors.marigoldInk,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.marigold,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 14,
                        ),
                        shape: const StadiumBorder(),
                      ),
                    )
                  else
                    const Text(
                      'This challenge has ended.',
                      style: TextStyle(color: Colors.white70),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'LEADERBOARD',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 1.2),
            ),
            const SizedBox(height: 12),
            FutureBuilder<(Challenge, List<CommunityDesign>)>(
              future: _entries,
              builder: (context, snap) {
                if (_entries == null) {
                  return const Text(
                    'Entries need the DesignWear API (set DESIGNWEAR_API_URL).',
                  );
                }
                if (snap.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snap.hasError) {
                  return Text(
                    snap.error is ApiException
                        ? '${snap.error}'
                        : "Couldn't load entries.",
                  );
                }
                final designs = snap.data!.$2;
                if (designs.isEmpty) {
                  return const Text('No entries yet. Be the first!');
                }
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 240,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: designs.length,
                  itemBuilder: (_, i) {
                    final d = designs[i];
                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DesignDetailScreen(design: d),
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.cardDark
                              : AppColors.cardLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? AppColors.hairDark
                                : AppColors.hairLight,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            Expanded(
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  DesignPreview(
                                    base64Png: d.previewImage,
                                    baseColor:
                                        d.designJson?['baseColor'] as String?,
                                  ),
                                  Positioned(
                                    top: 8,
                                    left: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: i == 0
                                            ? AppColors.goldGradient
                                            : null,
                                        color: i == 0 ? null : Colors.black54,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '#${i + 1}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 11,
                                          color: i == 0
                                              ? AppColors.marigoldInk
                                              : Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ListTile(
                              dense: true,
                              title: Text(
                                d.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text('@${d.creatorHandle}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    d.liked
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    size: 15,
                                  ),
                                  const SizedBox(width: 3),
                                  Text('${d.likeCount}'),
                                ],
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
          ],
        ),
      ),
    );
  }
}
