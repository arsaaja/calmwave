import 'package:flutter/material.dart';

class CategoryTabs extends StatefulWidget {
  final List<String> categories;
  final ValueChanged<int>? onChanged;

  const CategoryTabs({super.key, required this.categories, this.onChanged});

  @override
  State<CategoryTabs> createState() => _CategoryTabsState();
}

class _CategoryTabsState extends State<CategoryTabs> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(widget.categories.length, (index) {
        bool isSelected = selectedIndex == index;
        return GestureDetector(
          onTap: () {
            setState(() => selectedIndex = index);
            if (widget.onChanged != null) {
              widget.onChanged!(index);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF1B1A55)
                  : const Color(0xFF535C91),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white),
            ),
            child: Text(
              widget.categories[index],
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }),
    );
  }
}
