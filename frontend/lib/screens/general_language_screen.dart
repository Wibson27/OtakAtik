import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/common/app_color.dart';
import 'package:frontend/common/app_route.dart';
import 'package:frontend/common/screen_utils.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart'; 

class GeneralLanguageScreen extends StatefulWidget {
  const GeneralLanguageScreen({super.key});

  @override
  State<GeneralLanguageScreen> createState() => _GeneralLanguageScreenState();
}

class _GeneralLanguageScreenState extends State<GeneralLanguageScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _allLanguageCodes = []; 
  List<String> _filteredLanguageCodes = []; 
  late Map<String, String> _languageNamesMap; 

  @override
  void initState() {
    super.initState();
    _loadLanguages();
    _searchController.addListener(_filterLanguages);
  }

  void _loadLanguages() {
    _languageNamesMap = LocaleNamesLocalizationsDelegate.nativeLocaleNames;

    _allLanguageCodes = _languageNamesMap.keys.toList();
    // Urut alfabet berdasarkan nama bahasa
    _allLanguageCodes.sort((a, b) => (_languageNamesMap[a] ?? '').compareTo(_languageNamesMap[b] ?? ''));

    _filteredLanguageCodes = List.from(_allLanguageCodes);
  }

  void _filterLanguages() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredLanguageCodes = _allLanguageCodes.where((isoCode) {
        final languageName = _languageNamesMap[isoCode]?.toLowerCase() ?? '';
        return languageName.contains(query) || isoCode.toLowerCase().contains(query);
      }).toList();
    });
  }

  // untuk mendapatkan nama bahasa dari kode ISO
  String _getLanguageDisplayName(String isoCode) {
    return _languageNamesMap[isoCode] ?? isoCode; 
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterLanguages);
    _searchController.dispose();
    super.dispose();
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

              // Text 'Language' 
              Positioned(
                top: context.scaleHeight(35),
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'Language',
                    style: GoogleFonts.roboto(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColor.putihNormal,
                    ),
                  ),
                ),
              ),

              // Search Bar dan Daftar Bahasa
              Positioned(
                top: context.scaleHeight(130),
                left: context.scaleWidth(25),
                right: context.scaleWidth(25),
                bottom: context.scaleHeight(100),
                child: Column(
                  children: [
                    // Search Bar
                    Container(
                      width: double.infinity,
                      height: context.scaleHeight(50),
                      decoration: BoxDecoration(
                        color: AppColor.putihNormal,
                        borderRadius: BorderRadius.circular(context.scaleWidth(25)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: TextFormField(
                          controller: _searchController,
                          textAlignVertical: TextAlignVertical.center,
                          style: GoogleFonts.inter(
                            color: Colors.black,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search',
                            hintStyle: GoogleFonts.inter(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                            prefixIcon: Icon(Icons.search, color: Colors.grey, size: context.scaleWidth(24)),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: context.scaleWidth(10)),
                            isDense: true,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: context.scaleHeight(20)),

                    // Daftar Bahasa (bisa scroll)
                    Expanded(
                      child: ListView.builder(
                        itemCount: _filteredLanguageCodes.length,
                        itemBuilder: (context, index) {
                          final isoCode = _filteredLanguageCodes[index];
                          final languageDisplayName = _getLanguageDisplayName(isoCode);

                          return Padding(
                            padding: EdgeInsets.only(bottom: context.scaleHeight(15)),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.pop(context, isoCode);
                              },
                              child: Container(
                                width: double.infinity,
                                height: context.scaleHeight(62),
                                decoration: BoxDecoration(
                                  color: AppColor.putihNormal,
                                  borderRadius: BorderRadius.circular(context.scaleWidth(18)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.25),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: context.scaleWidth(20)),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text(
                                        languageDisplayName,
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
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