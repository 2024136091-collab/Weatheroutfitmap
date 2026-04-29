import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_data.dart';

const _owmKey = '7e29173a70b89b4919dfe873c2352b30';
const _owmBase = 'https://api.openweathermap.org/data/2.5';

const _wmoMap = <int, (String, String)>{
  0:  ('Clear',        '맑음'),
  1:  ('Clear',        '대체로 맑음'),
  2:  ('Clouds',       '구름 조금'),
  3:  ('Clouds',       '흐림'),
  45: ('Fog',          '안개'),
  48: ('Fog',          '안개'),
  51: ('Drizzle',      '가벼운 이슬비'),
  53: ('Drizzle',      '이슬비'),
  55: ('Drizzle',      '강한 이슬비'),
  61: ('Rain',         '가벼운 비'),
  63: ('Rain',         '비'),
  65: ('Rain',         '강한 비'),
  71: ('Snow',         '가벼운 눈'),
  73: ('Snow',         '눈'),
  75: ('Snow',         '강한 눈'),
  77: ('Snow',         '싸락눈'),
  80: ('Rain',         '소나기'),
  81: ('Rain',         '소나기'),
  82: ('Rain',         '강한 소나기'),
  85: ('Snow',         '눈 소나기'),
  86: ('Snow',         '강한 눈 소나기'),
  95: ('Thunderstorm', '천둥번개'),
  96: ('Thunderstorm', '우박 동반 천둥'),
  99: ('Thunderstorm', '강한 우박 동반 천둥'),
};

(String, String) _wmoLookup(int code) =>
    _wmoMap[code] ?? ('Clouds', '흐림');

Future<({double lat, double lon, String name, String country})> geocodeCity(String input) async {
  final city = input.split(',').first.trim();
  final uri = Uri.parse(
    'https://geocoding-api.open-meteo.com/v1/search'
    '?name=${Uri.encodeComponent(city)}&count=1&language=ko&format=json',
  );
  final res = await http.get(uri);
  if (res.statusCode != 200) throw Exception('위치를 찾을 수 없습니다');
  final data = jsonDecode(res.body) as Map<String, dynamic>;
  final results = data['results'] as List?;
  if (results == null || results.isEmpty) {
    throw Exception('도시를 찾을 수 없습니다. 다른 도시명으로 검색해 보세요.');
  }
  final r = results.first as Map<String, dynamic>;
  return (
    lat: (r['latitude'] as num).toDouble(),
    lon: (r['longitude'] as num).toDouble(),
    name: r['name'] as String,
    country: r['country_code'] as String,
  );
}

Future<String?> reverseGeocodeKo(double lat, double lon) async {
  try {
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse'
      '?lat=$lat&lon=$lon&format=json&accept-language=ko',
    );
    final res = await http.get(uri, headers: {'User-Agent': 'WeatherCodiApp/1.0'});
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final addr = (data['address'] as Map<String, dynamic>?) ?? {};
    final parts = <String>[
      if (addr['city_district'] != null) addr['city_district'] as String
      else if (addr['county'] != null) addr['county'] as String,
      if (addr['suburb'] != null) addr['suburb'] as String
      else if (addr['neighbourhood'] != null) addr['neighbourhood'] as String
      else if (addr['quarter'] != null) addr['quarter'] as String,
    ].where((s) => s.isNotEmpty).toList();
    return parts.isNotEmpty ? parts.join(' ') : null;
  } catch (_) {
    return null;
  }
}

Future<WeatherData> fetchWeatherByCoords(double lat, double lon) async {
  final results = await Future.wait([
    http.get(Uri.parse(
      '$_owmBase/weather?lat=$lat&lon=$lon&appid=$_owmKey&units=metric&lang=kr',
    )),
    reverseGeocodeKo(lat, lon),
  ]);
  final weatherRes = results[0] as http.Response;
  final district = results[1] as String?;
  if (weatherRes.statusCode != 200) throw Exception('날씨 정보를 가져올 수 없습니다');
  final d = jsonDecode(weatherRes.body) as Map<String, dynamic>;
  final main = d['main'] as Map<String, dynamic>;
  final wind = d['wind'] as Map<String, dynamic>;
  final weather = (d['weather'] as List).first as Map<String, dynamic>;
  final sys = d['sys'] as Map<String, dynamic>;
  return WeatherData(
    city: d['name'] as String,
    country: sys['country'] == 'KR' ? '대한민국' : sys['country'] as String,
    district: district,
    temperature: (main['temp'] as num).toDouble(),
    feelsLike: (main['feels_like'] as num).toDouble(),
    description: weather['description'] as String,
    condition: weather['main'] as String,
    humidity: main['humidity'] as int,
    windSpeed: (wind['speed'] as num).toDouble(),
    pressure: main['pressure'] as int,
    visibility: d['visibility'] as int,
  );
}

