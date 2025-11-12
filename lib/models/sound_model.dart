// lib/models/sound_model.dart

class Sound {
  final String id;
  final String title;
  final String audioUrl;
  final String imageUrl; // Digunakan untuk menentukan Icon/Gambar

  Sound({
    required this.id,
    required this.title,
    required this.audioUrl,
    required this.imageUrl,
  });

  factory Sound.fromJson(Map<String, dynamic> json) {
    // Supabase biasanya mengembalikan data JOIN sebagai map.
    // Jika Anda menggunakan `.select('sound(*)')`, datanya akan berada di 'sound'.
    final data = json['sound'] ?? json;

    return Sound(
      id: data['id'] as String,
      title: data['judul'] as String,
      audioUrl: data['audio_url'] as String,
      imageUrl: data['image_url'] as String,
    );
  }
}
