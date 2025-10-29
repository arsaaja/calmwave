import 'package:just_audio/just_audio.dart';

class AudioManager {
  final AudioPlayer _player = AudioPlayer();

  AudioPlayer get player => _player;

  Future<void> setAudio(String path) async {
    await _player.setAsset(path); // misalnya dari assets/audio/suara.mp3
  }

  Future<void> playPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  void seekTo(Duration position) {
    _player.seek(position);
  }

  void dispose() {
    _player.dispose();
  }
}
