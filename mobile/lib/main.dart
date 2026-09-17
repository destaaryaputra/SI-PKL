import 'package:flutter/material.dart';

import 'screens/login_screen.dart';

void main() {
  runApp(const SiPklApp());
}

class SiPklApp extends StatelessWidget {
  const SiPklApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SI-PKL',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
