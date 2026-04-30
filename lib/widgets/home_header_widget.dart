import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class HomeHeaderWidget extends StatelessWidget {
  const HomeHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Assalomu alaykum,",
              style: Theme.of(context).textTheme.bodyMedium),
            Text("Kudratulloh",
              style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)
            ],
          ),
          child: IconButton(
            icon: const Icon(LucideIcons.bell),
            onPressed: () {},
          ),
        ),
      ],
    );
  }
}
