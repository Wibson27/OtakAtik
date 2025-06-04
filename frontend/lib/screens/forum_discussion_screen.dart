import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ForumDiscussionScreen extends StatelessWidget {
  const ForumDiscussionScreen({Key? key}) : super(key: key);

  // Sample data untuk demonstrasi 
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
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: SizedBox(
          width: screenWidth,
          height: screenHeight,
          child: _buildMainContent(screenWidth, screenHeight),
        ),
      ),
    );
  }

  Widget _buildMainContent(double screenWidth, double screenHeight) {
    return Stack(
      children: [
        // Background kuning 
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
        
        // Blur top 
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
        
        // Arrow button 
        Positioned(
          top: 16,
          left: 8,
          child: Builder(
            builder: (BuildContext context) {
              return GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Container(
                  width: 66,
                  height: 66,
                  child: Image.asset(
                    'assets/images/arrow.png',
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          ),
        ),
        
        // Title "Forum Discuss" 
        Positioned(
          top: 16,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              'Forum Discuss',
              style: GoogleFonts.fredoka(
                color: const Color(0xFF001F3F),
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        
        // Scroll
        Positioned(
          top: 94, // 88 (blur_top height) + 6 (spacing)
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
                    child: _buildDiscussionCard(
                      topic['title']!,
                      topic['description']!,
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Fungsi untuk card
  Widget _buildDiscussionCard(String title, String description) {
    return Container(
      width: 348,
      decoration: BoxDecoration(
        color: const Color(0xFF6EBAB3),
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
            // Kotak putih besar (untuk title)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
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
                  color: const Color(0xFF001F3F),
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  height: 1.2,
                ),
                textAlign: TextAlign.left,
              ),
            ),
            
            const SizedBox(height: 12), 
            
            // Container putih kecil (untuk description)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(6),
              margin: const EdgeInsets.only(left: 17), 
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
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
                  color: const Color(0xFF001F3F),
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

// Extension untuk responsive design 
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