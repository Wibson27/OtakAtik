import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/common/app_color.dart'; 
import 'package:frontend/common/app_route.dart'; 

class ForumDiscussionScreen extends StatelessWidget {
  const ForumDiscussionScreen({super.key});

  // Sample data 
  final List<Map<String, String>> discussionTopics = const [
    {
      'title': 'Susah Bangun Pagi dan Merasa Tidak Semangat, Ada yang Punya Tips?',
      'description': 'Akhir-akhir ini sering banget ngalamin lesu',
    },
    {
      'title': 'Cara Mengatasi Kecemasan Saat Berinteraksi Sosial?',
      'description': 'Setiap kali harus ketemu orang banyak atau presentasi',
    },
    {
      'title': 'Merasa Kesepian Meskipun Dikelilingi Banyak Orang',
      'description': 'Akhir-akhir ini sering banget ngalamin lesu',
    },
    {
      'title': 'Mencari Jalur Karir Baru Setelah Resign, Butuh Masukan!',
      'description': 'Baru saja resign dari pekerjaan sebelumnya dan',
    },
    {
      'title': 'Tips Meningkatkan Produktivitas Saat WFH?',
      'description': 'Sejak WFH kadang suka hilang fokus dan',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    return Scaffold(
      backgroundColor: AppColor.putihNormal, 
      body: SafeArea(
        child: SizedBox(
          width: screenWidth,
          height: screenHeight,
          child: _buildMainContent(context, screenWidth, screenHeight), 
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, double screenWidth, double screenHeight) {
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          child: Image.asset(
            'assets/images/yellow_background.png',
            width: 931,
            height: 471,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Image.asset(
            'assets/images/blur_top.png',
            width: 429,
            height: 88,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 16,
          left: 8,
          child: GestureDetector(
            onTap: () {
              Navigator.pop(context); 
            },
            child: SizedBox(
              width: 66,
              height: 66,
              child: Image.asset(
                'assets/images/arrow.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        Positioned(
          top: 16,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              'Forum Discuss',
              style: GoogleFonts.fredoka(
                color: AppColor.navyText, 
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        Positioned(
          top: 94,
          left: 40,
          right: 41,
          bottom: 0,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              children: [
                ...discussionTopics.asMap().entries.map((entry) {
                  final index = entry.key;
                  final topic = entry.value;
                  return Container(
                    margin: EdgeInsets.only(
                      bottom: index == discussionTopics.length - 1 ? 20 : 12,
                    ),
                    child: GestureDetector( 
                      onTap: () {
                        // navigasi ke detail post (dengan id)
                        Navigator.pushNamed(context, AppRoute.forumDiscussDetail);
                      },
                      child: _buildDiscussionCard(
                        topic['title']!,
                        topic['description']!,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDiscussionCard(String title, String description) {
    return Container(
      width: 348,
      decoration: BoxDecoration(
        color: AppColor.hijauTosca.withOpacity(0.8), 
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColor.putihNormal,
                borderRadius: BorderRadius.circular(3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                title,
                style: GoogleFonts.fredoka(
                  color: AppColor.navyText, 
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  height: 1.2,
                ),
                textAlign: TextAlign.left,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(6),
              margin: const EdgeInsets.only(left: 17),
              decoration: BoxDecoration(
                color: AppColor.putihNormal,
                borderRadius: BorderRadius.circular(3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                description,
                style: GoogleFonts.fredoka(
                  color: AppColor.navyText, 
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  height: 1.2,
                ),
                textAlign: TextAlign.left,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension ScreenUtils on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;

  double scaleWidth(double figmaWidth) {
    return (screenWidth / 430.25) * figmaWidth;
  }

  double scaleHeight(double figmaHeight) {
    return (screenHeight / 932) * figmaHeight;
  }
}