import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'services/cart_service.dart';
import 'services/auth_service.dart';
import 'config/gokwik_config.dart';
import 'styles/app_theme.dart';
import 'services/theme_provider.dart';

enum Flavor { internal, external }

Future<void> mainCommon(Flavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize config loader (loads env.json for web)
  await ConfigLoader.init();

  // Load environment variables from .env (fallback for mobile)
  await dotenv.load(fileName: "assets/.env");
  debugPrint(
    "Sanity Config - ProjectID: ${ConfigLoader.get('SANITY_PROJECT_ID')}, Dataset: ${ConfigLoader.get('SANITY_DATASET')}",
  );

  // Initialize Firebase with error handling for duplicate initialization
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Ignore duplicate app error, Firebase is already initialized
    if (!e.toString().contains('duplicate-app')) {
      rethrow;
    }
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
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
