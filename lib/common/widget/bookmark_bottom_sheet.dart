import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PlaylistBottomSheet extends StatefulWidget {
  const PlaylistBottomSheet({super.key});

  @override
  State<PlaylistBottomSheet> createState() => _PlaylistBottomSheetState();
}

class _PlaylistBottomSheetState extends State<PlaylistBottomSheet> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<dynamic> _playlists = [];
  bool _isLoading = true;
  final TextEditingController _playlistNameController = TextEditingController();

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
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Nama playlist tidak boleh kosong.'),
                            backgroundColor: Colors.red,
                          ),
                        );
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

  Future<void> _deletePlaylist(int playlistId, String name) async {
    try {
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
    }
  }

  @override
  Widget build(BuildContext context) {
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _playlists.isEmpty
          ? const Center(
              child: Text(
                'Belum ada playlist.',
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _playlists.length,
              itemBuilder: (context, index) {
                final playlist = _playlists[index];
                return Card(
                  color: const Color(0xFF2A2A70),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF535C91),
        onPressed: _showCreatePlaylistSheet,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
