import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/common/app_color.dart';
import 'package:frontend/common/app_route.dart';
import 'package:frontend/common/screen_utils.dart';

class ForumDiscussionScreen extends StatelessWidget {
  const ForumDiscussionScreen({super.key});

  // sample data (nanti diganti backend)
  final List<Map<String, String>> discussionTopics = const [
    {
      'id': 'disc_001',
      'title': 'Susah Bangun Pagi dan Merasa Tidak Semangat, Ada yang Punya Tips?',
      'description': 'Akhir-akhir ini sering banget ngalamin lesu',
    },
    {
      'id': 'disc_002',
      'title': 'Cara Mengatasi Kecemasan Saat Berinteraksi Sosial?',
      'description': 'Setiap kali harus ketemu orang banyak atau presentasi',
    },
    {
      'id': 'disc_003',
      'title': 'Merasa Kesepian Meskipun Dikelilingi Banyak Orang',
      'description': 'Akhir-akhir ini sering banget ngalamin lesu',
    },
    {
      'id': 'disc_004',
      'title': 'Mencari Jalur Karir Baru Setelah Resign, Butuh Masukan!',
      'description': 'Baru saja resign dari pekerjaan sebelumnya dan',
    },
    {
      'id': 'disc_005',
      'title': 'Tips Meningkatkan Produktivitas Saat WFH?',
      'description': 'Sejak WFH kadang suka hilang fokus dan',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = context.screenWidth;
    final screenHeight = context.screenHeight;

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
            width: screenWidth, 
            height: screenHeight, 
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Image.asset(
            'assets/images/blur_top.png',
            width: screenWidth, 
            height: context.scaleHeight(88),
            fit: BoxFit.fill,
          ),
        ),
        Positioned(
          top: context.scaleHeight(16),
          left: context.scaleWidth(8),
          child: GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: SizedBox(
              width: context.scaleWidth(66),
              height: context.scaleHeight(66),
              child: Image.asset(
                'assets/images/arrow.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        Positioned(
          top: context.scaleHeight(16),
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              'Forum Discuss',
              style: GoogleFonts.fredoka(
                color: AppColor.navyText,
                fontSize: context.scaleWidth(24),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        Positioned(
          top: context.scaleHeight(94),
          left: context.scaleWidth(40),
          right: context.scaleWidth(41),
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
                      bottom: index == discussionTopics.length - 1 ? context.scaleHeight(20) : context.scaleHeight(12),
                    ),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoute.forumDiscussDetail,
                          arguments: {'discussionId': topic['id']}, 
                        );
                      },
                      child: _buildDiscussionCard(
                        topic['title']!,
                        topic['description']!,
                        context, 
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

  Widget _buildDiscussionCard(String title, String description, BuildContext context) {
    return Container(
      width: context.scaleWidth(348), 
      decoration: BoxDecoration(
        color: AppColor.hijauTosca.withOpacity(0.8),
        borderRadius: BorderRadius.circular(context.scaleWidth(18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: context.scaleWidth(8),
            offset: Offset(0, context.scaleHeight(4)),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(context.scaleWidth(15.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(context.scaleWidth(6)),
              decoration: BoxDecoration(
                color: AppColor.putihNormal,
                borderRadius: BorderRadius.circular(context.scaleWidth(3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: context.scaleWidth(4),
                    offset: Offset(0, context.scaleHeight(2)),
                  ),
                ],
              ),
              child: Text(
                title,
                style: GoogleFonts.fredoka(
                  color: AppColor.navyText,
                  fontSize: context.scaleWidth(20),
                  fontWeight: FontWeight.w400,
                  height: 1.2,
                ),
                textAlign: TextAlign.left,
              ),
            ),
            SizedBox(height: context.scaleHeight(12)),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(context.scaleWidth(6)),
              margin: EdgeInsets.only(left: context.scaleWidth(17)),
              decoration: BoxDecoration(
                color: AppColor.putihNormal,
                borderRadius: BorderRadius.circular(context.scaleWidth(3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: context.scaleWidth(4),
                    offset: Offset(0, context.scaleHeight(2)),
                  ),
                ],
              ),
              child: Text(
                description,
                style: GoogleFonts.fredoka(
                  color: AppColor.navyText,
                  fontSize: context.scaleWidth(12),
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