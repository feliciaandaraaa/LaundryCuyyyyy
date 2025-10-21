import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aplikasitest1/controllers/auth_controller.dart';
import 'package:aplikasitest1/controllers/order_controller.dart';
import 'package:aplikasitest1/services/auth_service.dart';
import 'package:aplikasitest1/splash_screen.dart';
import 'package:aplikasitest1/view/admin_page.dart';

void main() {
  // Pastikan Flutter sudah initialize sebelum menggunakan SharedPreferences
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthController(AuthService()),
        ),
        ChangeNotifierProvider(
          create: (_) => OrderController(),
        ),
      ],
      child: MaterialApp(
        title: 'LaundryCuy',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const SplashScreen(), // Mulai dari SplashScreen
        routes: {
          '/admin': (context) => const AdminPanel(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
