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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: LuxTokens.gold, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.cloudSun, color: LuxTokens.gold, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Ob-havo ma\'lumoti'.tr,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(LucideIcons.refreshCw, color: LuxTokens.gold, size: 20),
                onPressed: _fetchData,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_weatherService.isLoading || _isRefreshing)
            const Padding(
              padding: EdgeInsets.all(28.0),
              child: Center(child: CircularProgressIndicator(color: LuxTokens.gold, strokeWidth: 2.5)),
            )
          else if (_weatherService.hasData &&
              _weatherService.weather != null) ...[
            _buildWeatherInfo(),
            const SizedBox(height: 16),
            if (_weatherService.dailyForecast != null &&
                _weatherService.dailyForecast!.isNotEmpty)
              _buildDailyForecast(),
          ] else
            Center(
              child: Text(
                "Ma'lumot topilmadi".tr,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildWeatherInfo() {
    final weather = _weatherService.weather!;
    final temp = weather['temperature_celsius'] ?? weather['temperature'] ?? '--';
    final cond = weather['condition'] ?? '--';
    final wind = weather['windspeed'] ?? '--';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LuxTokens.goldGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: LuxTokens.gold.withValues(alpha: 0.25),
            blurRadius: 14,
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
                      color: Color(0xFF140D02),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    cond,
                    style: const TextStyle(
                      color: Color(0xFF4A3409),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const Icon(LucideIcons.cloudSun, color: Color(0xFF140D02), size: 38),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$temp°C',
                style: const TextStyle(
                  color: Color(0xFF140D02),
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.wind,
                      color: Color(0xFF4A3409),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$wind km/h',
                      style: const TextStyle(
                        color: Color(0xFF4A3409),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
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

  Widget _buildDailyForecast() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "7 kunlik prognoz".tr,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 125,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _weatherService.dailyForecast!.length,
            itemBuilder: (context, index) {
              final day = _weatherService.dailyForecast![index];
              return Container(
                width: 76,
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFDE68A),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDate(day['date']),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    Icon(
                      _getWeatherIcon(day['code']),
                      color: LuxTokens.gold,
                      size: 22,
                    ),
                    Column(
                      children: [
                        Text(
                          '${day['max']}°',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          '${day['min']}°',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF8A5D0B),
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: LuxTokens.gold, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.coins, color: LuxTokens.gold, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Valyuta kurslari'.tr,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(LucideIcons.refreshCw, color: LuxTokens.gold, size: 20),
                onPressed: _fetchCurrency,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(28.0),
              child: Center(child: CircularProgressIndicator(color: LuxTokens.gold, strokeWidth: 2.5)),
            )
          else if (currencies != null && currencies!.isNotEmpty)
            _buildCurrencyList()
          else
            Center(
              child: Text(
                "Ma'lumot topilmadi".tr,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCurrencyList() {
    return Column(
      children: currencies!.map((cur) {
        final String ccy = cur['Ccy'] ?? '';
        final String rate = cur['Rate'] ?? '0';
        final String diff = cur['Diff'] ?? '0';
        final bool isUp = !diff.startsWith('-');

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFFDE68A),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
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
                    width: 36,
                    height: 36,
                    decoration: LuxTokens.goldBoxDecoration(radius: 10),
                    child: Center(
                      child: Text(
                        _getCurrencySymbol(ccy),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF140D02),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    ccy,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: Color(0xFF0F172A),
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
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                      color: Color(0xFF8A5D0B),
                    ),
                  ),
                  const SizedBox(height: 3),

                  // Pill diff badge (Green for gain, Red for drop)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: isUp ? const Color(0xFFDCFCE7) : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
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
                          size: 12,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          diff,
                          style: TextStyle(
                            color: isUp ? const Color(0xFF166534) : const Color(0xFF991B1B),
                            fontSize: 11,
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
