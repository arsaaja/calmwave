import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart'; // Digunakan untuk debugPrint

class AudioManager {
  AudioManager._internal();
  static final AudioManager _instance = AudioManager._internal();
  static AudioManager get instance => _instance;

  // Batasan Maksimal Sound Campuran
  static const int MAX_MIXED_SOUNDS = 3;

  // player default (digunakan oleh SoundPlayer/Mini Player untuk Lagu Tunggal atau Playlist)
  AudioPlayer player = AudioPlayer();

  // Map untuk multi-sound (sound campuran: soundId -> AudioPlayer)
  final Map<String, AudioPlayer> _players = {};

  AudioPlayer getPlayer(String soundId) {
    if (!_players.containsKey(soundId)) {
      _players[soundId] = AudioPlayer();
      _players[soundId]!.setLoopMode(LoopMode.one);
    }
    return _players[soundId]!;
  }

  // -------------------------------------------------------------------
  // --- KONTROL GLOBAL (Untuk SoundPlayer/Mini Player) ---
  // -------------------------------------------------------------------

  // 🆕 Metode untuk PAUSE SEMUA AUDIO (Lagu Tunggal + Campuran)
  Future<void> pauseAll() async {
    // Pause player default (Lagu Tunggal/Playlist)
    if (player.playing) {
      await player.pause();
    }

    // Pause semua player campuran
    for (var p in _players.values) {
      if (p.playing) {
        await p.pause();
      }
    }
    debugPrint('GLOBAL CONTROL: Semua audio di-pause.');
  }

  // 🆕 Metode untuk PAUSE SEMUA AUDIO CAMPURAN SAJA (PENTING untuk Playlist)
  Future<void> pauseAllMixedSounds() async {
    final futures = <Future>[];
    for (var p in _players.values) {
      if (p.playing) {
        futures.add(p.pause());
      }
    }
    await Future.wait(futures);
    debugPrint('MIXED CONTROL: Semua mixed sounds di-pause.');
  }

  // 🆕 Metode untuk PLAY SEMUA AUDIO (Lagu Tunggal + Campuran)
  Future<void> playAll() async {
    // Play player default (Lagu Tunggal/Playlist), jika sudah di-set
    if (player.processingState != ProcessingState.idle && !player.playing) {
      await player.play();
    }

    // Play semua player campuran yang aktif
    for (var p in _players.values) {
      if (p.processingState != ProcessingState.idle && !p.playing) {
        await p.play();
      }
    }
    debugPrint('GLOBAL CONTROL: Semua audio di-play.');
  }

  bool get isAnyAudioPlaying {
    // 1. Cek player default
    if (player.playing) {
      return true;
    }

    // 2. Cek semua player campuran
    for (var p in _players.values) {
      if (p.playing) {
        return true;
      }
    }

    return false;
  }

  // -------------------------------------------------------------------
  // --- Metode Sound Campuran (Diakses dari Pop-up/Grid) ---
  // -------------------------------------------------------------------

  int get activeMixedSoundCount => _players.length;

  Future<void> playMixedSound({
    required String soundId,
    required String url,
    required double volume,
  }) async {
    final bool isNew = !_players.containsKey(soundId);

    if (isNew && activeMixedSoundCount >= MAX_MIXED_SOUNDS) {
      debugPrint('GAGAL: Batas $MAX_MIXED_SOUNDS sound campuran tercapai.');
      throw Exception(
        'Maksimal $MAX_MIXED_SOUNDS sound campuran yang dapat dimainkan.',
      );
    }

    final p = getPlayer(soundId);

    if (isNew) {
      await p.setUrl(url);
    }

    await p.setVolume(volume);

    if (!p.playing) {
      // ⚠️ PENTING: Jika ada lagu/playlist di player default, hentikan dulu
      if (player.playing) {
        await player.stop();
        debugPrint(
          'MIXED: Player default dihentikan untuk memberi ruang pada mixed sound.',
        );
      }

      await p.play();
      debugPrint('MIXED: Memutar sound baru: $soundId dengan Volume: $volume');
    } else {
      debugPrint('MIXED: Volume $soundId diupdate ke $volume');
    }
  }

  Future<void> stopMixedSound(String soundId) async {
    final p = _players.remove(soundId);
    if (p != null) {
      await p.stop();
      await p.dispose();
      debugPrint('MIXED: Sound $soundId dihentikan dan dispose.');
    }
  }

  Future<void> stopAllMixedSounds() async {
    debugPrint('MIXED: Menghentikan semua mixed sounds...');
    final List<String> activeIds = _players.keys.toList();
    for (String id in activeIds) {
      await stopMixedSound(id);
    }
  }

  // -------------------------------------------------------------------
  // --- Metode Warisan/Lama (Gunakan Player Default) ---
  // -------------------------------------------------------------------

  Future<void> setAudioUrlDefault(String url) async {
    if (player.audioSource != null) {
      await player.stop();
    }
    await player.setUrl(url);
  }

  void playPauseDefault() {
    if (player.playing) {
      player.pause();
    } else {
      player.play();
    }
  }

  Future<void> setAudioUrl(String soundId, String url) async {
    if (soundId == "default") {
      await setAudioUrlDefault(url);
    } else {
      await getPlayer(soundId).setUrl(url);
    }
  }

  void playPause({String soundId = "default"}) {
    if (soundId == "default") {
      playPauseDefault();
    } else {
      final p = getPlayer(soundId);
      if (p.playing) {
        p.pause();
      } else {
        p.play();
      }
    }
  }

  // -------------------------------------------------------------------
  // --- Dispose ---
  // -------------------------------------------------------------------

  @mustCallSuper
  void dispose() {
    stopAllMixedSounds(); // Membersihkan semua sound campuran
    player.dispose(); // Player default
    debugPrint('AudioManager dispose complete.');
  }
}
