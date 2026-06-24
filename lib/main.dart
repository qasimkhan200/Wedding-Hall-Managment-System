import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/config/env_config.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/order_provider.dart';
import 'core/providers/location_provider.dart';
import 'core/providers/cart_provider.dart';
import 'core/services/firebase_service.dart';
import 'core/services/local_storage_service.dart';
import 'core/services/preferences_service.dart';
import 'core/services/kpk_initialization_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/notification_navigator.dart';
import 'core/services/backend_connectivity_service.dart';
import 'features/auth/screens/splash_screen.dart';
import 'core/providers/category_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await EnvConfig.load();
  await PreferencesService.initialize();
  await LocalStorageService.initialize();
  await FirebaseService.initialize();

  // Check backend connectivity on startup
  await BackendConnectivityService.checkConnectivity();

  // Initialize FCM + local notifications
  await NotificationService.init();

  // Wire up notification tap → navigation
  NotificationService.onNotificationTap = NotificationNavigator.handleTap;

  await KpkInitializationService.initialize();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const LetsOrganizeItApp());
}

class LetsOrganizeItApp extends StatelessWidget {
  const LetsOrganizeItApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => OrderProvider()),
            ChangeNotifierProvider(create: (_) => CategoryProvider()),
            ChangeNotifierProvider(create: (_) => LocationProvider()),
            ChangeNotifierProvider(create: (_) => CartProvider()),
          ],
          child: MaterialApp(
            title: "Let's Organize It",
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.light,
            // Global navigator key for notification-driven navigation
            navigatorKey: NotificationNavigator.navigatorKey,
            home: const SplashScreen(),
          ),
        );
      },
    );
  }
}
