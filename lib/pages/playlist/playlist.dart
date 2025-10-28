import 'package:calm_wave/common/widget/custom_appbar.dart';
import 'package:flutter/material.dart';

class Playlist extends StatefulWidget {
  const Playlist({super.key});

  @override
  State<Playlist> createState() => _PlaylistState();
}

class _PlaylistState extends State<Playlist> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070F2B), // warna Background
      appBar: const CustomAppBar(
        title: 'Hi, User!',
        subtitle: 'Lagi mau dengerin apa?',
      ),
      body: const Center(
        child: Text(
          "Ini halaman Playlist",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
