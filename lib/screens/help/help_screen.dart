import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/app_constants.dart';
import '../../presentation/widgets/content_width.dart';
import '../../theme/app_theme.dart' show AppThemeColors;

/// Common questions and how to reach support. The email is copied rather than
/// opened, so it works on every platform without a mail app.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const questions = <(String, String)>[
    (
      'How long does an order take?',
      'Your local print team makes each order after it is confirmed. You will '
          'see every step (confirmed, packed, shipped, delivered) in My Orders '
          'and in notifications.',
    ),
    (
      'Can I cancel an order?',
      'Yes, from My Orders, until the team confirms it. After that it is '
          'already being made, so write to support.',
    ),
    (
      'I paid but the order says waiting for payment.',
      'Open My Orders and tap Pay now, or wait a minute and refresh. If money '
          'left your account and the order does not move, write to support with '
          'the order number.',
    ),
    (
      'Where is my receipt?',
      'We email a receipt when your order is placed. In My Orders, tap Email '
          'receipt to get it again.',
    ),
    (
      'Something is wrong with my print or size.',
      'Write to support within 7 days of delivery with your order number and a '
          'photo, and we will sort it out with the print team.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & support')),
      body: ContentWidth(
        maxWidth: 720,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            for (final (question, answer) in questions)
              ExpansionTile(
                title: Text(question),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [Text(answer)],
              ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.mail_outline),
                title: const Text(AppConstants.supportEmail),
                subtitle: Text(
                  'Include your order number. Tap to copy.',
                  style: TextStyle(color: context.muted),
                ),
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await Clipboard.setData(
                    const ClipboardData(text: AppConstants.supportEmail),
                  );
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Email address copied')),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
