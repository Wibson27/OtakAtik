import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/screens/profile_feedback_screen.dart';
import 'package:frontend/screens/profile_setting_screen.dart';
import 'package:frontend/screens/setting_general_screen.dart';
import 'package:frontend/screens/setting_notification_screen.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:frontend/common/app_color.dart';
import 'package:frontend/common/app_route.dart';
import 'package:frontend/presentation/bloc/user/user_cubit.dart';
import 'package:frontend/screens/splash_screen.dart';
import 'package:frontend/screens/sign_up_screen.dart';
import 'package:frontend/screens/sign_in_screen.dart';
import 'package:frontend/screens/dashboard_screen.dart';
import 'package:frontend/screens/forum_discussion_screen.dart';
import 'package:frontend/screens/voice_recorder_screen.dart';
import 'package:frontend/screens/chatbot_screen.dart';
import 'package:frontend/screens/history_screen.dart';
import 'package:frontend/screens/profile_screen.dart';
import 'package:frontend/screens/profile_edit_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then(
    (_) {
      runApp(const MyApp());
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<UserCubit>(
          create: (context) => UserCubit(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.light,
        title: 'Tenang.in',
        theme: ThemeData.light(useMaterial3: true).copyWith(
          primaryColor: AppColor.hijauTosca,
          colorScheme: const ColorScheme.light(
            primary: AppColor.hijauTosca,
            secondary: AppColor.kuning,
          ),
          scaffoldBackgroundColor: AppColor.putihNormal,
          textTheme: GoogleFonts.poppinsTextTheme(), 
          appBarTheme: AppBarTheme(
            surfaceTintColor: AppColor.hijauTosca,
            backgroundColor: AppColor.hijauTosca,
            foregroundColor: AppColor.whiteText,
            titleTextStyle: GoogleFonts.fredoka(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: AppColor.whiteText,
            ),
          ),
          popupMenuTheme: const PopupMenuThemeData(
            color: AppColor.putihNormal,
            surfaceTintColor: AppColor.putihNormal,
          ),
          dialogTheme: const DialogThemeData(
            surfaceTintColor: AppColor.putihNormal,
            backgroundColor: AppColor.putihNormal,
          ),
        ),
        initialRoute: AppRoute.splash,
        routes: {
          AppRoute.splash: (context) => const SplashScreen(),
          AppRoute.signUp: (context) => const SignUpScreen(),
          AppRoute.signIn: (context) => const SignInScreen(),
          AppRoute.dashboard: (context) => const DashboardScreen(),
          AppRoute.forumDiscussList: (context) => const ForumDiscussionScreen(),
          AppRoute.voiceSentiment: (context) => const VoiceRecorderScreen(),
          AppRoute.voiceSentimentHistory: (context) => HistoryScreen(),
          AppRoute.chatbot: (context) => const ChatbotScreen(),
          AppRoute.profile: (context) => const ProfileScreen(),
          AppRoute.profileEdit: (context) => const ProfileEditScreen(),
          AppRoute.feedback: (context) => const ProfileFeedbackScreen(),
          AppRoute.settings: (context) => const ProfileSettingScreen(), 
          AppRoute.notificationSettings: (context) => const SettingNotificationScreen(),
          AppRoute.generalSettings: (context) => const SettingGeneralScreen(),
        },
      ),
    );
  }
}