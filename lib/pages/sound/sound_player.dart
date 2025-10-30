import 'package:calm_wave/pages/sound/audio_manager.dart'; // <- IMPORT PENTING
import 'package:flutter/material.dart';

class SoundPlayer extends StatefulWidget {
  const SoundPlayer({super.key});

  @override
  State<SoundPlayer> createState() => _SoundPlayerState();
}

class _SoundPlayerState extends State<SoundPlayer> {
  final AudioManager _audioManager = AudioManager.instance;

  bool isPlaying = false;
  bool isBookmarked = false;
  bool isMuted = false;
  double volume = 0.5;

  final String audioUrl =
      'https://vioeocsssqihgkbjuucm.supabase.co/storage/v1/object/public/sounds/sounds/rain-and-thunder-for-better-sleep-148899.mp3';

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      if (_audioManager.player.audioSource == null) {
        await _audioManager.player.setUrl(audioUrl);
      }

      setState(() {
        isPlaying = _audioManager.player.playing;
        volume = _audioManager.player.volume;
        isMuted = volume == 0;
      });

      _audioManager.player.playingStream.listen((playing) {
        if (mounted) {
          setState(() => isPlaying = playing);
        }
      });

      _audioManager.player.volumeStream.listen((currentVolume) {
        if (mounted) {
          setState(() {
            volume = currentVolume;
            isMuted = currentVolume == 0;
          });
        }
      });
    } catch (e) {
      debugPrint("Gagal memuat audio: $e");
    }
  }

  Future<void> _togglePlay() async {
    if (_audioManager.player.playing) {
      await _audioManager.player.pause();
    } else {
      await _audioManager.player.play();
    }
  }

  Future<void> _toggleMute() async {
    final newMuteState = !isMuted;
    if (newMuteState) {
      await _audioManager.player.setVolume(0);
    } else {
      double newVolume = volume > 0 ? volume : 0.5;
      await _audioManager.player.setVolume(newVolume);
    }
    setState(() {
      isMuted = newMuteState;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFF535C91),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Tombol Play/Pause
          IconButton(
            onPressed: _togglePlay,
            icon: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 22,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 6),
          // Tombol Mute/Unmute
          IconButton(
            onPressed: _toggleMute,
            icon: Icon(
              isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
              color: Colors.white,
              size: 20,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 6),
          // Volume Bar (Slider)
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                trackHeight: 4,
                overlayShape: SliderComponentShape.noOverlay,
              ),
              child: Slider(
                value: volume, // Nilai slider langsung dari state
                min: 0,
                max: 1,
                onChanged: (v) async {
                  // Langsung set volume ke player global
                  await _audioManager.player.setVolume(v);
                },
                activeColor: const Color(0xFF0A0A3F),
                inactiveColor: Colors.white70,
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Tombol Playlist
          IconButton(
            onPressed: () {
              setState(() => isBookmarked = !isBookmarked);
            },
            icon: Icon(
              isBookmarked
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              color: Colors.white,
              size: 20,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
