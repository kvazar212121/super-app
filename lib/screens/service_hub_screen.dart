import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/barber_shop.dart';
import '../models/service_hub_kind.dart';
import '../widgets/hub_map_preview.dart';
import 'all_categories_screen.dart';
import 'barber_map_screen.dart';
import 'universal_booking_screen.dart';

class ServiceHubScreen extends StatelessWidget {
  final ServiceHubKind kind;
  final Color accentColor;

  const ServiceHubScreen({
    super.key,
    required this.kind,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(kind.title),
            Text(
              kind.hubSubtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.72),
                  ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              child: HubMapPreview(
                markers: _buildMarkers(context),
              ),
            ),
          ),
          Expanded(
            child: _ActionList(kind: kind, accentColor: accentColor),
          ),
        ],
      ),
    );
  }

  List<Marker> _buildMarkers(BuildContext context) {
    switch (kind) {
      case ServiceHubKind.sartarosh:
        return BarberShop.demoShops.map((shop) {
          return Marker(
            width: 88,
            height: 88,
            point: LatLng(shop.latitude, shop.longitude),
            child: GestureDetector(
              onTap: () => _openShopPeek(context, shop),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Icon(LucideIcons.scissors, color: accentColor, size: 22),
                  ),
                  const SizedBox(height: 4),
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Text(
                        shop.name,
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList();
      default:
        return _genericPins(context);
    }
  }

  List<Marker> _genericPins(BuildContext context) {
    final pts = [
      (const LatLng(41.3115, 69.2495), '1'),
      (const LatLng(41.302, 69.235), '2'),
      (const LatLng(41.318, 69.262), '3'),
    ];
    return pts.map((e) {
      final (p, id) = e;
      return Marker(
        width: 56,
        height: 56,
        point: p,
        child: GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Nuqta $id — ${kind.title} (demo)')),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: accentColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 5),
              ],
            ),
            child: Icon(LucideIcons.mapPin, color: Colors.white, size: 22),
          ),
        ),
      );
    }).toList();
  }

  void _openShopPeek(BuildContext context, BarberShop shop) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(shop.name, style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.star, size: 18, color: Colors.amber[700]),
                Text(' ${shop.rating}  ·  ${shop.reviewCount} sharh'),
              ],
            ),
            const SizedBox(height: 8),
            Text(shop.address, style: TextStyle(color: Colors.grey[700])),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Yopish'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => BarberMapScreen(shops: BarberShop.demoShops),
                        ),
                      );
                    },
                    child: const Text('To‘liq xarita'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionList extends StatelessWidget {
  final ServiceHubKind kind;
  final Color accentColor;

  const _ActionList({required this.kind, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final actions = _actions(context);
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: actions.length,
      separatorBuilder: (_, index) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) => _HubActionCard(
        title: actions[i].title,
        subtitle: actions[i].subtitle,
        icon: actions[i].icon,
        accentColor: accentColor,
        onTap: actions[i].onTap,
      ),
    );
  }

  List<_HubActionSpec> _actions(BuildContext context) {
    void toast(String m) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
    }

    void openBooking() {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => UniversalBookingScreen(kind: kind),
        ),
      );
    }

    final book = _HubActionSpec(
      LucideIcons.calendarCheck,
      '${kind.title} bron qilish',
      'Variant, manzil va vaqt — bir sahifada',
      openBooking,
    );

    return switch (kind) {
      ServiceHubKind.sartarosh => [
        book,
        _HubActionSpec(
          LucideIcons.map,
          'Kengaytirilgan xarita',
          'Barcha sartaroshlar ro‘yxati',
          () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => BarberMapScreen(shops: BarberShop.demoShops),
              ),
            );
          },
        ),
        _HubActionSpec(LucideIcons.bookmark, 'Saqlangan joylar', 'Tez orada', () => toast('Saqlanganlar — demo')),
      ],
      ServiceHubKind.salon => [
        book,
        _HubActionSpec(LucideIcons.sparkles, 'Kosmetik xizmatlar', 'Manikyur, fen va boshqalar', () => toast('Kosmetik — demo')),
        _HubActionSpec(LucideIcons.home, 'Uyga xizmat', 'Mobil brigada chaqirish', () => toast('Uyga salon — demo')),
      ],
      ServiceHubKind.futbol => [
        book,
        _HubActionSpec(LucideIcons.users, 'Jamoa o‘yini', 'Bir necha soat bandlov', () => toast('Jamoa rejasi — demo')),
        _HubActionSpec(LucideIcons.search, 'Maydon qidirish', 'Narx va joy filter', () => toast('Qidiruv — demo')),
      ],
      ServiceHubKind.ishchi => [
        book,
        _HubActionSpec(LucideIcons.package, 'Yuk ko‘tarish / yuklash', 'Kunlik yordamchi', () => toast('Yuk xizmati — demo')),
        _HubActionSpec(
          LucideIcons.briefcase,
          'Kunlik oddiy ish',
          'Qurilish yordami, tozalash va hokazo',
          () => toast('Kunlik ish — demo'),
        ),
      ],
      ServiceHubKind.usta => [
        book,
        _HubActionSpec(LucideIcons.messageSquare, 'Ta’mirlash bo‘yicha so‘rov', 'Rasm yuborish tez kunda', () => toast('Konsultatsiya — demo')),
        _HubActionSpec(LucideIcons.hammer, 'Uy-ro‘zg‘or ta’mirlash', 'Deraza, eshik, mebel', () => toast('Ta’mirlash — demo')),
      ],
      ServiceHubKind.elektrik => [
        book,
        _HubActionSpec(LucideIcons.alertTriangle, 'Shoshilinch chaqiruv', 'Uzilish / isitish ', () => toast('Favqulodda — demo')),
        _HubActionSpec(LucideIcons.clipboardList, 'Uy elektr tekshiruvi', 'Hisobot bilan', () => toast('Tekshiruv — demo')),
      ],
      ServiceHubKind.santexnik => [
        book,
        _HubActionSpec(LucideIcons.wrench, 'Toshma va probka', 'Shoshilinch ta’mir', () => toast('Toshma — demo')),
        _HubActionSpec(LucideIcons.clock, 'Navbatga yozilish', 'Aniqlashtirilgan vaqt', () => toast('Navbat — demo')),
      ],
      ServiceHubKind.tozalash => [
        book,
        _HubActionSpec(LucideIcons.home, 'Uy tozalash', 'Standart kvartira', openBooking),
        _HubActionSpec(LucideIcons.briefcase, 'Ofis tozalash', 'Davriy yoki bir martalik', openBooking),
      ],
      ServiceHubKind.avtoYordam => [
        book,
        _HubActionSpec(LucideIcons.alertTriangle, 'Shoshilinch chaqiruv', 'Yo‘l ustasi', openBooking),
        _HubActionSpec(LucideIcons.car, 'Evakuator', 'Qisqa va uzoq masofa', openBooking),
      ],
      ServiceHubKind.konditsioner => [
        book,
        _HubActionSpec(LucideIcons.wrench, 'Profilaktika tozalash', 'Filtr va plata', openBooking),
        _HubActionSpec(LucideIcons.zap, 'Gaz to‘ldirish', 'Hajmga qarab', openBooking),
      ],
      ServiceHubKind.enaga => [
        book,
        _HubActionSpec(LucideIcons.clock, 'Soatlik enaga', 'Tezkor chaqiruv', openBooking),
        _HubActionSpec(LucideIcons.heart, 'Doimiy enaga', 'Uzoq muddatli', openBooking),
      ],
      ServiceHubKind.repetitor => [
        book,
        _HubActionSpec(LucideIcons.bookOpen, 'Maktab fanlari', 'Matematika/Fizika/Til', openBooking),
        _HubActionSpec(LucideIcons.graduationCap, 'Test tayyorlov', 'DTM va xalqaro', openBooking),
      ],
      ServiceHubKind.yana => [
        _HubActionSpec(
          LucideIcons.layoutGrid,
          'Barcha xizmatlar',
          'To‘liq katalog',
          () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const AllCategoriesScreen(),
              ),
            );
          },
        ),
        _HubActionSpec(LucideIcons.helpCircle, 'Qo‘llanma', 'Ilovadan foydalanish', () => toast('Yordam — demo')),
        _HubActionSpec(LucideIcons.headphones, 'Qo‘llab-quvvatlash', 'Chat yoki qo‘ng‘iroq', () => toast('Support — demo')),
      ],
    };
  }
}

class _HubActionSpec {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  _HubActionSpec(this.icon, this.title, this.subtitle, this.onTap);
}

class _HubActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  const _HubActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: accentColor.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[500]),
            ],
          ),
        ),
      ),
    );
  }
}
