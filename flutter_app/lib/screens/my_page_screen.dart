import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/weather_provider.dart';

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final weather = context.watch<WeatherProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '마이페이지',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ProfileCard(user: auth.user),
          const SizedBox(height: 16),
          _FavoritesSection(weather: weather, token: auth.token),
          const SizedBox(height: 16),
          _HistorySection(weather: weather, token: auth.token),
          const SizedBox(height: 24),
          _LogoutButton(auth: auth, weather: weather),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final AuthUser? user;
  const _ProfileCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Center(
              child: Text(
                (user?.username.isNotEmpty == true)
                    ? user!.username[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.username ?? '',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoritesSection extends StatelessWidget {
  final WeatherProvider weather;
  final String? token;
  const _FavoritesSection({required this.weather, required this.token});

  @override
  Widget build(BuildContext context) {
    final favorites = weather.favorites;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              children: [
                const Text('⭐', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    '즐겨찾기',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                if (favorites.isNotEmpty)
                  TextButton(
                    onPressed: () => weather.clearFavorites(token),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text(
                      '전체삭제',
                      style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    ),
                  ),
              ],
            ),
          ),
          if (favorites.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                '즐겨찾기한 도시가 없습니다.',
                style: TextStyle(fontSize: 13, color: Color(0xFFCBD5E1)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: favorites.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                color: Color(0xFFF1F5F9),
                indent: 16,
                endIndent: 16,
              ),
              itemBuilder: (context, index) {
                final fav = favorites[index];
                final displayName =
                    fav['displayName'] as String? ?? fav['city'] as String? ?? '';
                final id = (fav['id'] as num?)?.toInt() ?? 0;
                final favWeather =
                    weather.favoriteWeathers[fav['city'] as String? ?? ''];
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE9FE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text('⭐', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  title: Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  subtitle: favWeather != null
                      ? Text(
                          '${favWeather.temperature.round()}° · ${favWeather.description}',
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF94A3B8)),
                        )
                      : null,
                  trailing: IconButton(
                    icon: const Icon(Icons.close,
                        size: 18, color: Color(0xFFCBD5E1)),
                    onPressed: () => weather.removeFavorite(id, token),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _HistorySection extends StatelessWidget {
  final WeatherProvider weather;
  final String? token;
  const _HistorySection({required this.weather, required this.token});

  @override
  Widget build(BuildContext context) {
    final history = weather.history;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              children: [
                const Text('🕐', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    '최근 검색',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                if (history.isNotEmpty)
                  TextButton(
                    onPressed: () => weather.clearHistory(token),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text(
                      '전체삭제',
                      style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    ),
                  ),
              ],
            ),
          ),
          if (history.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                '검색 기록이 없습니다.',
                style: TextStyle(fontSize: 13, color: Color(0xFFCBD5E1)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: history.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                color: Color(0xFFF1F5F9),
                indent: 16,
                endIndent: 16,
              ),
              itemBuilder: (context, index) {
                final h = history[index];
                final city = h['city'] as String? ?? '';
                final id = (h['id'] as num?)?.toInt() ?? 0;

                String displayName;
                if (city.startsWith('GPS:')) {
                  final parts = city.split(':');
                  final place = parts.length >= 3 ? parts[2] : 'GPS 위치';
                  displayName = '$place (GPS)';
                } else {
                  displayName =
                      city.contains(',') ? city.split(',')[0] : city;
                }

                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Icon(Icons.history,
                          size: 18, color: Color(0xFF94A3B8)),
                    ),
                  ),
                  title: Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close,
                        size: 18, color: Color(0xFFCBD5E1)),
                    onPressed: () => weather.deleteHistoryItem(id, token),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final AuthProvider auth;
  final WeatherProvider weather;
  const _LogoutButton({required this.auth, required this.weather});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          auth.logout();
          await weather.loadHistory(null);
          await weather.loadFavorites(null);
          if (context.mounted) Navigator.of(context).pop();
        },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: Color(0xFFFECACA)),
          foregroundColor: const Color(0xFFEF4444),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.logout, size: 18),
        label: const Text(
          '로그아웃',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}