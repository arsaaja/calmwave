import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String subtitle;
  // Tambahkan properti untuk menangani navigasi (Opsional: default true untuk halaman utama)
  final bool showBackButton;

  const CustomAppBar({
    super.key,
    required this.title,
    required this.subtitle,
    this.showBackButton = false, // Default: tidak menampilkan tombol kembali
  });

  @override
  Widget build(BuildContext context) {
    // Tentukan apakah kita perlu menampilkan tombol kembali
    final bool canPop = Navigator.canPop(context) && showBackButton;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF1B1A55),
        boxShadow: [
          BoxShadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 4),
        ],
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. Tombol Kembali (Opsional)
            if (canPop)
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              )
            else
              const SizedBox(width: 0), // Jika tidak ada tombol back
            // 2. Teks Sapaan (Dibungkus Expanded untuk Mencegah Overflow)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize
                    .min, // Penting agar Column tidak mengambil tinggi berlebihan
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis, // << SOLUSI OVERFLOW
                    maxLines: 1, // << SOLUSI OVERFLOW
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),

            // 3. Logo Aplikasi
            // Tambahkan sedikit jarak agar tidak terlalu mepet dengan teks
            const SizedBox(width: 16),

            // Logo tidak dibungkus Expanded
            Image.asset('assets/images/logo.png', height: 45),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(80);
}
