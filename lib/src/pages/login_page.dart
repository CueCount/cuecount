import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  Future<void> signIn() async {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );
  }

  Future<void> register() async {
    await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 320,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
              TextField(controller: passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: signIn, child: const Text('Login')),
              TextButton(onPressed: register, child: const Text('Create Account')),
            ],
          ),
        ),
      ),
    );
  }
}