Future<WeatherData> fetchWeatherData(String city) async {
  final geo = await geocodeCity(city);
  final results = await Future.wait([
    http.get(Uri.parse(
      '$_owmBase/weather?lat=${geo.lat}&lon=${geo.lon}&appid=$_owmKey&units=metric&lang=kr',
    )),
    reverseGeocodeKo(geo.lat, geo.lon),
  ]);
  final weatherRes = results[0] as http.Response;
  final district = results[1] as String?;
  if (weatherRes.statusCode != 200) throw Exception('날씨 정보를 가져올 수 없습니다');
  final d = jsonDecode(weatherRes.body) as Map<String, dynamic>;
  final sys = d['sys'] as Map<String, dynamic>;
  if (sys['country'] != 'KR') throw Exception('국내 도시만 검색할 수 있습니다');
  final main = d['main'] as Map<String, dynamic>;
  final wind = d['wind'] as Map<String, dynamic>;
  final weather = (d['weather'] as List).first as Map<String, dynamic>;
  return WeatherData(
    city: geo.name.isNotEmpty ? geo.name : d['name'] as String,
    country: '대한민국',
    district: district,
    temperature: (main['temp'] as num).toDouble(),
    feelsLike: (main['feels_like'] as num).toDouble(),
    description: weather['description'] as String,
    condition: weather['main'] as String,
    humidity: main['humidity'] as int,
    windSpeed: (wind['speed'] as num).toDouble(),
    pressure: main['pressure'] as int,
    visibility: d['visibility'] as int,
  );
}

Future<OpenMeteoResult> fetchOpenMeteoByCoords(double lat, double lon) async {
  return _fetchOpenMeteoForecast(lat, lon);
}

Future<OpenMeteoResult> fetchOpenMeteoData(String city) async {
  final geo = await geocodeCity(city);
  return _fetchOpenMeteoForecast(geo.lat, geo.lon);
}

Future<OpenMeteoResult> _fetchOpenMeteoForecast(double lat, double lon) async {
  final uri = Uri.parse(
    'https://api.open-meteo.com/v1/forecast'
    '?latitude=$lat&longitude=$lon'
    '&daily=temperature_2m_max,temperature_2m_min,weathercode,precipitation_probability_max,uv_index_max'
    '&timezone=auto&forecast_days=15',
  );
  final res = await http.get(uri);
  if (res.statusCode != 200) throw Exception('예보를 가져올 수 없습니다');
  final data = jsonDecode(res.body) as Map<String, dynamic>;
  final daily = data['daily'] as Map<String, dynamic>;
  final times = daily['time'] as List;
  final forecast = List<ForecastData>.generate(times.length, (i) {
    final date = DateTime.parse('${times[i]}T12:00:00');
    final wday = ['일', '월', '화', '수', '목', '금', '토'][date.weekday % 7];
    final dateStr = '${date.month}월 ${date.day}일($wday)';
    final (condition, description) = _wmoLookup(daily['weathercode'][i] as int);
    final tempMax = (daily['temperature_2m_max'][i] as num).toDouble();
    final tempMin = (daily['temperature_2m_min'][i] as num).toDouble();
    return ForecastData(
      date: dateStr,
      temp: ((tempMax + tempMin) / 2).roundToDouble(),
      tempMin: tempMin,
      tempMax: tempMax,
      condition: condition,
      description: description,
      precipitationProbability: (daily['precipitation_probability_max'][i] as num?)?.toInt() ?? 0,
    );
  });
  return OpenMeteoResult(
    forecast: forecast,
    todayUvIndex: (daily['uv_index_max'][0] as num?)?.toDouble() ?? 0,
    todayPrecipProb: (daily['precipitation_probability_max'][0] as num?)?.toInt() ?? 0,
  );
}