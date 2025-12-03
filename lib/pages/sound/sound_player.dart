import 'package:calm_wave/pages/sound/audio_manager.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:just_audio/just_audio.dart'; // Import just_audio untuk StreamBuilder

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

  // Variabel state hanya untuk Volume/Mute
  double volume = 0.5;
  bool isMuted = false;

  // 💡 Catatan: Variabel isPlaying Dihapus, diganti StreamBuilder.

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  @override
  void didUpdateWidget(covariant SoundPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    // MEMAKSA MEMUTAR AUDIO BARU
    if (widget.audioUrl != null && widget.audioUrl != oldWidget.audioUrl) {
      _audioManager.player.stop();
      _audioManager.player.setUrl(widget.audioUrl!).then((_) {
        // Setelah URL baru di-set, mulai putar.
        _audioManager.player.play();
      });
    }
  }

  Future<void> _initPlayer() async {
    try {
      if (widget.audioUrl == null) return;

      if (_audioManager.player.audioSource == null) {
        await _audioManager.player.setUrl(widget.audioUrl!);
      }

      // MEMAKSA PLAY PLAYER UTAMA (Jika tidak sedang bermain)
      if (!_audioManager.player.playing) {
        await _audioManager.player.play();
      }

      // Inisialisasi state awal (untuk slider dan mute)
      if (mounted) {
        setState(() {
          volume = _audioManager.player.volume;
          isMuted = volume == 0;
        });
      }

      // Listener Volume (tetap dipertahankan)
      _audioManager.player.volumeStream.listen((v) {
        if (mounted) {
          setState(() {
            volume = v;
            isMuted = v == 0;
          });
        }
      });

      // 💡 Catatan: playingStream listener Dihapus, diganti StreamBuilder.
    } catch (e) {
      debugPrint("Gagal memuat audio: $e");
    }
  }

  // 🔄 FUNGSI TOGGLE PLAY/PAUSE (KONTROL GLOBAL)
  Future<void> _togglePlay() async {
    // Logika: Jika ADA sound apapun yang sedang dimainkan (utama ATAU campuran),
    // maka tombol ini berarti PAUSE GLOBAL.
    if (_audioManager.isAnyAudioPlaying) {
      await _audioManager.pauseAll(); // Pause player utama + semua mixed sound
    } else {
      // Jika TIDAK ADA sound yang dimainkan, maka tombol ini berarti PLAY GLOBAL.
      await _audioManager
          .playAll(); // Play player utama + semua mixed sound yang paused
    }

    // UI Play/Pause akan diperbarui secara otomatis oleh StreamBuilder.
  }

  Future<void> _toggleMute() async {
    // Logika Mute yang diperbarui untuk mempertahankan volume terakhir
    final newMuted = !isMuted;

    // Dapatkan semua player (player utama + semua player campuran)
    final allPlayers = [_audioManager.player, ..._audioManager.players.values];

    // Simpan volume terakhir dari player utama
    final lastVolume = volume > 0 ? volume : 0.5;

    final futures = <Future>[];
    if (newMuted) {
      // Mute SEMUA
      for (var p in allPlayers) {
        futures.add(p.setVolume(0));
      }
    } else {
      // Unmute: Player utama kembali ke volume terakhir, player campuran di-unmute jika sedang bermain
      futures.add(_audioManager.player.setVolume(lastVolume));
      // Logika untuk player campuran mungkin perlu diatur di AudioManager agar mempertahankan volume per player.
      // Untuk simplifikasi, kita asumsikan player utama yang dikontrol mute-nya di sini
    }

    await Future.wait(futures);

    // setState akan dipicu oleh volumeStream listener player utama, tapi kita pastikan volume global
    setState(() => isMuted = newMuted);
  }

  // BOTTOM SHEET LIST PLAYLIST (Tidak ada perubahan)
  Future<void> _showPlaylistBottomSheet() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Harap login terlebih dahulu.')),
        );
      }
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
                  onTap: () {
                    // Tutup BottomSheet saat ini sebelum membuka yang baru
                    Navigator.pop(context);
                    _showCreatePlaylistSheet();
                  },
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
                              playlistId: playlist['id'].toString(),
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
                    Navigator.pop(context); // Tutup Buat Playlist
                    Navigator.pop(context); // Tutup Pilih Playlist
                    _showPlaylistBottomSheet(); // Muat ulang list playlist
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
      final soundId = widget.soundId?.toString();
      if (soundId == null) return;

      final existing = await supabase
          .from('playlist_sound')
          .select()
          .eq('id_playlist', playlistId)
          .eq('id_sounds', soundId)
          .maybeSingle();

      if (existing != null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sound sudah ada di playlist "$playlistName".'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.pop(context);
        }
        return;
      }

      await supabase.from('playlist_sound').insert({
        'id_playlist': playlistId,
        'id_sounds': soundId,
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berhasil ditambahkan ke "$playlistName"'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Gagal menambah sound ke playlist: $e");

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menambahkan sound.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // UI MINI PLAYER (Menggunakan StreamBuilder untuk ikon Play/Pause)
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
          // 🎯 StreamBuilder untuk Ikon Play/Pause
          StreamBuilder<PlayerState>(
            stream: _audioManager.player.playerStateStream,
            builder: (context, snapshot) {
              final playerState = snapshot.data;
              final playing = playerState?.playing ?? false;
              final processingState = playerState?.processingState;

              // Cek status global: apakah player utama atau player campuran sedang bermain
              // Karena tombol ini adalah GLOBAL TOGGLE, kita bisa cek status isAnyAudioPlaying
              final bool isPlayingGlobally = _audioManager.isAnyAudioPlaying;

              // Tentukan ikon: tampilkan pause jika ada audio yang bermain secara global
              final IconData icon = isPlayingGlobally
                  ? Icons.pause
                  : Icons.play_arrow;

              return IconButton(
                onPressed: _togglePlay, // Memanggil Kontrol Global
                icon: Icon(icon, color: Colors.white, size: 30),
              );
            },
          ),

          // Akhir StreamBuilder
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
                // Set volume hanya pada player utama
                await _audioManager.player.setVolume(value);
                // Set volume pada mixed sounds, jika diperlukan, dapat ditambahkan di sini
                // atau ditangani melalui stream listener di mixed sounds.
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
