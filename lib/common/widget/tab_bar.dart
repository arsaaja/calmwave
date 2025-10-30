import 'package:calm_wave/pages/dashboard/dashboard.dart';
import 'package:calm_wave/pages/playlist/playlist.dart'; // <- IMPORT PENTING
import 'package:calm_wave/pages/profile/profile.dart';
import 'package:calm_wave/pages/timer/timer.dart';
import 'package:flutter/material.dart';

class CustomTabBar extends StatefulWidget {
  const CustomTabBar({super.key});

  @override
  State<CustomTabBar> createState() => _CustomTabBarState();
}

class _CustomTabBarState extends State<CustomTabBar> {
  int currentTab = 0;

  // Daftarnya Halaman
  final List<Widget> screens = [Dashboard(), Playlist(), Timer(), Profile()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070F2B),

      body: IndexedStack(index: currentTab, children: screens),

      // Floating Play Button
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xff3D447C),
        elevation: 6,
        shape: const CircleBorder(),
        onPressed: () {},
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
              _buildTabButton(Icons.home_rounded, 0),
              _buildTabButton(Icons.bookmark_rounded, 1),
              const SizedBox(width: 40),
              _buildTabButton(Icons.access_time_rounded, 2),
              _buildTabButton(Icons.person_rounded, 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(IconData icon, int index) {
    bool isActive = currentTab == index;
    return MaterialButton(
      minWidth: 40,
      onPressed: () {
        setState(() {
          currentTab = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF535C91) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : Colors.grey,
          size: 28,
        ),
      ),
    );
  }
}
