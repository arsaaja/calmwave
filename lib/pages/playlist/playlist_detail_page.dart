import 'package:calm_wave/common/widget/custom_appbar.dart';
import 'package:calm_wave/models/sound_model.dart'; // Import model Sound
import 'package:flutter/material.dart';
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
  List<Sound> _sounds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPlaylistSounds();
  }

  // --- FUNGSI FETCH DATA DARI SUPABASE ---
  Future<void> _fetchPlaylistSounds() async {
    try {
      final response = await _supabase
          .from('playlist_sound')
          .select('sound:id_sounds(*)')
          .eq('id_playlist', widget.playlistId)
          .order('id', ascending: true);

      // Mapping data Supabase ke Model Sound
      final List<Sound> fetchedSounds = response
          .map((item) => Sound.fromJson(item['sound']))
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
          // Header Playlist (sesuai desain)
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
                      widget.playlistName, // Nama playlist
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
                    onPressed: () {
                      // Aksi putar playlist
                    },
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
                      // Item "Tambah sound"
                      _buildAddSoundItem(iconColor),

                      // Item-item Sound dari Supabase
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
                          );
                        }).toList(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // Widget untuk tombol "Tambah Sound"
  Widget _buildAddSoundItem(Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          // **UKURAN DIPERBESAR**
          width: 60,
          height: 70,
          decoration: BoxDecoration(
            // Diubah menjadi warna putih agar ikon hitam terlihat jelas
            color: Color(0xff9290C3),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: const Icon(
            Icons.add,
            // **WARNA DIUBAH MENJADI HITAM**
            color: Colors.black,
            size: 30,
          ),
        ),
        title: const Text(
          'Tambah sound',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(Icons.more_vert, color: Colors.white54),
        onTap: () {
          // Aksi navigasi ke halaman pemilihan Sound untuk ditambahkan
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Buka halaman Add Sound')),
          );
        },
      ),
    );
  }
}

// 🎧 Widget untuk setiap item Sound, dimodifikasi untuk menampilkan Gambar dari URL
class _SoundListItem extends StatelessWidget {
  final Sound sound;
  final Color iconColor;

  const _SoundListItem({required this.sound, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          // **UKURAN DIPERBESAR**
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Color(0xff9290C3),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            // Menggunakan Image.network untuk memuat gambar dari URL
            child: Image.network(
              sound.imageUrl,
              fit: BoxFit.cover, // Atur bagaimana gambar akan mengisi container
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                // Tampilkan loading indicator
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
                // Tampilkan ikon default jika gagal memuat gambar
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
        trailing: const Icon(Icons.more_vert, color: Colors.white54),
        onTap: () {
          // Aksi putar Sound ini
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Memutar: ${sound.title}')));
        },
      ),
    );
  }
}
