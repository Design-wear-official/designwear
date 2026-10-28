import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'api/api_client.dart';
import 'services/auth/google_id_token_source.dart';

import 'package:firebase_core/firebase_core.dart';

import 'cms/cms_service.dart';
import 'flavours/flavour_selector.dart';
import 'screens/errors/error_screen.dart';
import 'screens/home/home_screen.dart';
import 'services/auth/auth_service.dart';
import 'services/ai/ai_service.dart';
import 'services/shop/cart_service.dart';
import 'services/community/community_service.dart';
import 'services/ai/remote_ai_service.dart';
import 'services/shop/stores.dart';
import 'services/app/theme_service.dart';
import 'theme/app_theme.dart';
import 'logging/app_log.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppLog.installGlobalHandlers();
  await AppLog.instance.load();

  // `.env.local` (untracked, personal) overrides `.env`. Both are optional.
  await dotenv.load(
    fileName: '.env',
    overrideWithFiles: ['.env.local'],
    isOptional: true,
  );

  final cmsConfig = getCmsConfig();
  if (cmsConfig.isConfigured) {
    CmsService.instance = CmsService(cmsConfig);
  } else {
    AppLog.instance.warning(
      'startup',
      'SethuCMS not configured (flavour: $flavour); set SETHUCMS_* in .env',
    );
  }

  // The DesignWear API (accounts, orders, community, AI). Without it the app
  // runs fully on-device.
  final apiUrl = getApiUrl();
  ApiClient? api;
  if (apiUrl.isNotEmpty) {
    try {
      api = ApiClient(apiUrl);
    } on ArgumentError catch (e) {
      AppLog.instance.warning(
        'startup',
        'DesignWear API disabled: ${e.message}',
      );
    }
  }

  AppLog.instance.attach(api: api, flavour: flavour);
  AppLog.instance.info(
    'startup',
    'DesignWear starting (flavour: $flavour, api: ${api == null ? 'off' : 'on'})',
  );

  // Firebase is only used for "Continue with Google". It starts when this
  // flavour has Firebase options in .env and the platform supports it.
  final firebaseOptions = getFirebaseOptions();
  if (api != null && firebaseOptions != null) {
    try {
      await Firebase.initializeApp(options: firebaseOptions);
      GoogleIdTokenSource.instance = const FirebaseGoogleIdTokenSource();
    } catch (e) {
      AppLog.instance.warning(
        'startup',
        'Firebase failed to start; Google sign-in is off',
        e,
      );
    }
  }

  final auth = AuthService(api: api);
  final cart = CartService(api: api);
  final themeService = ThemeService();
  final addresses = AddressStore();
  final payments = PaymentMethodStore();
  final orders = OrderStore(api: api);
  final community = api == null ? null : CommunityService(api);
  await Future.wait([
    auth.load(),
    cart.load(),
    themeService.load(),
    addresses.load(),
    payments.load(),
    orders.load(),
  ]);

  runApp(
    MultiProvider(
      providers: [
        Provider<CommunityService?>.value(value: community),
        Provider<ApiClient?>.value(value: api),
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider.value(value: cart),
        ChangeNotifierProvider.value(value: themeService),
        ChangeNotifierProvider.value(value: addresses),
        ChangeNotifierProvider.value(value: payments),
        ChangeNotifierProvider.value(value: orders),
      ],
      child: const DesignWearApp(),
    ),
  );

  // Network work happens after the first frame so a slow or offline API
  // never delays startup.
  if (api != null) {
    unawaited(
      api.features().then((f) => AiService.instance = RemoteAiService(api!, f)),
    );

    // Keep per-account state in step with the session: load it on sign-in and
    // clear it on sign-out so the next person doesn't see it.
    var wasSignedIn = auth.isSignedIn;
    Future<void> loadAccountState() async {
      await cart.syncFromServer();
      await orders.refresh();
    }

    auth.addListener(() {
      final now = auth.isSignedIn;
      if (now && !wasSignedIn) {
        loadAccountState();
      } else if (!now && wasSignedIn) {
        cart.clearLocal();
        orders.setAll(const []);
      }
      wasSignedIn = now;
    });
    if (wasSignedIn) unawaited(loadAccountState());
  }
}

class DesignWearApp extends StatelessWidget {
  const DesignWearApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Design size is the original DesignWear one; ResponsiveUtils reads it.
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, _) => _buildApp(context),
    );
  }

  Widget _buildApp(BuildContext context) {
    return MaterialApp(
      title: getAppTitle(),
      // Flutter's debug banner tracks build mode, not flavour, so it's off and
      // the mode banner below (tied to FLAVOR, shown in release too) replaces
      // it: an internal build is never mistaken for the external one.
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      themeMode: context.watch<ThemeService>().mode,
      onUnknownRoute: (_) =>
          MaterialPageRoute(builder: (_) => const ErrorScreen.notFound()),
      builder: (context, child) {
        final label = getModeLabel();
        if (label == null || child == null) {
          return child ?? const SizedBox.shrink();
        }
        return Banner(
          message: label,
          location: BannerLocation.topEnd,
          color: Colors.red.shade700,
          child: child,
        );
      },
      home: const HomeScreen(),
    );
  }
}
