import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../l10n/locale_controller.dart';
import '../../theme/glass_tokens.dart';

/// AI BAJARA OLADIGAN ishlar katalogi.
///
/// NEGA KERAK: agent 50 dan ortiq amalni bajara oladi, lekin foydalanuvchi
/// ularning bir nechtasini ham bilmaydi. Chat oynasida bu ko'rinmaydi —
/// odam faqat o'zi o'ylab topgan narsani so'raydi.
///
/// Har element bosilganda TAYYOR MATN chatga qo'yiladi: foydalanuvchi
/// nimani qanday so'rashni o'rganadi.

class CatalogItem {
  /// Ro'yxatda ko'rinadigan nom.
  final String nom;

  /// Bosilganda chatga qo'yiladigan matn.
  final String matn;

  const CatalogItem(this.nom, this.matn);
}

class CatalogGroup {
  final String nom;
  final IconData belgi;
  final List<CatalogItem> elementlar;

  const CatalogGroup(this.nom, this.belgi, this.elementlar);
}

/// Katalog tarkibi. Backend'dagi tool guruhlariga MOS keladi
/// (`backend/app/services/ai_agent/tool_router.py`) — yangi tool
/// qo'shilsa shu yerga ham qo'shing, aks holda foydalanuvchi u haqda
/// bilmaydi.
List<CatalogGroup> catalogGroups() => [
      CatalogGroup('Xizmat va bron'.tr, LucideIcons.scissors, [
        CatalogItem('Usta qidirish'.tr, 'Eng yaqin sartaroshlarni ko\'rsat'.tr),
        CatalogItem('Bron qilish'.tr, 'Ertaga 15:00 ga sartaroshga yozib qo\'y'.tr),
        CatalogItem('Bronni ko\'chirish'.tr, 'Bronimni boshqa kunga ko\'chir'.tr),
        CatalogItem('Keyingi bronim'.tr, 'Keyingi bronim qachon?'.tr),
        CatalogItem('Bekor qilish'.tr, 'Buyurtmamni bekor qil'.tr),
      ]),
      CatalogGroup('Ish e\'loni'.tr, LucideIcons.wrench, [
        CatalogItem('E\'lon berish'.tr, 'Kranim oqyapti, usta kerak'.tr),
        CatalogItem('E\'lonlarim'.tr, 'Mening ish e\'lonlarim qani?'.tr),
      ]),
      CatalogGroup('Savdo'.tr, LucideIcons.tag, [
        CatalogItem('Sotish'.tr, 'Telefonimni sotmoqchiman'.tr),
        CatalogItem('Sotib olish'.tr, 'Arzon ishlatilgan noutbuk qidiryapman'.tr),
        CatalogItem('E\'lonlarim'.tr, 'Savdo e\'lonlarimni ko\'rsat'.tr),
      ]),
      CatalogGroup('Reja va vazifa'.tr, LucideIcons.calendar, [
        CatalogItem('Eslatma'.tr, 'Ertaga 10:00 da majlisni eslat'.tr),
        CatalogItem('Vazifa'.tr, 'Vazifalarimga kir yuvishni qo\'sh'.tr),
        CatalogItem('Budilnik'.tr, 'Ertalab 7 ga budilnik qo\'y'.tr),
        CatalogItem('Rejalarim'.tr, 'Bugungi rejalarimni ko\'rsat'.tr),
      ]),
      CatalogGroup('Moliya'.tr, LucideIcons.wallet, [
        CatalogItem('Xarajat'.tr, '50 ming so\'m taksiga sarfladim'.tr),
        CatalogItem('Daromad'.tr, 'Bugun 500 ming daromad qildim'.tr),
        CatalogItem('Xulosa'.tr, 'Bu oygi xarajatlarim qancha?'.tr),
      ]),
      CatalogGroup('Bozorlik'.tr, LucideIcons.shoppingBag, [
        CatalogItem('Qo\'shish'.tr, 'Bozorlik ro\'yxatiga non va sut qo\'sh'.tr),
        CatalogItem('Ro\'yxat'.tr, 'Bozorlik ro\'yxatimni ko\'rsat'.tr),
      ]),
      CatalogGroup('Sog\'liq va fitnes'.tr, LucideIcons.dumbbell, [
        CatalogItem('Ovqat'.tr, 'Bugun 2 ta non va bir kosa sho\'rva yedim'.tr),
        CatalogItem('Qadamlar'.tr, 'Bugun nechta qadam bosdim?'.tr),
      ]),
      CatalogGroup('Ma\'lumot'.tr, LucideIcons.cloudSun, [
        CatalogItem('Ob-havo'.tr, 'Bugun ob-havo qanday?'.tr),
        CatalogItem('Valyuta'.tr, 'Dollar kursi qancha?'.tr),
        CatalogItem('Namoz vaqti'.tr, 'Bugungi namoz vaqtlari'.tr),
      ]),
      CatalogGroup('Usta uchun'.tr, LucideIcons.users, [
        CatalogItem('Buyurtmalarim'.tr, 'Menga kelgan buyurtmalarni ko\'rsat'.tr),
        CatalogItem('Hisobotim'.tr, 'Reytingim va balansim qancha?'.tr),
        CatalogItem('Yangi ishlar'.tr, 'Sohamda yangi ish e\'lonlari bormi?'.tr),
        CatalogItem('Band vaqt'.tr, 'Ertaga 14:00 dan 18:00 gacha bandman'.tr),
      ]),
      CatalogGroup('Shikoyat'.tr, LucideIcons.shieldCheck, [
        CatalogItem('Shikoyat qilish'.tr, 'Usta ustidan shikoyat qilmoqchiman'.tr),
      ]),
    ];

