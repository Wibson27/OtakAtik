import 'package:flutter/material.dart';
import 'package:frontend/common/app_info.dart';
import 'package:frontend/data/services/auth_service.dart';
import 'package:frontend/data/services/secure_storage_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/common/app_route.dart';
import 'package:frontend/common/app_color.dart';
import 'package:frontend/common/screen_utils.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {

  final _formKey = GlobalKey<FormState>(); // GlobalKey for Form
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _fullNameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  bool _isLoginButtonActive = false;
  bool _isSignUpButtonActive = false;
  bool _isGoogleButtonActive = false;
  bool _isLoading = false;

  final _authService = AuthService();
  final _storage = SecureStorageService();
  final _googleSignIn = GoogleSignIn();

  @override
  void initState() {
    super.initState();
    _fullNameFocusNode.addListener(_onFocusChange);
    _emailFocusNode.addListener(_onFocusChange);
    _passwordFocusNode.addListener(_onFocusChange);
    _confirmPasswordFocusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() {});
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  // --- PERUBAHAN: Mengimplementasikan Logika Penuh untuk _handleSignUp ---
  Future<void> _handleSignUp() async {
    // Validasi form terlebih dahulu
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true); // Tampilkan loading indicator

      try {
        // Panggil service untuk register ke backend
        final response = await _authService.register(
          email: _emailController.text,
          password: _passwordController.text,
          fullName: _fullNameController.text,
        );

        // Jika berhasil, simpan token dengan aman
        await _storage.saveTokens(
          accessToken: response.tokens.accessToken,
          refreshToken: response.tokens.refreshToken,
        );

        if (mounted) {
          AppInfo.success(context, 'Registrasi berhasil!');
          // Navigasi ke dashboard setelah sukses
          Navigator.pushReplacementNamed(context, AppRoute.dashboard);
        }
      } catch (e) {
        // Tangani error dari API
        if (mounted) {
          AppInfo.error(context, e.toString());
        }
      } finally {
        // Hentikan loading indicator
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  // Logika untuk Sign In/Up dengan Google
  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('Gagal mendapatkan ID Token dari Google.');
      }

      final response = await _authService.googleSignIn(idToken: idToken);

      await _storage.saveTokens(
        accessToken: response.tokens.accessToken,
        refreshToken: response.tokens.refreshToken,
      );

      if (mounted) {
        AppInfo.success(context, response.message);
        Navigator.pushReplacementNamed(context, AppRoute.dashboard);
      }
    } catch (e) {
      if (mounted) AppInfo.error(context, "Login dengan Google gagal: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
          // Menambahkan Loading Overlay
          child: Stack(
            children: [
              _buildMainContent(context, screenWidth, screenHeight),
              if (_isLoading)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
            ],
          ),
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
              height: context.scaleHeight(165),
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/images/wave_shark_signup.png',
              width: screenWidth,
              height: context.scaleHeight(165),
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: context.scaleHeight(134),
            left: (screenWidth - context.scaleWidth(360)) / 2,
            child: _buildSignUpForm(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpForm(BuildContext context) {
    return SizedBox(
      width: context.scaleWidth(360),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: context.scaleWidth(273),
            height: context.scaleHeight(144),
            child: Center(child: Text('SIGN UP', style: GoogleFonts.fredoka(color: AppColor.hijauTosca, fontSize: context.scaleWidth(64), fontWeight: FontWeight.bold, letterSpacing: 2))),
          ),
          SizedBox(height: context.scaleHeight(22)),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: context.scaleWidth(265 * 1.30),
                // --- PERUBAHAN DI SINI: Memperpanjang sedikit kotak biru ---
                height: context.scaleHeight(278 * 1.30),
                child: Image.asset('assets/images/blue_background.png', fit: BoxFit.fill),
              ),
              Positioned(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // --- PERUBAHAN DI SINI: Menambahkan Input Field Full Name ---
                      _buildInputField(
                        context: context,
                        controller: _fullNameController,
                        focusNode: _fullNameFocusNode,
                        hintText: 'Full Name',
                        width: context.scaleWidth(230 * 1.30),
                        height: context.scaleHeight(33 * 1.30),
                        validator: (value) => (value?.isEmpty ?? true) ? 'Nama lengkap tidak boleh kosong' : null,
                      ),
                      SizedBox(height: context.scaleHeight(15)),
                      _buildInputField(
                        context: context,
                        controller: _emailController, // Sebelumnya _usernameController
                        focusNode: _emailFocusNode,
                        hintText: 'email', // Hint text diubah ke email
                        width: context.scaleWidth(230 * 1.30),
                        height: context.scaleHeight(33 * 1.30),
                        // keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Email tidak boleh kosong';
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Format email tidak valid';
                          return null;
                        },
                      ),
                      SizedBox(height: context.scaleHeight(15)),
                      _buildInputField(
                        context: context,
                        controller: _passwordController,
                        focusNode: _passwordFocusNode,
                        hintText: 'password',
                        width: context.scaleWidth(230 * 1.30),
                        height: context.scaleHeight(33 * 1.30),
                        obscureText: true,
                        validator: (value) => (value?.length ?? 0) < 8 ? 'Password minimal 8 karakter' : null,
                      ),
                      SizedBox(height: context.scaleHeight(15)),
                      _buildInputField(
                        context: context,
                        controller: _confirmPasswordController,
                        focusNode: _confirmPasswordFocusNode,
                        hintText: 'confirm password', // Hint text diubah
                        width: context.scaleWidth(230 * 1.30),
                        height: context.scaleHeight(33 * 1.30),
                        obscureText: true,
                        validator: (value) => value != _passwordController.text ? 'Password tidak cocok' : null,
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: context.scaleHeight(25)),
                        child: SizedBox(height: context.scaleHeight(18)),
                      ),
                      SizedBox(
                        width: context.scaleWidth(230 * 1.30),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTapDown: (_) => setState(() => _isGoogleButtonActive = true),
                              onTapUp: (_) => setState(() => _isGoogleButtonActive = false),
                              onTapCancel: () => setState(() => _isGoogleButtonActive = false),
                              onTap: _isLoading ? null : _handleGoogleSignIn,
                              // onTap: () {
                              //   // Logic for Google Sign Up/Sign In
                              //   Navigator.pushNamed(context, AppRoute.signIn);
                              // },
                              child: AnimatedScale(
                                scale: _isGoogleButtonActive ? 0.95 : 1.0,
                                duration: const Duration(milliseconds: 100),
                                child: SizedBox(
                                  width: context.scaleWidth(100 * 1.30),
                                  height: context.scaleHeight(33 * 1.30),
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
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTapDown: (_) => setState(() => _isSignUpButtonActive = true),
                  onTapUp: (_) => setState(() => _isSignUpButtonActive = false),
                  onTapCancel: () => setState(() => _isSignUpButtonActive = false),
                  onTap: _isLoading ? null : _handleSignUp,
                  child: AnimatedScale(
                    scale: _isSignUpButtonActive ? 0.95 : 1.0,
                    duration: const Duration(milliseconds: 100),
                    child: SizedBox(
                      width: context.scaleWidth(126 * 1.30),
                      height: context.scaleHeight(46 * 1.30),
                      child: Image.asset('assets/images/login_button.png', fit: BoxFit.contain),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: context.scaleHeight(70)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('you have account? ', style: GoogleFonts.roboto(color: Colors.black, fontSize: context.scaleWidth(20))),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, AppRoute.signIn),
                child: Text('Sign in', style: GoogleFonts.roboto(color: AppColor.biruNormal, fontSize: context.scaleWidth(20), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required BuildContext context,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required double width,
    required double height,
    bool obscureText = false,
    String? Function(String?)? validator,
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
        borderRadius: BorderRadius.circular(context.scaleWidth(25)),
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
              cursorColor: Colors.black,
            ),
            child: TextFormField(
              controller: controller,
              focusNode: focusNode,
              obscureText: obscureText,
              textAlign: TextAlign.center,
              textAlignVertical: TextAlignVertical.center,
              style: GoogleFonts.roboto(
                color: AppColor.whiteText,
                fontSize: context.scaleWidth(16),
                fontWeight: FontWeight.normal,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: GoogleFonts.roboto(
                  color: AppColor.whiteText,
                  fontSize: context.scaleWidth(16),
                  fontWeight: FontWeight.bold,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              validator: validator,
            ),
          ),
        ),
      ),
    );
  }
}