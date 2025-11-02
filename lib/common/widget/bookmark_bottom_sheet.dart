import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SoundBookmarkButton extends StatefulWidget {
  final String soundId; // ID dari sound yang sedang ditampilkan/diputar

  const SoundBookmarkButton({super.key, required this.soundId});

  @override
  State<SoundBookmarkButton> createState() => _SoundBookmarkButtonState();
}

class _SoundBookmarkButtonState extends State<SoundBookmarkButton> {
  // Instance Supabase client untuk berinteraksi dengan database
  final SupabaseClient supabase = Supabase.instance.client;

  /// Menampilkan bottom sheet yang berisi daftar playlist milik pengguna.
  Future<void> _showPlaylistBottomSheet(BuildContext context) async {
    // Pastikan user sudah login sebelum melanjutkan
    final user = supabase.auth.currentUser;
    if (user == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap login terlebih dahulu untuk menyimpan sound.'),
        ),
      );
      return;
    }

    try {
      // Ambil semua playlist yang dimiliki oleh user yang sedang login
      final playlists = await supabase
          .from('playlist')
          .select('id, nama_playlist') // Mengambil ID dan nama playlist
          .eq('user_id', user.id);

      if (!context.mounted) return;

      if (playlists.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Anda belum memiliki playlist. Buat satu terlebih dahulu!',
            ),
          ),
        );
        return;
      }

      showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF101046),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (BuildContext innerContext) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Tambahkan ke Playlist",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = playlists[index];
                    return Card(
                      color: const Color(0xFF1C1C5A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text(
                          playlist['nama_playlist'],
                          style: const TextStyle(color: Colors.white),
                        ),
                        onTap: () async {
                          Navigator.pop(innerContext);
                          await _addSoundToPlaylist(
                            playlistId: playlist['id'],
                            soundId: widget.soundId,
                            playlistName: playlist['nama_playlist'],
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal memuat playlist. Coba lagi nanti.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _addSoundToPlaylist({
    required int playlistId,
    required String soundId,
    required String playlistName,
  }) async {
    try {
      final existing = await supabase
          .from('playlist_sound')
          .select()
          .eq('id_playlist', playlistId)
          .eq('id_sounds', soundId)
          .maybeSingle();

      if (!context.mounted) return;

      if (existing != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sound ini sudah ada di playlist "$playlistName".'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      await supabase.from('playlist_sound').insert({
        'id_playlist': playlistId,
        'id_sounds': soundId,
      });

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Berhasil menambahkan ke playlist "$playlistName".'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      debugPrint('Error saat menambahkan sound ke playlist: $error');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menambahkan sound. Terjadi kesalahan.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(
        Icons.bookmark_add_outlined,
        color: Colors.white,
        size: 30,
      ),
      tooltip: 'Tambahkan ke playlist',
      onPressed: () => _showPlaylistBottomSheet(context),
    );
  }
}
