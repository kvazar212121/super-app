import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/api_service.dart';
import '../services/weather_service.dart';
import '../theme/glass_tokens.dart';

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
    // Agar ma'lumot hali yo'q bo'lsa, yuklashni kutamiz. Agar bor bo'lsa, srazi ko'rsatamiz.
    if (!_weatherService.hasData && !_weatherService.isLoading) {
      _fetchData();
    }
  }

  Future<void> _fetchData() async {
    setState(() => _isRefreshing = true);
    await _weatherService.prefetchWeather();
    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Ob-havo ma\'lumoti', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(LucideIcons.refreshCw), onPressed: _fetchData),
            ],
          ),
          const SizedBox(height: 24),
          if (_weatherService.isLoading || _isRefreshing)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_weatherService.hasData && _weatherService.weather != null) ...[
            _buildWeatherInfo(theme),
            const SizedBox(height: 24),
            if (_weatherService.dailyForecast != null && _weatherService.dailyForecast!.isNotEmpty)
              _buildDailyForecast(),
          ] else
            const Center(child: Text("Ma'lumot topilmadi")),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildWeatherInfo(ThemeData theme) {
    final weather = _weatherService.weather!;
    final temp = weather['temperature_celsius'] ?? weather['temperature'] ?? '--';
    final cond = weather['condition'] ?? '--';
    final wind = weather['windspeed'] ?? '--';
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade800, Colors.blue.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.blue, blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_weatherService.currentCity, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(cond, style: const TextStyle(color: Colors.white70, fontSize: 16)),
                ],
              ),
              const Icon(LucideIcons.cloudSun, color: Colors.white, size: 48),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$temp°C', style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900)),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    const Icon(LucideIcons.wind, color: Colors.white70, size: 16),
                    const SizedBox(width: 4),
                    Text('$wind km/h', style: const TextStyle(color: Colors.white70, fontSize: 16)),
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
        const Text("7 kunlik prognoz", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Container(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _weatherService.dailyForecast!.length,
            itemBuilder: (context, index) {
              final day = _weatherService.dailyForecast![index];
              return Container(
                width: 80,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatDate(day['date']), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    Icon(_getWeatherIcon(day['code']), color: Colors.white, size: 28),
                    Column(
                      children: [
                        Text('${day['max']}°', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text('${day['min']}°', style: const TextStyle(color: Colors.white54, fontSize: 12)),
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
      if (date.year == now.year && date.month == now.month && date.day == now.day) return "Bugun";
      if (date.year == now.year && date.month == now.month && date.day == now.day + 1) return "Ertaga";
      
      const months = ['Yan', 'Fev', 'Mar', 'Apr', 'May', 'Iyun', 'Iyul', 'Avg', 'Sen', 'Okt', 'Noy', 'Dek'];
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Valyuta kurslari', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(LucideIcons.refreshCw), onPressed: _fetchCurrency),
            ],
          ),
          const SizedBox(height: 24),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (currencies != null && currencies!.isNotEmpty)
            _buildCurrencyList(isDark)
          else
            const Center(child: Text("Ma'lumot topilmadi")),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildCurrencyList(bool isDark) {
    return Column(
      children: currencies!.map((cur) {
        final ccy = cur['Ccy'];
        final rate = cur['Rate'];
        final diff = cur['Diff'] ?? '0';
        final isUp = !diff.startsWith('-');
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.banknote, color: Colors.green, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(ccy, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$rate UZS', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(isUp ? LucideIcons.trendingUp : LucideIcons.trendingDown, 
                           color: isUp ? Colors.green : Colors.red, size: 14),
                      const SizedBox(width: 4),
                      Text(diff, style: TextStyle(color: isUp ? Colors.green : Colors.red, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
