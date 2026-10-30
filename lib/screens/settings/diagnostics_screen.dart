import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../logging/app_log.dart';

/// Local log viewer plus the switch for sending warnings and errors to DesignWear.
class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key, this.log});

  /// Injectable for tests; defaults to the app-wide log.
  final AppLog? log;

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  LogLevel _min = LogLevel.info;

  AppLog get _log => widget.log ?? AppLog.instance;

  Color _color(BuildContext context, LogLevel l) => switch (l) {
    LogLevel.error => Theme.of(context).colorScheme.error,
    LogLevel.warning => Colors.orange.shade800,
    _ => Theme.of(context).colorScheme.onSurfaceVariant,
  };

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _log,
      builder: (context, _) {
        final shown = _log.entries.reversed
            .where((e) => e.level.index >= _min.index)
            .toList();
        return Scaffold(
          appBar: AppBar(
            title: const Text('Diagnostics'),
            actions: [
              IconButton(
                tooltip: 'Copy log',
                icon: const Icon(Icons.copy),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await Clipboard.setData(ClipboardData(text: _log.export()));
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Log copied')),
                  );
                },
              ),
              IconButton(
                tooltip: 'Clear log',
                icon: const Icon(Icons.delete_outline),
                onPressed: _log.clear,
              ),
            ],
          ),
          body: Column(
            children: [
              if (_log.remoteAvailable)
                SwitchListTile(
                  title: const Text('Send warnings and errors'),
                  subtitle: const Text(
                    'Helps us fix crashes. Passwords, tokens and emails are removed first.',
                  ),
                  value: _log.remoteEnabled,
                  onChanged: _log.setRemoteEnabled,
                )
              else
                const ListTile(
                  leading: Icon(Icons.cloud_off_outlined),
                  title: Text('Logs stay on this device'),
                  subtitle: Text(
                    'Set DESIGNWEAR_API_URL to send warnings and errors.',
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: SegmentedButton<LogLevel>(
                  segments: const [
                    ButtonSegment(value: LogLevel.debug, label: Text('All')),
                    ButtonSegment(value: LogLevel.info, label: Text('Info')),
                    ButtonSegment(
                      value: LogLevel.warning,
                      label: Text('Warnings'),
                    ),
                    ButtonSegment(value: LogLevel.error, label: Text('Errors')),
                  ],
                  selected: {_min},
                  onSelectionChanged: (s) => setState(() => _min = s.first),
                ),
              ),
              const Divider(),
              Expanded(
                child: shown.isEmpty
                    ? const Center(child: Text('Nothing logged'))
                    : ListView.builder(
                        itemCount: shown.length,
                        itemBuilder: (_, i) {
                          final e = shown[i];
                          final t = e.at;
                          final time =
                              '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';
                          return ListTile(
                            dense: true,
                            title: Text(
                              e.message,
                              style: TextStyle(color: _color(context, e.level)),
                            ),
                            subtitle: Text(
                              '$time · ${e.level.name} · ${e.tagIcon} ${e.tag}',
                            ),
                            onTap: e.stack == null
                                ? null
                                : () => showDialog<void>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: Text(e.tag),
                                      content: SingleChildScrollView(
                                        child: SelectableText(
                                          '${e.message}\n\n${e.stack}',
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
        );
      },
    );
  }
}
