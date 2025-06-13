import 'package:flutter/material.dart';
import 'package:frontend/screens/chatbot_screen.dart';
import 'package:frontend/screens/dashboard_screen.dart';
import 'package:frontend/screens/forum_discussion_post_screen.dart'; // 1. PASTIKAN HALAMAN BARU DI-IMPORT
import 'package:frontend/screens/sign_in_screen.dart';
import 'package:frontend/screens/splash_screen.dart';

class AppRoute {
  static const String splash = '/';
  static const String signIn = '/signin';
  static const String signUp = '/signup';
  static const String dashboard = '/dashboard';
  static const String profile = '/profile';
  static const String profileEdit = '/profile-edit';
  static const String settings = '/settings';
  static const String forumDiscussList = '/forum-discuss';
  static const String forumDiscussPost = '/forum-discuss-post';
  static const String forumDiscussDetail = '/forum-discuss-detail';
  static const String voiceSentiment = '/voice-sentiment';
  static const String voiceSentimentHistory = '/voice-sentiment/history';
  static const String chatbot = '/chatbot';
  static const String chatbotHistory = '/chatbot/history';
  static const String feedback = '/feedback';
  static const String notificationSettings = '/settings/notifications';
  static const String generalSettings = '/settings/general';
  static const String timeZone = '/settings/general/timezone';
  static const String language = '/settings/general/language';
}


Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case AppRoute.splash:
      return MaterialPageRoute(builder: (_) => const SplashScreen());

    case AppRoute.signIn:
      return MaterialPageRoute(builder: (_) => const SignInScreen());

    case AppRoute.dashboard:
      return MaterialPageRoute(builder: (_) => const DashboardScreen());

    case AppRoute.chatbot:
      final sessionId = settings.arguments as String? ?? '';
      return MaterialPageRoute(builder: (_) => ChatbotScreen(initialSessionId: sessionId));

    // --- INI ADALAH LOGIKA YANG HILANG ---
    case AppRoute.forumDiscussPost:
      // Pastikan argumen yang dikirim adalah String (yaitu post.id)
      if (settings.arguments is String) {
        final postId = settings.arguments as String;
        // Buka halaman ForumDiscussionPostScreen dengan postId yang diterima
        return MaterialPageRoute(
          builder: (_) => ForumDiscussionPostScreen(postId: postId),
        );
      }
      // Jika argumen tidak valid, tampilkan halaman error
      return _errorRoute("Argumen untuk forumDiscussPost tidak valid");

    default:
      return _errorRoute("Rute tidak ditemukan: ${settings.name}");
  }
}

// Fungsi bantuan untuk menampilkan halaman error
Route<dynamic> _errorRoute(String message) {
  return MaterialPageRoute(
    builder: (_) => Scaffold(
      appBar: AppBar(title: const Text('Error Navigasi')),
      body: Center(
        child: Text(message),
      ),
    ),
  );
}