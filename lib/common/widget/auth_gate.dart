import 'package:calm_wave/common/widget/tab_bar.dart';
import 'package:calm_wave/pages/login.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // StreamBuilder mendengarkan perubahan status otentikasi Supabase
    return StreamBuilder<AuthState>(
      // Menggunakan onAuthStateChange untuk status otentikasi
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // 1. Periksa status koneksi
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Tampilkan indikator loading saat menunggu status awal Supabase
          return const Scaffold(
            backgroundColor: Color(0xFF070F2B),
            body: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }

        // 2. Ambil data sesi
        final session = snapshot.data?.session;

        // 3. Tentukan halaman yang akan ditampilkan
        if (session != null) {
          // Jika Sesi ada (Pengguna sudah login) -> Tampilkan Tab Bar
          return const CustomTabBar();
        } else {
          // Jika Sesi tidak ada (Pengguna belum login) -> Tampilkan Halaman Login
          return const LoginPage();
        }
      },
    );
  }
}
