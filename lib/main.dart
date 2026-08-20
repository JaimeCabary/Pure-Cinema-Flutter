import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'screens/main_nav_screen.dart';
import 'screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Enforce deep OLED black status bar and navigation bar with crisp white icons
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0xFF050505),
      statusBarBrightness: Brightness.dark, // iOS: Light icons on black
      statusBarIconBrightness: Brightness.light, // Android: Light icons
      systemNavigationBarColor: Color(0xFF050505),
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  final user = await AuthService.getCurrentUser();
  await DatabaseService.init();
  final prefs = await SharedPreferences.getInstance();
  final hasCompletedOnboarding = prefs.getBool('has_completed_onboarding') ?? false;

  // Seamless instant entry: Go straight to MainNav or Onboarding (No double splash)
  final Widget initialScreen = (user != null || hasCompletedOnboarding)
      ? const MainNavScreen()
      : const OnboardingScreen();
  
  runApp(PureCinemaApp(initialScreen: initialScreen));
}

class PureCinemaApp extends StatelessWidget {
  final Widget initialScreen;
  const PureCinemaApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF050505),
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF050505),
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: MaterialApp(
        title: 'Pure Cinema',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF050505),
          primaryColor: Colors.white,
          fontFamily: 'sCore Dream',
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF050505),
            elevation: 0,
            scrolledUnderElevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: Color(0xFF050505),
              statusBarBrightness: Brightness.dark,
              statusBarIconBrightness: Brightness.light,
            ),
          ),
          colorScheme: const ColorScheme.dark(
            primary: Colors.white,
            secondary: Color(0xFFE4E4E7),
            surface: Color(0xFF0C0C0C),
            surfaceContainerLowest: Color(0xFF050505),
          ),
          textTheme: GoogleFonts.outfitTextTheme(
            ThemeData.dark().textTheme,
          ).apply(fontFamily: 'sCore Dream'),
          useMaterial3: true,
        ),
        home: initialScreen,
      ),
    );
  }
}
