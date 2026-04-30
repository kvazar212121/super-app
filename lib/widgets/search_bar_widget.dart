import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SearchBarWidget extends StatelessWidget {
  const SearchBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)
        ],
      ),
      child: const TextField(
        decoration: InputDecoration(
          hintText: "Xizmatlarni qidirish...",
          border: InputBorder.none,
          icon: Icon(LucideIcons.search, color: Colors.grey),
        ),
      ),
    );
  }
}
