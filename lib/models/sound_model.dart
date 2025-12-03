class Sound {
  final String id;
  final String title;
  final String audioUrl;
  final String imageUrl; // Digunakan untuk menentukan Icon/Gambar
  bool isSelected; // Status pilihan (aktif/nonaktif)
  double volume; // Status volume (dari 0.0 sampai 1.0)

  Sound({
    required this.id,
    required this.title,
    required this.audioUrl,
    required this.imageUrl,
    this.isSelected = false, // Default: tidak dipilih
    this.volume = 0.5, // Default volume
  });

  // Factory constructor dari Supabase/JSON
  factory Sound.fromJson(Map<String, dynamic> json) {
    final data = json['sound'] ?? json;

    return Sound(
      id: data['id'] as String,
      title: data['judul'] as String,
      audioUrl: data['audio_url'] as String,
      imageUrl: data['image_url'] as String,
      isSelected: false,
      volume: 0.5,
    );
  }

  // Metode untuk membuat salinan Sound (penting untuk manajemen state)
  Sound copyWith({bool? isSelected, double? volume}) {
    return Sound(
      id: id,
      title: title,
      audioUrl: audioUrl,
      imageUrl: imageUrl,
      isSelected: isSelected ?? this.isSelected,
      volume: volume ?? this.volume,
    );
  }
}
