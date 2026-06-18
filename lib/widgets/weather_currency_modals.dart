import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/api_service.dart';
import '../theme/glass_tokens.dart';

class WeatherModal extends StatefulWidget {
  const WeatherModal({super.key});

  @override
  State<WeatherModal> createState() => _WeatherModalState();
}

class _WeatherModalState extends State<WeatherModal> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? weather;
  bool _loading = true;
  String _currentCity = 'Tashkent';

  @override
  void initState() {
    super.initState();
    _fetchLocationAndWeather();
  }

  Future<void> _fetchLocationAndWeather() async {
    setState(() => _loading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return _loadWeatherFallback();
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return _loadWeatherFallback();
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        return _loadWeatherFallback();
      }

      Position position = await Geolocator.getCurrentPosition();
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      
      if (placemarks.isNotEmpty) {
        _currentCity = placemarks.first.locality ?? placemarks.first.administrativeArea ?? 'Tashkent';
      }

      final w = await _api.getWeather(_currentCity, lat: position.latitude, lng: position.longitude);
      if (mounted) {
        setState(() {
          weather = w;
          _loading = false;
        });
      }
    } catch (e) {
      _loadWeatherFallback();
    }
  }

  Future<void> _loadWeatherFallback() async {
    try {
      final w = await _api.getWeather('Tashkent');
      if (mounted) {
        setState(() {
          weather = w;
          _currentCity = 'Tashkent';
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
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
              IconButton(icon: const Icon(LucideIcons.refreshCw), onPressed: _fetchLocationAndWeather),
            ],
          ),
          const SizedBox(height: 24),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (weather != null)
            _buildWeatherInfo(theme)
          else
            const Center(child: Text("Ma'lumot topilmadi")),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildWeatherInfo(ThemeData theme) {
    final temp = weather!['temperature_celsius'] ?? weather!['temperature'] ?? '--';
    final cond = weather!['condition'] ?? '--';
    final wind = weather!['windspeed'] ?? '--';
    
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
                  Text(_currentCity, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
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
