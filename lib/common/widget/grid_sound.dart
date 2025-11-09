import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GridSound extends StatefulWidget {
  final String selectedCategory;

  const GridSound({super.key, required this.selectedCategory});

  @override
  State<GridSound> createState() => _GridSoundState();
}

class _GridSoundState extends State<GridSound> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _sounds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSounds();
  }

  @override
  void didUpdateWidget(GridSound oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCategory != widget.selectedCategory) {
      _fetchSounds();
    }
  }

  Future<void> _fetchSounds() async {
    setState(() => _isLoading = true);

    var query = _supabase
        .from('sounds')
        .select('id, judul, image_url, id_kategori',);

    if (widget.selectedCategory != "Semua") {
      // Sesuaikan filter dengan struktur database kamu
      query = query.eq('id_kategori', widget.selectedCategory);
    }

    final data = await query;
    setState(() {
      _sounds = List<Map<String, dynamic>>.from(data);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_sounds.isEmpty) {
      return const Center(
        child: Text(
          "Tidak ada data sound.",
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _sounds.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final sound = _sounds[index];
        return GestureDetector(
          onTap: () {
            Navigator.pushNamed(
              context,
              '/sound_player',
              arguments: sound['id'],
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xff9290C3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (sound['image_url'] != null)
                  Image.network(
                    sound['image_url'],
                    height: 130,
                    width: 130,
                    fit: BoxFit.contain,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
