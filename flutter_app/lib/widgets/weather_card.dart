import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';

class WeatherCard extends StatelessWidget {
  final WeatherData weather;
  final bool isGpsLocation;

  const WeatherCard({
    super.key,
    required this.weather,
    required this.isGpsLocation,
  });

  List<Color> _getGradientColors(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return [const Color(0xFFFBBF24), const Color(0xFFF97316)];
      case 'clouds':
        return [const Color(0xFF94A3B8), const Color(0xFF64748B)];
      case 'rain':
      case 'drizzle':
        return [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)];
      case 'snow':
        return [const Color(0xFFBAE6FD), const Color(0xFF7DD3FC)];
      case 'thunderstorm':
        return [const Color(0xFF4B5563), const Color(0xFF1F2937)];
      case 'mist':
      case 'fog':
      case 'haze':
        return [const Color(0xFFD1D5DB), const Color(0xFF9CA3AF)];
      default:
        return [const Color(0xFF818CF8), const Color(0xFF6366F1)];
    }
  }

  String _formatTime(int? unixTimestamp) {
    if (unixTimestamp == null) return '--:--';
    final dt = DateTime.fromMillisecondsSinceEpoch(unixTimestamp * 1000);
    return DateFormat('HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final gradientColors = _getGradientColors(weather.condition);
    final emoji = WeatherService.conditionToEmoji(weather.condition);
    final displayCity = weather.district?.isNotEmpty == true
        ? weather.district!
        : weather.city;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 도시명 + GPS 뱃지
            Row(
              children: [
                Expanded(
                  child: Text(
                    displayCity,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isGpsLocation)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.gps_fixed,
                            color: Colors.white, size: 12),
                        SizedBox(width: 3),
                        Text(
                          'GPS',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            if (weather.country.isNotEmpty)
              Text(
                weather.country,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.8), fontSize: 13),
              ),
            const SizedBox(height: 16),
            // 온도 + 이모지
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${weather.temperature.round()}°C',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 52,
                        fontWeight: FontWeight.w300,
                        height: 1,
                      ),
                    ),
                    Text(
                      weather.description,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 15),
                    ),
                    Text(
                      '체감 ${weather.feelsLike.round()}°C',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 13),
                    ),
                  ],
                ),
                Text(emoji, style: const TextStyle(fontSize: 64)),
              ],
            ),
            const SizedBox(height: 16),
            // 상세 정보 그리드
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _DetailItem(
                      icon: Icons.water_drop_outlined,
                      label: '습도',
                      value: '${weather.humidity}%'),
                  _DetailItem(
                      icon: Icons.air,
                      label: '바람',
                      value: '${weather.windSpeed.toStringAsFixed(1)}m/s'),
                  _DetailItem(
                      icon: Icons.compress,
                      label: '기압',
                      value: '${weather.pressure}hPa'),
                  _DetailItem(
                      icon: Icons.visibility_outlined,
                      label: '가시거리',
                      value: '${(weather.visibility / 1000).toStringAsFixed(1)}km'),
                ],
              ),
            ),
            // 일출/일몰
            if (weather.sunrise != null || weather.sunset != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.wb_sunny_outlined,
                      color: Colors.white70, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '일출 ${_formatTime(weather.sunrise)}',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.nightlight_round,
                      color: Colors.white70, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '일몰 ${_formatTime(weather.sunset)}',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        Text(
          label,
          style: TextStyle(
              color: Colors.white.withOpacity(0.75), fontSize: 10),
        ),
      ],
    );
  }
}