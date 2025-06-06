import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/common/app_route.dart'; 
import 'package:frontend/common/app_color.dart'; 
import 'package:frontend/common/screen_utils.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    return Scaffold(
      backgroundColor: AppColor.navyElement, 
      body: SafeArea(
        child: SizedBox(
          width: screenWidth,
          height: screenHeight,
          child: _buildMainContent(context, screenWidth, screenHeight),
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, double screenWidth, double screenHeight) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColor.putihNormal, 
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/images/wave_top.png',
              width: screenWidth,
              height: 165,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/images/wave_bottom.png',
              width: screenWidth,
              height: 165,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 643,
            right: 35,
            child: Transform.rotate(
              angle: -25.52 * (3.14159 / 180),
              child: Image.asset(
                'assets/images/shark_icon.png',
                width: 97.5,
                height: 66.62,
              ),
            ),
          ),
          Positioned(
            top: 134,
            left: (screenWidth - 360) / 2,
            child: _buildSignUpForm(context, screenWidth),
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpForm(BuildContext context, double screenWidth) {
    return SizedBox(
      width: 360,
      height: 665,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 273,
            height: 144,
            child: Center(
              child: Text(
                'SIGNUP',
                style: GoogleFonts.fredoka(
                  color: AppColor.hijauTosca, 
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 255,
                height: 215,
                child: Image.asset(
                  'assets/images/blue_background.png',
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                child: Column(
                  children: [
                    _buildInputField(
                      'assets/images/username.png',
                      width: 239,
                      height: 33,
                    ),
                    const SizedBox(height: 15),
                    _buildInputField(
                      'assets/images/password.png',
                      width: 239,
                      height: 33,
                    ),
                    const SizedBox(height: 15),
                    _buildInputField(
                      'assets/images/password_correct.png',
                      width: 239,
                      height: 33,
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: 239,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {
                              // navigasi ke Sign In Screen (karena Google icon berfungsi sebagai login)
                              Navigator.pushNamed(context, AppRoute.signIn); 
                            },
                            child: SizedBox(
                              width: 98,
                              height: 33,
                              child: Image.asset(
                                'assets/images/google_icon.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    // navigasi setelah sign up sukses lalu ke dashboard
                    Navigator.pushReplacementNamed(context, AppRoute.dashboard);
                  },
                  child: SizedBox(
                    width: 126,
                    height: 46,
                    child: Image.asset(
                      'assets/images/login_button.png', 
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 70),
          SizedBox(
            width: 329,
            height: 50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'you have account? ',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 24,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, AppRoute.signIn); 
                  },
                  child: const Text(
                    'Sign in',
                    style: TextStyle(
                      color: AppColor.biruNormal,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(String imagePath, {required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Image.asset(
          imagePath,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

