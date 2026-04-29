import 'package:flutter/material.dart';
import '../models/weather_data.dart';

const _weatherGradients = <String, List<Color>>{
  'Clear':        [Color(0xFFFBBF24), Color(0xFFFB923C)],
  'Clouds':       [Color(0xFF94A3B8), Color(0xFFCBD5E1)],
  'Rain':         [Color(0xFF3B82F6), Color(0xFF22D3EE)],
  'Drizzle':      [Color(0xFF60A5FA), Color(0xFF67E8F9)],
  'Snow':         [Color(0xFF7DD3FC), Color(0xFFBAE6FD)],
  'Thunderstorm': [Color(0xFF9333EA), Color(0xFF475569)],
  'Fog':          [Color(0xFF94A3B8), Color(0xFFE2E8F0)],
};

const _weatherEmoji = <String, String>{
  'Clear': '☀️',
  'Clouds': '☁️',
  'Rain': '🌧️',
  'Drizzle': '🌦️',
  'Snow': '❄️',
  'Thunderstorm': '⛈️',
  'Fog': '🌫️',
};

class WeatherCard extends StatelessWidget {
  final WeatherData weather;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  const WeatherCard({
    super.key,
    required this.weather,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _weatherGradients[weather.condition] ?? _weatherGradients['Clouds']!;
    final emoji = _weatherEmoji[weather.condition] ?? '🌡️';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.first.withAlpha(100),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      weather.country,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      weather.city,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (weather.district != null)
                      Text(
                        weather.district!,
                        style: const TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    Text(
                      weather.description,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onToggleFavorite,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isFavorite ? Colors.white30 : Colors.white10,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isFavorite ? Icons.star : Icons.star_border,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${weather.temperature.round()}°',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 56,
                  fontWeight: FontWeight.w300,
                  height: 1,
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(emoji, style: const TextStyle(fontSize: 44)),
              ),
            ],
          ),
          Text(
            '체감 ${weather.feelsLike.round()}°C',
            style: const TextStyle(color: Colors.white60, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.only(top: 16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white24)),
            ),
            child: Row(
              children: [
                _InfoItem(icon: Icons.water_drop_outlined, label: '습도', value: '${weather.humidity}%'),
                _InfoItem(icon: Icons.air, label: '풍속', value: '${weather.windSpeed}m/s'),
                _InfoItem(icon: Icons.speed, label: '기압', value: '${weather.pressure}'),
                _InfoItem(
                  icon: Icons.visibility_outlined,
                  label: '가시',
                  value: '${(weather.visibility / 1000).toStringAsFixed(1)}km',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white60, size: 16),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}