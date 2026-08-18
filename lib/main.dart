import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF050505),
      systemNavigationBarIconBrightness: Brightness.light,
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
