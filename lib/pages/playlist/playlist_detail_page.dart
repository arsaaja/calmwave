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
          // Kueri yang diperbaiki: Menggunakan alias 'sound' dan referensi kolom FK 'id_sounds'
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memuat sound playlist.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 🎧 FUNGSI BARU: MEMUTAR SATU SOUND
  void _playSingleSound(Sound sound) async {
    try {
      await _audioManager.player.stop();
      await _audioManager.player.setAudioSource(
        AudioSource.uri(Uri.parse(sound.audioUrl), tag: sound.title),
      );
      await _audioManager.player.play();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Memutar: ${sound.title}'),
            backgroundColor: const Color(0xFF535C91),
          ),
        );
      }
    } catch (e) {
      debugPrint("Gagal memutar sound tunggal: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memutar sound. Cek URL audio.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 🎧 FUNGSI MEMUTAR SEMUA SOUND DALAM PLAYLIST SECARA BERURUTAN
  void _playAllSounds() async {
    if (_sounds.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Playlist kosong!')));
      return;
    }

    try {
      final List<AudioSource> audioSources = _sounds.map((s) {
        return AudioSource.uri(Uri.parse(s.audioUrl), tag: s.title);
      }).toList();

      final ConcatenatingAudioSource playlistSource = ConcatenatingAudioSource(
        children: audioSources,
      );

      await _audioManager.player.stop();
      await _audioManager.player.setAudioSource(playlistSource);
      await _audioManager.player.play();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Memutar ${_sounds.length} sound dari playlist "${widget.playlistName}" secara berurutan!',
            ),
            backgroundColor: const Color(0xFF535C91),
          ),
        );
      }
    } catch (e) {
      debugPrint("Gagal memutar playlist: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memutar playlist. Cek URL audio.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ❌ FUNGSI MENGHAPUS SOUND DARI PLAYLIST
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"$soundTitle" berhasil dihapus dari playlist.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error removing sound from playlist: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menghapus sound dari playlist.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ⚙️ FUNGSI BARU: MENAMPILKAN POP UP OPSI SOUND
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
          // Header Playlist dan Tombol Play All
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
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.play_arrow, color: backgroundColor),
                    onPressed: _playAllSounds,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, thickness: 1, height: 1),

          // Daftar Sound
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
                            // 🎯 KLIK ICON: Membuka Pop Up Opsi
                            onOptionsTap: () => _showSoundOptionsMenu(sound),
                            // 🎯 KLIK ITEM: Langsung Putar Sound
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
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Navigasi ke halaman Add Sound')),
          );
        },
      ),
    );
  }
}

// --- WIDGET ITEM DAFTAR SOUND (Tidak Berubah, hanya penggunaan callback yang berubah) ---

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
