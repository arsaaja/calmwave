import 'package:calm_wave/pages/sound/audio_manager.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SoundPlayer extends StatefulWidget {
  final String? audioUrl;
  final String? soundId; // ID sound dari dashboard (UUID diharuskan)

  const SoundPlayer({super.key, this.audioUrl, this.soundId});

  @override
  State<SoundPlayer> createState() => _SoundPlayerState();
}

class _SoundPlayerState extends State<SoundPlayer> {
  final AudioManager _audioManager = AudioManager.instance;
  final supabase = Supabase.instance.client;

  bool isPlaying = false;
  bool isMuted = false;
  double volume = 0.5;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  @override
  void didUpdateWidget(covariant SoundPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 🌟 MEMAKSA MEMUTAR AUDIO BARU 🌟
    if (widget.audioUrl != null && widget.audioUrl != oldWidget.audioUrl) {
      _audioManager.player.stop();
      _audioManager.player.setUrl(widget.audioUrl!).then((_) {
        _audioManager.player.play();
        // isPlaying akan diperbarui oleh listener di bawah
      });
    }
  }

  Future<void> _initPlayer() async {
    try {
      if (widget.audioUrl == null) return;

      if (_audioManager.player.audioSource == null) {
        await _audioManager.player.setUrl(widget.audioUrl!);
      }

      // 🌟 MEMAKSA PLAY (Jika tidak sedang bermain) 🌟
      if (!_audioManager.player.playing) {
        await _audioManager.player.play();
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
    // Memeriksa status global untuk Global Pause/Play
    if (_audioManager.isAnyAudioPlaying) {
      await _audioManager.pauseAll();
    } else {
      await _audioManager.playAll();
    }

    setState(() {
      isPlaying = _audioManager.player.playing;
    });
  }

  Future<void> _toggleMute() async {
    // Logika Mute yang diperbarui untuk mempertahankan volume terakhir
    final newMuted = !isMuted;

    if (newMuted) {
      // Mute
      await _audioManager.player.setVolume(0);
    } else {
      // Unmute: kembali ke volume terakhir atau 0.5
      final targetVolume = volume > 0 ? volume : 0.5;
      await _audioManager.player.setVolume(targetVolume);
    }

    // setState akan dipicu oleh volumeStream listener, tapi tetap jaga untuk kepastian UI
    setState(() => isMuted = newMuted);
  }

  // BOTTOM SHEET LIST PLAYLIST (Tidak ada perubahan)
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

                InkWell(
                  onTap: _showCreatePlaylistSheet,
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
                              playlistId: playlist['id'].toString(), // FIXED
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
    }
  }

  // BOTTOM SHEET BUAT PLAYLIST BARU (Tidak ada perubahan)
  Future<void> _showCreatePlaylistSheet() async {
    final controller = TextEditingController();
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
                    Navigator.pop(context);
                    Navigator.pop(context);
                    _showPlaylistBottomSheet();
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

  // ADD SOUND KE PLAYLIST (Tidak ada perubahan)
  Future<void> _addSoundToPlaylist({
    required String playlistId,
    required String playlistName,
  }) async {
    try {
      final soundId = widget.soundId?.toString(); // FIXED
      if (soundId == null) return;

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
        if (context.mounted) Navigator.pop(context);
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

      if (context.mounted) Navigator.pop(context);
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

  // UI MINI PLAYER (Tidak ada perubahan)
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
