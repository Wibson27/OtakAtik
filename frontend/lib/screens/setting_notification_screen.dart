// lib/screens/setting_notification_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/common/app_color.dart';
import 'package:frontend/common/app_route.dart';
import 'package:frontend/common/screen_utils.dart';

class SettingNotificationScreen extends StatefulWidget {
  const SettingNotificationScreen({super.key});

  @override
  State<SettingNotificationScreen> createState() => _SettingNotificationScreenState();
}

class _SettingNotificationScreenState extends State<SettingNotificationScreen> {
  // State untuk setiap toggle notifikasi
  bool _chatNotificationEnabled = true;
  bool _communityNotificationsEnabled = true;
  bool _dailyCheckinScheduleEnabled = true;

  // Widget pembangun item notifikasi dengan toggle
  Widget _buildNotificationItem(
    BuildContext context,
    String assetPath, // Path ke gambar PNG utuh (misal: menu_chat_notification.png)
    bool isEnabled,
    ValueSetter<bool> onChanged, // Callback saat toggle berubah
  ) {
    return GestureDetector(
      onTap: () {
        // Ketika seluruh area item di-tap, ubah status toggle
        onChanged(!isEnabled);
      },
      child: Container(
        width: context.scaleWidth(380),
        height: context.scaleHeight(62),
        // *** BAGIAN INI SUDAH TIDAK ADA BoxDecoration AGAR TIDAK ADA KOTAK BERTUMPUK ***
        // decoration: BoxDecoration(
        //   color: AppColor.putihNormal,
        //   borderRadius: BorderRadius.circular(context.scaleWidth(18)),
        //   boxShadow: [
        //     BoxShadow(
        //       color: Colors.black.withOpacity(0.25),
        //       blurRadius: 5,
        //       offset: const Offset(0, 2),
        //     ),
        //   ],
        // ),
        child: Stack(
          children: [
            // Gambar PNG utama (sudah termasuk ikon, teks, dan background putih)
            Positioned.fill(
              child: Image.asset(
                assetPath,
                fit: BoxFit.fill, // Penting agar gambar mengisi area
              ),
            ),
            // *** BAGIAN INI ADALAH SWITCH YANG TETAP ADA DAN INTERAKTIF ***
            Positioned(
              right: context.scaleWidth(15), // Posisi dari kanan
              top: 0,
              bottom: 0,
              child: Center(
                child: SizedBox( // Menggunakan SizedBox untuk mengatur ukuran Switch
                  width: context.scaleWidth(46), // Lebar dari Figma: 46px
                  height: context.scaleHeight(29), // Tinggi dari Figma: 29px
                  child: Switch(
                    value: isEnabled,
                    onChanged: onChanged, // Mengelola perubahan state toggle
                    activeColor: AppColor.putihNormal, // Warna Thumb saat aktif (FFFFFF)
                    activeTrackColor: const Color(0xFF8FDAB6), // Warna Track saat aktif (8FDAB6)
                    inactiveThumbColor: AppColor.putihNormal, // Warna Thumb saat tidak aktif (FFFFFF)
                    inactiveTrackColor: Colors.grey.withOpacity(0.6), // Warna Track saat tidak aktif (mirip Figma)
                  ),
                ),
              ),
            ),
          ],
        ),
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

              // Text 'Notifications' - posisinya di wave_top
              Positioned(
                top: context.scaleHeight(35),
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'Notifications',
                    style: GoogleFonts.roboto(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColor.putihNormal,
                    ),
                  ),
                ),
              ),

              // Daftar menu notifikasi
              Positioned(
                top: context.scaleHeight(230), // Posisi disesuaikan
                left: context.scaleWidth(25),
                right: context.scaleWidth(25),
                child: Column(
                  children: [
                    SizedBox(height: context.scaleHeight(20)), // Jarak dari wave_top
                    _buildNotificationItem(
                      context,
                      'assets/images/menu_chat_notification.png',
                      _chatNotificationEnabled,
                      (bool newValue) {
                        setState(() {
                          _chatNotificationEnabled = newValue;
                        });
                        print('Chat Notification: $newValue');
                        // TODO: Simpan status notifikasi ke preferensi pengguna
                      },
                    ),
                    SizedBox(height: context.scaleHeight(20)),
                    _buildNotificationItem(
                      context,
                      'assets/images/menu_community_notifications.png',
                      _communityNotificationsEnabled,
                      (bool newValue) {
                        setState(() {
                          _communityNotificationsEnabled = newValue;
                        });
                        print('Community Notifications: $newValue');
                        // TODO: Simpan status notifikasi ke preferensi pengguna
                      },
                    ),
                    SizedBox(height: context.scaleHeight(20)),
                    _buildNotificationItem(
                      context,
                      'assets/images/menu_daily_checkin_schedule.png',
                      _dailyCheckinScheduleEnabled,
                      (bool newValue) {
                        setState(() {
                          _dailyCheckinScheduleEnabled = newValue;
                        });
                        print('Daily Check-in Schedule: $newValue');
                        // TODO: Simpan status notifikasi ke preferensi pengguna
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