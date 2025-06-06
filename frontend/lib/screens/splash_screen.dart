// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:frontend/common/app_route.dart'; 
import 'package:frontend/common/screen_utils.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToSignUp(); 
  }

  _navigateToSignUp() async {
    // ada loading 3 detik sebelum masuk ke halaman sign up
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) { 
      Navigator.pushReplacementNamed(context, AppRoute.signUp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill( 
            child: Image.asset(
              'assets/images/wave_tosca_splash.png',
              fit: BoxFit.cover, 
            ),
          ),
          Center(
            child: Image.asset(
              'assets/images/tenangin_logo.png', 
            ),
          ),
        ],
      ),
    );
  }
}