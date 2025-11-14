import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GridSound extends StatefulWidget {
  // Menerima ID Kategori (UUID) untuk filter
  final String selectedCategoryId;

  const GridSound({super.key, required this.selectedCategoryId});

  @override
  State<GridSound> createState() => _GridSoundState();
}

class _GridSoundState extends State<GridSound> {
  final supabase = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _soundFuture;

  @override
  void initState() {
    super.initState();
    _soundFuture = _fetchSounds();
  }

  @override
  void didUpdateWidget(covariant GridSound oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Panggil ulang fetch saat ID kategori berubah
    if (oldWidget.selectedCategoryId != widget.selectedCategoryId) {
      _soundFuture = _fetchSounds();
    }
  }

  Future<List<Map<String, dynamic>>> _fetchSounds() async {
    try {
      final categoryId = widget.selectedCategoryId;

      PostgrestFilterBuilder query = supabase.from('sounds').select('*');

      if (categoryId != "all") {
        query = query.eq('id_kategori', categoryId);
      }

      final response = await query.order('judul', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("Error fetching sounds: $e");
      throw Exception('Gagal memuat data sounds.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      key: ValueKey(widget.selectedCategoryId),
      future: _soundFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.redAccent),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'Tidak ada sound dalam kategori ini.',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        final sounds = snapshot.data!;

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
            childAspectRatio: 1.0,
          ),
          itemCount: sounds.length,
          itemBuilder: (context, index) {
            final sound = sounds[index];

            return _SoundGridItem(
              imageUrl: sound['image_url'] ?? '',

             
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/sound_player',
                  arguments: <String, String>{
                    'soundId': sound['id'].toString(),
                    'audioUrl': (sound['audio_url'] ?? '').toString(),
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

// --- Widget untuk Tampilan Grid ---
class _SoundGridItem extends StatelessWidget {
  final String imageUrl;
  final VoidCallback onTap;

  const _SoundGridItem({required this.imageUrl, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // ➕ Aksi pencet
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF9290C3),
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,

            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white70,
                    strokeWidth: 2,
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },

            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_not_supported,
                      color: Colors.white54,
                      size: 40,
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Gagal muat',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
