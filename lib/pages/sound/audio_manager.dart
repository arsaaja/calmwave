import 'package:just_audio/just_audio.dart';

class AudioManager {
  AudioManager._internal();

  static final AudioManager _instance = AudioManager._internal();

  static AudioManager get instance => _instance;

  final player = AudioPlayer();

  Future<void> setAudio(String assetPath) async {
    try {
      await player.setAsset(assetPath);
    } catch (e) {
      print("Error loading audio asset: $e");
    }
  }

  void playPause() {
    if (player.playing) {
      player.pause();
    } else {
      player.play();
    }
  }

  void dispose() {
    player.dispose();
  }
}
