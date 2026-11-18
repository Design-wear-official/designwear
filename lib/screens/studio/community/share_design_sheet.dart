import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../api/api_client.dart';
import '../../../models/design.dart';
import '../../../services/community/community_service.dart';
import 'share_links.dart';

/// Who can open one of my designs: only me, the people I pick, anyone with a private link, or everyone (public).
/// Both links open the design: one on its detail page, one in the virtual try-on.
Future<void> showShareDesignSheet(
  BuildContext context, {
  required String designId,
  required String designName,
  VoidCallback? onChanged,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _ShareSheet(
    designId: designId,
    designName: designName,
    onChanged: onChanged,
  ),
);

class _ShareSheet extends StatefulWidget {
  const _ShareSheet({
    required this.designId,
    required this.designName,
    this.onChanged,
  });
  final String designId, designName;
  final VoidCallback? onChanged;

  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet> {
  DesignSharing? _s;
  String? _error;
  String? _note;
  bool _busy = false;
  final _email = TextEditingController();

  CommunityService get _service => context.read<CommunityService?>()!;

  @override
  void initState() {
    super.initState();
    _run(() => _service.sharing(widget.designId));
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _run(Future<DesignSharing> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
      _note = null;
    });
    try {
      final next = await action();
      if (!mounted) return;
      setState(() {
        _s = next;
        if (next.notFound.isNotEmpty) {
          _note = 'No DesignWear account for ${next.notFound.join(', ')}.';
        }
      });
      widget.onChanged?.call();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = "Couldn't update sharing. Please try again.");
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _copy(String text, String what) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$what link copied')));
  }

  String _status(DesignSharing s) => switch (s.visibility) {
    'public' => 'Public: anyone can find it in the community.',
    'shared' => 'Shared: only the people and links below can open it.',
    _ => 'Private: only you can open it.',
  };

  @override
  Widget build(BuildContext context) {
    final s = _s;
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: s == null
            ? SizedBox(
                height: 160,
                child: Center(
                  child: _error == null
                      ? const CircularProgressIndicator()
                      : Text(_error!),
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Share "${widget.designName}"',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(_status(s), style: theme.textTheme.bodyMedium),
                    if (_busy)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: LinearProgressIndicator(),
                      ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _error!,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Public in the community'),
                      subtitle: const Text(
                        'Everyone can see, like and remix it',
                      ),
                      value: s.visibility == 'public',
                      onChanged: _busy
                          ? null
                          : (on) => _run(
                              () => _service.updateSharing(
                                widget.designId,
                                visibility: on ? 'public' : 'private',
                              ),
                            ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Anyone with the private link'),
                      subtitle: const Text(
                        'Opens without signing in; turn it off to stop it',
                      ),
                      value: s.linkOn,
                      onChanged: _busy
                          ? null
                          : (on) => _run(
                              () => _service.updateSharing(
                                widget.designId,
                                link: on,
                              ),
                            ),
                    ),
                    if (s.linkOn) ...[
                      _LinkRow(
                        icon: Icons.article_outlined,
                        label: 'Details link',
                        onCopy: () => _copy(
                          detailLink(widget.designId, token: s.linkToken),
                          'Details',
                        ),
                      ),
                      _LinkRow(
                        icon: Icons.checkroom_outlined,
                        label: 'Try-on link',
                        onCopy: () => _copy(
                          tryOnLink(widget.designId, token: s.linkToken),
                          'Try-on',
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _busy
                              ? null
                              : () => _run(
                                  () => _service.updateSharing(
                                    widget.designId,
                                    regenerateLink: true,
                                  ),
                                ),
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text(
                            'Make a new link (the old one stops working)',
                          ),
                        ),
                      ),
                    ] else if (s.visibility == 'public') ...[
                      _LinkRow(
                        icon: Icons.article_outlined,
                        label: 'Details link',
                        onCopy: () =>
                            _copy(detailLink(widget.designId), 'Details'),
                      ),
                      _LinkRow(
                        icon: Icons.checkroom_outlined,
                        label: 'Try-on link',
                        onCopy: () =>
                            _copy(tryOnLink(widget.designId), 'Try-on'),
                      ),
                    ],
                    const Divider(height: 24),
                    Text('People', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              isDense: true,
                              border: OutlineInputBorder(),
                              hintText: "Their DesignWear email",
                            ),
                            onSubmitted: (_) => _add(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: _busy ? null : _add,
                          child: const Text('Share'),
                        ),
                      ],
                    ),
                    if (_note != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(_note!, style: theme.textTheme.bodySmall),
                      ),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final p in s.people)
                          InputChip(
                            label: Text(p.name),
                            onDeleted: _busy
                                ? null
                                : () => _run(
                                    () => _service.updateSharing(
                                      widget.designId,
                                      removeUserIds: [p.userId],
                                    ),
                                  ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Let them order or copy it'),
                      subtitle: const Text(
                        'People it is shared with can remix it or buy it',
                      ),
                      value: s.allowRemix,
                      onChanged: _busy
                          ? null
                          : (on) => _run(
                              () => _service.updateSharing(
                                widget.designId,
                                allowRemix: on,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  void _add() {
    final email = _email.text.trim();
    if (!email.contains('@')) return;
    _email.clear();
    _run(() => _service.updateSharing(widget.designId, addEmails: [email]));
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.icon,
    required this.label,
    required this.onCopy,
  });
  final IconData icon;
  final String label;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon),
    title: Text(label),
    trailing: TextButton.icon(
      onPressed: onCopy,
      icon: const Icon(Icons.link, size: 18),
      label: const Text('Copy'),
    ),
    onTap: onCopy,
  );
}
