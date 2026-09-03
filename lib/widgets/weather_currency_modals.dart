import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/api_service.dart';
import '../services/weather_service.dart';
import 'package:super_app/l10n/locale_controller.dart';
import '../theme/lux_tokens.dart';

class WeatherModal extends StatefulWidget {
  const WeatherModal({super.key});

  @override
  State<WeatherModal> createState() => _WeatherModalState();
}

class _WeatherModalState extends State<WeatherModal> {
  final WeatherService _weatherService = WeatherService();
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    if (!_weatherService.hasData && !_weatherService.isLoading) {
      _fetchData();
    }
  }

  Future<void> _fetchData() async {
    setState(() => _isRefreshing = true);
    await _weatherService.prefetchWeather(force: true);
    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? LuxTokens.surface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: LuxTokens.gold, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.cloudSun, color: LuxTokens.gold, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Ob-havo ma\'lumoti'.tr,
                    style: TextStyle(
                      fontFamily: LuxTokens.body,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(LucideIcons.refreshCw, color: LuxTokens.gold, size: 22),
                onPressed: _fetchData,
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_weatherService.isLoading || _isRefreshing)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: CircularProgressIndicator(color: LuxTokens.gold)),
            )
          else if (_weatherService.hasData &&
              _weatherService.weather != null) ...[
            _buildWeatherInfo(isDark),
            const SizedBox(height: 20),
            if (_weatherService.dailyForecast != null &&
                _weatherService.dailyForecast!.isNotEmpty)
              _buildDailyForecast(isDark),
          ] else
            Center(
              child: Text(
                "Ma'lumot topilmadi".tr,
                style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildWeatherInfo(bool isDark) {
    final weather = _weatherService.weather!;
    final temp = weather['temperature_celsius'] ?? weather['temperature'] ?? '--';
    final cond = weather['condition'] ?? '--';
    final wind = weather['windspeed'] ?? '--';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LuxTokens.goldGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: LuxTokens.gold.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _weatherService.currentCity,
                    style: const TextStyle(
                      fontFamily: LuxTokens.body,
                      color: Color(0xFF140D02),
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    cond,
                    style: const TextStyle(
                      color: Color(0xFF4A3409),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const Icon(LucideIcons.cloudSun, color: Color(0xFF140D02), size: 48),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$temp°C',
                style: const TextStyle(
                  fontFamily: LuxTokens.body,
                  color: Color(0xFF140D02),
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.wind,
                      color: Color(0xFF4A3409),
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$wind km/h',
                      style: const TextStyle(
                        color: Color(0xFF4A3409),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyForecast(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "7 kunlik prognoz".tr,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _weatherService.dailyForecast!.length,
            itemBuilder: (context, index) {
              final day = _weatherService.dailyForecast![index];
              return Container(
                width: 82,
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFFDE68A),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDate(day['date']),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    Icon(
                      _getWeatherIcon(day['code']),
                      color: LuxTokens.gold,
                      size: 26,
                    ),
                    Column(
                      children: [
                        Text(
                          '${day['max']}°',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          '${day['min']}°',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _getWeatherIcon(int code) {
    if (code == 0) return LucideIcons.sun;
    if (code == 1 || code == 2) return LucideIcons.cloudSun;
    if (code == 3) return LucideIcons.cloud;
    if (code == 45 || code == 48) return LucideIcons.cloudFog;
    if (code >= 51 && code <= 67) return LucideIcons.cloudRain;
    if (code >= 71 && code <= 77) return LucideIcons.cloudSnow;
    if (code >= 80 && code <= 82) return LucideIcons.cloudRain;
    if (code >= 85 && code <= 86) return LucideIcons.cloudSnow;
    if (code >= 95 && code <= 99) return LucideIcons.cloudLightning;
    return LucideIcons.cloud;
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      final now = DateTime.now();
      if (date.year == now.year &&
          date.month == now.month &&
          date.day == now.day) {
        return "Bugun";
      }
      if (date.year == now.year &&
          date.month == now.month &&
          date.day == now.day + 1) {
        return "Ertaga";
      }

      const months = [
        'Yan',
        'Fev',
        'Mar',
        'Apr',
        'May',
        'Iyun',
        'Iyul',
        'Avg',
        'Sen',
        'Okt',
        'Noy',
        'Dek',
      ];
      return "${date.day} ${months[date.month - 1]}";
    } catch (_) {
      return isoDate;
    }
  }
}

class CurrencyModal extends StatefulWidget {
  const CurrencyModal({super.key});

  @override
  State<CurrencyModal> createState() => _CurrencyModalState();
}

class _CurrencyModalState extends State<CurrencyModal> {
  final ApiService _api = ApiService();
  List<dynamic>? currencies;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchCurrency();
  }

  Future<void> _fetchCurrency() async {
    setState(() => _loading = true);
    try {
      final c = await _api.getCurrency();
      if (c.containsKey('rates')) {
        if (mounted) setState(() => currencies = c['rates']);
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? LuxTokens.surface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: LuxTokens.gold, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.coins, color: LuxTokens.gold, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Valyuta kurslari'.tr,
                    style: TextStyle(
                      fontFamily: LuxTokens.body,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(LucideIcons.refreshCw, color: LuxTokens.gold, size: 22),
                onPressed: _fetchCurrency,
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: CircularProgressIndicator(color: LuxTokens.gold)),
            )
          else if (currencies != null && currencies!.isNotEmpty)
            _buildCurrencyList(isDark)
          else
            Center(
              child: Text(
                "Ma'lumot topilmadi".tr,
                style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCurrencyList(bool isDark) {
    return Column(
      children: currencies!.map((cur) {
        final String ccy = cur['Ccy'] ?? '';
        final String rate = cur['Rate'] ?? '0';
        final String diff = cur['Diff'] ?? '0';
        final bool isUp = !diff.startsWith('-');

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFFDE68A),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: 24K Gold Specular Circle Badge & Currency Code
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: LuxTokens.goldBoxDecoration(radius: 12),
                    child: Center(
                      child: Text(
                        _getCurrencySymbol(ccy),
                        style: const TextStyle(
                          fontFamily: LuxTokens.body,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF140D02),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    ccy,
                    style: TextStyle(
                      fontFamily: LuxTokens.body,
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),

              // Right: Rate amount & Pill Diff Badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$rate UZS',
                    style: TextStyle(
                      fontFamily: LuxTokens.body,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: isDark ? LuxTokens.gold : const Color(0xFF8A5D0B),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Pill diff badge (Green for gain, Red for drop)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isUp ? const Color(0xFFDCFCE7) : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isUp ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isUp ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                          color: isUp ? const Color(0xFF166534) : const Color(0xFF991B1B),
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          diff,
                          style: TextStyle(
                            color: isUp ? const Color(0xFF166534) : const Color(0xFF991B1B),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _getCurrencySymbol(String ccy) {
    switch (ccy.toUpperCase()) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'RUB':
        return '₽';
      case 'GBP':
        return '£';
      case 'KZT':
        return '₸';
      default:
        return ccy.substring(0, 1);
    }
  }
}
