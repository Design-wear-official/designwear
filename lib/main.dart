import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'services/cart_service.dart';
import 'services/auth_service.dart';
import 'config/gokwik_config.dart';

enum Flavor { internal, external }

Future<void> mainCommon(Flavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize config loader (loads env.json for web)
  await ConfigLoader.init();

  // Load environment variables from .env (fallback for mobile)
  await dotenv.load(fileName: "assets/.env");

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
      ],
      child: MaterialApp(
        title: 'Design Wear',
        debugShowCheckedModeBanner: flavor == Flavor.internal,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          primaryColor: const Color(0xFF1A1A1A),
          scaffoldBackgroundColor: Colors.white,
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF1A1A1A),
            secondary: Color(0xFFD4AF37), // Muted Gold
            surface: Colors.white,
            error: Color(0xFFB00020),
            onPrimary: Colors.white,
            onSecondary: Colors.black,
            onSurface: Color(0xFF1A1A1A),
          ),
          textTheme: GoogleFonts.outfitTextTheme().copyWith(
            displayLarge: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A1A),
            ),
            titleLarge: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A1A),
            ),
            bodyLarge: GoogleFonts.outfit(
              fontSize: 16,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Color(0xFF1A1A1A),
            elevation: 0,
            scrolledUnderElevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A1A1A), // Black background
              foregroundColor: Colors.white, // White text
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1A1A1A),
              side: const BorderSide(color: Color(0xFF1A1A1A), width: 1.5),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
