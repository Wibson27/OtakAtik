import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ForumDiscussionPostScreen extends StatelessWidget {
  const ForumDiscussionPostScreen({Key? key}) : super(key: key);

  // Sample data 
  final String discussionTitle = "Susah Bangun Pagi dan Merasa Tidak Semangat, Ada yang Punya Tips?";
  final String discussionQuestion = "Akhir-akhir ini sering ngalamin lesu pagi-pagi, padahal udah tidur awal tapi tetep aja susah bangun. Kadang sampe alarm udah bunyi berkali-kali baru bisa bangun, terus pas bangun badan tu lemes dan ga semangat buat mulai hari. Ada yang punya pengalaman serupa? Gimana cara ngatasinnya ya? Mungkin ada tips?";
  
  final List<Map<String, String>> discussionMessages = const [
    {
      'text': 'Aku banget ini! Kadang sampe telat kerja karena susah bangun. Coba deh sleep hygiene-nya diperbaiki dulu, kayak matiin gadget 1 jam sebelum tidur. Terus juga coba atur jadwal tidur yang konsisten setiap hari.',
      'isOwner': 'true',
    },
    {
      'text': 'Setuju sama yang di atas! Plus coba rutin olahraga ringan sore hari, ngaruh banget ke kualitas tidur. Terus jangan lupa sarapan yang bergizi. Aku dulu juga gitu, tapi setelah rutin olahraga dan makan teratur, sekarang udah lebih gampang bangun pagi.',
      'isOwner': 'false',
    },
    {
      'text': 'Aku pake teknik 5 detik rule pas alarm bunyi langsung berdiri. Awalnya susah tapi lama-lama jadi kebiasaan. Sama lamp yang simulasi sunrise juga membantu! Oh iya, coba juga taruh alarm jauh dari tempat tidur biar terpaksa bangun.',
      'isOwner': 'false',
    },
    {
      'text': 'Wah makasih semuanya! Aku coba deh step by step. Semoga bisa konsisten ngjalanin tipsnya 🙏 Bakal aku update lagi nanti gimana hasilnya.',
      'isOwner': 'true',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    
    return Scaffold(
      backgroundColor: Colors.transparent,
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
        // Background blur
        _buildBlurBackground(),
        
        // Scroll content area
        _buildScrollableContent(context),
        
        // Bottom message input
        _buildBottomMessageArea(),
        
        // Arrow button 
        _buildArrowButton(context),
      ],
    );
  }

  Widget _buildBlurBackground() {
    return Positioned.fill(
      child: Image.asset(
        'assets/images/blur_background.png',
        width: 430,
        height: 931,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildScrollableContent(BuildContext context) {
    return Positioned(
      top: 111,
      left: 41,
      right: 41,
      bottom: 74,
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          children: [
            _buildMainDiscussionCard(),
            const SizedBox(height: 10),
            ..._buildDiscussionMessages(),
            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }

  Widget _buildMainDiscussionCard() {
    return Container(
      width: 348,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/kotak_hijau_tosca.png'),
          fit: BoxFit.fill,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 19),
          
          // Title Section
          Padding(
            padding: const EdgeInsets.only(left: 15, right: 16),
            child: _buildTitleSection(),
          ),
          
          const SizedBox(height: 29),
          
          // Question Section  
          Padding(
            padding: const EdgeInsets.only(left: 15, right: 16),
            child: _buildQuestionSection(),
          ),
          
          const SizedBox(height: 14),
        ],
      ),
    );
  }

  Widget _buildTitleSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/title_box.png'),
          fit: BoxFit.fill,
        ),
      ),
      padding: const EdgeInsets.all(10),
      child: Text(
        discussionTitle,
        style: GoogleFonts.fredoka(
          fontSize: 18,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF001F3F),
        ),
        textAlign: TextAlign.left,
      ),
    );
  }

  Widget _buildQuestionSection() {
    return Container(
      width: 317,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/question_box.png'),
          fit: BoxFit.fill,
        ),
      ),
      child: Stack(
        children: [
          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              left: 10,
              right: 40, // Extra space untuk ellips
              top: 10,
              bottom: 10,
            ),
            child: Text(
              discussionQuestion,
              style: GoogleFonts.fredoka(
                fontSize: 11,
                fontWeight: FontWeight.w300,
                color: const Color(0xFF001F3F),
              ),
              textAlign: TextAlign.left,
            ),
          ),
          
          // Ellips 
          Positioned(
            right: 14,
            bottom: 6,
            child: Image.asset(
              'assets/images/ellips.png',
              width: 22,
              height: 6,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDiscussionMessages() {
    return discussionMessages.asMap().entries.map((entry) {
      final index = entry.key;
      final message = entry.value;
      final isOwner = message['isOwner'] == 'true';
      
      return Container(
        margin: EdgeInsets.only(
          bottom: index == discussionMessages.length - 1 ? 0 : 20,
        ),
        child: _buildDiscussionMessage(
          message['text']!,
          isOwner,
        ),
      );
    }).toList();
  }

  Widget _buildDiscussionMessage(String text, bool isOwner) {
    return Align(
      alignment: isOwner ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 250, 
          minWidth: 100,
        ),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              isOwner 
                ? 'assets/images/yellow_discussion_box.png'
                : 'assets/images/green_discussion_box.png'
            ),
            fit: BoxFit.fill,
          ),
        ),
        padding: const EdgeInsets.all(25),
        child: Text(
          text,
          style: GoogleFonts.fredoka(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF001F3F),
          ),
          textAlign: TextAlign.left,
        ),
      ),
    );
  }

  Widget _buildBottomMessageArea() {
    return Positioned(
      bottom: 16,
      left: 10,
      right: 10,
      child: Stack(
        children: [
          // message_box.png 
          Container(
            width: 417,
            height: 50,
            child: Image.asset(
              'assets/images/message_box.png',
              width: 300,
              height: 50,
              fit: BoxFit.contain,
            ),
          ),
          
          // happy_emoji.png
          Positioned(
            left: 14,
            top: 8,
            bottom: 8,
            child: Image.asset(
              'assets/images/happy_emoji.png',
              width: 34,
              height: 34,
            ),
          ),
          
          // paper_clip.png
          Positioned(
            left: 87,
            top: 9,
            bottom: 11,
            child: Image.asset(
              'assets/images/paper_clip.png',
              width: 30,
              height: 30,
            ),
          ),
          
          // polygon_button.png (send button)
          Positioned(
            right: 24,
            top: 8,
            bottom: 8,
            child: Container(
              child: Image.asset(
                'assets/images/polygon_button.png',
                width: 34,
                height: 32,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArrowButton(BuildContext context) {
    return Positioned(
      top: 16,
      left: 8,
      child: GestureDetector(
        onTap: () {
          Navigator.pop(context);
        },
        child: Image.asset(
          'assets/images/arrow.png',
          width: 66,
          height: 66,
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