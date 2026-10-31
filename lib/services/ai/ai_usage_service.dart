import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../api/api_client.dart';

/// Today's AI allowance for the signed-in person (plan, limit, used), read from
/// the server. The server enforces it; this only lets the screens show it and
/// stop the person before they hit it.
class AiUsageService extends ChangeNotifier {
  AiUsageService({this.api});

  final ApiClient? api;

  String plan = 'free';
  int? _limit;
  int _used = 0;

  /// Whether the server has told us the allowance yet.
  bool get known => _limit != null;
  int get limit => _limit ?? 0;
  int get remaining => known ? (limit - _used).clamp(0, limit) : 0;

  /// True only when the server said there is nothing left today.
  bool get exhausted => known && remaining == 0;

  String get planLabel =>
      plan.isEmpty ? 'Free' : '${plan[0].toUpperCase()}${plan.substring(1)}';

  /// "2 of 3 AI creations left today".
  String get summary => exhausted
      ? 'No AI creations left today. They reset at midnight.'
      : '$remaining of $limit AI creations left today';

  Future<void> refresh() async {
    final api = this.api;
    if (api == null || !api.hasToken) return;
    try {
      final j = await api.get('/v1/me/ai-usage');
      plan = '${j['plan'] ?? 'free'}';
      _limit = (j['limit'] as num?)?.toInt();
      _used = (j['used'] as num?)?.toInt() ?? 0;
      notifyListeners();
    } on ApiException catch (_) {}
  }

  void clear() {
    plan = 'free';
    _limit = null;
    _used = 0;
    notifyListeners();
  }
}

/// The allowance if the app provides one (tests and signed-out screens may not).
///
/// Pass `listen: false` from event handlers (outside `build`).
AiUsageService? maybeAiUsage(BuildContext context, {bool listen = true}) {
  try {
    return Provider.of<AiUsageService>(context, listen: listen);
  } on ProviderNotFoundException {
    return null;
  }
}
