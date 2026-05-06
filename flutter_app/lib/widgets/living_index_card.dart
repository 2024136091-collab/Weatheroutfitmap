import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/weather_model.dart';

class LivingIndexCard extends StatelessWidget {
  final WeatherData weather;
  final double uvIndex;
  final int precipProb;
  final AirQuality? airQuality;

  const LivingIndexCard({
    super.key,
    required this.weather,
    required this.uvIndex,
    required this.precipProb,
    this.airQuality,
  });

  // 자외선 지수 등급
  Map<String, dynamic> _uvGrade(double uv) {
    if (uv <= 2) return {'label': '좋음', 'color': const Color(0xFF22C55E), 'value': uv / 10};
    if (uv <= 5) return {'label': '보통', 'color': const Color(0xFFF59E0B), 'value': uv / 10};
    if (uv <= 7) return {'label': '높음', 'color': const Color(0xFFF97316), 'value': uv / 10};
    if (uv <= 10) return {'label': '매우높음', 'color': const Color(0xFFEF4444), 'value': uv / 11};
    return {'label': '위험', 'color': const Color(0xFF7C3AED), 'value': 1.0};
  }

  // 불쾌지수
  Map<String, dynamic> _discomfortGrade(double temp, int humidity) {
    final h = humidity / 100;
    final di = temp - 0.55 * (1 - h) * (temp - 14.5);
    final score = ((di - 55) / 25).clamp(0.0, 1.0);
    if (di < 68) return {'label': '쾌적', 'color': const Color(0xFF22C55E), 'value': score, 'di': di};
    if (di < 75) return {'label': '보통', 'color': const Color(0xFFF59E0B), 'value': score, 'di': di};
    if (di < 80) return {'label': '불쾌', 'color': const Color(0xFFF97316), 'value': score, 'di': di};
    return {'label': '매우불쾌', 'color': const Color(0xFFEF4444), 'value': score, 'di': di};
  }

  // 세탁 지수
  Map<String, dynamic> _laundryGrade(int precipProbability, int humidity, double windSpeed) {
    final score = ((1 - precipProbability / 100) * 50 +
            (1 - math.min(humidity, 80) / 80) * 30 +
            math.min(windSpeed / 10, 1) * 20) /
        100;
    if (score >= 0.8) return {'label': '매우좋음', 'color': const Color(0xFF22C55E), 'value': score};
    if (score >= 0.6) return {'label': '좋음', 'color': const Color(0xFF86EFAC), 'value': score};
    if (score >= 0.4) return {'label': '보통', 'color': const Color(0xFFF59E0B), 'value': score};
    return {'label': '나쁨', 'color': const Color(0xFFEF4444), 'value': score};
  }

  // 운동 지수
  Map<String, dynamic> _exerciseGrade(double temp, int humidity, double windSpeed) {
    double score = 1.0;
    if (temp < 0 || temp > 35) score -= 0.4;
    else if (temp < 5 || temp > 30) score -= 0.2;
    if (humidity > 80) score -= 0.2;
    if (windSpeed > 10) score -= 0.1;
    score = score.clamp(0.0, 1.0);
    if (score >= 0.8) return {'label': '매우좋음', 'color': const Color(0xFF22C55E), 'value': score};
    if (score >= 0.6) return {'label': '좋음', 'color': const Color(0xFF86EFAC), 'value': score};
    if (score >= 0.4) return {'label': '보통', 'color': const Color(0xFFF59E0B), 'value': score};
    return {'label': '나쁨', 'color': const Color(0xFFEF4444), 'value': score};
  }

  // 우산 지수
  Map<String, dynamic> _umbrellaGrade(int precipProb, String condition) {
    final c = condition.toLowerCase();
    double score = precipProb / 100;
    if (c == 'rain' || c == 'drizzle') score = math.max(score, 0.9);
    if (c == 'thunderstorm') score = 1.0;
    if (score >= 0.8) return {'label': '필수', 'color': const Color(0xFF3B82F6), 'value': score};
    if (score >= 0.5) return {'label': '권장', 'color': const Color(0xFF60A5FA), 'value': score};
    if (score >= 0.3) return {'label': '가능', 'color': const Color(0xFFF59E0B), 'value': score};
    return {'label': '불필요', 'color': const Color(0xFF22C55E), 'value': score};
  }

  // AQI 등급 (PM10)
  Map<String, dynamic> _pm10Grade(int pm10) {
    if (pm10 <= 30) return {'label': '좋음', 'color': const Color(0xFF22C55E)};
    if (pm10 <= 80) return {'label': '보통', 'color': const Color(0xFFF59E0B)};
    if (pm10 <= 150) return {'label': '나쁨', 'color': const Color(0xFFF97316)};
    return {'label': '매우나쁨', 'color': const Color(0xFFEF4444)};
  }

