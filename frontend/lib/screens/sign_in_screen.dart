// lib/screens/sign_in_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/common/app_route.dart';
import 'package:frontend/common/app_color.dart';
import 'package:frontend/common/screen_utils.dart'; 

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  // Controllers untuk input
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // FocusNodes 
  final FocusNode _usernameFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  // untuk efek animasi di button
  bool _isLoginButtonActive = false;
  bool _isGoogleButtonActive = false;

  @override
  void initState() {
    super.initState();
    _usernameFocusNode.addListener(_onFocusChange);
    _passwordFocusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() {}); 
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = context.screenWidth;
    final double screenHeight = context.screenHeight;

    return Scaffold(
      backgroundColor: AppColor.hijauTosca,
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
          // Wave atas
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/images/wave_top.png',
              width: screenWidth,
              height: context.scaleHeight(165),
              fit: BoxFit.cover,
            ),
          ),
          // Wave bawah + shark
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/images/wave_shark_signin.png',
              width: screenWidth,
              height: context.scaleHeight(165),
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: context.scaleHeight(134),
            left: (screenWidth - context.scaleWidth(360)) / 2,
            child: _buildSignInForm(context, screenWidth),
          ),
        ],
      ),
    );
  }

  Widget _buildSignInForm(BuildContext context, double screenWidth) {
    final double formAreaWidth = context.scaleWidth(360);
    final double formAreaHeight = context.scaleHeight(665);

    // -- AWAL SET UKURAN UKURAN ELEMEN FORM 
    final double inputFieldWidth = context.scaleWidth(230 * 1.30);
    final double inputFieldHeight = context.scaleHeight(33 * 1.30);

    final double blueBackgroundWidth = context.scaleWidth(265 * 1.30);
    final double blueBackgroundHeight = context.scaleHeight(215 * 1.30);

    final double loginButtonWidth = context.scaleWidth(126 * 1.30);
    final double loginButtonHeight = context.scaleHeight(46 * 1.30);

    final double googleIconWidth = context.scaleWidth(100 * 1.30);
    final double googleIconHeight = context.scaleHeight(33 * 1.30);
    // -- AKHIRAN SET UKURAN 

    return SizedBox(
      width: formAreaWidth,
      height: formAreaHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: context.scaleWidth(273),
            height: context.scaleHeight(144),
            child: Center(
              child: Text(
                'SIGN IN', 
                style: GoogleFonts.fredoka(
                  color: AppColor.hijauTosca,
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          SizedBox(height: context.scaleHeight(22)),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: blueBackgroundWidth,
                height: blueBackgroundHeight,
                child: Image.asset(
                  'assets/images/blue_background.png',
                  fit: BoxFit.contain,
                ),
              ),
              Positioned(
                child: Column(
                  children: [
                    // Username field
                    _buildInputField(
                      context: context,
                      controller: _usernameController,
                      focusNode: _usernameFocusNode,
                      hintText: 'username',
                      width: inputFieldWidth,
                      height: inputFieldHeight,
                      obscureText: false,
                    ),
                    SizedBox(height: context.scaleHeight(45)),
                    // Password field
                    _buildInputField(
                      context: context,
                      controller: _passwordController,
                      focusNode: _passwordFocusNode,
                      hintText: 'password',
                      width: inputFieldWidth,
                      height: inputFieldHeight,
                      obscureText: true,
                    ),
                    SizedBox(height: context.scaleHeight(15)),
                    SizedBox(height: context.scaleHeight(18)), 
                    SizedBox(
                      width: inputFieldWidth,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          // Google icon (with animasi)
                          GestureDetector(
                            onTapDown: (_) => setState(() => _isGoogleButtonActive = true),
                            onTapUp: (_) => setState(() => _isGoogleButtonActive = false),
                            onTapCancel: () => setState(() => _isGoogleButtonActive = false),
                            onTap: () {
                              Navigator.pushReplacementNamed(context, AppRoute.dashboard);
                            },
                            child: AnimatedScale(
                              scale: _isGoogleButtonActive ? 0.95 : 1.0,
                              duration: const Duration(milliseconds: 100),
                              child: SizedBox(
                                width: googleIconWidth,
                                height: googleIconHeight,
                                child: Image.asset(
                                  'assets/images/google_icon.png',
                                  fit: BoxFit.contain,
                                ),
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
                  onTapDown: (_) => setState(() => _isLoginButtonActive = true),
                  onTapUp: (_) => setState(() => _isLoginButtonActive = false),
                  onTapCancel: () => setState(() => _isLoginButtonActive = false),
                  onTap: () {
                    Navigator.pushReplacementNamed(context, AppRoute.dashboard);
                  },
                  child: AnimatedScale(
                    scale: _isLoginButtonActive ? 0.95 : 1.0,
                    duration: const Duration(milliseconds: 100),
                    child: SizedBox(
                      width: loginButtonWidth,
                      height: loginButtonHeight,
                      child: Image.asset(
                        'assets/images/login_button.png', 
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: context.scaleHeight(70)),
          SizedBox(
            width: context.scaleWidth(350),
            height: context.scaleHeight(50),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'you don\'t have account? ', 
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Sign up',
                    style: TextStyle(
                      color: AppColor.biruNormal,
                      fontSize: 20,
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

  // Widget _buildInputField 
  Widget _buildInputField({
    required BuildContext context,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required double width,
    required double height,
    bool obscureText = false,
  }) {
    Color boxColor = AppColor.hijauTosca;
    Color borderColor = focusNode.hasFocus ? AppColor.biruNormal : AppColor.hijauTosca;
    double borderWidth = focusNode.hasFocus ? 2 : 1;
    double blurRadius = focusNode.hasFocus ? 8 : 0;
    Offset offset = focusNode.hasFocus ? const Offset(0, 4) : const Offset(0, 0);

    final double textFontSize = GoogleFonts.roboto().fontSize ?? 16.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: boxColor,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: blurRadius,
            offset: offset,
          ),
        ],
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.scaleWidth(20),
            vertical: (height - textFontSize - 2) / 2,
          ).clamp(
            EdgeInsets.zero,
            EdgeInsets.all(context.scaleWidth(10)),
          ),
          child: TextSelectionTheme(
            data: const TextSelectionThemeData(
              cursorColor: Colors.black, // Kursor hitam
            ),
            child: TextFormField(
              controller: controller,
              focusNode: focusNode,
              obscureText: obscureText,
              textAlign: TextAlign.center,
              textAlignVertical: TextAlignVertical.center,
              style: GoogleFonts.roboto(
                color: AppColor.whiteText,
                fontSize: 16,
                fontWeight: FontWeight.normal,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: GoogleFonts.roboto(
                  color: AppColor.whiteText,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}