// lib/screens/setting_general_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/common/app_color.dart';
import 'package:frontend/common/app_route.dart';
import 'package:frontend/common/screen_utils.dart';

class SettingGeneralScreen extends StatelessWidget {
  const SettingGeneralScreen({super.key});

  // Widget pembangun item menu general menggunakan gambar PNG
  Widget _buildGeneralMenuItem(
    BuildContext context,
    String assetPath, // Path ke gambar PNG utuh (misal: menu_timezone.png)
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Image.asset(
        assetPath,
        width: context.scaleWidth(380), // Lebar dari Figma
        height: context.scaleHeight(62), // Tinggi dari Figma
        fit: BoxFit.fill, // Penting agar gambar mengisi area
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = context.screenWidth;
    final double screenHeight = context.screenHeight;

    return Scaffold(
      backgroundColor: AppColor.putihNormal,
      body: SafeArea(
        child: SizedBox(
          width: screenWidth,
          height: screenHeight,
          child: Stack(
            children: [
              // wave_top.png (background atas)
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

              // arrow.png (tombol kembali)
              Positioned(
                top: context.scaleHeight(16),
                left: context.scaleWidth(8),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Image.asset(
                    'assets/images/arrow.png',
                    width: context.scaleWidth(66),
                    height: context.scaleHeight(66),
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              // Text 'General' - posisinya di wave_top
              Positioned(
                top: context.scaleHeight(35),
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'General',
                    style: GoogleFonts.roboto(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColor.putihNormal,
                    ),
                  ),
                ),
              ),

              // Daftar menu General (Time Zone, Language, About Application)
              Positioned(
                top: context.scaleHeight(230), // Posisi disesuaikan
                left: context.scaleWidth(25),
                right: context.scaleWidth(25),
                child: Column(
                  children: [
                    SizedBox(height: context.scaleHeight(20)), // Jarak dari wave_top
                    _buildGeneralMenuItem(
                      context,
                      'assets/images/menu_timezone.png', // Pastikan path ini benar
                      () {
                        print('Time Zone Tapped');
                        // TODO: Navigasi ke halaman Time Zone
                      },
                    ),
                    SizedBox(height: context.scaleHeight(20)), // Jarak antar item menu
                    _buildGeneralMenuItem(
                      context,
                      'assets/images/menu_language.png', // Pastikan path ini benar
                      () {
                        print('Language Tapped');
                        // TODO: Navigasi ke halaman Language
                      },
                    ),
                    SizedBox(height: context.scaleHeight(20)),
                    _buildGeneralMenuItem(
                      context,
                      'assets/images/menu_about_application.png', // Pastikan path ini benar
                      () {
                        print('About Application Tapped');
                        // TODO: Navigasi ke halaman About Application
                      },
                    ),
                  ],
                ),
              ),

              // Navigation Bar Bawah (sama dengan halaman lainnya)
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
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacementNamed(context, AppRoute.profile);
                        },
                        child: Image.asset(
                          'assets/images/button_profile.png',
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
}