import 'package:flutter/material.dart';
import '../models/weather_data.dart';
import '../services/weather_api.dart';

class WeatherProvider extends ChangeNotifier {
  WeatherData? weather;
  List<ForecastData> forecast = [];
  double todayUvIndex = 0;
  int todayPrecipProb = 0;
  bool loading = false;
  String? error;

  Future<WeatherData?> search(String city) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        fetchWeatherData(city),
        fetchOpenMeteoData(city),
      ]);
      weather = results[0] as WeatherData;
      final meteo = results[1] as OpenMeteoResult;
      forecast = meteo.forecast;
      todayUvIndex = meteo.todayUvIndex;
      todayPrecipProb = meteo.todayPrecipProb;
      loading = false;
      notifyListeners();
      return weather;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      loading = false;
      notifyListeners();
      return null;
    }
  }

  Future<WeatherData?> searchByCoords(double lat, double lon) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        fetchWeatherByCoords(lat, lon),
        fetchOpenMeteoByCoords(lat, lon),
      ]);
      weather = results[0] as WeatherData;
      final meteo = results[1] as OpenMeteoResult;
      forecast = meteo.forecast;
      todayUvIndex = meteo.todayUvIndex;
      todayPrecipProb = meteo.todayPrecipProb;
      loading = false;
      notifyListeners();
      return weather;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      loading = false;
      notifyListeners();
      return null;
    }
  }
}