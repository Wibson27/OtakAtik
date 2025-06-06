import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; //  <-- Import yang benar untuk BlocProvider dan MultiBlocProvider
import 'package:frontend/presentation/bloc/user/user_cubit.dart';
import 'package:frontend/screens/sign_up_screen.dart'; // Pastikan path ini benar

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<UserCubit>(
          create: (context) => UserCubit(), // 
        ),
      ],
      // 
      // MultiBlocProvider harus memiliki 'child' yang merupakan widget aplikasi utama Anda (MaterialApp)
      // Properti 'title', 'theme', dan 'home' adalah milik MaterialApp, bukan MultiBlocProvider.
      child: MaterialApp( //  <-- MaterialApp dibungkus sebagai child
        title: 'Tenang.in', // 
        theme: ThemeData( // 
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple), // 
          useMaterial3: true, // Opsional, untuk Material Design 3
        ),
        home: const SignUpScreen(), //  <-- Halaman awal aplikasi
      ),
    );
  }
}

// Bagian MyHomePage dan _MyHomePageState yang merupakan template default Flutter
// Saya biarkan tetap ada di sini seperti format yang Anda berikan,
// meskipun tidak digunakan dalam MaterialApp di atas.
// Anda bisa menghapusnya jika memang tidak akan digunakan.
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