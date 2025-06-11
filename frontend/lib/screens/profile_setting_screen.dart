import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/common/app_color.dart';
import 'package:frontend/common/app_route.dart';
import 'package:frontend/common/screen_utils.dart';

class ProfileSettingScreen extends StatelessWidget {
  const ProfileSettingScreen({super.key});

  // Widget pembangun item menu setting menggunakan gambar PNG
  Widget _buildSettingMenuItem(
    BuildContext context,
    String assetPath, 
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Image.asset(
        assetPath,
        width: context.scaleWidth(380), 
        height: context.scaleHeight(62), 
        fit: BoxFit.fill, 
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
              // wave_top.png
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

              // arrow.png
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

              // Text 'Settings'
              Positioned(
                top: context.scaleHeight(35),
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'Settings',
                    style: GoogleFonts.roboto(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColor.putihNormal,
                    ),
                  ),
                ),
              ),

              // Daftar menu setting ada 4 (General, Notifikasi, Privacy, Voice Journal)
              Positioned(
                top: context.scaleHeight(230),
                left: context.scaleWidth(25),
                right: context.scaleWidth(25),
                child: Column(
                  children: [
                    SizedBox(height: context.scaleHeight(20)), 
                    _buildSettingMenuItem(
                      context,
                      'assets/images/menu_setting_general.png',
                      () {
                        print('General Tapped');
                      },
                    ),
                    SizedBox(height: context.scaleHeight(20)), 
                    _buildSettingMenuItem(
                      context,
                      'assets/images/menu_setting_notifikasi.png',
                      () {
                        Navigator.pushNamed(context, AppRoute.notificationSettings);
                      },
                    ),
                    SizedBox(height: context.scaleHeight(20)),
                    _buildSettingMenuItem(
                      context,
                      'assets/images/menu_setting_privacy.png',
                      () {
                        print('Privacy Tapped');
                      },
                    ),
                    SizedBox(height: context.scaleHeight(20)),
                    _buildSettingMenuItem(
                      context,
                      'assets/images/menu_setting_voice_journal.png',
                      () {
                        print('Voice Journal Tapped');
                      },
                    ),
                  ],
                ),
              ),

              // Navigation Bar Bawah
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
                          Navigator.pushReplacementNamed(
                              context, AppRoute.dashboard);
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
                          Navigator.pushReplacementNamed(
                              context, AppRoute.profile);
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