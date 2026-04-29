class WeatherData {
  final String city;
  final String country;
  final String? district;
  final double temperature;
  final double feelsLike;
  final String description;
  final String condition;
  final int humidity;
  final double windSpeed;
  final int pressure;
  final int visibility;

  const WeatherData({
    required this.city,
    required this.country,
    this.district,
    required this.temperature,
    required this.feelsLike,
    required this.description,
    required this.condition,
    required this.humidity,
    required this.windSpeed,
    required this.pressure,
    required this.visibility,
  });
}

class ForecastData {
  final String date;
  final double temp;
  final double tempMin;
  final double tempMax;
  final String condition;
  final String description;
  final int precipitationProbability;

  const ForecastData({
    required this.date,
    required this.temp,
    required this.tempMin,
    required this.tempMax,
    required this.condition,
    required this.description,
    required this.precipitationProbability,
  });
}

class OpenMeteoResult {
  final List<ForecastData> forecast;
  final double todayUvIndex;
  final int todayPrecipProb;

  const OpenMeteoResult({
    required this.forecast,
    required this.todayUvIndex,
    required this.todayPrecipProb,
  });
}