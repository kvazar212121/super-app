import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../l10n/locale_controller.dart';
import '../../theme/glass_tokens.dart';

/// AI nima qila olishini KO'RSATADIGAN taklif tugmalari.
///
/// NEGA KERAK: foydalanuvchi bo'sh chatni ochib nima yozishni bilmaydi.
/// Haqiqiy misolda odam shunchaki «30» deb yozgan va agent nima
/// nazarda tutilganini tushunmagan. Tugmalar agentning imkoniyatini
/// bir qarashda ko'rsatadi — hujjat o'qish shart emas.
///
/// Turli bo'limlardan ARALASH beriladi: foydalanuvchi AI faqat bron
/// qiladi deb o'ylab qolmasin.

/// Bitta taklif: chatga yuboriladigan matn + ko'rinishi.
class ChatSuggestion {
  final String matn;
  final IconData belgi;

  const ChatSuggestion(this.matn, this.belgi);
}

/// Boshlang'ich takliflar — ataylab ARALASH bo'limlardan.
/// 8 ta: ikki qatorga tekis taqsimlanadi.
List<ChatSuggestion> defaultSuggestions() => [
      // Belgilar ATAYLAB loyihada allaqachon ishlatilganlaridan olingan:
      // paket keshi bo'lmagan muhitda yangi nom mavjudligini tekshirib
      // bo'lmaydi, noto'g'ri nom esa kompilyatsiyani buzadi.
      ChatSuggestion('E\'lon yarat'.tr, LucideIcons.wrench),
      ChatSuggestion('Sartaroshga bron qil'.tr, LucideIcons.scissors),
      ChatSuggestion('Bugun 2 ta non yedim'.tr, LucideIcons.utensils),
      ChatSuggestion('Fitnes rejasini bajardim'.tr, LucideIcons.dumbbell),
      ChatSuggestion('Ertaga 10:00 ga eslat'.tr, LucideIcons.bellRing),
      ChatSuggestion('50 ming taksiga sarfladim'.tr, LucideIcons.wallet),
      ChatSuggestion('Telefon sotmoqchiman'.tr, LucideIcons.tag),
      ChatSuggestion('Bugun ob-havo qanday?'.tr, LucideIcons.cloudSun),
    ];

/// Xabar maydoni tepasida chiqadigan ikki qatorli tugmalar lentasi.
class ChatSuggestionBar extends StatelessWidget {
  final List<ChatSuggestion> takliflar;
  final ValueChanged<String> onTanlandi;

  /// «Yana nima qila olasan?» tugmasi — to'liq katalogni ochadi.
  final VoidCallback onKatalog;

  const ChatSuggestionBar({
    super.key,
    required this.takliflar,
    required this.onTanlandi,
    required this.onKatalog,
  });

  @override
  Widget build(BuildContext context) {
    // Ikki qatorga bo'lamiz: birinchi yarmi tepaga, qolgani pastga.
    final yarim = (takliflar.length / 2).ceil();
    final tepa = takliflar.take(yarim).toList();
    final past = takliflar.skip(yarim).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _qator(context, tepa),
          const SizedBox(height: 8),
          _qator(context, past, katalogQoshilsin: true),
        ],
      ),
    );
  }

  /// Bitta gorizontal qator — sig'masa surib ko'riladi (o'ralmaydi,
  /// aks holda balandlik o'zgarib chat sakraydi).
  Widget _qator(BuildContext context, List<ChatSuggestion> ro_yxat,
      {bool katalogQoshilsin = false}) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (final t in ro_yxat) ...[
            _Chip(
              matn: t.matn,
              belgi: t.belgi,
              onBosildi: () => onTanlandi(t.matn),
            ),
            const SizedBox(width: 8),
          ],
          if (katalogQoshilsin)
            _Chip(
              matn: 'Yana...'.tr,
              belgi: LucideIcons.layoutGrid,
              tanlangan: true,
              onBosildi: onKatalog,
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String matn;
  final IconData belgi;
  final VoidCallback onBosildi;
  final bool tanlangan;

  const _Chip({
    required this.matn,
    required this.belgi,
    required this.onBosildi,
    this.tanlangan = false,
  });

  @override
  Widget build(BuildContext context) {
    final asosiy = GlassTokens.primaryText(context);
    final ikkilamchi = GlassTokens.secondaryText(context);
    return Material(
      color: tanlangan
          ? asosiy.withValues(alpha: 0.08)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onBosildi,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: asosiy.withValues(alpha: tanlangan ? 0.28 : 0.16),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(belgi, size: 15, color: ikkilamchi),
              const SizedBox(width: 7),
              Text(
                matn,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.1,
                  color: asosiy,
                  fontWeight: tanlangan ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
