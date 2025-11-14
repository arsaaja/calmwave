import 'package:just_audio/just_audio.dart';

class AudioManager {
  AudioManager._internal();
  static final AudioManager _instance = AudioManager._internal();
  static AudioManager get instance => _instance;

  // player default, supaya kode lama tetap jalan
  AudioPlayer player = AudioPlayer();

  // Map untuk multi-sound (jangan ganggu player default)
  final Map<String, AudioPlayer> _players = {};

  AudioPlayer getPlayer(String soundId) {
    if (!_players.containsKey(soundId)) {
      _players[soundId] = AudioPlayer();
    }
    return _players[soundId]!;
  }

  Future<void> setAudioUrl(String soundId, String url) async {
    if (soundId == "default") {
      await player.setUrl(url);
    } else {
      await getPlayer(soundId).setUrl(url);
    }
  }

  void playPause({String soundId = "default"}) {
    final p = soundId == "default" ? player : getPlayer(soundId);
    if (p.playing) {
      p.pause();
    } else {
      p.play();
    }
  }

  void dispose() {
    player.dispose();
    for (var p in _players.values) {
      p.dispose();
    }
  }
}
