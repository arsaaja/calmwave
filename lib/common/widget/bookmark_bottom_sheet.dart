import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PlaylistPage extends StatefulWidget {
  const PlaylistPage({super.key});

  @override
  State<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<dynamic> _playlists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPlaylists();
  }

  Future<void> _fetchPlaylists() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await supabase
          .from('playlist')
          .select('id, nama_playlist')
          .eq('user_id', user.id)
          .order('nama_playlist', ascending: true);

      setState(() {
        _playlists = response;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Gagal memuat playlist: $error');
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal memuat daftar playlist.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deletePlaylist(int playlistId, String name) async {
    try {
      await supabase.from('playlist').delete().eq('id', playlistId);

      setState(() {
        _playlists.removeWhere((p) => p['id'] == playlistId);
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Playlist "$name" berhasil dihapus.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      debugPrint('Gagal hapus playlist: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menghapus playlist.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF101046),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final user = supabase.auth.currentUser;
    if (user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF101046),
        body: Center(
          child: Text(
            'Silakan login untuk melihat playlist Anda.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF101046),
      appBar: AppBar(
        title: const Text(
          'Playlist Saya',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1C1C5A),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _playlists.isEmpty
          ? const Center(
              child: Text(
                'Belum ada playlist. Buat satu untuk mulai menyimpan sound!',
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _playlists.length,
              itemBuilder: (context, index) {
                final playlist = _playlists[index];
                return Card(
                  color: const Color(0xFF1C1C5A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    title: Text(
                      playlist['nama_playlist'],
                      style: const TextStyle(color: Colors.white),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => _deletePlaylist(
                        playlist['id'],
                        playlist['nama_playlist'],
                      ),
                    ),
                    onTap: () {
                      // Navigasi ke halaman detail playlist
                      // Misal: Navigator.pushNamed(context, '/playlistDetail', arguments: playlist['id']);
                    },
                  ),
                );
              },
            ),
    );
  }
}
