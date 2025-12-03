import 'package:flutter/material.dart';
import 'package:calm_wave/models/sound_model.dart';

class SoundSelectionDialog extends StatefulWidget {
  // Menerima daftar SoundItem dengan status isSelected dan volume saat ini
  final List<Sound> initialSounds;

  // Callback untuk mengembalikan daftar SoundItem yang sudah diubah statusnya
  final Function(List<Sound> selectedSounds) onSelectionConfirmed;

  const SoundSelectionDialog({
    Key? key,
    required this.initialSounds,
    required this.onSelectionConfirmed,
  }) : super(key: key);

  @override
  _SoundSelectionDialogState createState() => _SoundSelectionDialogState();
}

class _SoundSelectionDialogState extends State<SoundSelectionDialog> {
  // Gunakan salinan untuk mengelola state di dialog tanpa memengaruhi data parent
  late List<Sound> _currentSounds;

  @override
  void initState() {
    super.initState();
    // Salin objek, bukan hanya referensi
    _currentSounds = widget.initialSounds
        .map((item) => item.copyWith())
        .toList();
  }

  Widget _buildSoundListItem(Sound item) {
    // Tentukan ikon berdasarkan judul (opsional, bisa pakai gambar)
    IconData icon;
    if (item.title.toLowerCase().contains('mic')) {
      icon = Icons.mic_external_on;
    } else if (item.title.toLowerCase().contains('keyboard')) {
      icon = Icons.keyboard;
    } else {
      icon = Icons.volume_up;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        children: [
          ListTile(
            leading: Icon(icon, color: Colors.white),
            title: Text(
              item.title,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            // Checkbox di samping kanan
            trailing: Checkbox(
              value: item.isSelected,
              onChanged: (bool? newValue) {
                setState(() {
                  item.isSelected = newValue ?? false;
                });
              },
              activeColor: Colors.blueAccent,
              checkColor: Colors.white,
            ),
            onTap: () {
              setState(() {
                item.isSelected = !item.isSelected;
              });
            },
          ),
          // Tambahkan slider volume jika item dipilih
          if (item.isSelected)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.volume_down,
                    color: Colors.white70,
                    size: 18,
                  ),
                  Expanded(
                    child: Slider(
                      value: item.volume,
                      min: 0.0,
                      max: 1.0,
                      divisions: 100,
                      onChanged: (double value) {
                        setState(() {
                          item.volume = value;
                        });
                      },
                      activeColor: Colors.lightGreen,
                      inactiveColor: Colors.white30,
                    ),
                  ),
                  const Icon(Icons.volume_up, color: Colors.white70, size: 18),
                ],
              ),
            ),
          const Divider(color: Colors.white12, height: 1),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF4C4281),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      contentPadding: const EdgeInsets.only(
        top: 20,
        left: 10,
        right: 10,
        bottom: 5,
      ),

      title: const Text(
        'Semua Daftar Sound',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
        textAlign: TextAlign.start,
      ),

      content: SingleChildScrollView(
        child: ListBody(
          children: _currentSounds
              .map((item) => _buildSoundListItem(item))
              .toList(),
        ),
      ),

      actions: <Widget>[
        // Tombol Konfirmasi
        TextButton(
          onPressed: () {
            // Mengembalikan seluruh daftar SoundItem yang telah dimodifikasi
            widget.onSelectionConfirmed(_currentSounds);
            Navigator.of(context).pop();
          },
          child: const Text(
            'Konfirmasi',
            style: TextStyle(
              color: Colors.lightBlueAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // Tombol Batalkan
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text(
            'Batalkan',
            style: TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
      actionsAlignment: MainAxisAlignment.end,
    );
  }
}
