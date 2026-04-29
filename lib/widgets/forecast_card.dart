import 'package:flutter/material.dart';
import '../models/weather_data.dart';

const _weatherEmoji = <String, String>{
  'Clear': '☀️',
  'Clouds': '☁️',
  'Rain': '🌧️',
  'Drizzle': '🌦️',
  'Snow': '❄️',
  'Thunderstorm': '⛈️',
  'Fog': '🌫️',
};

List<String> _getForecastOutfit(double tempMax, String condition, int precipProb) {
  List<String> base;
  if (tempMax < 5) {
    base = ['🧥', '🧣', '🧤'];
  } else if (tempMax < 15) {
    base = ['🧥', '👕', '👖'];
  } else if (tempMax < 25) {
    base = ['👕', '👖', '👟'];
  } else {
    base = ['👕', '👖', '👡'];
  }

  final extras = <String>[];
  if (['Rain', 'Drizzle', 'Thunderstorm'].contains(condition) || precipProb >= 50) {
    extras.add('☂️');
  }
  if (condition == 'Snow') extras.add('👢');
  if (condition == 'Clear' && tempMax >= 20) extras.add('🕶️');

  return [...base, ...extras];
}

class ForecastCard extends StatelessWidget {
  final List<ForecastData> forecast;

  const ForecastCard({super.key, required this.forecast});

  @override
  Widget build(BuildContext context) {
    if (forecast.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            forecast.length > 5 ? '15일 예보' : '5일 예보',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(forecast.length, (i) {
            final item = forecast[i];
            final outfit = _getForecastOutfit(item.tempMax, item.condition, item.precipitationProbability);
            final isLast = i == forecast.length - 1;
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFFF8FAFC))),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 72,
                    child: Text(
                      item.date,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF334155)),
                    ),
                  ),
                  Text(_weatherEmoji[item.condition] ?? '🌡️', style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 40,
                    child: item.precipitationProbability > 0
                        ? Text(
                            '💧${item.precipitationProbability}%',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF60A5FA)),
                          )
                        : null,
                  ),
                  Text(
                    '${item.tempMin.round()}°',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF3B82F6)),
                  ),
                  const Text(' / ', style: TextStyle(fontSize: 13, color: Color(0xFFCBD5E1))),
                  Text(
                    '${item.tempMax.round()}°',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                  ),
                  const Spacer(),
                  Text(outfit.join(''), style: const TextStyle(fontSize: 15)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}