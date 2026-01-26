import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/login/login_page.dart';
import 'themes/app_theme.dart';
import 'services/auth_service.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [Provider<AuthService>(create: (_) => AuthService())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Check-in Maanaim',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const LoginPage(),
    );
  }
}
