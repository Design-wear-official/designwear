import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:io' show Platform;
import 'dart:async' show unawaited;
import 'package:flutter/foundation.dart' show PlatformDispatcher, kIsWeb;
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/error_404_screen.dart';
import 'screens/error_405_screen.dart';
import 'package:designwear/services/services.dart';
import 'package:designwear/config/config.dart';
import 'package:designwear/presentation/styles/styles.dart';
import 'data/repositories/product_repository.dart';
import 'data/repositories/product_repository_impl.dart';
import 'domain/usecases/product_use_cases.dart';

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

  // Load environment variables from .env on mobile/desktop only.
  // Firebase Hosting excludes dotfiles, so .env is never served on web — dotenv
  // would silently skip the load and stay uninitialized, breaking everything that
  // reads from it. Web Firebase config is hardcoded in firebase_options.dart
  // (those keys are intentionally non-secret in web apps).
  if (!kIsWeb) {
    await dotenv.load(fileName: ".env", isOptional: true);
    await dotenv.load(
      fileName: ".env.local",
      isOptional: true,
      mergeWith: Map<String, String>.from(dotenv.env),
    );
  }

  final isDesktop = !kIsWeb && (Platform.isWindows || Platform.isLinux);

  // Skip Firebase when no credentials are configured (e.g. running without .env)
  final hasFirebaseCreds = kIsWeb ||
      (dotenv.env['FIREBASE_ANDROID_API_KEY']?.isNotEmpty ?? false) ||
      (isDesktop && (dotenv.env['FIREBASE_WEB_API_KEY']?.isNotEmpty ?? false));

  if (hasFirebaseCreds) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Crashlytics is not supported on Windows/Linux.
      if (!kIsWeb && !isDesktop) {
        FlutterError.onError =
            FirebaseCrashlytics.instance.recordFlutterFatalError;
        PlatformDispatcher.instance.onError = (error, stack) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          return true;
        };
      }

      // FCM background handler is not supported on Windows/Linux.
      if (!isDesktop) {
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      }
    } catch (e) {
      if (!e.toString().contains('duplicate-app')) {
        debugPrint('⚠️ Firebase init failed: $e');
      }
    }
  } else {
    debugPrint('ℹ️ Firebase credentials not configured — running without Firebase');
  }

  FlavorConfig.init(flavor);

  // Fire-and-forget: logging init is non-critical, don't block runApp.
  unawaited(LoggingService.instance.init(
    flavor: flavor == Flavor.internal ? 'internal' : 'external',
    appVersion: '1.0.0+1',
  ));

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
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => MultiProvider(
        providers: [
          Provider<ProductRepository>(
            create: (_) => ProductRepositoryImpl(
              WebApiConfig.useWebApi
                  ? ApiService.webApi(WebApiConfig.baseUrl)
                  : ApiService.sanity(),
            ),
          ),
          Provider<GetCategoriesUseCase>(
            create: (ctx) => GetCategoriesUseCase(ctx.read<ProductRepository>()),
          ),
          Provider<GetFeaturedProductsUseCase>(
            create: (ctx) => GetFeaturedProductsUseCase(ctx.read<ProductRepository>()),
          ),
          Provider<GetProductsUseCase>(
            create: (ctx) => GetProductsUseCase(ctx.read<ProductRepository>()),
          ),
          Provider<GetProductsByCategoryUseCase>(
            create: (ctx) => GetProductsByCategoryUseCase(ctx.read<ProductRepository>()),
          ),
          Provider<GetProductByIdUseCase>(
            create: (ctx) => GetProductByIdUseCase(ctx.read<ProductRepository>()),
          ),
          Provider<GetTaxRateUseCase>(
            create: (ctx) => GetTaxRateUseCase(ctx.read<ProductRepository>()),
          ),
          ChangeNotifierProvider(
            create: (ctx) => CartService(ctx.read<GetTaxRateUseCase>()),
          ),
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
          builder: (context, themeProvider, _) {
            return MaterialApp(
              title: 'Design Wear',
              debugShowCheckedModeBanner: flavor == Flavor.internal,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeProvider.themeMode,
              navigatorObservers: [LoggingService.instance.routeObserver],
              builder: (context, child) {
                final bg = Theme.of(context).scaffoldBackgroundColor;
                final screenW = MediaQuery.sizeOf(context).width;
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
              routes: {
                Error404Screen.routeName: (_) => const Error404Screen(),
                Error405Screen.routeName: (_) => const Error405Screen(),
              },
              onUnknownRoute: (_) => MaterialPageRoute(
                builder: (_) => const Error404Screen(),
              ),
            );
          },
        ),
      ),
    );
  }
}

