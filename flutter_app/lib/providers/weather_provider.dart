import 'package:flutter/foundation.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';
import '../services/location_service.dart';
import '../services/api_service.dart';

class WeatherProvider extends ChangeNotifier {
  WeatherData? _weather;
  List<ForecastData> _forecast = [];
  double _todayUvIndex = 0;
  int _todayPrecipProb = 0;
  AirQuality? _airQuality;
  bool _isGpsLocation = false;
  bool _loading = false;
  String? _error;

  List<Map<String, dynamic>> _history = [];
  List<Map<String, dynamic>> _favorites = [];

  final WeatherService _weatherService = WeatherService();
  final LocationService _locationService = LocationService();
  final ApiService _apiService = ApiService();

  WeatherData? get weather => _weather;
  List<ForecastData> get forecast => _forecast;
  double get todayUvIndex => _todayUvIndex;
  int get todayPrecipProb => _todayPrecipProb;
  AirQuality? get airQuality => _airQuality;
  bool get isGpsLocation => _isGpsLocation;
  bool get loading => _loading;
  String? get error => _error;
  List<Map<String, dynamic>> get history => _history;
  List<Map<String, dynamic>> get favorites => _favorites;

  Future<WeatherData?> searchByCity(String city, {String? token}) async {
    _loading = true;
    _error = null;
    _isGpsLocation = false;
    notifyListeners();
    try {
      final weather = await _weatherService.fetchWeatherByCity(city);
      _weather = weather;
      final result = await _weatherService.fetchForecastByCoords(
          weather.lat, weather.lon);
      _forecast = result['forecast'] as List<ForecastData>;
      _todayUvIndex = result['uvIndex'] as double;
      _todayPrecipProb = result['precipProb'] as int;
      _airQuality = result['airQuality'] as AirQuality?;

      // 검색 기록 저장
      if (token != null && token.isNotEmpty) {
        await _apiService.addHistory(city, token);
        await loadHistory(token);
      }

      return weather;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<WeatherData?> searchByLocation({String? token}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final coords = await _locationService.getCurrentLocation();
      final lat = coords['lat']!;
      final lon = coords['lon']!;

      final weather = await _weatherService.fetchWeatherByCoords(lat, lon);
      _weather = weather;
      _isGpsLocation = true;

      // 역지오코딩으로 한국어 지역명 보완 시도
      final district = await _weatherService.reverseGeocode(lat, lon);
      if (district.isNotEmpty) {
        _weather = WeatherData(
          city: weather.city,
          country: weather.country,
          description: weather.description,
          condition: weather.condition,
          district: district,
          temperature: weather.temperature,
          feelsLike: weather.feelsLike,
          windSpeed: weather.windSpeed,
          humidity: weather.humidity,
          pressure: weather.pressure,
          visibility: weather.visibility,
          sunrise: weather.sunrise,
          sunset: weather.sunset,
          lat: weather.lat,
          lon: weather.lon,
        );
      }

      final result = await _weatherService.fetchForecastByCoords(lat, lon);
      _forecast = result['forecast'] as List<ForecastData>;
      _todayUvIndex = result['uvIndex'] as double;
      _todayPrecipProb = result['precipProb'] as int;
      _airQuality = result['airQuality'] as AirQuality?;

      // GPS 검색 기록 저장
      if (token != null && token.isNotEmpty) {
        final cityName = _weather?.district ?? _weather?.city ?? 'GPS 위치';
        await _apiService.addHistory('GPS:$lat,$lon:$cityName', token);
        await loadHistory(token);
      }

      return _weather;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isGpsLocation = false;
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadHistory(String? token) async {
    if (token == null || token.isEmpty) {
      _history = [];
      notifyListeners();
      return;
    }
    try {
      _history = await _apiService.getHistory(token);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> deleteHistoryItem(int id, String? token) async {
    await _apiService.deleteHistoryItem(id, token);
    await loadHistory(token);
  }

  Future<void> clearHistory(String? token) async {
    await _apiService.deleteHistory(token);
    await loadHistory(token);
  }

  Future<void> loadFavorites(String? token) async {
    if (token == null || token.isEmpty) {
      _favorites = [];
      notifyListeners();
      return;
    }
    try {
      _favorites = await _apiService.getFavorites(token);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> addFavorite(
      String city, String displayName, String? token) async {
    await _apiService.addFavorite(city, displayName, token);
    await loadFavorites(token);
  }

  Future<void> removeFavorite(int id, String? token) async {
    await _apiService.removeFavorite(id, token);
    await loadFavorites(token);
  }

  Future<void> clearFavorites(String? token) async {
    await _apiService.clearFavorites(token);
    await loadFavorites(token);
  }

  bool isFavorite(String city) {
    return _favorites.any((f) =>
        (f['city'] as String?)?.toLowerCase() == city.toLowerCase() ||
        (f['displayName'] as String?)?.toLowerCase() == city.toLowerCase());
  }

  void clearWeather() {
    _weather = null;
    _forecast = [];
    _error = null;
    notifyListeners();
  }
}