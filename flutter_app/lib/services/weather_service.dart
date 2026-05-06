import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';

class WeatherService {
  static const String _owmApiKey = '7e29173a70b89b4919dfe873c2352b30';

  static String wmoToCondition(int code) {
    if (code == 0) return 'Clear';
    if (code <= 3) return 'Clouds';
    if (code <= 9) return 'Mist';
    if (code <= 19) return 'Mist';
    if (code <= 29) return 'Mist';
    if (code <= 39) return 'Mist';
    if (code <= 49) return 'Mist';
    if (code <= 59) return 'Drizzle';
    if (code <= 69) return 'Rain';
    if (code <= 79) return 'Snow';
    if (code <= 84) return 'Rain';
    if (code <= 94) return 'Thunderstorm';
    return 'Thunderstorm';
  }

  static String wmoToDescription(int code) {
    const Map<int, String> descriptions = {
      0: '맑음',
      1: '대체로 맑음',
      2: '구름 조금',
      3: '흐림',
      45: '안개',
      48: '서리 안개',
      51: '가벼운 이슬비',
      53: '이슬비',
      55: '짙은 이슬비',
      61: '가벼운 비',
      63: '비',
      65: '강한 비',
      71: '가벼운 눈',
      73: '눈',
      75: '강한 눈',
      77: '소나기',
      80: '약한 소나기',
      81: '소나기',
      82: '강한 소나기',
      85: '눈 소나기',
      86: '강한 눈 소나기',
      95: '뇌우',
      96: '약한 우박 뇌우',
      99: '강한 우박 뇌우',
    };
    return descriptions[code] ?? '흐림';
  }

  static String wmoToEmoji(int code) {
    if (code == 0) return '☀️';
    if (code <= 2) return '⛅';
    if (code == 3) return '☁️';
    if (code <= 49) return '🌫️';
    if (code <= 59) return '🌦️';
    if (code <= 69) return '🌧️';
    if (code <= 79) return '❄️';
    if (code <= 84) return '🌧️';
    if (code <= 99) return '⛈️';
    return '🌥️';
  }

  Future<Map<String, dynamic>> geocodeCity(String cityName) async {
    final uri = Uri.parse(
      'https://geocoding-api.open-meteo.com/v1/search?name=${Uri.encodeComponent(cityName)}&count=1&language=ko&format=json',
    );
    final response = await http.get(uri);
    if (response.statusCode != 200) throw Exception('지오코딩 실패');
    final data = jsonDecode(response.body);
    final results = data['results'] as List?;
    if (results == null || results.isEmpty) throw Exception('도시를 찾을 수 없습니다: $cityName');
    final r = results[0];
    return {
      'lat': (r['latitude'] as num).toDouble(),
      'lon': (r['longitude'] as num).toDouble(),
      'name': r['name'] as String? ?? cityName,
      'country': r['country_code'] as String? ?? '',
    };
  }

