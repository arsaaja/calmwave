import 'package:flutter/material.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import komponen pendukung (Ganti path sesuai proyek Anda)
import 'package:calm_wave/pages/sound/audio_manager.dart'; // AudioManager yang sudah dimodifikasi
import 'package:calm_wave/models/sound_model.dart'; // Model Sound
import 'package:calm_wave/common/widget/sound_selection.dart'; // SoundSelectionDialog
import 'package:calm_wave/pages/dashboard/dashboard.dart';
import 'package:calm_wave/pages/playlist/playlist.dart';
import 'package:calm_wave/pages/profile/profile.dart';
import 'package:calm_wave/pages/timer/timer.dart';

// --- KELAS POPUP (DIASUMSIKAN ADA) ---
class PopUp {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xff535C91),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          title: const Text("Perhatian", style: TextStyle(color: Colors.white)),
          content: const Text(
            "Untuk mengakses penuh aplikasi dibutuhkan login, anda ingin login?",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xff1B1A55),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text("Abaikan"),
            ),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xff070F2B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text("Login"),
            ),
          ],
        );
      },
    );
  }
}

// ------------------------------------------
//           CUSTOM TAB BAR UTAMA
// ------------------------------------------

class CustomTabBar extends StatefulWidget {
  const CustomTabBar({super.key});

  @override
  State<CustomTabBar> createState() => _CustomTabBarState();
}

class _CustomTabBarState extends State<CustomTabBar> {
  // State Navigasi & Auth
  int currentTab = 0;
  bool _isLoggedIn = false;
  StreamSubscription<AuthState>? _authStateSubscription;

  // State Audio
  final AudioManager _audioManager = AudioManager.instance;
  List<Sound> _allSounds = [];
  bool _isLoadingSounds = true;
  static const String _defaultBackgroundSoundId =
      'music_default'; // ID untuk background music

