import 'package:flutter/material.dart';
import 'package:tenangin/screens/sign_up_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tenang.in',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF5DACA3)),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: SignUpScreen(),
    );
  }
}