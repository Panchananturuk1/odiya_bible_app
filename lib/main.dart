import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/settings_provider.dart';
import 'providers/bible_provider.dart';
import 'providers/audio_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const OdiyaBibleApp());
}

class OdiyaBibleApp extends StatelessWidget {
  const OdiyaBibleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => BibleProvider()),
        ChangeNotifierProvider(create: (_) => AudioProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          return MaterialApp(
            title: 'Odiya Bible (ଓଡିଆ ବାଇବଲ)',
            debugShowCheckedModeBanner: false,
            theme: settingsProvider.lightTheme,
            darkTheme: settingsProvider.darkTheme,
            themeMode: settingsProvider.isDarkMode 
                ? ThemeMode.dark 
                : ThemeMode.light,
            home: settingsProvider.isInitialized 
                ? const HomeScreen() 
                : const SplashScreen(),
          );
        },
      ),
    );
  }
}
