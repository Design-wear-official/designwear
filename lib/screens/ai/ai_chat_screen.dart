import 'package:flutter/material.dart';

import '../../services/ai/ai_service.dart';
import '../../theme/app_theme.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});
  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _controller = TextEditingController();
  final _history = <({bool fromUser, String text})>[];
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _busy) return;
    _controller.clear();
    setState(() {
      _history.add((fromUser: true, text: text));
      _busy = true;
    });
    try {
      final reply = await AiService.instance.chat(List.of(_history));
      _history.add((fromUser: false, text: reply));
    } on AiUnavailable catch (e) {
      _history.add((fromUser: false, text: '$e'));
    } on AiFailure catch (e) {
      _history.add((fromUser: false, text: e.message));
    } catch (_) {
      _history.add((fromUser: false, text: 'Something went wrong. Try again.'));
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Design assistant')),
    body: Column(
      children: [
        if (!AiService.instance.chatEnabled)
          const MaterialBanner(
            content: Text(
              'The AI service is not connected yet, so replies are unavailable.',
            ),
            actions: [SizedBox.shrink()],
          ),
        Expanded(
          child: _history.isEmpty
              ? const Center(
                  child: Text('Ask for design ideas, sizing or styling help'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _history.length,
                  itemBuilder: (_, i) {
                    final m = _history[i];
                    return Align(
                      alignment: m.fromUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        constraints: const BoxConstraints(maxWidth: 480),
                        decoration: BoxDecoration(
                          color: m.fromUser
                              ? AppColors.purple
                              : Theme.of(context).colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(m.text),
                      ),
                    );
                  },
                ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _send(),
                    decoration: const InputDecoration(
                      hintText: 'Message',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: 'Send',
                  onPressed: _busy ? null : _send,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
