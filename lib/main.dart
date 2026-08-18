import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Enforce solid deep black status bar and navigation bar across all devices
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0xFF050505),
      statusBarBrightness: Brightness.dark, // iOS: Light text/battery on solid black
      statusBarIconBrightness: Brightness.light, // Android: Light text/battery
      systemNavigationBarColor: Color(0xFF050505),
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );
  
  runApp(const PureCinemaApp());
}

class PureCinemaApp extends StatelessWidget {
  const PureCinemaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
          secondary: Color(0xFFE50914),
          surface: Color(0xFF0C0C0C),
        ),
        textTheme: GoogleFonts.outfitTextTheme(
          ThemeData.dark().textTheme,
        ).apply(fontFamily: 'sCore Dream'),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
