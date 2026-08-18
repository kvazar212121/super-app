/// E'lon rasmlarini to'liq ekranda ko'rish (surib, kattalashtirib).
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../config/app_config.dart';

class ListingPhotosScreen extends StatelessWidget {
  final List<String> photos;
  final int initialIndex;

  const ListingPhotosScreen({
    super.key,
    required this.photos,
    this.initialIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${photos.length} ta rasm'),
      ),
      body: PageView.builder(
        controller: PageController(initialPage: initialIndex),
        itemCount: photos.length,
        itemBuilder: (context, i) => InteractiveViewer(
          // Xaridor mahsulot tafsilotini (masalan ekrandagi chizilgan
          // joyni) ko'rishi kerak — shuning uchun kattalashtirish.
          minScale: 1,
          maxScale: 4,
          child: Center(
            child: CachedNetworkImage(
              imageUrl: AppConfig.formatImageUrl(photos[i]),
              fit: BoxFit.contain,
              errorWidget: (_, _, _) =>
                  const Icon(LucideIcons.imageOff, color: Colors.white54),
            ),
          ),
        ),
      ),
    );
  }
}
