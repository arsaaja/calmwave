import 'package:flutter/material.dart';

class CategoryTabs extends StatefulWidget {
  // ⚠️ REVISI 1: Mengubah tipe categories menjadi List<Map<String, String>>
  final List<Map<String, String>> categories;

  // ⚠️ REVISI 2: Mengubah onChanged untuk mengembalikan String (ID/UUID)
  final ValueChanged<String> onChanged;

  const CategoryTabs({
    super.key,
    required this.categories,
    required this.onChanged,
  });

  @override
  State<CategoryTabs> createState() => _CategoryTabsState();
}

class _CategoryTabsState extends State<CategoryTabs> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        spacing: 8.0,
        children: List.generate(widget.categories.length, (index) {
          final category = widget.categories[index];
          final isSelected = _selectedIndex == index;

          return ChoiceChip(
            // Menggunakan 'name' untuk label yang ditampilkan ke user
            label: Text(category['name']!),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  _selectedIndex = index;
                });
                // ⚠️ Meneruskan ID (UUID) yang dipilih ke Dashboard
                widget.onChanged(category['id']!);
              }
            },
            // Style Chip
            selectedColor: const Color(0xFF6A0DAD),
            backgroundColor: const Color(0xFF1B1A55),
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          );
        }),
      ),
    );
  }
}
