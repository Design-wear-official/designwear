import 'dart:async';

import 'package:designwear/logging/app_log.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Runs before every test file.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // The shared app log doesn't write to disk or the console during tests.
  AppLog.persistInstance = false;
  AppLog.echoToConsole = false;

  // The theme asks google_fonts for fonts; there is no network (and, for plain unit
  // tests, no binding yet) here, so use the fallback font quietly.
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  await testMain();
}
