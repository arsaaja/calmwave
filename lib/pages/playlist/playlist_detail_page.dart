import 'package:calm_wave/common/widget/custom_appbar.dart';
import 'package:calm_wave/models/sound_model.dart';
import 'package:calm_wave/pages/sound/audio_manager.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PlaylistDetailPage extends StatefulWidget {
  final String playlistId;
  final String playlistName;

  const PlaylistDetailPage({
    super.key,
    required this.playlistId,
    required this.playlistName,
  });

  @override
  State<PlaylistDetailPage> createState() => _PlaylistDetailPageState();
}

class _PlaylistDetailPageState extends State<PlaylistDetailPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  // Pastikan AudioManager memiliki fungsi pauseAllMixedSounds()
  final AudioManager _audioManager = AudioManager.instance;
  List<Sound> _sounds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPlaylistSounds();
  }

  // 📝 FUNGSI FETCH DATA DARI SUPABASE
  Future<void> _fetchPlaylistSounds() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('playlist_sound')
          .select('sound:id_sounds(*)')
          .eq('id_playlist', widget.playlistId)
          .order('id', ascending: true);

      final List<Sound> fetchedSounds = response
          .map((item) => Sound.fromJson(item['sound'] as Map<String, dynamic>))
          .toList();

      if (mounted) {
        setState(() {
          _sounds = fetchedSounds;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching playlist sounds: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // 🎧 FUNGSI MEMUTAR SEMUA SOUND DALAM PLAYLIST SECARA BERURUTAN (DIREVISI)
  void _playAllSounds() async {
    if (_sounds.isEmpty) {
      return;
    }

    final playerState = _audioManager.player.playerState;
    final processingState = playerState.processingState;
    final playing = playerState.playing;

    try {
      // 1. Jika player sedang di-PAUSE dan sudah dimuat (ready), kita lanjutkan (resume)
      if (processingState == ProcessingState.ready && !playing) {
        await _audioManager.player.play();
        return;
      }

      // 2. Hentikan semua player campuran sebelum memulai playlist baru (PENTING!)
      await _audioManager.pauseAllMixedSounds();
      await _audioManager.player.stop();

      final List<AudioSource> audioSources = _sounds.map((s) {
        return AudioSource.uri(Uri.parse(s.audioUrl), tag: s.title);
      }).toList();

      // 🌟 PERBAIKAN DI SINI: useLooping dihapus 🌟
      final ConcatenatingAudioSource playlistSource = ConcatenatingAudioSource(
        children: audioSources,
      );

      // Reset dan set audio source baru
      await _audioManager.player.setAudioSource(playlistSource);
      // Atur LoopMode ke off agar playlist tidak berulang secara otomatis
      await _audioManager.player.setLoopMode(LoopMode.off);
      await _audioManager.player.play();
    } catch (e) {
      debugPrint("Gagal memutar playlist: $e");
    }
  }

  // ⏸️ FUNGSI BARU: MENJEDA SEMUA SOUND DALAM PLAYLIST
  void _pauseAllSounds() async {
    await _audioManager.player.pause();
  }

  // 🎧 FUNGSI MEMUTAR SATU SOUND (DIREVISI)
  void _playSingleSound(Sound sound) async {
    try {
      // 1. Hentikan semua player campuran (PENTING!)
      await _audioManager.pauseAllMixedSounds();

      // 2. Hentikan putaran saat ini (baik single sound atau playlist)
      await _audioManager.player.stop();

      // 3. Set source baru (single sound) dan putar
      await _audioManager.player.setAudioSource(
        AudioSource.uri(Uri.parse(sound.audioUrl), tag: sound.title),
      );
      await _audioManager.player.play();
    } catch (e) {
      debugPrint("Gagal memutar sound tunggal: $e");
    }
  }

  // ❌ FUNGSI MENGHAPUS SOUND DARI PLAYLIST (Tidak Berubah)
  Future<void> _removeSoundFromPlaylist(
    String soundId,
    String soundTitle,
  ) async {
    try {
      await _supabase
          .from('playlist_sound')
          .delete()
          .eq('id_playlist', widget.playlistId)
          .eq('id_sounds', soundId);

      if (mounted) {
        await _fetchPlaylistSounds();
      }
    } catch (e) {
      debugPrint('Error removing sound from playlist: $e');
    }
  }

  // ⚙️ FUNGSI BARU: MENAMPILKAN POP UP OPSI SOUND (Tidak Berubah)
  void _showSoundOptionsMenu(Sound sound) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F0C2F), // Background gelap
          title: Text(
            'Opsi: ${sound.title}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Tombol Putar
              ListTile(
                leading: const Icon(
                  Icons.play_circle_outline,
                  color: Colors.white,
                ),
                title: const Text(
                  'Putar Sound Tunggal',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context); // Tutup pop up
                  _playSingleSound(sound); // Panggil fungsi putar
                },
              ),
              // 2. Tombol Hapus
              ListTile(
                leading: const Icon(
                  Icons.remove_circle_outline,
                  color: Colors.redAccent,
                ),
                title: const Text(
                  'Hapus dari Playlist',
                  style: TextStyle(color: Colors.redAccent),
                ),
                onTap: () async {
                  Navigator.pop(context); // Tutup pop up
                  await _removeSoundFromPlaylist(sound.id, sound.title);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Tutup',
                style: TextStyle(color: Color(0xff9290C3)),
              ),
            ),
          ],
        );
      },
    );
  }

  // 🎨 UI UTAMA
  @override
  Widget build(BuildContext context) {
    const Color iconColor = Colors.white;
    const Color textColor = Colors.white;
    const Color backgroundColor = Color(0xFF0F0C2F);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: CustomAppBar(title: widget.playlistName, subtitle: ''),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Playlist dan Tombol Play/Pause All (Menggunakan StreamBuilder)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 10.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Playlist',
                      style: TextStyle(fontSize: 16, color: Colors.white60),
                    ),
                    Text(
                      widget.playlistName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                // 🎯 StreamBuilder untuk Ikon Play/Pause
                StreamBuilder<PlayerState>(
                  stream: _audioManager.player.playerStateStream,
                  builder: (context, snapshot) {
                    final playerState = snapshot.data;
                    final playing = playerState?.playing ?? false;

                    // Tentukan apakah player utama sedang memutar audio (bukan idle atau completed)
                    final bool isPlayingPlaylist =
                        playing &&
                        (playerState?.processingState !=
                            ProcessingState.completed) &&
                        (playerState?.processingState != ProcessingState.idle);

                    // Tentukan fungsi yang akan dipanggil
                    final VoidCallback onPressedHandler = isPlayingPlaylist
                        ? _pauseAllSounds
                        : _playAllSounds;

                    // Tentukan ikon yang akan ditampilkan
                    final IconData icon = isPlayingPlaylist
                        ? Icons.pause
                        : Icons.play_arrow;

                    return Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(icon, color: backgroundColor),
                        onPressed: onPressedHandler,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, thickness: 1, height: 1),

          // Daftar Sound (Tidak Berubah)
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : ListView(
                    padding: const EdgeInsets.only(top: 8.0),
                    children: [
                      _buildAddSoundItem(iconColor),

                      if (_sounds.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 40),
                            child: Text(
                              'Playlist kosong. Tambahkan sound!',
                              style: TextStyle(color: Colors.white54),
                            ),
                          ),
                        )
                      else
                        ..._sounds.map((sound) {
                          return _SoundListItem(
                            sound: sound,
                            iconColor: iconColor,
                            // KLIK ICON: Membuka Pop Up Opsi
                            onOptionsTap: () => _showSoundOptionsMenu(sound),
                            // KLIK ITEM: Langsung Putar Sound
                            onSoundTap: () => _playSingleSound(sound),
                          );
                        }),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // Widget untuk tombol "Tambah Sound" (Tidak Berubah)
  Widget _buildAddSoundItem(Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          width: 60,
          height: 70,
          decoration: BoxDecoration(
            color: const Color(0xff9290C3),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: const Icon(Icons.add, color: Colors.black, size: 30),
        ),
        title: const Text(
          'Tambah sound',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54),
        onTap: () {},
      ),
    );
  }
}

// --- WIDGET ITEM DAFTAR SOUND (Tidak Berubah) ---

class _SoundListItem extends StatelessWidget {
  final Sound sound;
  final Color iconColor;
  final VoidCallback onOptionsTap;
  final VoidCallback onSoundTap;

  const _SoundListItem({
    required this.sound,
    required this.iconColor,
    required this.onOptionsTap,
    required this.onSoundTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xff9290C3),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.network(
              sound.imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                        : null,
                    color: iconColor.withOpacity(0.5),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.image_not_supported,
                  color: iconColor.withOpacity(0.8),
                  size: 30,
                );
              },
            ),
          ),
        ),
        title: Text(
          sound.title,
          style: const TextStyle(
            color: Color(0xff9290C3),
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.white54),
          onPressed: onOptionsTap, // Memanggil _showSoundOptionsMenu
        ),
        onTap: onSoundTap, // Memanggil _playSingleSound
      ),
    );
  }
}
