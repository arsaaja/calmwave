import 'package:calm_wave/common/widget/custom_appbar.dart';
import 'package:flutter/material.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070F2B), // warna latar belakang utama
      appBar: const CustomAppBar(
        title: 'Hi, User!',
        subtitle: 'Lagi mau dengerin apa?',
      ),
      body: const Center(
        child: Text(
          "Ini halaman profil",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
