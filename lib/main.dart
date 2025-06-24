import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final atsign = prefs.getString('atsign');

  runApp(MyApp(initialRoute: atsign != null ? '/home' : '/onboard'));
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({required this.initialRoute, super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Private Journal',
      routes: {
        '/onboard': (_) => const OnboardingScreen(),
        '/home': (_) => const HomeScreen(),
      },
      initialRoute: initialRoute,
    );
  }
}