import 'package:designwear/api/api_client.dart';
import 'package:designwear/services/auth/auth_service.dart';
import 'package:designwear/services/shop/cart_service.dart';
import 'package:designwear/services/community/community_service.dart';
import 'package:designwear/services/notifications/notification_service.dart';
import 'package:designwear/services/shop/stores.dart';
import 'package:designwear/services/app/theme_service.dart';
import 'package:designwear/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

/// The app's providers, theme and ScreenUtil setup around [home].
Widget testApp(
  Widget home, {
  CartService? cart,
  AuthService? auth,
  NotificationService? inbox,
  Brightness brightness = Brightness.dark,
}) => MultiProvider(
  providers: [
    Provider<CommunityService?>.value(value: null),
    // A real (non-null) client: Provider rejects Listenable types in debug.
    Provider<ApiClient?>.value(
      value: ApiClient(
        'https://api.example.com',
        // Tests never reach the network: every call answers with an empty catalog.
        httpClient: MockClient(
          (_) async => http.Response(
            '{"data":[]}',
            200,
            headers: {'content-type': 'application/json'},
          ),
        ),
      ),
    ),
    ChangeNotifierProvider.value(value: auth ?? AuthService()),
    ChangeNotifierProvider.value(value: cart ?? CartService()),
    ChangeNotifierProvider(create: (_) => ThemeService()),
    ChangeNotifierProvider(create: (_) => AddressStore()),
    ChangeNotifierProvider(create: (_) => PaymentMethodStore()),
    ChangeNotifierProvider(create: (_) => OrderStore()),
    ChangeNotifierProvider.value(value: inbox ?? NotificationService()),
  ],
  child: ScreenUtilInit(
    designSize: const Size(390, 844),
    builder: (context, _) => MaterialApp(
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      themeMode: brightness == Brightness.dark
          ? ThemeMode.dark
          : ThemeMode.light,
      home: home,
    ),
  ),
);
