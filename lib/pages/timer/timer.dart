import 'package:calm_wave/common/widget/custom_appbar.dart';
import 'package:calm_wave/pages/sound/audio_manager.dart'; // <- IMPORT PENTING
import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:flutter/material.dart';

class Timer extends StatefulWidget {
  const Timer({super.key});

  @override
  State<Timer> createState() => _TimerState();
}

class _TimerState extends State<Timer> {
  final CountDownController _controller = CountDownController();
  final TextEditingController _inputController = TextEditingController();

  // --- PERUBAHAN UTAMA ---
  // Dapatkan satu-satunya instance AudioManager, bukan membuat yang baru.
  final AudioManager _audioManager = AudioManager.instance;

  bool _isRunning = false;
  bool _isPaused = false;
  int _duration = 0;

  @override
  void initState() {
    super.initState();
    // Tidak perlu lagi membuat instance AudioManager di sini.
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _startTimer() {
    // Sembunyikan keyboard saat timer dimulai
    FocusScope.of(context).unfocus();

    final int? minutes = int.tryParse(_inputController.text);
    if (minutes == null || minutes <= 0) {
      // Tampilkan pesan jika input tidak valid
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan jumlah menit yang valid.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final int durationInSeconds = minutes * 60;

    setState(() {
      _duration = durationInSeconds;
      _isRunning = true;
      _isPaused = false;
    });

    _controller.restart(duration: _duration);
  }

  void _pauseTimer() {
    _controller.pause();
    setState(() => _isPaused = true);
  }

  void _resumeTimer() {
    _controller.resume();
    setState(() => _isPaused = false);
  }

  void _resetTimer() {
    _controller.reset();
    _inputController.clear();
    setState(() {
      _duration = 0;
      _isRunning = false;
      _isPaused = false;
    });
  }

  // Fungsi ini sekarang akan bekerja dengan benar.
  void _onTimerComplete() {
    // Cek apakah player dari AudioManager sedang berjalan
    if (_audioManager.player.playing) {
      _audioManager.player.pause();
    }
    setState(() {
      _isRunning = false;
      _isPaused = false;
      _duration = 0;
    });

    // Beri notifikasi kepada pengguna
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Waktu habis! Audio telah dijeda.'),
        backgroundColor: Color(0xFF535C91),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070F2B),
      appBar: const CustomAppBar(
        title: 'Hi, User!',
        subtitle: 'Lagi mau dengerin apa?',
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Calmwave Timer",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              const Icon(Icons.access_time, color: Colors.white, size: 60),
              const SizedBox(height: 24),
              const Text(
                "Set your Relaxation Time",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 30),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF161E54),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _inputController,
                  keyboardType: TextInputType.number,
                  enabled: !_isRunning,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: "Masukkan waktu (menit)",
                    hintStyle: TextStyle(color: Colors.white54),
                  ),
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Adjust Time: ${_inputController.text.isEmpty ? 0 : _inputController.text} minutes",
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 40),
              CircularCountDownTimer(
                duration: _duration,
                initialDuration: 0,
                controller: _controller,
                width: 220,
                height: 220,
                ringColor: const Color(0xFF4048BF),
                fillColor: Colors.white,
                backgroundColor: const Color(0xFF161E54),
                strokeWidth: 10,
                strokeCap: StrokeCap.round,
                textStyle: const TextStyle(
                  fontSize: 40.0,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                isReverse: true,
                autoStart: false,
                isTimerTextShown: true,
                onComplete: _onTimerComplete,
              ),
              const SizedBox(height: 40),
              if (!_isRunning)
                ElevatedButton.icon(
                  onPressed: _startTimer,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text("Start Timer"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF535C91),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isPaused ? _resumeTimer : _pauseTimer,
                      icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                      label: Text(_isPaused ? "Lanjutkan" : "Jeda"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF535C91),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 25,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _resetTimer,
                      icon: const Icon(Icons.stop),
                      label: const Text("Batal"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9290C3),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 25,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
