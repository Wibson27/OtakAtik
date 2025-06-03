import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ambil ukuran screen untuk responsive design
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    
    return Scaffold(
      backgroundColor: const Color(0xFF2C3E50),
      body: SafeArea(
        child: SizedBox(
          width: screenWidth,
          height: screenHeight,
          child: _buildMainContent(screenWidth, screenHeight),
        ),
      ),
    );
  }

  Widget _buildMainContent(double screenWidth, double screenHeight) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Stack(
        children: [
          // Wave atas - positioned rata atas
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
          
          // Elemen Wave bawah 
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
          
          // Elemen Shark icon 
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
          
          // Form signup group 
          Positioned(
            top: 134, 
            left: (screenWidth - 360) / 2, 
            child: _buildSignUpForm(screenWidth),
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpForm(double screenWidth) {
    return Container(
      width: 360,
      height: 665, 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Text SIGNUP 
          Container(
            width: 273, 
            height: 144, 
            child: Center(
              child: Text(
                'SIGNUP',
                style: GoogleFonts.fredoka(
                  color: const Color(0xFF5CB1A9),
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 22), 
          // Stack 
          Stack(
            alignment: Alignment.center,
            children: [
              // Background biru
              Container(
                width: 255, 
                height: 215, 
                child: Image.asset(
                  'assets/images/blue_background.png',
                  fit: BoxFit.cover,
                ),
              ),
              
              // Form elements di atas background
              Positioned(
                child: Column(
                  children: [
                    // Username field 
                    _buildInputField(
                      'assets/images/username.png',
                      width: 239,
                      height: 33,
                    ),
                    
                    const SizedBox(height: 15), 
                    
                    // Password field 
                    _buildInputField(
                      'assets/images/password.png',
                      width: 239,
                      height: 33,
                    ),
                    
                    const SizedBox(height: 15), 
                    
                    // Password correct field 
                    _buildInputField(
                      'assets/images/password_correct.png',
                      width: 239,
                      height: 33,
                    ),
                    
                    const SizedBox(height: 18), 
                    
                    // Google icon
                    Container(
                      width: 239, // Sama dengan width input fields
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          // Google icon - sejajar kiri dengan input fields
                          Container(
                            width: 98, 
                            height: 33, 
                            child: Image.asset(
                              'assets/images/google_icon.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Login button 
              Positioned(
                bottom: 0, 
                right: 0, 
                child: Container(
                  width: 126, 
                  height: 46, 
                  child: Image.asset(
                    'assets/images/login_button.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 70), 
          
          // Text "you have account?" dan link Sign in
          Container(
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
                // Builder widget untuk context
                Builder(
                  builder: (BuildContext context) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context); 
                      },
                      child: const Text(
                        'Sign in',
                        style: TextStyle(
                          color: Color(0xFF103DCF),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
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

// Extension untuk kemudahan konversi pixel ke logical pixel
extension ScreenUtils on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  
  // Function untuk responsive scaling jika diperlukan
  double scaleWidth(double figmaWidth) {
    return (screenWidth / 430.25) * figmaWidth; 
  }
  
  double scaleHeight(double figmaHeight) {
    return (screenHeight / 932) * figmaHeight; 
  }
}