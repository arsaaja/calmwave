import 'package:calm_wave/common/widget/tab_bar.dart';
import 'package:calm_wave/pages/login.dart';
import 'package:calm_wave/pages/signup.dart';
import 'package:calm_wave/pages/sound/sound_player.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  await Supabase.initialize(
    anonKey:
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZpb2VvY3Nzc3FpaGdrYmp1dWNtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjAzNjc3MDUsImV4cCI6MjA3NTk0MzcwNX0.ZvzuRdPnTZygTJ4KoY_XdGfi2J0O3vMcuFIZt7Hk_dA",
    url: "https://vioeocsssqihgkbjuucm.supabase.co",
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SignupPage(),
      debugShowCheckedModeBanner: false,
      title: 'CalmWave',
      theme: ThemeData(
        primaryColor: const Color(0xFF070F2B),
        scaffoldBackgroundColor: const Color(0xFF1B1A55),
      ),

      // Route
      routes: {
        '/signup': (context) => const SignupPage(),
        '/login': (context) => const LoginPage(),
        '/tab_bar': (context) => const CustomTabBar(),
        '/sound_player': (context) => const Scaffold(
          backgroundColor: Color(0xFF070F2B),
          body: SafeArea(child: SoundPlayer()),
        ),
      },
    );
  }
}
