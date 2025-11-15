import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth/auth_gate.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Intentional Web',
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
    );
  }
}
