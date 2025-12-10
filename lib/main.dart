import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'pages/splash_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/property_provider.dart';
import 'providers/rental_provider.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PropertyProvider()),
        ChangeNotifierProvider(create: (_) => RentalProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: '360 Real Estate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightThemeWith(themeProvider.seedColor),
      darkTheme: AppTheme.darkThemeWith(themeProvider.seedColor),
      themeMode: themeProvider.themeMode,
      home: const SplashScreen(),
    );
  }
}
