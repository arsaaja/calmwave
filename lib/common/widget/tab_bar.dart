import 'package:calm_wave/pages/dashboard/dashboard.dart';
import 'package:calm_wave/pages/playlist/playlist.dart';
import 'package:calm_wave/pages/profile/profile.dart';
import 'package:calm_wave/pages/timer/timer.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int currentTab = 0;
  final List<Widget> screen = [Dashboard(), Playlist(), Timer(), Profile()];

  final PageStorageBucket bucket = PageStorageBucket();
  Widget currentScreen = Dashboard();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070F2B), // warna Background
      body: PageStorage(bucket: bucket, child: currentScreen),

      // Floating Play Button
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xff3D447C),
        elevation: 6,
        shape: const CircleBorder(),
        onPressed: () {
          Navigator.pushNamed(context, '/sound_player');
        },
        child: const Icon(Icons.play_arrow, size: 36, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

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
              const SizedBox(width: 40), // ruang untuk FAB
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
          currentScreen = screen[index];
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