  // AQI 등급 (PM2.5)
  Map<String, dynamic> _pm25Grade(int pm25) {
    if (pm25 <= 15) return {'label': '좋음', 'color': const Color(0xFF22C55E)};
    if (pm25 <= 35) return {'label': '보통', 'color': const Color(0xFFF59E0B)};
    if (pm25 <= 75) return {'label': '나쁨', 'color': const Color(0xFFF97316)};
    return {'label': '매우나쁨', 'color': const Color(0xFFEF4444)};
  }

  @override
  Widget build(BuildContext context) {
    final uv = _uvGrade(uvIndex);
    final di = _discomfortGrade(weather.temperature, weather.humidity);
    final laundry = _laundryGrade(precipProb, weather.humidity, weather.windSpeed);
    final exercise = _exerciseGrade(
        weather.temperature, weather.humidity, weather.windSpeed);
    final umbrella = _umbrellaGrade(precipProb, weather.condition);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Text('📊', style: TextStyle(fontSize: 20)),
                SizedBox(width: 8),
                Text(
                  '생활 지수',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 5개 지수 원형 표시
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _CircleIndex(
                  emoji: '☀️',
                  label: '자외선',
                  grade: uv['label'] as String,
                  color: uv['color'] as Color,
                  progress: (uv['value'] as double).clamp(0.0, 1.0),
                  detail: '${uvIndex.toStringAsFixed(1)}',
                ),
                _CircleIndex(
                  emoji: '😓',
                  label: '불쾌지수',
                  grade: di['label'] as String,
                  color: di['color'] as Color,
                  progress: (di['value'] as double).clamp(0.0, 1.0),
                  detail: (di['di'] as double).toStringAsFixed(0),
                ),
                _CircleIndex(
                  emoji: '👕',
                  label: '세탁',
                  grade: laundry['label'] as String,
                  color: laundry['color'] as Color,
                  progress: (laundry['value'] as double).clamp(0.0, 1.0),
                  detail: '',
                ),
                _CircleIndex(
                  emoji: '🏃',
                  label: '운동',
                  grade: exercise['label'] as String,
                  color: exercise['color'] as Color,
                  progress: (exercise['value'] as double).clamp(0.0, 1.0),
                  detail: '',
                ),
                _CircleIndex(
                  emoji: '☂️',
                  label: '우산',
                  grade: umbrella['label'] as String,
                  color: umbrella['color'] as Color,
                  progress: (umbrella['value'] as double).clamp(0.0, 1.0),
                  detail: '$precipProb%',
                ),
              ],
            ),
            // 대기질 섹션
            if (airQuality != null) ...[
              const SizedBox(height: 16),
              const Divider(color: Color(0xFFE2E8F0)),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Text('💨', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 6),
                  Text(
                    '대기질 정보',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _AqiBar(
                label: 'PM10',
                value: airQuality!.pm10,
                maxValue: 200,
                grade: _pm10Grade(airQuality!.pm10),
                unit: 'μg/m³',
              ),
              const SizedBox(height: 8),
              _AqiBar(
                label: 'PM2.5',
                value: airQuality!.pm25,
                maxValue: 100,
                grade: _pm25Grade(airQuality!.pm25),
                unit: 'μg/m³',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CircleIndex extends StatelessWidget {
  final String emoji;
  final String label;
  final String grade;
  final Color color;
  final double progress;
  final String detail;

  const _CircleIndex({
    required this.emoji,
    required this.label,
    required this.grade,
    required this.color,
    required this.progress,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 54,
              height: 54,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 5,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            Text(emoji, style: const TextStyle(fontSize: 20)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
        ),
        Text(
          grade,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        if (detail.isNotEmpty)
          Text(
            detail,
            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
          ),
      ],
    );
  }
}

class _AqiBar extends StatelessWidget {
  final String label;
  final int value;
  final int maxValue;
  final Map<String, dynamic> grade;
  final String unit;

  const _AqiBar({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.grade,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (value / maxValue).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(
          width: 40,
          child: Text(
            label,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF374151)),
          ),
        ),
        Expanded(
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: const Color(0xFFE2E8F0),
            valueColor:
                AlwaysStoppedAnimation<Color>(grade['color'] as Color),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 70,
          child: Text(
            '$value $unit',
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: (grade['color'] as Color).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            grade['label'] as String,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: grade['color'] as Color,
            ),
          ),
        ),
      ],
    );
  }
}