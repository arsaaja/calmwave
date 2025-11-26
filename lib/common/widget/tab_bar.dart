import 'package:calm_wave/pages/dashboard/dashboard.dart';
import 'package:calm_wave/pages/playlist/playlist.dart';
import 'package:calm_wave/pages/profile/profile.dart';
import 'package:calm_wave/pages/timer/timer.dart';
import 'package:flutter/material.dart';

class CustomTabBar extends StatefulWidget {
  const CustomTabBar({super.key});

  @override
  State<CustomTabBar> createState() => _CustomTabBarState();
}

class _CustomTabBarState extends State<CustomTabBar> {
  // State untuk melacak tab yang sedang aktif
  int currentTab = 0;

  // Daftar Halaman
  final List<Widget> screens = [
    const Dashboard(), // Pastikan semua Widget di sini adalah const
    const Playlist(),
    const Timer(),
    const Profile(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070F2B),

      // IndexedStack digunakan untuk menjaga state halaman saat berganti tab
      // Tambahkan key (opsional) untuk memastikan IndexedStack di-rebuild
      body: IndexedStack(
        key: ValueKey(currentTab),
        index: currentTab,
        children: screens,
      ),

      // Floating Play Button
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xff3D447C),
        elevation: 6,
        shape: const CircleBorder(),
        onPressed: () {
          // Aksi untuk tombol putar/play
        },
        child: const Icon(Icons.play_arrow, size: 36, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // BottomAppBar
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: const Color(0xFF1B1A55),
        child: SizedBox(
          height: 65,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Tombol Tab 1: Home/Dashboard
              _buildTabButton(Icons.home_rounded, 0),

              // Tombol Tab 2: Playlist
              _buildTabButton(Icons.bookmark_rounded, 1),

              // SizedBox sebagai placeholder untuk FloatingActionButton
              const SizedBox(width: 40),

              // Tombol Tab 3: Timer
              _buildTabButton(Icons.access_time_rounded, 2),

              // Tombol Tab 4: Profile
              _buildTabButton(Icons.person_rounded, 3),
            ],
          ),
        ),
      ),
    );
  }

  // Fungsi pembangun untuk setiap tombol tab
  Widget _buildTabButton(IconData icon, int index) {
    // Tentukan apakah tab ini adalah tab yang aktif
    bool isActive = currentTab == index;

    return MaterialButton(
      minWidth: 40,
      onPressed: () {
        // Mengubah state ketika tombol ditekan
        setState(() {
          currentTab = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        // Ubah warna latar belakang jika aktif
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF535C91) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          // Ubah warna ikon jika aktif
          color: isActive ? Colors.white : Colors.grey,
          size: 28,
        ),
      ),
    );
  }
}
