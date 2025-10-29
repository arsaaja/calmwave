import 'package:flutter/material.dart';
import 'audio_manager.dart';

class SoundPlayer extends StatefulWidget {
  const SoundPlayer({super.key});

  @override
  State<SoundPlayer> createState() => _SoundPlayerState();
}

class _SoundPlayerState extends State<SoundPlayer> {
  late final AudioManager audioManager;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isMuted = false;
  double _previousVolume = 1.0;
  double _volume = 1.0; // volume default 100%

  @override
  void initState() {
    super.initState();
    audioManager = AudioManager();
    _initializeAudio();
  }

  Future<void> _initializeAudio() async {
    await audioManager.setAudio('assets/audio/sample.mp3');

    // durasi lagu
    audioManager.player.durationStream.listen((d) {
      if (d != null) setState(() => _duration = d);
    });

    // posisi lagu
    audioManager.player.positionStream.listen((p) {
      setState(() => _position = p);
    });
  }

  void _toggleMute() {
    setState(() {
      if (_isMuted) {
        // Kembali ke volume sebelumnya
        audioManager.player.setVolume(_previousVolume);
        _isMuted = false;
        _volume = _previousVolume;
      } else {
        // Menyimpen volume lama dan set jadi 0
        _previousVolume = _volume;
        audioManager.player.setVolume(0);
        _isMuted = true;
        _volume = 0;
      }
    });
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    audioManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 55,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        margin: const EdgeInsets.only(bottom: 45, left: 12, right: 12),
        decoration: BoxDecoration(
          color: const Color(0xff535C91),
          borderRadius: BorderRadius.circular(25),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Tombol Play / Pause
            IconButton(
              icon: Icon(
                audioManager.player.playing ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
              ),
              iconSize: 30,
              onPressed: () => audioManager.playPause(),
            ),

            // Tombol Mute / Unmute
            IconButton(
              icon: Icon(
                _isMuted ? Icons.volume_off : Icons.volume_up_rounded,
                color: Colors.white,
              ),
              iconSize: 25,
              onPressed: _toggleMute,
            ),

            // Slider Volume
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 2,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 4,
                  ),
                ),
                child: Slider(
                  value: _volume,
                  min: 0.0,
                  max: 1.0,
                  divisions: 10,
                  label: '${(_volume * 100).toInt()}%',
                  activeColor: const Color(0xFF0A0A3F),
                  inactiveColor: Colors.white,
                  onChanged: (value) {
                    setState(() {
                      _volume = value;
                      _isMuted = value == 0;
                    });
                    audioManager.player.setVolume(value);
                  },
                ),
              ),
            ),

            // Tombol Playlist
            IconButton(
              icon: const Icon(Icons.bookmark_add, color: Colors.white),
              iconSize: 25,
              onPressed: () {
                // Tambahkan pop up nanti
              },
            ),
          ],
        ),
      ),
    );
  }
}