/// Katalogni pastdan chiquvchi oynada ko'rsatadi.
/// Tanlangan matnni qaytaradi (hech narsa tanlanmasa `null`).
Future<String?> showChatCatalog(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _CatalogSheet(),
  );
}

class _CatalogSheet extends StatelessWidget {
  const _CatalogSheet();

  @override
  Widget build(BuildContext context) {
    final asosiy = GlassTokens.primaryText(context);
    final ikkilamchi = GlassTokens.secondaryText(context);
    final guruhlar = catalogGroups();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: ikkilamchi.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
              child: Row(
                children: [
                  Icon(LucideIcons.sparkles, size: 19, color: asosiy),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'AI nima qila oladi'.tr,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: asosiy,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                'Tanlang — matn chatga qo\'yiladi, tahrirlashingiz mumkin'.tr,
                style: TextStyle(fontSize: 12.5, color: ikkilamchi),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                itemCount: guruhlar.length,
                itemBuilder: (context, i) {
                  final g = guruhlar[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 12, 8, 6),
                          child: Row(
                            children: [
                              Icon(g.belgi, size: 15, color: ikkilamchi),
                              const SizedBox(width: 8),
                              Text(
                                g.nom,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: ikkilamchi,
                                ),
                              ),
                            ],
                          ),
                        ),
                        for (final e in g.elementlar)
                          _KatalogQator(
                            element: e,
                            onBosildi: () => Navigator.pop(context, e.matn),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KatalogQator extends StatelessWidget {
  final CatalogItem element;
  final VoidCallback onBosildi;

  const _KatalogQator({required this.element, required this.onBosildi});

  @override
  Widget build(BuildContext context) {
    final asosiy = GlassTokens.primaryText(context);
    final ikkilamchi = GlassTokens.secondaryText(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onBosildi,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      element.nom,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: asosiy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '«${element.matn}»',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, color: ikkilamchi),
                    ),
                  ],
                ),
              ),
              Icon(LucideIcons.chevronRight, size: 17, color: ikkilamchi),
            ],
          ),
        ),
      ),
    );
  }
}
