import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/screens/splash_screen.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:frontend/common/app_color.dart';
import 'package:frontend/common/app_route.dart';
import 'package:frontend/presentation/bloc/user/user_cubit.dart';
import 'package:frontend/screens/sign_up_screen.dart';
import 'package:frontend/screens/sign_in_screen.dart';
import 'package:frontend/screens/dashboard_screen.dart';
import 'package:frontend/screens/forum_discussion_screen.dart';

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
        },
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}