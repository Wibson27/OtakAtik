import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/common/app_info.dart';
import 'package:frontend/data/services/chat_service.dart';
import 'package:frontend/common/app_color.dart';
import 'package:frontend/common/app_route.dart';
import 'package:frontend/common/screen_utils.dart';
import 'package:frontend/screens/profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _chatService = ChatService();
  bool _isLoading = false;

  // Fungsi untuk memulai sesi chat dan navigasi
  void _startChat() async {
    setState(() => _isLoading = true);
    try {
      // Panggil API untuk membuat sesi baru
      final newSession = await _chatService.createChatSession();
      if (mounted) {
        // Kirim ID sesi ke halaman chatbot
        Navigator.pushNamed(context, AppRoute.chatbot, arguments: newSession.id);
      }
    } catch (e) {
      if (mounted) {
        AppInfo.error(context, "Gagal memulai chat: ${e.toString()}");
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Image.asset(
                  'assets/images/wave_dashboard_background.png',
                  width: screenWidth,
                  height: context.scaleHeight(832.9),
                  fit: BoxFit.fill,
                ),
              ),
              Positioned(
                top: context.scaleHeight(224),
                left: 0,
                right: 0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, AppRoute.forumDiscussList);
                      },
                      child: Image.asset(
                        'assets/images/menu_forum_discussion.png',
                        width: context.scaleWidth(213),
                        height: context.scaleHeight(90),
                        fit: BoxFit.fill,
                      ),
                    ),
                    SizedBox(height: context.scaleHeight(43)),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, AppRoute.voiceSentiment);
                      },
                      child: Image.asset(
                        'assets/images/menu_voice_sentiment.png',
                        width: context.scaleWidth(213),
                        height: context.scaleHeight(90),
                        fit: BoxFit.fill,
                      ),
                    ),
                    SizedBox(height: context.scaleHeight(43)),
                    GestureDetector(
                    onTap: _isLoading ? null : _startChat, // Panggil fungsi _startChat
                    child: Image.asset(
                      'assets/images/menu_chatbot.png',
                      width: context.scaleWidth(213),
                      height: context.scaleHeight(90),
                      fit: BoxFit.fill,
                    ),
                  ),
                  ],
                ),
              ),
              // Navigation bawah
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
                ),
              ),
              Positioned(
                bottom: context.scaleHeight(23),
                left: context.scaleWidth(107),
                child: GestureDetector(
                  onTap: () {

                  },
                  child: Image.asset(
                    'assets/images/home_button.png',
                    width: context.scaleWidth(46),
                    height: context.scaleHeight(50),
                  ),
                ),
              ),
              Positioned(
                bottom: context.scaleHeight(16),
                right: context.scaleWidth(76),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, AppRoute.profile); //
                  },
                  child: Image.asset(
                    'assets/images/profile_button.png',
                    width: context.scaleWidth(68),
                    height: context.scaleHeight(68),
                  ),
                ),
              ),
              // Tambahkan loading overlay
              if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}