import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/api_service.dart';
import 'weather_currency_modals.dart';
import '../theme/lux_tokens.dart';
import '../l10n/locale_controller.dart';

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
            _currentCurrencyIndex =
                (_currentCurrencyIndex + 1) % currencies!.length;
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

  TextStyle _valueStyle(BuildContext context) {
    return const TextStyle(
      color: Color(0xFF0F172A),
      fontSize: 11,
      fontWeight: FontWeight.w800,
    );
  }

  Widget _buildWeatherCard() {
    String txt = 'Yuklanmoqda...'.tr;
    if (weather != null) {
      final temp =
          weather!['temperature_celsius'] ?? weather!['temperature'] ?? '';
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
        icon: LucideIcons.sun,
        color: const Color(0xFFC9A227),
        title: 'Ob-havo'.tr,
        customSubtitle: Text(
          txt,
          style: _valueStyle(context),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildCurrencyCard() {
    String txt = 'Yuklanmoqda...'.tr;
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
        color: const Color(0xFFC9A227),
        title: 'Valyuta kursi'.tr,
        customSubtitle: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          layoutBuilder: (current, previous) => Stack(
            alignment: Alignment.centerLeft,
            children: [
              ...previous,
              if (current != null) current,
            ],
          ),
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
            style: _valueStyle(context),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
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
    if (!isDark) return _buildLight(context);

    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: LuxTokens.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: LuxTokens.border),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: LuxTokens.goldBoxDecoration(radius: 7),
            child: Icon(icon, color: const Color(0xFF140D02), size: 13),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title.toUpperCase(),
                  style: LuxTokens.label(size: 7.5, spacing: 1.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                DefaultTextStyle.merge(
                  style: const TextStyle(
                    fontFamily: LuxTokens.display,
                    color: LuxTokens.text,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                  child: customSubtitle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLight(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: LuxTokens.gold.withValues(alpha: 0.6),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: LuxTokens.gold.withValues(alpha: 0.10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: LuxTokens.goldBoxDecoration(radius: 8),
            child: Icon(icon, color: const Color(0xFF140D02), size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: Color(0xFF8A5D0B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                DefaultTextStyle.merge(
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                  child: customSubtitle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
