/// E'lon rasmlari aylanmasi (3-6 ta, surib ko'riladi).
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../config/app_config.dart';
import '../../theme/glass_tokens.dart';

class PhotoCarousel extends StatefulWidget {
  final List<String> photos;
  final double height;

  const PhotoCarousel({super.key, required this.photos, this.height = 220});

  @override
  State<PhotoCarousel> createState() => _PhotoCarouselState();
}

class _PhotoCarouselState extends State<PhotoCarousel> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.photos.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: ColoredBox(
          color: Colors.blue.withValues(alpha: 0.10),
          child: const Center(
            child: Icon(LucideIcons.image, size: 40, color: Colors.blue),
          ),
        ),
      );
    }

    return SizedBox(
      height: widget.height,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.photos.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) => ClipRRect(
              borderRadius: BorderRadius.circular(GlassTokens.radiusSm),
              child: CachedNetworkImage(
                imageUrl: AppConfig.formatImageUrl(widget.photos[i]),
                fit: BoxFit.cover,
                width: double.infinity,
                errorWidget: (_, _, _) => const ColoredBox(
                  color: Color(0x11000000),
                  child: Center(child: Icon(LucideIcons.imageOff)),
                ),
                placeholder: (_, _) => const ColoredBox(
                  color: Color(0x11000000),
                ),
              ),
            ),
          ),
          // Nuqtalar: nechta rasm borligi va qaysisidaligi ko'rinsin.
          if (widget.photos.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.photos.length, (i) {
                  final faol = i == _index;
                  return Container(
                    width: faol ? 18 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: faol ? Colors.white : Colors.white70,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}
