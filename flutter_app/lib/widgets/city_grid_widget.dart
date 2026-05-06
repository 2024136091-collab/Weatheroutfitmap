import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../providers/auth_provider.dart';

class CityGridWidget extends StatelessWidget {
  const CityGridWidget({super.key});

  static const List<Map<String, String>> _majorCities = [
    {'city': 'Seoul,KR', 'name': '서울'},
    {'city': 'Busan,KR', 'name': '부산'},
    {'city': 'Incheon,KR', 'name': '인천'},
    {'city': 'Daegu,KR', 'name': '대구'},
    {'city': 'Daejeon,KR', 'name': '대전'},
    {'city': 'Gwangju,KR', 'name': '광주'},
    {'city': 'Suwon,KR', 'name': '수원'},
    {'city': 'Ulsan,KR', 'name': '울산'},
    {'city': 'Changwon,KR', 'name': '창원'},
    {'city': 'Goyang,KR', 'name': '고양'},
    {'city': 'Yongin,KR', 'name': '용인'},
    {'city': 'Seongnam,KR', 'name': '성남'},
  ];

  void _searchCity(BuildContext context, String city) {
    final wp = context.read<WeatherProvider>();
    final ap = context.read<AuthProvider>();
    wp.searchByCity(city, token: ap.token);
  }

  @override
  Widget build(BuildContext context) {
    final weatherProvider = context.watch<WeatherProvider>();
    final authProvider = context.watch<AuthProvider>();
    final favorites = weatherProvider.favorites;
    final history = weatherProvider.history;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 즐겨찾기 섹션
        if (favorites.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Text('⭐', style: TextStyle(fontSize: 16)),
                    SizedBox(width: 6),
                    Text(
                      '즐겨찾기',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => weatherProvider.clearFavorites(authProvider.token),
                  child: const Text(
                    '전체삭제',
                    style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 2.2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final fav = favorites[index];
                final displayName = fav['displayName'] as String? ??
                    fav['city'] as String? ?? '';
                final city = fav['city'] as String? ?? '';
                final id = (fav['id'] as num?)?.toInt() ?? 0;
                return GestureDetector(
                  onTap: () => _searchCity(context, city),
                  onLongPress: () => weatherProvider.removeFavorite(
                      id, authProvider.token),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        // 최근 검색 섹션
        if (history.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Text('🕐', style: TextStyle(fontSize: 16)),
                    SizedBox(width: 6),
                    Text(
                      '최근 검색',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () =>
                      weatherProvider.clearHistory(authProvider.token),
                  child: const Text(
                    '전체삭제',
                    style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: history.take(10).map((h) {
                final city = h['city'] as String? ?? '';
                final id = (h['id'] as num?)?.toInt() ?? 0;
                // GPS 기록은 "GPS:lat,lon:cityName" 형식
                String displayName;
                String searchCity;
                if (city.startsWith('GPS:')) {
                  final parts = city.split(':');
                  displayName = parts.length >= 3 ? parts[2] : 'GPS 위치';
                  searchCity = city;
                } else {
                  displayName = city.contains(',')
                      ? city.split(',')[0]
                      : city;
                  searchCity = city;
                }
                return GestureDetector(
                  onTap: () {
                    if (searchCity.startsWith('GPS:')) {
                      // GPS 기록은 도시명으로 재검색
                      final parts = searchCity.split(':');
                      final cityName =
                          parts.length >= 3 ? parts[2] : displayName;
                      weatherProvider.searchByCity(cityName,
                          token: authProvider.token);
                    } else {
                      weatherProvider.searchByCity(searchCity,
                          token: authProvider.token);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.history,
                            size: 13, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 4),
                        Text(
                          displayName,
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFF475569)),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => weatherProvider.deleteHistoryItem(
                              id, authProvider.token),
                          child: const Icon(Icons.close,
                              size: 13, color: Color(0xFFCBD5E1)),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
        // 주요 도시 섹션
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Text('🏙️', style: TextStyle(fontSize: 16)),
              SizedBox(width: 6),
              Text(
                '주요 도시',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 2.0,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _majorCities.length,
            itemBuilder: (context, index) {
              final cityData = _majorCities[index];
              final isFav = weatherProvider
                  .isFavorite(cityData['city']!);
              return GestureDetector(
                onTap: () =>
                    _searchCity(context, cityData['city']!),
                child: Container(
                  decoration: BoxDecoration(
                    color: isFav
                        ? const Color(0xFFEDE9FE)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isFav
                          ? const Color(0xFFC4B5FD)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      cityData['name']!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isFav
                            ? const Color(0xFF7C3AED)
                            : const Color(0xFF374151),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}