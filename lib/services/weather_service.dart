import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'api_service.dart';

class WeatherService {
  static final WeatherService _instance = WeatherService._internal();
  factory WeatherService() => _instance;
  WeatherService._internal();

  Map<String, dynamic>? weather;
  List<Map<String, dynamic>>? dailyForecast;
  String currentCity = 'Tashkent';
  bool isLoading = false;
  bool hasData = false;

  Future<void> prefetchWeather() async {
    if (isLoading || hasData) return;
    isLoading = true;
    try {
      final api = ApiService();
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await _loadWeatherFallback(api);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      // O'rnatilganda (startup) avtomat location permission so'ramaymiz.
      // Agar ruxsat berilmagan bo'lsa, Toshkent ma'lumotini yuklaymiz.
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        await _loadWeatherFallback(api);
        return;
      }

      Position position = await Geolocator.getCurrentPosition();

      // Nominatim orqali shahar nomini aniqlash
      try {
        final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse'
          '?lat=${position.latitude}&lon=${position.longitude}'
          '&format=json&accept-language=uz,ru,en',
        );
        final res = await http.get(uri, headers: {
          'User-Agent': 'HubServis/1.0 (uz.hubservis.app)',
        }).timeout(const Duration(seconds: 8));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          final addr = data['address'] as Map<String, dynamic>? ?? {};
          currentCity = (addr['city'] ?? addr['town'] ?? addr['village'] ?? addr['county'] ?? 'Tashkent').toString();
        }
      } catch (_) {
        currentCity = 'Tashkent';
      }

      final w = await api.getWeather(currentCity, lat: position.latitude, lng: position.longitude);
      
      List<Map<String, dynamic>>? dForecast;
      try {
        final dio = Dio();
        final response = await dio.get(
          'https://api.open-meteo.com/v1/forecast',
          queryParameters: {
            'latitude': position.latitude,
            'longitude': position.longitude,
            'daily': 'weathercode,temperature_2m_max,temperature_2m_min',
            'timezone': 'auto'
          }
        );
        dForecast = _parseDailyForecast(response.data);
      } catch (e) {
        debugPrint("Daily forecast error: $e");
      }

      weather = w;
      dailyForecast = dForecast;
      hasData = true;
    } catch (e) {
      await _loadWeatherFallback(ApiService());
    } finally {
      isLoading = false;
    }
  }

  Future<void> _loadWeatherFallback(ApiService api) async {
    try {
      final w = await api.getWeather('Tashkent');
      
      List<Map<String, dynamic>>? dForecast;
      try {
        final dio = Dio();
        final response = await dio.get(
          'https://api.open-meteo.com/v1/forecast',
          queryParameters: {
            'latitude': 41.2995,
            'longitude': 69.2401,
            'daily': 'weathercode,temperature_2m_max,temperature_2m_min',
            'timezone': 'auto'
          }
        );
        dForecast = _parseDailyForecast(response.data);
      } catch (e) {
        debugPrint("Daily forecast fallback error: $e");
      }

      weather = w;
      dailyForecast = dForecast;
      currentCity = 'Tashkent';
      hasData = true;
    } catch (_) {}
  }

  List<Map<String, dynamic>> _parseDailyForecast(Map<String, dynamic> data) {
    List<Map<String, dynamic>> forecast = [];
    try {
      final daily = data['daily'];
      final times = daily['time'] as List;
      final maxTemps = daily['temperature_2m_max'] as List;
      final minTemps = daily['temperature_2m_min'] as List;
      final codes = daily['weathercode'] as List;

      for (int i = 0; i < times.length; i++) {
        forecast.add({
          'date': times[i],
          'max': maxTemps[i],
          'min': minTemps[i],
          'code': codes[i],
        });
      }
    } catch (e) {
      debugPrint("Parsing forecast error: $e");
    }
    return forecast;
  }
}
