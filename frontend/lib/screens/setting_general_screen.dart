import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/common/app_color.dart';
import 'package:frontend/common/app_route.dart';
import 'package:frontend/common/screen_utils.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';

class SettingGeneralScreen extends StatefulWidget {
  const SettingGeneralScreen({super.key});

  @override
  State<SettingGeneralScreen> createState() => _SettingGeneralScreenState();
}

class _SettingGeneralScreenState extends State<SettingGeneralScreen> {
  String? _selectedTimeZoneId;
  String _selectedTimeZoneDisplayName = 'Not Set';

  String? _selectedLanguageCode;
  String _selectedLanguageDisplayName = 'English'; // default

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeTimeZone();
      _initializeLanguage();
    });
  }

  void _initializeTimeZone() async {
    final localTimeZone = tz.local;
    setState(() {
      _selectedTimeZoneId = localTimeZone.name;
      _selectedTimeZoneDisplayName = _formatTimeZoneDisplay(localTimeZone.name);
    });
  }

  void _initializeLanguage() {
    final String defaultLocaleCode = WidgetsBinding.instance.window.locale?.languageCode ?? 'en';
    setState(() {
      _selectedLanguageCode = defaultLocaleCode;
      _selectedLanguageDisplayName = LocaleNames.of(context)!.nameOf(defaultLocaleCode) ?? defaultLocaleCode;
    });
  }

  // untuk ambil nama bahasa dari kode ISO menggunakan package 'flutter_localized_locales'
  String _getLanguageDisplayNameFromCode(String isoCode) {
    return LocaleNames.of(context)!.nameOf(isoCode) ?? isoCode; 
  }

  String _formatTimeZoneDisplay(String tzId) {
    try {
      final location = tz.getLocation(tzId);
      final nowInLocation = tz.TZDateTime.now(location);
      final cityName = _extractCityName(tzId);
      final formattedTime = DateFormat('h:mm a').format(nowInLocation);
      return '$cityName ($formattedTime)';
    } catch (e) {
      return tzId;
    }
  }

  String _extractCityName(String tzId) {
    List<String> parts = tzId.split('/');
    String city = parts.last.replaceAll('_', ' ');
    return city;
  }

  Widget _buildGeneralMenuItem(
    BuildContext context,
    String assetPath,
    String text,
    VoidCallback onTap,
    {String? subText}
  ) {
    return GestureDetector(
      onTap: onTap,
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
            if (subText != null && subText.isNotEmpty && (text == 'Time Zone' || text == 'Language'))
              Positioned(
                right: context.scaleWidth(35),
                top: 0,
                bottom: 0,
                child: Center(
                  child: Text(
                    subText,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.black.withOpacity(0.7),
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

              // Text 'General' 
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

              // Daftar menu general - ada 3 (Time Zone, Language, About Application)
              Positioned(
                top: context.scaleHeight(230), 
                left: context.scaleWidth(25),
                right: context.scaleWidth(25),
                child: Column(
                  children: [
                    SizedBox(height: context.scaleHeight(20)),
                    _buildGeneralMenuItem(
                      context,
                      'assets/images/menu_timezone.png',
                      'Time Zone',
                      () async {
                        final result = await Navigator.pushNamed(context, AppRoute.timeZone);
                        if (result != null && result is String) {
                          setState(() {
                            _selectedTimeZoneId = result;
                            _selectedTimeZoneDisplayName = _formatTimeZoneDisplay(result);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Zona waktu diatur ke $_selectedTimeZoneDisplayName'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        }
                      },
                      subText: _selectedTimeZoneDisplayName,
                    ),
                    SizedBox(height: context.scaleHeight(20)),
                    _buildGeneralMenuItem(
                      context,
                      'assets/images/menu_language.png',
                      'Language',
                      () async {
                        final result = await Navigator.pushNamed(context, AppRoute.language);
                        if (result != null && result is String) {
                          setState(() {
                            _selectedLanguageCode = result;
                            _selectedLanguageDisplayName = _getLanguageDisplayNameFromCode(result);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Bahasa diatur ke $_selectedLanguageDisplayName'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        }
                      },
                      subText: _selectedLanguageDisplayName,
                    ),
                    SizedBox(height: context.scaleHeight(20)),
                    _buildGeneralMenuItem(
                      context,
                      'assets/images/menu_about_application.png',
                      'About Application',
                      () {
                        print('About Application Tapped');
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