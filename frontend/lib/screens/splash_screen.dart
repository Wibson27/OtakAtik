import 'package:flutter/material.dart';
import 'package:frontend/common/app_route.dart';
import 'package:frontend/common/screen_utils.dart'; // Keep if used for scaling (though not directly here)

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp(); // Ubah nama method untuk lebih umum
  }

  Future<void> _initializeApp() async {
    // Simulasi loading atau inisialisasi awal
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // TODO: Implementasi logika pengecekan status login/token di sini
    // Contoh:
    // bool isLoggedIn = await AuthService.checkLoginStatus(); // Asumsi ada AuthService
    // if (isLoggedIn) {
    //   Navigator.pushReplacementNamed(context, AppRoute.dashboard);
    // } else {
    //   Navigator.pushReplacementNamed(context, AppRoute.signUp); // Atau AppRoute.signIn
    // }

    // Untuk demo, navigasi ke SignUpScreen (sesuai alur awal Anda)
    Navigator.pushReplacementNamed(context, AppRoute.signUp);
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