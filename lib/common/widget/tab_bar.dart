import 'package:flutter/material.dart';
import 'dart:async'; // Diperlukan untuk StreamSubscription
import 'package:supabase_flutter/supabase_flutter.dart'; // Diperlukan untuk Auth
import 'package:calm_wave/pages/dashboard/dashboard.dart';
import 'package:calm_wave/pages/playlist/playlist.dart';
import 'package:calm_wave/pages/profile/profile.dart';
import 'package:calm_wave/pages/timer/timer.dart';

// --- KELAS POPUP (DIASUMSIKAN ADA) ---
// Kelas ini harus ada di file Anda atau di-import dari lokasi yang benar
class PopUp {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xff535C91),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          title: const Text("Perhatian", style: TextStyle(color: Colors.white)),
          content: const Text(
            "Untuk mengakses penuh aplikasi dibutuhkan login, anda ingin login?",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xff1B1A55),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text("Abaikan"),
            ),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xff070F2B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                // Navigasi ke halaman login Anda
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text("Login"),
            ),
          ],
        );
      },
    );
  }
}

// ------------------------------------------
//           CUSTOM TAB BAR UTAMA
// ------------------------------------------

class CustomTabBar extends StatefulWidget {
  const CustomTabBar({super.key});

  @override
  State<CustomTabBar> createState() => _CustomTabBarState();
}

class _CustomTabBarState extends State<CustomTabBar> {
  int currentTab = 0;

  // Status login yang akan diperbarui oleh listener Supabase
  bool _isLoggedIn = false;
  StreamSubscription<AuthState>? _authStateSubscription;

  // Daftar Index Halaman
  final List<Widget> screens = [
    const Dashboard(), // Index 0: Dashboard (Akses Publik)
    const Playlist(), // Index 1: Membutuhkan Login
    const Timer(), // Index 2: Membutuhkan Login
    const Profile(), // Index 3: Membutuhkan Login
  ];

  // Daftar index yang memerlukan login (1, 2, 3)
  final List<int> requiresLogin = [1, 2, 3];

  @override
  void initState() {
    super.initState();
    // 1. Cek status awal saat widget dibuat
    _checkAuthStatus();
    // 2. Dengarkan perubahan status auth Supabase
    _listenToAuthChanges();
  }

  @override
  void dispose() {
    // Batalkan subscription ketika widget dihapus
    _authStateSubscription?.cancel();
    super.dispose();
  }

  // --- LOGIKA OTENTIKASI ---

  // Fungsi untuk cek status awal
  void _checkAuthStatus() {
    // Mendapatkan user saat ini dari Supabase
    final user = Supabase.instance.client.auth.currentUser;
    setState(() {
      _isLoggedIn = user != null;
    });
  }

  // Fungsi untuk mendengarkan perubahan status Supabase secara real-time
  void _listenToAuthChanges() {
    _authStateSubscription = Supabase.instance.client.auth.onAuthStateChange
        .listen((data) {
          final AuthChangeEvent event = data.event;
          final Session? session = data.session;

          if (event == AuthChangeEvent.signedIn ||
              event == AuthChangeEvent.signedOut) {
            // Perbarui state _isLoggedIn dan UI
            setState(() {
              _isLoggedIn = session != null;

              // Jika pengguna logout, paksa kembali ke Dashboard (Index 0)
              if (!_isLoggedIn && currentTab != 0) {
                currentTab = 0;
              }
            });
          }
        });
  }

  // --- UI DAN LOGIKA TAB BAR ---

  @override
  Widget build(BuildContext context) {
    // Memastikan tab kembali ke Dashboard jika logout terjadi saat berada di tab lain
    if (!_isLoggedIn && currentTab != 0) {
      currentTab = 0;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF070F2B),

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

  // Fungsi pembangun untuk setiap tombol tab
  Widget _buildTabButton(IconData icon, int index) {
    // Cek apakah tab dibatasi: Membutuhkan login DAN pengguna belum login
    final bool isRestricted = requiresLogin.contains(index) && !_isLoggedIn;

    bool isActive = currentTab == index;

    // Tentukan warna ikon dan latar belakang berdasarkan status
    Color iconColor = isActive
        ? Colors.white
        : (isRestricted ? Colors.grey.shade700 : Colors.grey);
    Color containerColor = isActive
        ? const Color(0xFF535C91)
        : Colors.transparent;

    return MaterialButton(
      minWidth: 40,
      onPressed: isRestricted
          ? () {
              // ⛔ Jika Dibatasi, tampilkan PopUp
              PopUp.show(context);
            }
          : () {
              // ✅ Jika Diizinkan (sudah login atau tab Dashboard), ganti tab
              setState(() {
                currentTab = index;
              });
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: containerColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 28),
      ),
    );
  }
}
