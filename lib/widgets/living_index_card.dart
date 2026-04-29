import 'package:flutter/material.dart';
import '../models/weather_data.dart';

class _IndexItem {
  final String emoji;
  final String name;
  final String label;
  final Color color;
  final Color bg;

  const _IndexItem({
    required this.emoji,
    required this.name,
    required this.label,
    required this.color,
    required this.bg,
  });
}

List<_IndexItem> _computeIndices(WeatherData weather, double uvIndex, int precipProb) {
  final uvLabel = uvIndex <= 2 ? '낮음' : uvIndex <= 5 ? '보통' : uvIndex <= 7 ? '높음' : uvIndex <= 10 ? '매우높음' : '위험';
  final uvColor = uvIndex <= 2 ? const Color(0xFF16A34A) : uvIndex <= 5 ? const Color(0xFFCA8A04) : uvIndex <= 7 ? const Color(0xFFF97316) : const Color(0xFFDC2626);
  final uvBg    = uvIndex <= 2 ? const Color(0xFFF0FDF4) : uvIndex <= 5 ? const Color(0xFFFEFCE8) : uvIndex <= 7 ? const Color(0xFFFFF7ED) : const Color(0xFFFEF2F2);

  final T = weather.temperature;
  final H = weather.humidity;
  final windSpeed = weather.windSpeed;
  final di = T - 0.55 * (1 - H / 100) * (T - 14.5);
  final diLabel = di < 68 ? '쾌적' : di < 72 ? '보통' : di < 75 ? '약간불쾌' : di < 80 ? '불쾌' : '매우불쾌';
  final diColor = di < 68 ? const Color(0xFF16A34A) : di < 72 ? const Color(0xFF2563EB) : di < 75 ? const Color(0xFFCA8A04) : di < 80 ? const Color(0xFFF97316) : const Color(0xFFDC2626);
  final diBg    = di < 68 ? const Color(0xFFF0FDF4) : di < 72 ? const Color(0xFFEFF6FF) : di < 75 ? const Color(0xFFFEFCE8) : di < 80 ? const Color(0xFFFFF7ED) : const Color(0xFFFEF2F2);

  final laundry = ((1 - precipProb / 100) * 50 + (1 - (H > 80 ? 80 : H) / 80) * 30 + ((windSpeed / 10 < 1 ? windSpeed / 10 : 1)) * 20).round();
  final laundryLabel = laundry >= 80 ? '매우좋음' : laundry >= 60 ? '좋음' : laundry >= 40 ? '보통' : laundry >= 20 ? '나쁨' : '매우나쁨';
  final laundryColor = laundry >= 60 ? const Color(0xFF16A34A) : laundry >= 40 ? const Color(0xFFCA8A04) : const Color(0xFFDC2626);
  final laundryBg    = laundry >= 60 ? const Color(0xFFF0FDF4) : laundry >= 40 ? const Color(0xFFFEFCE8) : const Color(0xFFFEF2F2);

  final tempFit = T >= 10 && T <= 25 ? (100 - (T - 18).abs() * 4).clamp(0, 100) : T > 25 ? (100 - (T - 25) * 10).clamp(0, 100) : (100 - (10 - T) * 8).clamp(0, 100);
  final humFit  = (100 - ((H - 60 > 0 ? H - 60 : 0) * 2)).clamp(0, 100);
  final exercise = (tempFit * 0.5 + humFit * 0.3 - precipProb * 0.4).clamp(0, 100).round();
  final exerciseLabel = exercise >= 80 ? '매우좋음' : exercise >= 60 ? '좋음' : exercise >= 40 ? '보통' : exercise >= 20 ? '나쁨' : '매우나쁨';
  final exerciseColor = exercise >= 60 ? const Color(0xFF16A34A) : exercise >= 40 ? const Color(0xFFCA8A04) : const Color(0xFFDC2626);
  final exerciseBg    = exercise >= 60 ? const Color(0xFFF0FDF4) : exercise >= 40 ? const Color(0xFFFEFCE8) : const Color(0xFFFEF2F2);

  final umbrellaLabel = precipProb < 20 ? '불필요' : precipProb < 50 ? '챙기기' : precipProb < 80 ? '권장' : '필수';
  final umbrellaColor = precipProb < 20 ? const Color(0xFF16A34A) : precipProb < 50 ? const Color(0xFFCA8A04) : precipProb < 80 ? const Color(0xFFF97316) : const Color(0xFFDC2626);
  final umbrellaBg    = precipProb < 20 ? const Color(0xFFF0FDF4) : precipProb < 50 ? const Color(0xFFFEFCE8) : precipProb < 80 ? const Color(0xFFFFF7ED) : const Color(0xFFFEF2F2);

  return [
    _IndexItem(emoji: '🌞', name: '자외선',   label: uvLabel,       color: uvColor,       bg: uvBg),
    _IndexItem(emoji: '🌡️', name: '불쾌지수', label: diLabel,       color: diColor,       bg: diBg),
    _IndexItem(emoji: '👕', name: '세탁',     label: laundryLabel,  color: laundryColor,  bg: laundryBg),
    _IndexItem(emoji: '🏃', name: '운동',     label: exerciseLabel, color: exerciseColor, bg: exerciseBg),
    _IndexItem(emoji: '☂️', name: '우산',     label: umbrellaLabel, color: umbrellaColor, bg: umbrellaBg),
  ];
}

class LivingIndexCard extends StatelessWidget {
  final WeatherData weather;
  final double uvIndex;
  final int precipProb;

  const LivingIndexCard({
    super.key,
    required this.weather,
    required this.uvIndex,
    required this.precipProb,
  });

  @override
  Widget build(BuildContext context) {
    final indices = _computeIndices(weather, uvIndex, precipProb);

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
          const Text(
            '생활 지수',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B), letterSpacing: 0.5),
          ),
          const SizedBox(height: 16),
          Row(
            children: indices.map((item) => Expanded(
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: item.bg, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text(item.emoji, style: const TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(height: 6),
                  Text(item.name, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)), textAlign: TextAlign.center),
                  const SizedBox(height: 2),
                  Text(item.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: item.color), textAlign: TextAlign.center),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}