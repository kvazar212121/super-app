import 'package:flutter/material.dart';

/// App-wide 24K Metallic Gold TabBar with specular gold gradient active text & icons.
class GoldTabBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController? controller;
  final List<String> tabs;
  final List<IconData>? icons;

  const GoldTabBar({
    super.key,
    this.controller,
    required this.tabs,
    this.icons,
  });

  @override
  Size get preferredSize => Size.fromHeight(icons != null ? 58 : 48);

  @override
  Widget build(BuildContext context) {
    final tabController = controller ?? DefaultTabController.of(context);
    final hasIcons = icons != null && icons!.length == tabs.length;

    return AnimatedBuilder(
      animation: tabController,
      builder: (context, _) {
        final currentIndex = tabController.index;
        return Container(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0x1A102A43), width: 1),
            ),
          ),
          child: TabBar(
            controller: tabController,
            indicatorColor: const Color(0xFF102A43),
            indicatorWeight: 3,
            labelPadding: EdgeInsets.zero,
            dividerColor: Colors.transparent,
            tabs: List.generate(tabs.length, (index) {
              final isSelected = index == currentIndex;
              final iconData = hasIcons ? icons![index] : null;

              return Tab(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (iconData != null) ...[
                        Icon(
                          iconData,
                          size: isSelected ? 20 : 18,
                          color: isSelected ? const Color(0xFF102A43) : const Color(0xFF6B7280),
                        ),
                        const SizedBox(height: 3),
                      ],
                      Text(
                        tabs[index],
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: isSelected ? 13.5 : 12.5,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? const Color(0xFF102A43) : const Color(0xFF6B7280),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
