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

  /// Fungsi untuk memulai sesi chat baru via API dan navigasi ke chatbot.
  void _startChat() async {
    if (_isLoading) return; // 🔧 PERBAIKAN: Prevent double-tap

    setState(() => _isLoading = true);

    try {
      print("📤 Starting new chat session...");

      // Panggil API untuk membuat sesi baru
      final newSession = await _chatService.createChatSession();

      print("✅ Chat session created: ${newSession.id}");

      if (mounted) {
        // 🔧 PERBAIKAN: Validasi session ID sebelum navigasi
        if (newSession.id.isNotEmpty) {
          Navigator.pushNamed(
            context,
            AppRoute.chatbot,
            arguments: newSession.id,
          );
        } else {
          throw Exception("Session ID kosong");
        }
      }
    } catch (e) {
      print("❌ Error starting chat: $e");

      if (mounted) {
        // 🔧 PERBAIKAN: Error message yang lebih user-friendly
        String errorMessage = "Gagal memulai chat";

        if (e.toString().contains('Sesi tidak valid')) {
          errorMessage = "Sesi login tidak valid. Silakan login ulang.";
        } else if (e.toString().contains('network') || e.toString().contains('connection')) {
          errorMessage = "Masalah koneksi internet. Silakan coba lagi.";
        } else {
          errorMessage = "Gagal memulai chat. Silakan coba lagi.";
        }

        AppInfo.error(context, errorMessage);
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
              // Background
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

              // Menu buttons
              Positioned(
                top: context.scaleHeight(224),
                left: 0,
                right: 0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Forum Discussion
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

                    // Voice Sentiment
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

                    // Chatbot - 🔧 PERBAIKAN: Better interaction feedback
                    GestureDetector(
                      onTap: _isLoading ? null : _startChat,
                      child: Stack(
                        children: [
                          // 🔧 PERBAIKAN: Opacity saat loading
                          Opacity(
                            opacity: _isLoading ? 0.6 : 1.0,
                            child: Image.asset(
                              'assets/images/menu_chatbot.png',
                              width: context.scaleWidth(213),
                              height: context.scaleHeight(90),
                              fit: BoxFit.fill,
                            ),
                          ),

                          // 🔧 PERBAIKAN: Loading indicator overlay
                          if (_isLoading)
                            Positioned.fill(
                              child: Center(
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.0,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColor.putihNormal,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom navigation
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

              // Home button
              Positioned(
                bottom: context.scaleHeight(23),
                left: context.scaleWidth(107),
                child: GestureDetector(
                  onTap: () {
                    // Already on dashboard, no action needed
                  },
                  child: Image.asset(
                    'assets/images/home_button.png',
                    width: context.scaleWidth(46),
                    height: context.scaleHeight(50),
                  ),
                ),
              ),

              // Profile button
              Positioned(
                bottom: context.scaleHeight(16),
                right: context.scaleWidth(76),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, AppRoute.profile);
                  },
                  child: Image.asset(
                    'assets/images/profile_button.png',
                    width: context.scaleWidth(68),
                    height: context.scaleHeight(68),
                  ),
                ),
              ),

              // 🔧 PERBAIKAN: Loading overlay yang lebih baik
              if (_isLoading)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.all(context.scaleWidth(20)),
                      decoration: BoxDecoration(
                        color: AppColor.putihNormal,
                        borderRadius: BorderRadius.circular(context.scaleWidth(12)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColor.hijauTosca,
                            ),
                          ),
                          SizedBox(height: context.scaleHeight(12)),
                          Text(
                            'Memulai sesi chat...',
                            style: GoogleFonts.fredoka(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColor.navyText,
                            ),
                          ),
                        ],
                      ),
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