import 'package:flutter/material.dart';

import '../../presentation/widgets/designwear_logo.dart';

import '../../theme/app_theme.dart';

/// Shown for unknown routes (404) and unsupported actions (405).
class ErrorScreen extends StatelessWidget {
  const ErrorScreen.notFound({super.key})
    : code = 404,
      title = 'Page not found',
      message = "We couldn't find what you were looking for.";
  const ErrorScreen.notAllowed({super.key})
    : code = 405,
      title = 'Not allowed',
      message = "That action isn't available here.";

  final int code;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const DesignWearLogo(size: 56),
            const SizedBox(height: 16),
            Text(
              '$code',
              style: TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.w900,
                color: context.accent,
              ),
            ),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.muted),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
              child: const Text('Back to home'),
            ),
          ],
        ),
      ),
    ),
  );
}
