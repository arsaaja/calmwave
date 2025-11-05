import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:calm_wave/common/widget/category_tabs.dart';
import 'package:calm_wave/common/widget/custom_appbar.dart';
import 'package:calm_wave/common/widget/pop_up.dart';
import 'package:calm_wave/common/widget/grid_sound.dart';
import 'package:calm_wave/pages/sound/sound_player.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final supabase = Supabase.instance.client;
  final List<String> _categories = ["Semua", "Benda", "Hewan", "Alam"];
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();

    // 🔹 Cek apakah user sudah login
    final user = supabase.auth.currentUser;

    // 🔸 Kalau belum login, tampilkan popup setelah 10 detik
    if (user == null) {
      Timer(const Duration(seconds: 10), () {
        if (mounted) {
          PopUp.show(context);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A3F),
      appBar: CustomAppBar(
        title: user != null
            ? 'Hi, ${user.userMetadata?["username"] ?? "User"}!'
            : 'Hi, Tamu!',
        subtitle: user != null
            ? 'Lagi mau dengerin apa?'
            : 'Login dulu biar bisa akses semua fitur!',
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),

          // 🔹 Tabs kategori
          CategoryTabs(
            categories: _categories,
            onChanged: (index) {
              setState(() => selectedIndex = index);
            },
          ),

          const SizedBox(height: 20),

          // 🔹 Grid sound dari Supabase
          Expanded(
            child: GridSound(selectedCategory: _categories[selectedIndex]),
          ),

          // 🔹 Pemutar suara global (optional)
          const SoundPlayer(),
        ],
      ),
    );
  }
}
