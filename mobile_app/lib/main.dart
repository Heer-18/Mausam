import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'providers/weather_provider.dart';
import 'screens/main_shell_screen.dart';
import 'utils/constants.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables (.env) before running the app
  try {
    await dotenv.load(fileName: ".env");
    debugPrint("[main] .env loaded successfully. GEMINI_API_KEY present: ${dotenv.env['GEMINI_API_KEY'] != null && dotenv.env['GEMINI_API_KEY']!.isNotEmpty}");
  } catch (e) {
    debugPrint("[main] Warning: Could not load .env file: $e");
  }

  runApp(const MausamApp());
}

class MausamApp extends StatelessWidget {
  const MausamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => WeatherProvider()..initializeApp(),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const MainShellScreen(),
      ),
    );
  }
}
