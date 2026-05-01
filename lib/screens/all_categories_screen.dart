import 'package:flutter/material.dart';

import '../models/service_hub_kind.dart';
import 'service_hub_screen.dart';

/// Barcha 13 ta xizmat kategoriyasini ro'yxat ko'rinishida ko'rsatadi.
/// "Yana" bandidan ochiladi.
class AllCategoriesScreen extends StatelessWidget {
  const AllCategoriesScreen({super.key});

  static const _all = <ServiceHubKind>[
    ServiceHubKind.sartarosh,
    ServiceHubKind.salon,
    ServiceHubKind.futbol,
    ServiceHubKind.ishchi,
    ServiceHubKind.usta,
    ServiceHubKind.elektrik,
    ServiceHubKind.santexnik,
    ServiceHubKind.tozalash,
    ServiceHubKind.avtoYordam,
    ServiceHubKind.konditsioner,
    ServiceHubKind.enaga,
    ServiceHubKind.repetitor,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Barcha xizmatlar')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _all.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) {
          final k = _all[i];
          return Material(
            color: k.accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            child: ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: k.accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(k.icon, color: k.accent),
              ),
              title: Text(
                k.title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                k.hubSubtitle,
                style: const TextStyle(fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) =>
                      ServiceHubScreen(kind: k, accentColor: k.accent),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
