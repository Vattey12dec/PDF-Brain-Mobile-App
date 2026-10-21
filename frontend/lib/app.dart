import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/app_providers.dart';
import 'screens/splash_and_onboarding.dart';
import 'screens/home_and_upload_screens.dart';

class PdfBrainApp extends StatelessWidget {
  const PdfBrainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final themeProv = context.watch<ThemeProvider>();
    return MaterialApp(
      title: 'PDF Brain',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProv.themeMode,
      home: auth.isAuthenticated
          ? const MainNavigationShell()
          : const WelcomeOnboardingScreen(),
    );
  }
}