  Future<String> reverseGeocode(double lat, double lon) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json&accept-language=ko',
      );
      final response = await http.get(uri, headers: {'User-Agent': 'WeatherCodiApp/1.0'});
      if (response.statusCode != 200) return '';
      final data = jsonDecode(response.body);
      final address = data['address'] as Map<String, dynamic>?;
      if (address == null) return '';
      return address['city'] as String? ??
          address['town'] as String? ??
          address['village'] as String? ??
          address['county'] as String? ??
          '';
    } catch (_) {
      return '';
    }
  }

  Future<WeatherData> fetchWeatherByCoords(double lat, double lon) async {
    final uri = Uri.parse(
      'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$_owmApiKey&units=metric&lang=kr',
    );
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('날씨 정보를 불러오지 못했습니다 (${response.statusCode})');
    }
    return _parseWeatherResponse(response.body);
  }

  Future<WeatherData> fetchWeatherByCity(String city) async {
    Uri uri;
    // city가 "Seoul,KR" 형식인지 확인
    if (city.contains(',')) {
      uri = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?q=${Uri.encodeComponent(city)}&appid=$_owmApiKey&units=metric&lang=kr',
      );
    } else {
      final geo = await geocodeCity(city);
      final lat = geo['lat'] as double;
      final lon = geo['lon'] as double;
      return fetchWeatherByCoords(lat, lon);
    }
    final response = await http.get(uri);
    if (response.statusCode == 404) {
      // fallback: 지오코딩으로 재시도
      final name = city.contains(',') ? city.split(',')[0] : city;
      final geo = await geocodeCity(name);
      return fetchWeatherByCoords(geo['lat'] as double, geo['lon'] as double);
    }
    if (response.statusCode != 200) {
      throw Exception('날씨 정보를 불러오지 못했습니다 (${response.statusCode})');
    }
    return _parseWeatherResponse(response.body);
  }

  WeatherData _parseWeatherResponse(String body) {
    final data = jsonDecode(body);
    final weather = (data['weather'] as List)[0] as Map<String, dynamic>;
    final main = data['main'] as Map<String, dynamic>;
    final wind = data['wind'] as Map<String, dynamic>? ?? {};
    final sys = data['sys'] as Map<String, dynamic>? ?? {};
    final coord = data['coord'] as Map<String, dynamic>;

    return WeatherData(
      city: data['name'] as String? ?? '',
      country: sys['country'] as String? ?? '',
      description: weather['description'] as String? ?? '',
      condition: weather['main'] as String? ?? 'Clear',
      temperature: (main['temp'] as num).toDouble(),
      feelsLike: (main['feels_like'] as num).toDouble(),
      windSpeed: (wind['speed'] as num?)?.toDouble() ?? 0.0,
      humidity: (main['humidity'] as num).toInt(),
      pressure: (main['pressure'] as num).toInt(),
      visibility: ((data['visibility'] as num?)?.toInt() ?? 10000),
      sunrise: sys['sunrise'] as int?,
      sunset: sys['sunset'] as int?,
      lat: (coord['lat'] as num).toDouble(),
      lon: (coord['lon'] as num).toDouble(),
    );
  }

  Future<Map<String, dynamic>> fetchForecastByCoords(double lat, double lon) async {
    final forecastUri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon'
      '&daily=temperature_2m_max,temperature_2m_min,weathercode,precipitation_probability_max,uv_index_max'
      '&timezone=auto&forecast_days=15',
    );
    final aqiUri = Uri.parse(
      'https://air-quality-api.open-meteo.com/v1/air-quality?latitude=$lat&longitude=$lon'
      '&hourly=pm10,pm2_5,european_aqi&timezone=auto&forecast_days=1',
    );

    final responses = await Future.wait([
      http.get(forecastUri),
      http.get(aqiUri),
    ]);

    final forecastResp = responses[0];
    final aqiResp = responses[1];

    if (forecastResp.statusCode != 200) {
      throw Exception('예보 정보를 불러오지 못했습니다');
    }

    final forecastData = jsonDecode(forecastResp.body);
    final daily = forecastData['daily'] as Map<String, dynamic>;
    final dates = daily['time'] as List;
    final maxTemps = daily['temperature_2m_max'] as List;
    final minTemps = daily['temperature_2m_min'] as List;
    final weatherCodes = daily['weathercode'] as List;
    final precipProbs = daily['precipitation_probability_max'] as List;
    final uvIndices = daily['uv_index_max'] as List;

    final List<ForecastData> forecasts = [];
    for (int i = 0; i < dates.length; i++) {
      final code = (weatherCodes[i] as num?)?.toInt() ?? 0;
      final maxT = (maxTemps[i] as num?)?.toDouble() ?? 0.0;
      final minT = (minTemps[i] as num?)?.toDouble() ?? 0.0;
      forecasts.add(ForecastData(
        date: dates[i] as String,
        condition: wmoToCondition(code),
        description: wmoToDescription(code),
        temp: ((maxT + minT) / 2),
        tempMin: minT,
        tempMax: maxT,
        precipitationProbability: (precipProbs[i] as num?)?.toInt() ?? 0,
        uvIndex: (uvIndices[i] as num?)?.toInt() ?? 0,
      ));
    }

    final double todayUvIndex = uvIndices.isNotEmpty ? (uvIndices[0] as num?)?.toDouble() ?? 0.0 : 0.0;
    final int todayPrecipProb = precipProbs.isNotEmpty ? (precipProbs[0] as num?)?.toInt() ?? 0 : 0;

    AirQuality? airQuality;
    if (aqiResp.statusCode == 200) {
      try {
        final aqiData = jsonDecode(aqiResp.body);
        final hourly = aqiData['hourly'] as Map<String, dynamic>;
        final pm10List = hourly['pm10'] as List;
        final pm25List = hourly['pm2_5'] as List;
        final aqiList = hourly['european_aqi'] as List;

        double pm10Sum = 0, pm25Sum = 0, aqiSum = 0;
        int count = 0;
        for (int i = 0; i < pm10List.length && i < 24; i++) {
          if (pm10List[i] != null && pm25List[i] != null && aqiList[i] != null) {
            pm10Sum += (pm10List[i] as num).toDouble();
            pm25Sum += (pm25List[i] as num).toDouble();
            aqiSum += (aqiList[i] as num).toDouble();
            count++;
          }
        }
        if (count > 0) {
          airQuality = AirQuality(
            pm10: (pm10Sum / count).round(),
            pm25: (pm25Sum / count).round(),
            aqi: (aqiSum / count).round(),
          );
        }
      } catch (_) {}
    }

    return {
      'forecast': forecasts,
      'uvIndex': todayUvIndex,
      'precipProb': todayPrecipProb,
      'airQuality': airQuality,
    };
  }

  Future<Map<String, dynamic>> fetchForecastByCity(String city) async {
    final geo = await geocodeCity(city.contains(',') ? city.split(',')[0] : city);
    return fetchForecastByCoords(geo['lat'] as double, geo['lon'] as double);
  }

  static String conditionToEmoji(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return '☀️';
      case 'clouds':
        return '☁️';
      case 'rain':
        return '🌧️';
      case 'drizzle':
        return '🌦️';
      case 'snow':
        return '❄️';
      case 'thunderstorm':
        return '⛈️';
      case 'mist':
      case 'fog':
      case 'haze':
        return '🌫️';
      default:
        return '🌥️';
    }
  }
}