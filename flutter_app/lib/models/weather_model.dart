class WeatherData {
  final String city;
  final String country;
  final String description;
  final String condition;
  final String? district;
  final double temperature;
  final double feelsLike;
  final double windSpeed;
  final int humidity;
  final int pressure;
  final int visibility;
  final int? sunrise;
  final int? sunset;
  final double lat;
  final double lon;

  WeatherData({
    required this.city,
    required this.country,
    required this.description,
    required this.condition,
    this.district,
    required this.temperature,
    required this.feelsLike,
    required this.windSpeed,
    required this.humidity,
    required this.pressure,
    required this.visibility,
    this.sunrise,
    this.sunset,
    required this.lat,
    required this.lon,
  });
}

class ForecastData {
  final String date;
  final String condition;
  final String description;
  final double temp;
  final double tempMin;
  final double tempMax;
  final int precipitationProbability;
  final int uvIndex;

  ForecastData({
    required this.date,
    required this.condition,
    required this.description,
    required this.temp,
    required this.tempMin,
    required this.tempMax,
    required this.precipitationProbability,
    required this.uvIndex,
  });
}

class AirQuality {
  final int pm25;
  final int pm10;
  final int aqi;

  AirQuality({
    required this.pm25,
    required this.pm10,
    required this.aqi,
  });
}