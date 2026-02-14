import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/auth/login_screen.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen_common.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.loadBaseUrl();
  final token = await AuthService.getToken();
  runApp(HealthAnalyzerApp(initialRoute: token != null ? '/home' : '/login'));
}

class HealthAnalyzerApp extends StatelessWidget {
  final String initialRoute;
  const HealthAnalyzerApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Well360',
      theme: ThemeData.dark().copyWith(

        scaffoldBackgroundColor: const Color(0xFF050505), // Almost Black
        primaryColor: Colors.cyanAccent,
        colorScheme: const ColorScheme.dark(
          primary: Colors.cyanAccent,
          secondary: Colors.purpleAccent,
          surface: Color(0xFF1E1E1E),
        ),
        textTheme: GoogleFonts.exo2TextTheme(ThemeData.dark().textTheme),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.orbitron(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      initialRoute: initialRoute,
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreenCommon(),
      },
      home: const LoginScreen(), 
    );
  }
}
