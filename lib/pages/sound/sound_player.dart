import 'package:calm_wave/pages/sound/audio_manager.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SoundPlayer extends StatefulWidget {
  const SoundPlayer({super.key});

  @override
  State<SoundPlayer> createState() => _SoundPlayerState();
}

class _SoundPlayerState extends State<SoundPlayer> {
  final AudioManager _audioManager = AudioManager.instance;
  final supabase = Supabase.instance.client;

  bool isPlaying = false;
  bool isMuted = false;
  double volume = 0.5;

  final String audioUrl =
      'https://vioeocsssqihgkbjuucm.supabase.co/storage/v1/object/public/sounds/sounds/rain-and-thunder-for-better-sleep-148899.mp3';
  final String soundId = "1";

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      if (_audioManager.player.audioSource == null) {
        await _audioManager.player.setUrl(audioUrl);
      }

      setState(() {
        isPlaying = _audioManager.player.playing;
        volume = _audioManager.player.volume;
        isMuted = volume == 0;
      });

      _audioManager.player.playingStream.listen((playing) {
        if (mounted) setState(() => isPlaying = playing);
      });

      _audioManager.player.volumeStream.listen((v) {
        if (mounted) {
          setState(() {
            volume = v;
            isMuted = v == 0;
          });
        }
      });
    } catch (e) {
      debugPrint("Gagal memuat audio: $e");
    }
  }

  Future<void> _togglePlay() async {
    if (_audioManager.player.playing) {
      await _audioManager.player.pause();
    } else {
      await _audioManager.player.play();
    }
  }

  Future<void> _toggleMute() async {
    final newMuted = !isMuted;
    await _audioManager.player.setVolume(
      newMuted ? 0 : (volume > 0 ? volume : 0.5),
    );
    setState(() => isMuted = newMuted);
  }

  // 🧩 Bottom Sheet Utama: daftar playlist user
  Future<void> _showPlaylistBottomSheet() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap login terlebih dahulu.')),
      );
      return;
    }

    try {
      final response = await supabase
          .from('playlist')
          .select('id, nama_playlist')
          .eq('user_id', user.id);

      final userPlaylists = List<Map<String, dynamic>>.from(response);

      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFF535C91),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Tambah ke Playlist",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // Tombol buat playlist baru
                InkWell(
                  onTap: _showCreatePlaylistSheet, // 🔄 ganti ke fungsi baru
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF818FB4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          "Buat Playlist Baru",
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // List playlist user
                if (userPlaylists.isNotEmpty) ...[
                  const Text(
                    "Pilih Playlist",
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 10),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: userPlaylists.length,
                      itemBuilder: (context, index) {
                        final playlist = userPlaylists[index];
                        return InkWell(
                          onTap: () async {
                            await _addSoundToPlaylist(
                              playlistId: playlist['id'],
                              playlistName: playlist['nama_playlist'],
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6B72A0),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              playlist['nama_playlist'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ] else
                  const Center(
                    child: Text(
                      "Anda belum punya playlist.",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      debugPrint("Gagal ambil playlist: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text("Gagal memuat playlist."),
        ),
      );
    }
  }

  // 🧩 Bottom Sheet kedua: input nama playlist baru
  Future<void> _showCreatePlaylistSheet() async {
    final TextEditingController controller = TextEditingController();
    final user = supabase.auth.currentUser;
    if (user == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF535C91),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Nama Playlist Baru",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: "Masukkan nama playlist...",
                  hintStyle: TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Color(0xFF6B72A0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF818FB4),
                ),
                onPressed: () async {
                  final name = controller.text.trim();
                  if (name.isEmpty) return;

                  await supabase.from('playlist').insert({
                    'nama_playlist': name,
                    'user_id': user.id,
                  });

                  if (context.mounted) {
                    Navigator.pop(context); // tutup input
                    Navigator.pop(context); // tutup sheet lama
                    _showPlaylistBottomSheet(); // refresh
                  }
                },
                child: const Text(
                  "Simpan",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addSoundToPlaylist({
    required int playlistId,
    required String playlistName,
  }) async {
    try {
      final existing = await supabase
          .from('playlist_sound')
          .select()
          .eq('id_playlist', playlistId)
          .eq('id_sounds', soundId)
          .maybeSingle();

      if (existing != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sound sudah ada di playlist "$playlistName".'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.pop(context);
        return;
      }

      await supabase.from('playlist_sound').insert({
        'id_playlist': playlistId,
        'id_sounds': soundId,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Berhasil ditambahkan ke "$playlistName"'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      debugPrint("Gagal menambah sound ke playlist: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menambahkan sound.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // UI Sound Bar
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF535C91),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _togglePlay,
            icon: Icon(
              isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _toggleMute,
            icon: Icon(
              isMuted ? Icons.volume_off : Icons.volume_up,
              color: Colors.white,
            ),
          ),
          Expanded(
            child: Slider(
              activeColor: Colors.white,
              inactiveColor: Colors.white24,
              value: isMuted ? 0 : volume,
              onChanged: (value) async {
                await _audioManager.player.setVolume(value);
                setState(() {
                  volume = value;
                  isMuted = value == 0;
                });
              },
            ),
          ),
          IconButton(
            onPressed: _showPlaylistBottomSheet,
            icon: const Icon(Icons.bookmark_add_outlined, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
