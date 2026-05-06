import 'package:flutter/material.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';

class ForecastCard extends StatelessWidget {
  final List<ForecastData> forecast;

  const ForecastCard({super.key, required this.forecast});

  String _formatDate(String dateStr) {
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);
        final date = DateTime(int.parse(parts[0]), month, day);
        const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
        final weekday = weekdays[date.weekday - 1];
        return '$month/$day ($weekday)';
      }
    } catch (_) {}
    return dateStr;
  }

  bool _isToday(String dateStr) {
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return dateStr == todayStr;
  }

  @override
  Widget build(BuildContext context) {
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
            Row(
              children: [
                const Text('📅', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                const Text(
                  '15일 예보',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const Spacer(),
                Text(
                  '${forecast.length}일',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 130,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: forecast.length,
                itemBuilder: (context, index) {
                  final item = forecast[index];
                  final isToday = _isToday(item.date);
                  final emoji = WeatherService.conditionToEmoji(item.condition);
                  return _ForecastItem(
                    dateLabel: isToday ? '오늘' : _formatDate(item.date),
                    emoji: emoji,
                    description: item.description,
                    tempMax: item.tempMax,
                    tempMin: item.tempMin,
                    precipProb: item.precipitationProbability,
                    isToday: isToday,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ForecastItem extends StatelessWidget {
  final String dateLabel;
  final String emoji;
  final String description;
  final double tempMax;
  final double tempMin;
  final int precipProb;
  final bool isToday;

  const _ForecastItem({
    required this.dateLabel,
    required this.emoji,
    required this.description,
    required this.tempMax,
    required this.tempMin,
    required this.precipProb,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: isToday
            ? const Color(0xFFEDE9FE)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isToday
              ? const Color(0xFFC4B5FD)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
            dateLabel,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              color: isToday
                  ? const Color(0xFF7C3AED)
                  : const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          Text(emoji, style: const TextStyle(fontSize: 22)),
          Text(
            '${tempMax.round()}°',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFFEF4444),
            ),
          ),
          Text(
            '${tempMin.round()}°',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF3B82F6),
            ),
          ),
          if (precipProb > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('💧', style: TextStyle(fontSize: 9)),
                Text(
                  '$precipProb%',
                  style: const TextStyle(
                    fontSize: 9,
                    color: Color(0xFF3B82F6),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}