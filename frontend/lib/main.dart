import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/screens/data_privacy_level_screen.dart';
import 'package:frontend/screens/setting_privacy_screen.dart';
import 'package:frontend/screens/setting_voice_journal_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_localizations/flutter_localizations.dart'; 
import 'package:flutter_localized_locales/flutter_localized_locales.dart'; 

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
import 'package:frontend/screens/profile_feedback_screen.dart';
import 'package:frontend/screens/profile_setting_screen.dart';
import 'package:frontend/screens/setting_notification_screen.dart';
import 'package:frontend/screens/setting_general_screen.dart';
import 'package:frontend/screens/general_timezone_screen.dart';
import 'package:frontend/screens/general_language_screen.dart'; 

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
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
        // untuk localization
        localizationsDelegates: const [
          LocaleNamesLocalizationsDelegate(), 
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate, 
          GlobalCupertinoLocalizations.delegate, 
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('id'), 
        ],
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
          AppRoute.timeZone: (context) => const GeneralTimeZoneScreen(),
          AppRoute.language: (context) => const GeneralLanguageScreen(),
          AppRoute.privacySettings: (context) => const SettingPrivacyScreen(),
          AppRoute.dataPrivacyLevel: (context) => const DataPrivacyLevelScreen(),
          AppRoute.voiceJournalSettings: (context) => const SettingVoiceJournalScreen(),
        },
      ),
    );
  }
}