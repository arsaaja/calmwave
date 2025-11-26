import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// TAMBAH: soundId diperlukan untuk menyimpan sound ke playlist
class PlaylistBottomSheet extends StatefulWidget {
  final String soundId;

  const PlaylistBottomSheet({super.key, required this.soundId});

  @override
  State<PlaylistBottomSheet> createState() => _PlaylistBottomSheetState();
}

class _PlaylistBottomSheetState extends State<PlaylistBottomSheet> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<dynamic> _playlists = [];
  bool _isLoading = true;
  final TextEditingController _playlistNameController = TextEditingController();

  // Getter untuk soundId yang diterima
  String get currentSoundId => widget.soundId;

  @override
  void initState() {
    super.initState();
    _fetchPlaylists();
  }

  @override
  void dispose() {
    _playlistNameController.dispose();
    super.dispose();
  }

  Future<void> _fetchPlaylists() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await supabase
          .from('playlist')
          .select('id, nama_playlist')
          .eq('user_id', user.id)
          .order('nama_playlist', ascending: true);

      if (mounted) {
        setState(() {
          _playlists = response;
          _isLoading = false;
        });
      }
    } catch (error) {
      debugPrint('Gagal memuat playlist: $error');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memuat daftar playlist.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createPlaylist(String name) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase.from('playlist').insert({
        'user_id': user.id,
        'nama_playlist': name,
      });
      await _fetchPlaylists(); // refresh data

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Playlist "$name" berhasil dibuat.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      debugPrint('Gagal membuat playlist: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal membuat playlist.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 🎯 LOGIKA UNTUK MENAMBAH SOUND KE PLAYLIST
  Future<void> _addSoundToPlaylist({
    required String playlistId,
    required String playlistName,
  }) async {
    // 1. Pengecekan ID sound
    if (currentSoundId.isEmpty) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Sound ID tidak ditemukan.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Tutup bottom sheet segera untuk feedback yang cepat
    if (mounted) Navigator.pop(context);

    try {
      // 2. Cek apakah sound sudah ada
      final existing = await supabase
          .from('playlist_sound')
          .select()
          .eq('id_playlist', playlistId)
          .eq('id_sounds', currentSoundId)
          .maybeSingle();

      if (existing != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sound sudah ada di playlist "$playlistName".'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // 3. Masukkan record baru
      await supabase.from('playlist_sound').insert({
        'id_playlist': playlistId,
        'id_sounds': currentSoundId,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berhasil ditambahkan ke "$playlistName"'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("Gagal menambah sound ke playlist: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menambahkan sound. Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCreatePlaylistSheet() {
    _playlistNameController.clear();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C5A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Buat Playlist Baru',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _playlistNameController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Masukkan nama playlist...',
                  hintStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF2A2A70),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Batal',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF535C91),
                    ),
                    onPressed: () async {
                      final name = _playlistNameController.text.trim();
                      if (name.isEmpty) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Nama playlist tidak boleh kosong.',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                        return;
                      }

                      if (context.mounted) Navigator.pop(context);
                      await _createPlaylist(name);
                    },
                    child: const Text(
                      'Buat',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deletePlaylist(String playlistId, String name) async {
    try {
      // Hapus sound yang terkait (di tabel playlist_sound)
      await supabase
          .from('playlist_sound')
          .delete()
          .eq('id_playlist', playlistId);

      // Hapus playlist utama
      await supabase.from('playlist').delete().eq('id', playlistId);

      if (mounted) {
        setState(() {
          _playlists.removeWhere((p) => p['id'] == playlistId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Playlist "$name" berhasil dihapus.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      debugPrint('Gagal hapus playlist: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menghapus playlist.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    // Pastikan ini kembali ke Container, karena ini akan dipanggil sebagai modal sheet
    return Container(
      height:
          MediaQuery.of(context).size.height *
          0.6, // Batasi tinggi bottom sheet
      decoration: const BoxDecoration(
        color: Color(0xFF101046),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pilih Playlist',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // --- Tombol Buat Baru ---
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: ElevatedButton.icon(
              onPressed: user == null ? null : _showCreatePlaylistSheet,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF535C91),
                minimumSize: const Size(double.infinity, 40),
              ),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Buat Playlist Baru',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),

          const Divider(color: Colors.white10),

          // --- Daftar Playlist ---
          Expanded(
            child: user == null
                ? const Center(
                    child: Text(
                      "Harap login untuk mengakses playlist.",
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                : _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : _playlists.isEmpty
                ? const Center(
                    child: Text(
                      'Anda belum punya playlist.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: _playlists.length,
                    itemBuilder: (context, index) {
                      final playlist = _playlists[index];
                      return Card(
                        color: const Color(0xFF2A2A70),
                        margin: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          // Aksi saat di-tap: Tambahkan sound ke playlist
                          onTap: () => _addSoundToPlaylist(
                            playlistId: playlist['id'],
                            playlistName: playlist['nama_playlist'],
                          ),

                          title: Text(
                            playlist['nama_playlist'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.redAccent,
                            ),
                            onPressed: () => _deletePlaylist(
                              playlist['id'],
                              playlist['nama_playlist'],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
