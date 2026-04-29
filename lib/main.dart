import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/weather_provider.dart';
import 'providers/storage_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authProvider = AuthProvider();
  await authProvider.loadSaved();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => WeatherProvider()),
        ChangeNotifierProvider(create: (_) => StorageProvider()),
      ],
      child: const WeatherCodiApp(),
    ),
  );
}

class WeatherCodiApp extends StatelessWidget {
  const WeatherCodiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '날씨별 코디',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3B82F6)),
        useMaterial3: true,
        fontFamily: 'pretendard',
      ),
      home: const HomeScreen(),
    );
  }
}