  // Daftar index halaman dan index yang memerlukan login
  final List<Widget> screens = [
    const Dashboard(),
    const Playlist(),
    const Timer(),
    const Profile(),
  ];
  final List<int> requiresLogin = [1, 2, 3];

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
    _listenToAuthChanges();
    // 1. Ambil semua sound saat inisialisasi
    _fetchAllSounds();
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    // 2. Penting: Stop semua mixed sound saat CustomTabBar di-dispose (misalnya saat keluar aplikasi)
    _audioManager.stopAllMixedSounds();
    _audioManager.dispose();
    super.dispose();
  }

  // =================================================================
  //  LOGIKA AUDIO & DATA
  // =================================================================

  Future<void> _fetchAllSounds() async {
    setState(() {
      _isLoadingSounds = true;
    });
    try {
      // Ambil data dari Supabase (asumsi tabel 'sounds')
      final response = await Supabase.instance.client
          .from('sounds')
          .select('id, judul, audio_url, image_url');

      final List<Sound> fetchedSounds = List<Map<String, dynamic>>.from(
        response,
      ).map((data) => Sound.fromJson(data)).toList();

      setState(() {
        _allSounds = fetchedSounds;
        _isLoadingSounds = false;
      });
    } catch (e) {
      debugPrint("Error fetching all sounds for PopUp: $e");
      setState(() {
        _isLoadingSounds = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memuat daftar sound dari server.'),
          ),
        );
      }
    }
  }

  // --- HANDLER SELECTION DARI POPUP/GRID ---
  void _handleSelectionConfirmed(List<Sound> updatedSounds) {
    const int maxSounds = AudioManager.MAX_MIXED_SOUNDS; // Batas 3
    final selectedMixedSounds = updatedSounds
        .where((s) => s.isSelected && s.id != _defaultBackgroundSoundId)
        .toList();

    // 1. Terapkan Batas 3 Sound Campuran
    if (selectedMixedSounds.length > maxSounds) {
      // Nonaktifkan sound ke-4 dan seterusnya
      for (int i = maxSounds; i < selectedMixedSounds.length; i++) {
        selectedMixedSounds[i].isSelected = false;
        _stopAudio(selectedMixedSounds[i].id);
      }
      _showLimitWarning(context);
    }

    setState(() {
      _allSounds = updatedSounds;

      // 2. Perbarui Audio Manager
      _updateAudioManager();
    });
  }

  // --- LOGIKA PLAYBACK KE AUDIO MANAGER ---
  void _updateAudioManager() {
    // Loop untuk mixed sounds
    for (var sound in _allSounds.where(
      (s) => s.id != _defaultBackgroundSoundId,
    )) {
      if (sound.isSelected) {
        _playAudio(sound);
      } else {
        _stopAudio(sound.id);
      }
    }

    // Loop untuk background music
    final bgMusic = _allSounds.firstWhereOrNull(
      (s) => s.id == _defaultBackgroundSoundId,
    );
    if (bgMusic != null) {
      if (bgMusic.isSelected) {
        _playAudio(bgMusic);
      } else {
        _stopAudio(bgMusic.id);
      }
    }
  }

  void _playAudio(Sound sound) {
    try {
      if (sound.id == _defaultBackgroundSoundId) {
        // Background Music: Gunakan player default
        _audioManager.setAudioUrlDefault(sound.audioUrl).then((_) {
          _audioManager.player.setVolume(sound.volume); // Set volume background
          _audioManager.playPauseDefault();
        });
      } else {
        // Sound Campuran: Gunakan multi-player (dengan batasan 3)
        _audioManager.playMixedSound(
          soundId: sound.id,
          url: sound.audioUrl,
          volume: sound.volume,
        );
      }
    } on Exception catch (e) {
      // Tangani jika batasan 3 sound tercapai di AudioManager
      debugPrint('PLAY GAGAL: $e');
      _showLimitWarning(context);

      // Sinkronkan kembali model di UI
      setState(() {
        final failedSound = _allSounds.firstWhere((s) => s.id == sound.id);
        failedSound.isSelected = false;
      });
    }
  }

  void _stopAudio(String soundId) {
    if (soundId == _defaultBackgroundSoundId) {
      _audioManager.player.pause();
    } else {
      _audioManager.stopMixedSound(soundId);
    }
  }

  void _showLimitWarning(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hanya bisa memilih maksimal 3 sound campuran.'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // =================================================================
  // 🔐 LOGIKA OTENTIKASI
  // =================================================================

  void _checkAuthStatus() {
    final user = Supabase.instance.client.auth.currentUser;
    setState(() {
      _isLoggedIn = user != null;
    });
  }

  void _listenToAuthChanges() {
    _authStateSubscription = Supabase.instance.client.auth.onAuthStateChange
        .listen((data) {
          final AuthChangeEvent event = data.event;
          final Session? session = data.session;

          if (event == AuthChangeEvent.signedIn ||
              event == AuthChangeEvent.signedOut) {
            setState(() {
              _isLoggedIn = session != null;
              if (!_isLoggedIn && currentTab != 0) {
                currentTab = 0;
              }
            });
          }
        });
  }

  // =================================================================
  // 🎨 UI DAN FLOATING BUTTON
  // =================================================================

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn && currentTab != 0) {
      currentTab = 0;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF070F2B),

      body: IndexedStack(
        key: ValueKey(currentTab),
        index: currentTab,
        children: screens,
      ),

      // 🎶 Floating Play Button -> Sound Selection Pop Up
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xff3D447C),
        elevation: 6,
        shape: const CircleBorder(),
        onPressed: () {
          if (_isLoadingSounds) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Memuat daftar sound...')),
            );
          } else if (_allSounds.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tidak ada sound yang tersedia.')),
            );
          } else {
            // Tampilkan PopUp Dialog Sound Selection
            showDialog(
              context: context,
              builder: (BuildContext dialogContext) {
                return SoundSelectionDialog(
                  initialSounds: _allSounds
                      .map((s) => s.copyWith())
                      .toList(), // Kirim salinan
                  onSelectionConfirmed: _handleSelectionConfirmed,
                );
              },
            );
          }
        },
        child: _isLoadingSounds
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(
                Icons.music_note_rounded,
                size: 36,
                color: Colors.white,
              ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // BottomAppBar
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: const Color(0xFF1B1A55),
        child: SizedBox(
          height: 65,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTabButton(Icons.home_rounded, 0),
              _buildTabButton(Icons.bookmark_rounded, 1),
              const SizedBox(width: 40),
              _buildTabButton(Icons.access_time_rounded, 2),
              _buildTabButton(Icons.person_rounded, 3),
            ],
          ),
        ),
      ),
    );
  }

  // Fungsi pembangun untuk setiap tombol tab
  Widget _buildTabButton(IconData icon, int index) {
    final bool isRestricted = requiresLogin.contains(index) && !_isLoggedIn;
    bool isActive = currentTab == index;

    Color iconColor = isActive
        ? Colors.white
        : (isRestricted ? Colors.grey.shade700 : Colors.grey);
    Color containerColor = isActive
        ? const Color(0xFF535C91)
        : Colors.transparent;

    return MaterialButton(
      minWidth: 40,
      onPressed: isRestricted
          ? () {
              PopUp.show(context);
            }
          : () {
              setState(() {
                currentTab = index;
              });
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: containerColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 28),
      ),
    );
  }
}

// Extension sederhana untuk memudahkan pencarian (Opsional, tapi membantu)
extension ListExtension<E> on List<E> {
  E? firstWhereOrNull(bool Function(E element) test) {
    for (E element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
