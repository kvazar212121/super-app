import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/api_service.dart';
import '../theme/glass_tokens.dart';
import 'weather_currency_modals.dart';
class DailyUtilitiesWidget extends StatefulWidget {
  const DailyUtilitiesWidget({super.key});

  @override
  State<DailyUtilitiesWidget> createState() => _DailyUtilitiesWidgetState();
}

class _DailyUtilitiesWidgetState extends State<DailyUtilitiesWidget> {
  final ApiService _api = ApiService();
  
  Map<String, dynamic>? weather;
  List<dynamic>? currencies;
  
  int _currentCurrencyIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (currencies != null && currencies!.isNotEmpty) {
        if (mounted) {
          setState(() {
            _currentCurrencyIndex = (_currentCurrencyIndex + 1) % currencies!.length;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final w = await _api.getWeather('Tashkent');
      if (mounted) setState(() => weather = w);
    } catch (_) {}

    try {
      final c = await _api.getCurrency();
      if (c.containsKey('rates')) {
        if (mounted) setState(() => currencies = c['rates']);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildWeatherCard()),
        const SizedBox(width: 8),
        Expanded(child: _buildCurrencyCard()),
      ],
    );
  }

  Widget _buildWeatherCard() {
    String txt = 'Yuklanmoqda...';
    if (weather != null) {
      final temp = weather!['temperature_celsius'] ?? weather!['temperature'] ?? '';
      final cond = weather!['condition'] ?? '';
      txt = '$temp°C • $cond';
    }
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const WeatherModal(),
        );
      },
      child: _BaseCard(
        icon: LucideIcons.cloudSun,
        color: Colors.blueAccent,
        title: 'Ob-havo',
        customSubtitle: Text(
          txt,
          style: TextStyle(
            color: GlassTokens.secondaryText(context),
            fontSize: 10,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildCurrencyCard() {
    String txt = 'Yuklanmoqda...';
    if (currencies != null && currencies!.isNotEmpty) {
      final cur = currencies![_currentCurrencyIndex];
      final ccy = cur['Ccy'];
      final rate = cur['Rate'];
      txt = '1 $ccy = $rate UZS';
    }
    
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const CurrencyModal(),
        );
      },
      child: _BaseCard(
        icon: LucideIcons.circleDollarSign,
        color: Colors.greenAccent,
        title: 'Valyuta kurslari',
        customSubtitle: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.5),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: Text(
            txt,
            key: ValueKey<int>(_currentCurrencyIndex),
            style: TextStyle(
              color: GlassTokens.secondaryText(context),
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

class PrayerWidget extends StatefulWidget {
  const PrayerWidget({super.key});
  @override
  State<PrayerWidget> createState() => _PrayerWidgetState();
}

class _PrayerWidgetState extends State<PrayerWidget> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? prayers;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final p = await _api.getPrayerTimes('Tashkent');
      if (mounted) setState(() => prayers = p);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    String txt = 'Yuklanmoqda...';
    if (prayers != null && prayers!.containsKey('timings')) {
      final timings = prayers!['timings'];
      txt = 'Bomdod: ${timings['Fajr']} • Peshin: ${timings['Dhuhr']}';
    }
    return _BaseCard(
      icon: LucideIcons.moon,
      color: Colors.deepPurpleAccent,
      title: 'Namoz vaqtlari',
      customSubtitle: Text(
        txt,
        style: TextStyle(
          color: GlassTokens.secondaryText(context),
          fontSize: 10,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _BaseCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final Widget customSubtitle;

  const _BaseCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.customSubtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Color.lerp(const Color(0xFF1E293B), color, 0.15) : Color.lerp(Colors.white, color, 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? color.withValues(alpha: 0.4) : color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          /* Icon removed to save space
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 8),
          */
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
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                customSubtitle,
              ],
            ),
          )
        ],
      ),
    );
  }
}
