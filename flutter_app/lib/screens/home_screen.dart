import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/weather_card.dart';
import '../widgets/outfit_card.dart';
import '../widgets/living_index_card.dart';
import '../widgets/forecast_card.dart';
import '../widgets/city_grid_widget.dart';
import '../widgets/login_bottom_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showFavoriteButton = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    final query = value.trim();
    if (query.isEmpty) return;
    final weatherProvider = context.read<WeatherProvider>();
    final authProvider = context.read<AuthProvider>();
    weatherProvider.searchByCity(query, token: authProvider.token);
    _searchController.clear();
    FocusScope.of(context).unfocus();
    setState(() => _showFavoriteButton = true);
  }

  Future<void> _onGpsSearch() async {
    final weatherProvider = context.read<WeatherProvider>();
    final authProvider = context.read<AuthProvider>();
    await weatherProvider.searchByLocation(token: authProvider.token);
    if (mounted) setState(() => _showFavoriteButton = true);
  }

  void _showLoginSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const LoginBottomSheet(),
    );
  }

  void _handleLogout() {
    final authProvider = context.read<AuthProvider>();
    final weatherProvider = context.read<WeatherProvider>();
    authProvider.logout();
    weatherProvider.loadHistory(null);
    weatherProvider.loadFavorites(null);
  }

  Future<void> _toggleFavorite() async {
    final weatherProvider = context.read<WeatherProvider>();
    final authProvider = context.read<AuthProvider>();
    final weather = weatherProvider.weather;
    if (weather == null) return;

    if (!authProvider.isLoggedIn) {
      _showLoginSheet();
      return;
    }

    final cityKey =
        '${weather.city},${weather.country}';
    final displayName =
        weather.district?.isNotEmpty == true ? weather.district! : weather.city;

    if (weatherProvider.isFavorite(cityKey)) {
      final fav = weatherProvider.favorites.firstWhere(
        (f) =>
            (f['city'] as String?)?.toLowerCase() == cityKey.toLowerCase() ||
            (f['displayName'] as String?)?.toLowerCase() ==
                displayName.toLowerCase(),
        orElse: () => {},
      );
      final id = (fav['id'] as num?)?.toInt();
      if (id != null) {
        await weatherProvider.removeFavorite(id, authProvider.token);
      }
    } else {
      await weatherProvider.addFavorite(cityKey, displayName, authProvider.token);
    }
  }

  @override
  Widget build(BuildContext context) {
    final weatherProvider = context.watch<WeatherProvider>();
    final authProvider = context.watch<AuthProvider>();
    final weather = weatherProvider.weather;
    final isFav = weather != null
        ? weatherProvider.isFavorite('${weather.city},${weather.country}')
        : false;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // 헤더
            SliverToBoxAdapter(
              child: _buildHeader(authProvider),
            ),
            // 검색바
            SliverToBoxAdapter(
              child: _buildSearchBar(),
            ),
            // 로딩
            if (weatherProvider.loading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(color: Colors.purple),
                        SizedBox(height: 12),
                        Text(
                          '날씨 정보를 불러오는 중...',
                          style: TextStyle(
                              color: Color(0xFF64748B), fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            // 에러
            if (!weatherProvider.loading && weatherProvider.error != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: Color(0xFFEF4444), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            weatherProvider.error!,
                            style: const TextStyle(
                                color: Color(0xFFDC2626), fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            // 날씨 카드
            if (weather != null && !weatherProvider.loading) ...[
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    WeatherCard(
                      weather: weather,
                      isGpsLocation: weatherProvider.isGpsLocation,
                    ),
                    // 즐겨찾기 버튼
                    if (_showFavoriteButton)
                      Positioned(
                        top: 16,
                        right: 24,
                        child: GestureDetector(
                          onTap: _toggleFavorite,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              isFav ? Icons.star : Icons.star_border,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // 코디 카드
              SliverToBoxAdapter(
                child: OutfitCard(weather: weather),
              ),
              // 생활 지수 카드
              SliverToBoxAdapter(
                child: LivingIndexCard(
                  weather: weather,
                  uvIndex: weatherProvider.todayUvIndex,
                  precipProb: weatherProvider.todayPrecipProb,
                  airQuality: weatherProvider.airQuality,
                ),
              ),
              // 예보 카드
              if (weatherProvider.forecast.isNotEmpty)
                SliverToBoxAdapter(
                  child: ForecastCard(forecast: weatherProvider.forecast),
                ),
            ],
            // 도시 그리드 (날씨 없을 때도 항상 보임)
            if (!weatherProvider.loading)
              const SliverToBoxAdapter(
                child: CityGridWidget(),
              ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AuthProvider authProvider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          const Text('☁️', style: TextStyle(fontSize: 26)),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '날씨 코디',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  '오늘 날씨에 맞는 코디를 추천해드려요',
                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          if (authProvider.isLoggedIn) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  authProvider.user?.username ?? '',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151)),
                ),
                GestureDetector(
                  onTap: _handleLogout,
                  child: const Text(
                    '로그아웃',
                    style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                  ),
                ),
              ],
            ),
          ] else
            TextButton(
              onPressed: _showLoginSheet,
              style: TextButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('로그인',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onSubmitted: _onSearch,
              decoration: InputDecoration(
                hintText: '도시 이름으로 검색 (예: Seoul, 부산)',
                hintStyle: const TextStyle(
                    fontSize: 13, color: Color(0xFFCBD5E1)),
                prefixIcon: const Icon(Icons.search,
                    color: Color(0xFFCBD5E1), size: 20),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.purple),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 검색 버튼
          Material(
            color: Colors.purple,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _onSearch(_searchController.text),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.search, color: Colors.white, size: 22),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // GPS 버튼
          Material(
            color: const Color(0xFF06B6D4),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _onGpsSearch,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.my_location, color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }
}