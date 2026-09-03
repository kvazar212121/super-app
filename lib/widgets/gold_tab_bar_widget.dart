import 'package:flutter/material.dart';

/// App-wide 24K Metallic Gold TabBar with specular gold gradient active text.
class GoldTabBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController? controller;
  final List<String> tabs;

  const GoldTabBar({
    super.key,
    this.controller,
    required this.tabs,
  });

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    final tabController = controller ?? DefaultTabController.of(context);
    return AnimatedBuilder(
      animation: tabController,
      builder: (context, _) {
        final currentIndex = tabController.index;
        return Container(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0x22C9A227), width: 1),
            ),
          ),
          child: TabBar(
            controller: tabController,
            indicatorColor: const Color(0xFFC9A227),
            indicatorWeight: 3,
            labelPadding: EdgeInsets.zero,
            dividerColor: Colors.transparent,
            tabs: List.generate(tabs.length, (index) {
              final isSelected = index == currentIndex;
              // Tab yorliqlari bitta qatorda tursin — uzun ruscha so'zlar
              // (masalan "Завершённые") 1.5x miqyosda ikkinchi qatorga
              // tushmasligi uchun FittedBox bilan kichraytiramiz.
              return Tab(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: isSelected
                    ? ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            Color(0xFFFFEEA0),
                            Color(0xFFE0B454),
                            Color(0xFFC99427),
                            Color(0xFF8A5D0B),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ).createShader(bounds),
                        child: Text(
                          tabs[index],
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                      )
                    : Text(
                        tabs[index],
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF140D02),
                        ),
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
