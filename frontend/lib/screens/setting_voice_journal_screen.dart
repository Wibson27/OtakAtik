import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/common/app_color.dart';
import 'package:frontend/common/app_route.dart';
import 'package:frontend/common/screen_utils.dart';

class SettingVoiceJournalScreen extends StatefulWidget {
  const SettingVoiceJournalScreen({super.key});

  @override
  State<SettingVoiceJournalScreen> createState() => _SettingVoiceJournalScreenState();
}

class _SettingVoiceJournalScreenState extends State<SettingVoiceJournalScreen> {
  bool _enableTranscriptionEnabled = true; 
  bool _saveVoiceEnabled = true; 

  Widget _buildToggleItem(
    BuildContext context,
    String assetPath, 
    bool isEnabled,
    ValueSetter<bool> onChanged,
  ) {
    return GestureDetector(
      onTap: () {
        onChanged(!isEnabled); 
      },
      child: Container(
        width: context.scaleWidth(380),
        height: context.scaleHeight(62),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                assetPath,
                fit: BoxFit.fill,
              ),
            ),
            // Toggle
            Positioned(
              right: context.scaleWidth(15), 
              top: 0,
              bottom: 0,
              child: Center(
                child: SizedBox( 
                  width: context.scaleWidth(46), 
                  height: context.scaleHeight(29), 
                  child: Switch(
                    value: isEnabled,
                    onChanged: onChanged, 
                    activeColor: AppColor.putihNormal, 
                    activeTrackColor: AppColor.hijauToggle, 
                    inactiveThumbColor: AppColor.putihNormal, 
                    inactiveTrackColor: AppColor.abuAbuNormal,
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

              // Text 'Voice Journal' 
              Positioned(
                top: context.scaleHeight(35),
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'Voice Journal',
                    style: GoogleFonts.roboto(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColor.putihNormal,
                    ),
                  ),
                ),
              ),

              // menu voice journal
              Positioned(
                top: context.scaleHeight(230), 
                left: context.scaleWidth(25),
                right: context.scaleWidth(25),
                child: Column(
                  children: [
                    SizedBox(height: context.scaleHeight(20)), 
                    _buildToggleItem(
                      context,
                      'assets/images/menu_enable_transcription.png', 
                      _enableTranscriptionEnabled,
                      (bool newValue) {
                        setState(() {
                          _enableTranscriptionEnabled = newValue;
                        });
                        print('Enable Transcription: $newValue');
                      },
                    ),
                    SizedBox(height: context.scaleHeight(20)),
                    _buildToggleItem(
                      context,
                      'assets/images/menu_save_voice.png',
                      _saveVoiceEnabled,
                      (bool newValue) {
                        setState(() {
                          _saveVoiceEnabled = newValue;
                        });
                        print('Save Voice: $newValue');
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