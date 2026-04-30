import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SearchInputWidget extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;
  final VoidCallback onClear;

  const SearchInputWidget({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: (_) => onChanged(),
      decoration: InputDecoration(
        hintText: "Xizmatlarni qidirish...",
        prefixIcon: const Icon(LucideIcons.search, color: Colors.grey),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(icon: const Icon(LucideIcons.x, color: Colors.grey), onPressed: onClear)
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
