import 'package:calm_wave/common/widget/category_tabs.dart';
import 'package:calm_wave/common/widget/custom_appbar.dart';
import 'package:calm_wave/pages/sound/sound_player.dart';
import 'package:flutter/material.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final List<String> _categories = ["Semua", "Benda", "Hewan", "Alam"];
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A3F),
      appBar: const CustomAppBar(
        title: 'Hi, User!',
        subtitle: 'Lagi mau dengerin apa?',
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),

          CategoryTabs(
            categories: _categories,
            onChanged: (index) {
              setState(() => selectedIndex = index);
            },
          ),

          const SizedBox(height: 20),

          Expanded(
            child: Center(
              child: Text(
                "Konten kategori: ${_categories[selectedIndex]}",
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),

          const SoundPlayer(),
        ],
      ),
    );
  }
}
