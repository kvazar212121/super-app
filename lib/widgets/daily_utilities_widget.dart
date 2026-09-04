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
    String txt = '23°C, Tashkent';
    if (weather != null) {
      final temp = weather!['temperature_celsius'] ?? weather!['temperature'] ?? '23';
      txt = '$temp°C, Tashkent';
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
      child: _PillChip(
        leading: const Text('☀️', style: TextStyle(fontSize: 14)),
        text: txt,
      ),
    );
  }

  Widget _buildCurrencyCard() {
    String txt = 'USD 1 = 12,300 UZS';
    if (currencies != null && currencies!.isNotEmpty) {
      final cur = currencies![_currentCurrencyIndex];
      final ccy = cur['Ccy'] ?? 'USD';
      final rate = cur['Rate'] ?? '12,300';
      txt = '$ccy 1 = $rate UZS';
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
      child: _PillChip(
        leading: const Icon(
          LucideIcons.circleDollarSign,
          size: 16,
          color: Color(0xFFC9A227),
        ),
        text: txt,
      ),
    );
  }
}

class _PillChip extends StatelessWidget {
  final Widget leading;
  final String text;

  const _PillChip({
    required this.leading,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFC9A227).withValues(alpha: 0.6),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          leading,
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
