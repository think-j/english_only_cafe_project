import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'splash.dart'; // Import your splash screen
import 'home_page.dart'; // If your HomePage is in a separate file

const double kDefaultFontSize = 14.0;


void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter is initialized
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Other system settings...s

  // Run app with routes
  runApp(MaterialApp(
    initialRoute: '/', // Start at splash screen
    routes: {
      '/': (context) => const SplashPage(), // Splash screen as initial route
      '/home': (context) => const HomePage(), // Route to HomePage
    },
  ));
}