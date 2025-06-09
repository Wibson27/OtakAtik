// lib/screens/profile_update_password_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/common/app_color.dart';
import 'package:frontend/common/app_route.dart';
import 'package:frontend/common/screen_utils.dart';
// Import model User jika nanti akan menampilkan data user dari model
// import 'package:frontend/data/models/user.dart';

class ProfileUpdatePasswordScreen extends StatefulWidget {
  const ProfileUpdatePasswordScreen({super.key});

  @override
  State<ProfileUpdatePasswordScreen> createState() => _ProfileUpdatePasswordScreenState();
}

class _ProfileUpdatePasswordScreenState extends State<ProfileUpdatePasswordScreen> {
  // Controllers input
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // FocusNodes
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  // GlobalKey for Form
  final _formKey = GlobalKey<FormState>();

  // untuk efek animasi di button
  bool _isResetButtonActive = false;
  bool _isDoneButtonActive = false;

  @override
  void initState() {
    super.initState();
    _passwordFocusNode.addListener(_onFocusChange);
    _confirmPasswordFocusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() {}); // Untuk me-rebuild UI saat fokus berubah
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  // Metode untuk menangani proses update password
  void _handleUpdatePassword() {
    if (_formKey.currentState?.validate() ?? false) {
      // Jika form valid, lakukan proses update password
      print('Password: ${_passwordController.text}');
      print('Confirm Password: ${_confirmPasswordController.text}');
      // TODO: Panggil API backend untuk update password
      // Misalnya: context.read<UserCubit>().updatePassword(_passwordController.text);
      Navigator.pop(context); // Kembali ke ProfileScreen setelah berhasil update
      // Tampilkan SnackBar sukses
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password berhasil diupdate!', style: GoogleFonts.roboto(color: AppColor.putihNormal)),
          backgroundColor: AppColor.hijauSuccess,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _handleReset() {
    setState(() {
      _passwordController.clear();
      _confirmPasswordController.clear();
      _passwordFocusNode.unfocus();
      _confirmPasswordFocusNode.unfocus();
    });
    print('Password reset');
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = context.screenWidth;
    final double screenHeight = context.screenHeight;

    return Scaffold(
      backgroundColor: AppColor.putihNormal, // Warna background dasar putih
      body: SafeArea(
        child: SizedBox(
          width: screenWidth,
          height: screenHeight,
          child: Stack(
            children: [
              // wave_top.png (background atas) - Sama seperti ProfileScreen
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Image.asset(
                  'assets/images/wave_top.png',
                  width: context.scaleWidth(431.5),
                  height: context.scaleHeight(200),
                  fit: BoxFit.fill,
                ),
              ),

              // arrow.png (tombol kembali) - Sama seperti ProfileScreen
              Positioned(
                top: context.scaleHeight(16),
                left: context.scaleWidth(8),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context); // Kembali ke ProfileScreen
                  },
                  child: Image.asset(
                    'assets/images/arrow.png',
                    width: context.scaleWidth(66),
                    height: context.scaleHeight(66),
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              // Text 'Update Password' (diganti dari 'Profile')
              Positioned(
                top: context.scaleHeight(35),
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'Update Password',
                    style: GoogleFonts.roboto(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColor.navyText,
                    ),
                  ),
                ),
              ),

              // Konten Utama Update Password
              Positioned(
                top: context.scaleHeight(130), // Rectangle 31 top dari Figma
                left: context.scaleWidth(25),
                right: context.scaleWidth(25),
                child: Container(
                  width: context.scaleWidth(380), // Rectangle 31 width
                  height: context.scaleHeight(373), // Rectangle 31 height
                  decoration: BoxDecoration(
                    color: AppColor.putihNormal, // Rectangle 31 color
                    borderRadius: BorderRadius.circular(context.scaleWidth(18)), // Rectangle 31 radius
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 4,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Form( // Wrap dengan Form widget
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: context.scaleHeight(15)), // Padding atas

                        // Profile Picture Section (sama seperti di ProfileScreen)
                        Container(
                          width: context.scaleWidth(104),
                          height: context.scaleHeight(104),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(context.scaleWidth(52)),
                            image: const DecorationImage(
                              image: AssetImage('assets/images/profile_photo_pink.jpg'),
                              fit: BoxFit.cover,
                            ),
                            border: Border.all(
                              color: AppColor.putihNormal.withOpacity(0.5),
                              width: context.scaleWidth(2),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 4,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(context.scaleWidth(52)),
                            child: Image.asset( // Placeholder image, replace with actual user photo
                              'assets/images/user_placeholder.png', // Ganti dengan placeholder gambar user
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        SizedBox(height: context.scaleHeight(5)),

                        // 1. Text "Ubah foto profil"
                        Text(
                          'Ubah foto profil',
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF5CC4BB), // Warna dari Figma #5CC4BB
                          ),
                        ),
                        SizedBox(height: context.scaleHeight(10)),

                        // Input Field Password (Menggunakan `_buildInputField` kustom)
                        _buildInputField(
                          context: context,
                          controller: _passwordController,
                          focusNode: _passwordFocusNode,
                          hintText: 'Password',
                          width: context.scaleWidth(297), // Dari Figma Nama field
                          height: context.scaleHeight(33), // Dari Figma Nama field
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password tidak boleh kosong';
                            }
                            if (value.length < 6) {
                              return 'Password minimal 6 karakter';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: context.scaleHeight(10)),

                        // Input Field Correct Password (Menggunakan `_buildInputField` kustom)
                        _buildInputField(
                          context: context,
                          controller: _confirmPasswordController,
                          focusNode: _confirmPasswordFocusNode,
                          hintText: 'Correct Password', // Dari Figma
                          width: context.scaleWidth(297), // Dari Figma Nama field
                          height: context.scaleHeight(33), // Dari Figma Nama field
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Konfirmasi password tidak boleh kosong';
                            }
                            if (value != _passwordController.text) {
                              return 'Password tidak cocok';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: context.scaleHeight(20)),

                        // Buttons: Reset dan Done
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // 5. Frame Google (reset_button.png) - Sekarang jadi Reset button
                            GestureDetector(
                              onTapDown: (_) => setState(() => _isResetButtonActive = true),
                              onTapUp: (_) => setState(() => _isResetButtonActive = false),
                              onTapCancel: () => setState(() => _isResetButtonActive = false),
                              onTap: _handleReset,
                              child: AnimatedScale(
                                scale: _isResetButtonActive ? 0.95 : 1.0,
                                duration: const Duration(milliseconds: 100),
                                child: Image.asset(
                                  'assets/images/reset_button.png', // Aset gambar untuk Reset
                                  width: context.scaleWidth(122), // Dari Figma Frame Google width
                                  height: context.scaleHeight(33), // Dari Figma Frame Google height
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            SizedBox(width: context.scaleWidth(20)), // Jarak antara tombol
                            // 4. Frame Login (done_button.png) - Sekarang jadi Done button
                            GestureDetector(
                              onTapDown: (_) => setState(() => _isDoneButtonActive = true),
                              onTapUp: (_) => setState(() => _isDoneButtonActive = false),
                              onTapCancel: () => setState(() => _isDoneButtonActive = false),
                              onTap: _handleUpdatePassword,
                              child: AnimatedScale(
                                scale: _isDoneButtonActive ? 0.95 : 1.0,
                                duration: const Duration(milliseconds: 100),
                                child: Image.asset(
                                  'assets/images/done_button.png', // Aset gambar untuk Done
                                  width: context.scaleWidth(157), // Dari Figma Frame Login width
                                  height: context.scaleHeight(46), // Dari Figma Frame Login height
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom Navigation Bar - Sama seperti ProfileScreen
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: context.scaleHeight(100),
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColor.putihNormal,
                    border: Border(
                      top: BorderSide(
                        color: Colors.black,
                        width: 1.0,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // home_button_profile.png
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacementNamed(context, AppRoute.dashboard);
                        },
                        child: Image.asset(
                          'assets/images/home_button_profile.png',
                          width: context.scaleWidth(46),
                          height: context.scaleHeight(50),
                          fit: BoxFit.contain,
                        ),
                      ),
                      // profile_button.png
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacementNamed(context, AppRoute.profile); // Kembali ke ProfileScreen
                        },
                        child: Image.asset(
                          'assets/images/profile_button.png',
                          width: context.scaleWidth(68),
                          height: context.scaleHeight(68),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget _buildInputField kustom untuk password input
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
    Color boxColor = AppColor.hijauTosca; // Warna dari Figma #5CB1A9
    Color borderColor = focusNode.hasFocus ? AppColor.biruNormal : AppColor.hijauTosca;
    double borderWidth = focusNode.hasFocus ? 2 : 1;
    double blurRadius = focusNode.hasFocus ? 8 : 0;
    Offset offset = focusNode.hasFocus ? const Offset(0, 4) : const Offset(0, 0);

    // Estimasi tinggi font Fredoka untuk kalkulasi padding vertikal
    final double textFontSize = GoogleFonts.fredoka().fontSize ?? 16.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: boxColor,
        borderRadius: BorderRadius.circular(context.scaleWidth(25)), // Radius 25px
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
            horizontal: context.scaleWidth(20), // Padding horizontal 20px
            vertical: (height - textFontSize - 2) / 2, // Perhitungan vertikal disesuaikan
          ).clamp(
            EdgeInsets.zero,
            EdgeInsets.all(context.scaleWidth(10)), // Clamp max padding
          ),
          child: TextSelectionTheme(
            data: const TextSelectionThemeData(
              cursorColor: AppColor.navyText, // Kursor hitam
            ),
            child: TextFormField(
              controller: controller,
              focusNode: focusNode,
              obscureText: obscureText,
              textAlign: TextAlign.center,
              textAlignVertical: TextAlignVertical.center,
              style: GoogleFonts.fredoka( // Menggunakan Fredoka
                color: AppColor.whiteText, // Warna teks putih
                fontSize: 16,
                fontWeight: FontWeight.normal,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: GoogleFonts.fredoka( // Menggunakan Fredoka untuk hint
                  color: AppColor.whiteText.withOpacity(0.7), // Hint lebih transparan
                  fontSize: 16,
                  fontWeight: FontWeight.w400, // Fredoka default hint weight
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