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

  // Struktur Kategori menggunakan ID (UUID) dan Nama
  final List<Map<String, String>> _categories = [
    {'id': 'all', 'name': 'Semua'},
    {
      'id': '61a8d950-8cd6-4e4a-a9ec-4dde31d7e82b',
      'name': 'Benda',
    }, // Ganti dengan UUID asli dari tabel kategori Anda
    {'id': '448e9800-5645-4674-a3ea-b0b778d3a5e5', 'name': 'Hewan'},
    {'id': '9764102b-b5db-4ede-9657-0ff485fa719d', 'name': 'Alam'},
  ];

  // Melacak ID kategori yang dipilih (UUID)
  String selectedCategoryId = 'all';

  @override
  void initState() {
    super.initState();
    final user = supabase.auth.currentUser;

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

          // Tabs kategori (ChoiceChip)
          CategoryTabs(
            categories: _categories, // Mengirim List<Map>
            onChanged: (id) {
              // Menerima ID (UUID) yang dipilih
              setState(() => selectedCategoryId = id);
            },
          ),

          const SizedBox(height: 20),

          // Grid sound dari Supabase
          Expanded(
            // Meneruskan ID Kategori (UUID) ke GridSound
            child: GridSound(selectedCategoryId: selectedCategoryId),
          ),

          // Pemutar suara global (optional)
          //const SoundPlayer(),
        ],
      ),
    );
  }
}
