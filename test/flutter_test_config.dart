import 'dart:async';

import 'package:designwear/logging/app_log.dart';

/// Runs before every test file: the shared app log doesn't write to disk in tests.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  AppLog.persistInstance = false;
  await testMain();
}
