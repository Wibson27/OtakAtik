// lib/screens/general_timezone_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/common/app_color.dart';
import 'package:frontend/common/app_route.dart';
import 'package:frontend/common/screen_utils.dart';
import 'package:timezone/timezone.dart' as tz; 
import 'package:intl/intl.dart'; 

class GeneralTimeZoneScreen extends StatefulWidget {
  const GeneralTimeZoneScreen({super.key});

  @override
  State<GeneralTimeZoneScreen> createState() => _GeneralTimeZoneScreenState();
}

class _GeneralTimeZoneScreenState extends State<GeneralTimeZoneScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _allTimeZones = [];
  List<String> _filteredTimeZones = [];

  @override
  void initState() {
    super.initState();
    _loadTimeZones();
    _searchController.addListener(_filterTimeZones);
  }

  void _loadTimeZones() {
    // Ambil semua time zones dari database timezone
    _allTimeZones = tz.timeZoneDatabase.locations.keys.toList();
    // Urutkan sesuai abjad
    _allTimeZones.sort();
    _filteredTimeZones = List.from(_allTimeZones);
  }

  void _filterTimeZones() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredTimeZones = _allTimeZones.where((tzId) {
        return tzId.toLowerCase().contains(query) ||
               _extractCityName(tzId).toLowerCase().contains(query);
      }).toList();
    });
  }

  String _extractCityName(String tzId) {
    List<String> parts = tzId.split('/');
    String city = parts.last.replaceAll('_', ' ');
    return city;
  }

  String _formatDate(tz.TZDateTime dateTime) {
    return DateFormat('M/d/yyyy').format(dateTime); 
  }

  String _formatTime(tz.TZDateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime); 
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterTimeZones);
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

              // Text 'Time Zone' 
              Positioned(
                top: context.scaleHeight(35),
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'Time Zone',
                    style: GoogleFonts.roboto(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColor.putihNormal,
                    ),
                  ),
                ),
              ),

              // Search Bar + Daftar Time Zone from pub.dev
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

                    // Daftar Time Zone bisa di scroll from pubdev
                    Expanded(
                      child: ListView.builder(
                        itemCount: _filteredTimeZones.length,
                        itemBuilder: (context, index) {
                          final tzId = _filteredTimeZones[index];
                          final location = tz.getLocation(tzId);
                          final nowInLocation = tz.TZDateTime.now(location);
                          final cityName = _extractCityName(tzId);
                          final formattedDate = _formatDate(nowInLocation);
                          final formattedTime = _formatTime(nowInLocation);

                          return Padding(
                            padding: EdgeInsets.only(bottom: context.scaleHeight(15)),
                            child: GestureDetector( 
                              onTap: () {
                                Navigator.pop(context, tzId);
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
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        cityName,
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            formattedDate,
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w400,
                                              color: Colors.black.withOpacity(0.7),
                                            ),
                                          ),
                                          SizedBox(width: context.scaleWidth(10)),
                                          Text(
                                            formattedTime,
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w400,
                                              color: Colors.black.withOpacity(0.7),
                                            ),
                                          ),
                                        ],
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