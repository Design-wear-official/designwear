import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show PlatformDispatcher, kIsWeb;
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'services/cart_service.dart';
import 'services/auth_service.dart';
import 'config/app_config.dart';
import 'config/demo_config.dart';
import 'styles/app_theme.dart';
import 'services/theme_provider.dart';

enum Flavor { internal, external }

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
}

Future<void> mainCommon(Flavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize config loader (loads env.json for web)
  await ConfigLoader.init();

  // Initialize demo configuration
  await DemoConfig().initializeDemoMode();

  // Load environment variables from .env
  await dotenv.load(fileName: ".env");

  // Initialize Firebase with error handling for duplicate initialization
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    if (!kIsWeb) {
      // Pass all uncaught "fatal" errors from the framework to Crashlytics
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;

      // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    }
  } catch (e) {
    // Ignore duplicate app error, Firebase is already initialized
    if (!e.toString().contains('duplicate-app')) {
      rethrow;
    }
  }

  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
  }

  runApp(DesignWearApp(flavor: flavor));
}

Future<void> main() async {
  await mainCommon(Flavor.external);
}

class DesignWearApp extends StatelessWidget {
  final Flavor? flavor;

  const DesignWearApp({super.key, this.flavor});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartService()),
        ChangeNotifierProvider(
          create: (_) {
            final authService = AuthService();
            authService.init();
            return authService;
          },
        ),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Design Wear',
            debugShowCheckedModeBanner: flavor == Flavor.internal,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            builder: (context, child) {
              // Fill full viewport with scaffold bg color
              final bg = Theme.of(context).scaffoldBackgroundColor;
              final screenW = MediaQuery.of(context).size.width;
              // If screen is very wide use full width; just cap at 1440 for ultra-wide
              final maxW = screenW > 1440 ? 1440.0 : double.infinity;
              return DecoratedBox(
                decoration: BoxDecoration(color: bg),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxW),
                    child: child,
                  ),
                ),
              );
            },
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
