// Untuk tabel pivot: playlist_sound
class PlaylistSound {
  final String id;
  final String playlistId; // id_playlist
  final String soundId; // id_sounds

  PlaylistSound({
    required this.id,
    required this.playlistId,
    required this.soundId,
  });

  factory PlaylistSound.fromJson(Map<String, dynamic> json) {
    return PlaylistSound(
      id: json['id'] as String,
      playlistId: json['id_playlist'] as String,
      soundId: json['id_sounds'] as String,
    );
  }
}
