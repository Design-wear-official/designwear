import 'package:flutter/material.dart';

import '../../services/ai/ai_usage_service.dart';

/// "2 of 3 AI creations left today", shown wherever AI is used. Nothing is shown
/// until the server has reported the allowance.
class AiAllowanceChip extends StatelessWidget {
  const AiAllowanceChip({super.key});

  @override
  Widget build(BuildContext context) {
    final usage = maybeAiUsage(context);
    if (usage == null || !usage.known) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final color = usage.exhausted ? scheme.error : scheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt, size: 13, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              usage.summary,
              style: TextStyle(fontSize: 11, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
