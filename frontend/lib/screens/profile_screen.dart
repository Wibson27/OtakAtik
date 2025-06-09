import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/common/app_color.dart';
import 'package:frontend/common/app_route.dart';
import 'package:frontend/common/screen_utils.dart';
import 'package:frontend/data/models/user.dart'; 

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
              // 1. wave_top.png (background atas)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Image.asset(
                  'assets/images/wave_top.png',
                  width: context.scaleWidth(431.5), // Sesuaikan dengan width di Figma
                  height: context.scaleHeight(200), // Sesuaikan dengan height di Figma
                  fit: BoxFit.fill,
                ),
              ),

              // 2. arrow.png (tombol kembali)
              Positioned(
                top: context.scaleHeight(16), // Contoh posisi, sesuaikan dengan screen lain
                left: context.scaleWidth(8), // Contoh posisi, sesuaikan dengan screen lain
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context); // Kembali ke screen sebelumnya
                  },
                  child: Image.asset(
                    'assets/images/arrow.png',
                    width: context.scaleWidth(66), // Ukuran seperti screen lain
                    height: context.scaleHeight(66), // Ukuran seperti screen lain
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              // 3. Text 'Profile'
              Positioned(
                top: context.scaleHeight(35), // Sesuaikan top agar di tengah wave_top
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'Profile',
                    style: GoogleFonts.inter( // Font: Inter as replacement for Helvetica
                      fontSize: 24, // Size: 24px
                      fontWeight: FontWeight.w700, // Weight: 700
                      color: AppColor.navyText, // Warna navyText
                    ),
                  ),
                ),
              ),

              // Area Profile Utama (gambar profil, nama, username, edit profile)
              Positioned(
                top: context.scaleHeight(94), // Posisi Top dari Figma (10px + 81px dari wave_top)
                left: context.scaleWidth(25), // Sesuaikan dengan margin
                right: context.scaleWidth(25), // Sesuaikan dengan margin
                child: Container(
                  width: context.scaleWidth(380), // Rectangle 31 width
                  height: context.scaleHeight(167), // Rectangle 31 height
                  decoration: BoxDecoration(
                    color: AppColor.putihNormal, // Rectangle 31 color
                    borderRadius: BorderRadius.circular(context.scaleWidth(18)), // Rectangle 31 radius
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25), // Rectangle 31 shadow color
                        blurRadius: 4, // Rectangle 31 blur
                        offset: const Offset(0, 4), // Rectangle 31 offset
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // 18. Rectangle 2 (rectangle_photo_profile.png)
                      Positioned(
                        top: context.scaleHeight(31.5), // (167 - 104) / 2 + 10 (margin dari Figma) = 43.5 - 12 (padding) = 31.5 (approx center)
                        left: context.scaleWidth(24.5), // (380 - 104) / 2 - 12 (padding) = 138 - 12 = 126
                        child: Container(
                          width: context.scaleWidth(104), // Dari Figma
                          height: context.scaleHeight(104), // Dari Figma
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(context.scaleWidth(52)), // Radius 52px (setengah dari 104px untuk circle)
                            image: const DecorationImage(
                              image: AssetImage('assets/images/rectangle_photo_profile.png'),
                              fit: BoxFit.cover,
                            ),
                            border: Border.all(
                              color: AppColor.putihNormal.withOpacity(0.5), // Warna border dari figma #D9D9D9
                              width: context.scaleWidth(2), // Tebal border
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 4,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          // Anda bisa menambahkan Image.network atau Image.file di sini nanti
                          // untuk menampilkan gambar profil dinamis.
                          child: ClipRRect( // Clip gambar agar sesuai dengan border radius
                            borderRadius: BorderRadius.circular(context.scaleWidth(52)),
                            child: Image.asset( // Placeholder image, replace with actual user photo
                              'assets/images/user_placeholder.png', // Ganti dengan placeholder gambar user
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      // 4. Text "display name" (El fonso mantey)
                      Positioned(
                        top: context.scaleHeight(53), // Dari Figma
                        left: context.scaleWidth(149), // Dari Figma (149px)
                        child: Text(
                          'El fonso mantey', // Ganti dengan display name dari model User
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.black, // Warna hitam
                          ),
                        ),
                      ),
                      // 5. Text "username" (@Elcuphacabra)
                      Positioned(
                        top: context.scaleHeight(75), // Dari Figma
                        left: context.scaleWidth(149), // Dari Figma (149px)
                        child: Text(
                          '@Elcuphacabra', // Ganti dengan username dari model User
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Colors.black.withOpacity(0.5), // Warna dengan opacity
                          ),
                        ),
                      ),
                      // 6. Frame Edit Profile (edit_profile_button.png)
                      Positioned(
                        top: context.scaleHeight(94), // Dari Figma
                        left: context.scaleWidth(149), // Dari Figma
                        child: GestureDetector(
                          onTap: () {
                            // TODO: Navigasi ke Edit Profile Screen
                            print('Edit Profile tapped');
                          },
                          child: Image.asset(
                            'assets/images/edit_profile_button.png',
                            width: context.scaleWidth(212), // Dari Figma
                            height: context.scaleHeight(54), // Dari Figma
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 8. Frame Setting (menu_setting.png)
              Positioned(
                top: context.scaleHeight(271), // Top dari Figma (265px)
                left: context.scaleWidth(25), // Dari Figma (25px)
                right: context.scaleWidth(25), // Dari Figma (25px)
                child: GestureDetector(
                  onTap: () {
                    // TODO: Navigasi ke Setting Screen
                    print('Setting menu tapped');
                  },
                  child: Image.asset(
                    'assets/images/menu_setting.png',
                    width: context.scaleWidth(380), // Dari Figma
                    height: context.scaleHeight(62), // Dari Figma
                    fit: BoxFit.fill,
                  ),
                ),
              ),

              // 9. Frame Feedback (menu_feedback.png)
              Positioned(
                top: context.scaleHeight(343), // Top dari Figma (337px)
                left: context.scaleWidth(25), // Dari Figma (25px)
                right: context.scaleWidth(25), // Dari Figma (25px)
                child: GestureDetector(
                  onTap: () {
                    // TODO: Navigasi ke Feedback Screen
                    print('Feedback menu tapped');
                  },
                  child: Image.asset(
                    'assets/images/menu_feedback.png',
                    width: context.scaleWidth(380),
                    height: context.scaleHeight(62),
                    fit: BoxFit.fill,
                  ),
                ),
              ),

              // 10. Frame Update Password (menu_update_password.png)
              Positioned(
                top: context.scaleHeight(415), // Top dari Figma (409px)
                left: context.scaleWidth(25), // Dari Figma (25px)
                right: context.scaleWidth(25), // Dari Figma (25px)
                child: GestureDetector(
                  onTap: () {
                    // TODO: Navigasi ke Update Password Screen
                    print('Update Password menu tapped');
                  },
                  child: Image.asset(
                    'assets/images/menu_update_password.png',
                    width: context.scaleWidth(380),
                    height: context.scaleHeight(62),
                    fit: BoxFit.fill,
                  ),
                ),
              ),

              // 11. Text "Link to connect with Apps"
              Positioned(
                top: context.scaleHeight(592), // Dari Figma
                left: context.scaleWidth(110), // Dari Figma
                child: Text(
                  'Link to connect with Apps',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Colors.black, // Warna hitam
                  ),
                ),
              ),

              // Social Media Icons Group
              Positioned(
                top: context.scaleHeight(643), // Top dari Figma
                left: context.scaleWidth(103), // Left dari Figma
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 12. Ellipse 4 (ellipse_instagram.png) + 15. instagram_logo.png
                    _buildSocialMediaIcon(
                      context,
                      'assets/images/ellipse_instagram.png',
                      'assets/images/instagram_logo.png',
                      () {
                        // TODO: Implement Instagram link
                        print('Instagram tapped');
                      },
                      Colors.orange, // Placeholder color for tinting
                    ),
                    SizedBox(width: context.scaleWidth(20)), // Jarak antar icon (62 - 34) / 2 = 14, 184-103-62 = 19 (approx)
                    // 14. Ellipse 3 (ellipse_twitter.png) + 16. twitter_logo.png
                    _buildSocialMediaIcon(
                      context,
                      'assets/images/ellipse_twitter.png',
                      'assets/images/twitter_logo.png',
                      () {
                        // TODO: Implement Twitter link
                        print('Twitter tapped');
                      },
                      Colors.blue, // Placeholder color for tinting
                    ),
                    SizedBox(width: context.scaleWidth(20)),
                    // 13. Ellipse 5 (ellipse_facebook.png) + 17. facebook_logo.png
                    _buildSocialMediaIcon(
                      context,
                      'assets/images/ellipse_facebook.png',
                      'assets/images/facebook_logo.png',
                      () {
                        // TODO: Implement Facebook link
                        print('Facebook tapped');
                      },
                      Colors.indigo, // Placeholder color for tinting
                    ),
                  ],
                ),
              ),

              // 21. Menu Frame (Bottom Navigation Bar)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: context.scaleHeight(100), // Dari Figma
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColor.putihNormal,
                    border: Border(
                      top: BorderSide(
                        color: Colors.black, // Border 1px #000000
                        width: 1.0,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Distribusi merata
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 19. Vector (home_button_profile.png)
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacementNamed(context, AppRoute.dashboard);
                        },
                        child: Image.asset(
                          'assets/images/home_button_profile.png',
                          width: context.scaleWidth(46), // Dari Figma
                          height: context.scaleHeight(50), // Dari Figma
                          fit: BoxFit.contain,
                        ),
                      ),
                      // 20. iconamoon:profile (profile_button.png)
                      GestureDetector(
                        onTap: () {
                          // Already on Profile Screen, do nothing or show a toast
                          print('Already on Profile Screen');
                        },
                        child: Image.asset(
                          'assets/images/button_profile.png',
                          width: context.scaleWidth(68), // Dari Figma
                          height: context.scaleHeight(68), // Dari Figma
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

  // Helper Widget untuk Social Media Icons
  Widget _buildSocialMediaIcon(
    BuildContext context,
    String ellipseAsset,
    String logoAsset,
    VoidCallback onTap,
    Color ellipseColor, // Tambahkan parameter warna ellipse
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ellipse (background icon)
          Image.asset(
            ellipseAsset,
            width: context.scaleWidth(62), // Dari Figma
            height: context.scaleHeight(62), // Dari Figma
            fit: BoxFit.contain,
            // color: ellipseColor, // Jika ingin warna ellipse sesuai AppColor
          ),
          // Logo (foreground icon)
          Image.asset(
            logoAsset,
            width: context.scaleWidth(34), // Dari Figma
            height: context.scaleHeight(34), // Dari Figma
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}