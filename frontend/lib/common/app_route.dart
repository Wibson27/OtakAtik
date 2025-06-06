class AppRoute {
  // Autentikasi
  static const String signIn = '/signin';
  static const String signUp = '/signup';

  // Dashboard
  static const String dashboard = '/dashboard';

  // Forum Diskusi
  static const String forumDiscussList = '/forum-discuss';
  static const String forumDiscussDetail = '/forum-discuss-detail/:id';
  static const String createForumPost = '/forum-discuss/create';

  // Voice Sentiment
  static const String voiceSentiment = '/voice-sentiment';
  static const String voiceSentimentResult = '/voice-sentiment/result';
  static const String voiceSentimentHistory = '/voice-sentiment/history'; 

  // Chat Bot
  static const String chatBot = '/chatbot';
  static const String chatBotHistory = '/chatbot/history';

  // Profile dan Sub-fiturnya
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String settings = '/profile/settings'; 
  static const String feedback = '/profile/feedback';
  static const String updatePassword = '/profile/update-password';
}