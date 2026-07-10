import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/service_hub_kind.dart';
import '../services/call_service.dart';
import '../utils/auth_guard.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../widgets/glass/glass_surface.dart';
import '../theme/glass_tokens.dart';
import 'calls/call_screen.dart';

class SimpleCallBookingScreen extends StatelessWidget {
  final ServiceHubKind kind;
  final Map<String, dynamic> provider;
  final Color accentColor;

  const SimpleCallBookingScreen({
    super.key,
    required this.kind,
    required this.provider,
    required this.accentColor,
  });

  Future<void> _initiateCall(BuildContext context) async {
    if (!await ensureAuthenticated(context)) return;

    final providerId = provider['id'] as int? ?? 0;
    final providerName = provider['name'] as String? ?? 'Soha egasi';

    if (providerId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xatolik: Provayder ma\'lumoti yo\'q')),
      );
      return;
    }

    // Call through CallService
    await CallService().startCall(providerId, providerName);

    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CallScreen(isIncoming: false)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = provider['name'] as String? ?? 'Soha egasi';
    final address = provider['address'] as String? ?? 'Manzil ko\'rsatilmagan';
    final rating = (provider['rating'] as num?)?.toDouble() ?? 0.0;
    final phone = provider['phone'] as String? ?? '';

    return GlassScaffold(
      showBackButton: true,
      title: kind.title,
      body: SafeArea(
        top: false,
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              GlassSurface(
                padding: const EdgeInsets.all(24),
                borderRadius: GlassTokens.radiusLg,
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(kind.icon, color: accentColor, size: 40),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: GlassTokens.primaryText(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: GlassTokens.primaryText(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          LucideIcons.mapPin,
                          color: GlassTokens.secondaryText(context),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            address,
                            style: TextStyle(
                              color: GlassTokens.secondaryText(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (phone.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.phone,
                            color: GlassTokens.secondaryText(context),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            phone,
                            style: TextStyle(
                              color: GlassTokens.secondaryText(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: accentColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => _initiateCall(context),
                  icon: const Icon(LucideIcons.phoneCall, color: Colors.white),
                  label: const Text(
                    'Dastur orqali qo\'ng\'iroq qilish',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Joyni band qilish uchun to\'g\'ridan-to\'g\'ri soha egasi bilan bog\'laning.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: GlassTokens.secondaryText(context),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
