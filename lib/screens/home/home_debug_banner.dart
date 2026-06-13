import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:designwear/config/config.dart';
import 'package:designwear/services/services.dart';

/// Shown at the very top of the home screen for internal flavor builds only.
/// Returns [SizedBox.shrink] for external builds — zero overhead.
class HomeDebugBanner extends StatelessWidget {
  const HomeDebugBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (!FlavorConfig.isInternal) return const SizedBox.shrink();

    final auth = context.watch<AuthService>();
    final user = auth.currentUser;

    return Material(
      color: const Color(0xFFE65100), // deep orange — unmistakable
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'INTERNAL BUILD  ·  ${WebApiConfig.useWebApi ? "WebAPI" : "Sanity"}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    Text(
                      user != null
                          ? '${user.email ?? user.id ?? "guest"}  ·  uid: ${_short(user.id)}'
                          : 'Not logged in',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 9,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              // Copy user ID to clipboard for debugging
              if (user?.id != null)
                GestureDetector(
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: user!.id!));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('UID copied'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Copy UID',
                      style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              SizedBox(width: 6.w),
              // Show API base URL on tap
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Internal Build Info', style: TextStyle(fontSize: 15)),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _infoRow('Flavor', FlavorConfig.label),
                          _infoRow('API URL', WebApiConfig.baseUrl),
                          _infoRow('Data source', WebApiConfig.useWebApi ? 'Web API' : 'Sanity'),
                          _infoRow('Debug mode', AppConfig.isDebug.toString()),
                          if (user != null) ...[
                            _infoRow('Email', user.email ?? '—'),
                            _infoRow('UID', user.id ?? '—'),
                            _infoRow('Guest', user.isGuest.toString()),
                          ],
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Icon(Icons.info_outline_rounded, color: Colors.white70, size: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _short(String? id) =>
      id != null && id.length > 8 ? '${id.substring(0, 8)}…' : (id ?? '—');

  static Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 90,
              child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
            Expanded(
              child: Text(value, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ),
          ],
        ),
      );
}
