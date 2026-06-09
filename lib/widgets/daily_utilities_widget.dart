import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/api_service.dart';
import '../theme/glass_tokens.dart';

class DailyUtilitiesWidget extends StatefulWidget {
  const DailyUtilitiesWidget({super.key});

  @override
  State<DailyUtilitiesWidget> createState() => _DailyUtilitiesWidgetState();
}

class _DailyUtilitiesWidgetState extends State<DailyUtilitiesWidget> {
  final ApiService _api = ApiService();
  
  Map<String, dynamic>? weather;
  Map<String, dynamic>? currency;
  Map<String, dynamic>? prayers;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final w = await _api.getWeather('Tashkent');
      setState(() => weather = w);
    } catch (_) {}

    try {
      final c = await _api.getCurrency();
      setState(() => currency = c);
    } catch (_) {}

    try {
      final p = await _api.getPrayerTimes('Tashkent');
      setState(() => prayers = p);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildWeatherCard(),
          const SizedBox(width: 12),
          _buildCurrencyCard(),
          const SizedBox(width: 12),
          _buildPrayerCard(),
        ],
      ),
    );
  }

  Widget _buildWeatherCard() {
    return _BaseCard(
      icon: LucideIcons.cloudSun,
      color: Colors.blueAccent,
      title: 'Ob-havo',
      subtitle: weather != null 
        ? '${weather!['temperature']}°C • ${weather!['condition']}' 
        : 'Yuklanmoqda...',
    );
  }

  Widget _buildCurrencyCard() {
    String txt = 'Yuklanmoqda...';
    if (currency != null && currency!.containsKey('USD')) {
      txt = '1\$ = ${currency!['USD']['rate']} so\'m';
    }
    return _BaseCard(
      icon: LucideIcons.circleDollarSign,
      color: Colors.greenAccent,
      title: 'Valyuta',
      subtitle: txt,
    );
  }

  Widget _buildPrayerCard() {
    String txt = 'Yuklanmoqda...';
    if (prayers != null && prayers!.containsKey('Bomdod')) {
      txt = 'Bomdod: ${prayers!['Bomdod']} • Peshin: ${prayers!['Peshin']}';
    }
    return _BaseCard(
      icon: LucideIcons.moon,
      color: Colors.deepPurpleAccent,
      title: 'Namoz',
      subtitle: txt,
    );
  }
}

class _BaseCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _BaseCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: GlassTokens.primaryText(context),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: GlassTokens.secondaryText(context),
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
