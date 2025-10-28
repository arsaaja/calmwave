import 'package:calm_wave/common/widget/custom_appbar.dart';
import 'package:flutter/material.dart';

class Timer extends StatefulWidget {
  const Timer({super.key});

  @override
  State<Timer> createState() => _TimerState();
}

class _TimerState extends State<Timer> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070F2B), // warna Background
      appBar: const CustomAppBar(
        title: 'Hi, User!',
        subtitle: 'Lagi mau dengerin apa?',
      ),
      body: const Center(
        child: Text("Ini halaman Timer", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
