import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/common/app_color.dart';
import 'package:frontend/common/app_route.dart';
import 'package:frontend/common/screen_utils.dart';
import 'package:frontend/data/models/user.dart'; 
import 'package:frontend/screens/profile_update_password_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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

              // 2. arrow.png
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

              // 3. Text 'Profile'
              Positioned(
                top: context.scaleHeight(35), 
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'Profile',
                    style: GoogleFonts.inter( 
                      fontSize: 24, 
                      fontWeight: FontWeight.w700, 
                      color: AppColor.navyText, 
                    ),
                  ),
                ),
              ),

              // gambar profil, nama, username, edit profile
              Positioned(
                top: context.scaleHeight(94), 
                left: context.scaleWidth(25), 
                right: context.scaleWidth(25), 
                child: Container(
                  width: context.scaleWidth(380), 
                  height: context.scaleHeight(167), 
                  decoration: BoxDecoration(
                    color: AppColor.putihNormal, 
                    borderRadius: BorderRadius.circular(context.scaleWidth(18)), 
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25), 
                        blurRadius: 4, 
                        offset: const Offset(0, 4), 
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // profile_photo_pink.jpg
                      Positioned(
                        top: context.scaleHeight(31.5), 
                        left: context.scaleWidth(24.5), 
                        child: Container(
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
                            child: Image.asset( 
                              'assets/images/profile_photo_pink.png', 
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      // 4. Text "display name" (El fonso mantey)
                      Positioned(
                        top: context.scaleHeight(53), 
                        left: context.scaleWidth(149), 
                        child: Text(
                          'El fonso mantey', 
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.black, 
                          ),
                        ),
                      ),
                      // Text "username" (@Elcuphacabra)
                      Positioned(
                        top: context.scaleHeight(75), 
                        left: context.scaleWidth(149), 
                        child: Text(
                          '@Elcuphacabra',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Colors.black.withOpacity(0.5), 
                          ),
                        ),
                      ),
                      // edit_profile_button.png
                      Positioned(
                        top: context.scaleHeight(94), 
                        left: context.scaleWidth(149), 
                        child: GestureDetector(
                          onTap: () {
                            print('Edit Profile tapped');
                          },
                          child: Image.asset(
                            'assets/images/edit_profile_button.png',
                            width: context.scaleWidth(212), 
                            height: context.scaleHeight(54), 
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // menu_setting.png
              Positioned(
                top: context.scaleHeight(271), 
                left: context.scaleWidth(25), 
                right: context.scaleWidth(25), 
                child: GestureDetector(
                  onTap: () {
                    print('Setting menu tapped');
                  },
                  child: Image.asset(
                    'assets/images/menu_setting.png',
                    width: context.scaleWidth(380),
                    height: context.scaleHeight(62), 
                    fit: BoxFit.fill,
                  ),
                ),
              ),

              // menu_feedback.png
              Positioned(
                top: context.scaleHeight(343), 
                left: context.scaleWidth(25), 
                right: context.scaleWidth(25), 
                child: GestureDetector(
                  onTap: () {
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

              // menu_update_password.png
              Positioned(
                top: context.scaleHeight(415), 
                left: context.scaleWidth(25), 
                right: context.scaleWidth(25), 
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileUpdatePasswordScreen(),
                      ),
                    );
                  },
                  child: Image.asset(
                    'assets/images/menu_update_password.png',
                    width: context.scaleWidth(380),
                    height: context.scaleHeight(62),
                    fit: BoxFit.fill,
                  ),
                ),
              ),

              // Text "Link to connect with Apps"
              Positioned(
                top: context.scaleHeight(592),
                left: context.scaleWidth(110), 
                child: Text(
                  'Link to connect with Apps',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Colors.black, 
                  ),
                ),
              ),

              // sosmed logo group
              Positioned(
                top: context.scaleHeight(643), 
                left: context.scaleWidth(103), 
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ellipse_instagram.png + instagram_logo.png
                    _buildSocialMediaIcon(
                      context,
                      'assets/images/ellipse_instagram.png',
                      'assets/images/instagram_logo.png',
                      () {
                        print('Instagram tapped');
                      },
                      Colors.orange, 
                    ),
                    SizedBox(width: context.scaleWidth(20)),
                    _buildSocialMediaIcon(
                      context,
                      'assets/images/ellipse_twitter.png',
                      'assets/images/twitter_logo.png',
                      () {
                        print('Twitter tapped');
                      },
                      Colors.blue,
                    ),
                    SizedBox(width: context.scaleWidth(20)),
                    // 13. ellipse_facebook.png + facebook_logo.png
                    _buildSocialMediaIcon(
                      context,
                      'assets/images/ellipse_facebook.png',
                      'assets/images/facebook_logo.png',
                      () {
                        print('Facebook tapped');
                      },
                      Colors.indigo, 
                    ),
                  ],
                ),
              ),

              // frame putih bottom
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
                          print('Already on Profile Screen');
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

  // widget untuk logo sosmed
  Widget _buildSocialMediaIcon(
    BuildContext context,
    String ellipseAsset,
    String logoAsset,
    VoidCallback onTap,
    Color ellipseColor, 
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ellipse 
          Image.asset(
            ellipseAsset,
            width: context.scaleWidth(62),
            height: context.scaleHeight(62), 
            fit: BoxFit.contain,
          ),
          Image.asset(
            logoAsset,
            width: context.scaleWidth(34), 
            height: context.scaleHeight(34), 
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}