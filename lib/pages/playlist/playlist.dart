import 'package:calm_wave/common/widget/custom_appbar.dart';
import 'package:calm_wave/pages/playlist/playlist_detail_page.dart'; // Pastikan path ini benar!
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Playlist extends StatefulWidget {
  const Playlist({super.key});

  @override
  State<Playlist> createState() => _PlaylistState();
}

class _PlaylistState extends State<Playlist> {
  // Asumsi Supabase sudah diinisialisasi di main.dart
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _playlists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPlaylists();
  }

  Future<void> _fetchPlaylists() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // Ambil playlist pengguna dan hitung jumlah sound melalui tabel pivot
      final response = await _supabase
          .from('playlist')
          .select('*, playlist_sound(count)')
          .eq('user_id', user.id)
          .order('nama_playlist', ascending: true);

      if (mounted) {
        setState(() {
          _playlists = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching playlists: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memuat data playlist.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createPlaylist() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final TextEditingController nameController = TextEditingController();

    // Dialog untuk input nama playlist baru
    // Menggunakan showGeneralDialog agar lebih mudah kustomisasi style-nya
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Buat Playlist',
      barrierColor: Colors.black.withOpacity(0.85),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Beri nama playlist-mu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF070F2B),
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFA8A8D0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFFA8A8D0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Batal',
                            style: TextStyle(
                              color: Color(0xFF070F2B),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFF6F76B3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () async {
                            final name = nameController.text.trim();
                            if (name.isEmpty) return;

                            await _supabase.from('playlist').insert({
                              'user_id': user.id,
                              'nama_playlist': name,
                            });

                            if (context.mounted) Navigator.pop(context);
                            _fetchPlaylists(); // Refresh daftar playlist
                          },
                          child: const Text(
                            'Buat',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _editPlaylist(Map<String, dynamic> playlist) async {
    final TextEditingController controller = TextEditingController(
      text: playlist['nama_playlist'] ?? '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C2450),
          title: const Text(
            'Edit Nama Playlist',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Nama baru...',
              hintStyle: TextStyle(color: Colors.white54),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Batal',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () async {
                final newName = controller.text.trim();
                if (newName.isEmpty) return;

                await _supabase
                    .from('playlist')
                    .update({'nama_playlist': newName})
                    .eq('id', playlist['id']);

                // Update state secara lokal agar UI langsung berubah tanpa fetch ulang
                setState(() {
                  playlist['nama_playlist'] = newName;
                });

                if (context.mounted) Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Nama playlist diperbarui'),
                    backgroundColor: Color(0xFF535C91),
                  ),
                );
              },
              child: const Text(
                'Simpan',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deletePlaylist(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C2450),
          title: const Text(
            'Hapus Playlist?',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Yakin ingin menghapus playlist ini? Ini akan menghapus semua sound di dalamnya.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Batal',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Hapus',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      // Supabase biasanya akan menangani penghapusan cascade pada 'playlist_sound'
      await _supabase.from('playlist').delete().eq('id', id);

      if (mounted) {
        setState(() {
          _playlists.removeWhere((p) => p['id'] == id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Playlist berhasil dihapus'),
            backgroundColor: Color(0xFF535C91),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting playlist: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menghapus playlist'),
            backgroundColor: Color(0xFF535C91),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070F2B),
      appBar: const CustomAppBar(
        title: 'Hi, User!',
        subtitle: 'Lagi mau dengerin apa?',
      ),
      body: RefreshIndicator(
        onRefresh: _fetchPlaylists,
        color: Colors.white,
        backgroundColor: const Color(0xFF1C2450),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : ListView(
                  children: [
                    // Tombol Buat Playlist
                    GestureDetector(
                      onTap: _createPlaylist,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C2450),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Color(0xFF8A86FF),
                              child: Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            SizedBox(width: 16),
                            Text(
                              'Buat Playlist',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Daftar playlist
                    if (_playlists.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 40),
                          child: Text(
                            'Belum ada playlist. Ayo buat satu!',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                      )
                    else
                      ..._playlists.map((playlist) {
                        final sounds = playlist['playlist_sound'] as List;
                        // Mengambil jumlah sound. Jika sounds kosong, count 0
                        final count = sounds.isNotEmpty
                            ? sounds[0]['count'] as int
                            : 0;

                        // ID dan Nama yang akan diteruskan
                        final String playlistId = playlist['id'].toString();
                        final String playlistName =
                            playlist['nama_playlist'] ?? 'Tanpa Nama';

                        return GestureDetector(
                          // --- LOGIKA NAVIGASI KE DETAIL PLAYLIST ---
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PlaylistDetailPage(
                                  playlistId: playlistId,
                                  playlistName: playlistName,
                                ),
                              ),
                            );
                          },
                          // ------------------------------------------
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1C2450),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Color(0xFF8A86FF),
                                  child: Icon(
                                    Icons.music_note,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        playlistName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '$count lagu',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Tombol Popup
                                PopupMenuButton<String>(
                                  // Menghentikan onTap dari GestureDetector di bawahnya saat ikon ditekan
                                  onSelected: (value) async {
                                    if (value == 'edit') {
                                      _editPlaylist(playlist);
                                    } else if (value == 'delete') {
                                      _deletePlaylist(playlist['id']);
                                    }
                                  },
                                  color: const Color(
                                    0xFF1C2450,
                                  ), // Warna popup menu
                                  icon: const Icon(
                                    Icons.more_vert,
                                    color: Colors.white70,
                                    size: 22,
                                  ),
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.edit,
                                            color: Colors.white70,
                                            size: 18,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Ganti Nama',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.delete,
                                            color: Colors.redAccent,
                                            size: 18,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Hapus',
                                            style: TextStyle(
                                              color: Colors.redAccent,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ),
        ),
      ),
    );
  }
}
