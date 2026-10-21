import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/config/app_config.dart';
import 'providers/app_providers.dart';
import 'services/api_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  final apiService = ApiService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DocumentProvider(apiService)),
        ChangeNotifierProvider(create: (_) => ChatProvider(apiService)),
      ],
      child: const PdfBrainApp(),
    ),
  );
}