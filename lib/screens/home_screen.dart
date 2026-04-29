import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/weather_provider.dart';
import '../providers/storage_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/weather_card.dart';
import '../widgets/outfit_card.dart';
import '../widgets/living_index_card.dart';
import '../widgets/forecast_card.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  bool _showHistory = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StorageProvider>().load();
      context.read<WeatherProvider>().search('Seoul,KR');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleSearch(String city) async {
    if (city.trim().isEmpty) return;
    _searchController.clear();
    setState(() => _showHistory = false);
    FocusScope.of(context).unfocus();
    final wp = context.read<WeatherProvider>();
    final result = await wp.search(city.trim());
    if (!mounted) return;
    if (result != null) {
      context.read<StorageProvider>().saveHistory('${result.city},${result.country == '대한민국' ? 'KR' : result.country}');
    }
  }

  Future<void> _handleLocate() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnack('위치 서비스가 비활성화되어 있습니다.');
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnack('위치 권한이 거부되었습���다.');
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      _showSnack('위치 권한이 영구 거부되었습니다. 설정에서 허용해 주세요.');
      return;
    }
    final pos = await Geolocator.getCurrentPosition();
    if (!mounted) return;
    context.read<WeatherProvider>().searchByCoords(pos.latitude, pos.longitude);
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _openLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wp = context.watch<WeatherProvider>();
    final sp = context.watch<StorageProvider>();
    final auth = context.watch<AuthProvider>();

    final currentCityKey = wp.weather != null
        ? '${wp.weather!.city},${wp.weather!.country == '대한민국' ? 'KR' : wp.weather!.country}'
        : '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 헤더
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '날씨별 코디',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              Text(
                                '오늘 날씨에 맞는 옷차림을 추천해드려요',
                                style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 로그인 버튼 / 유저 정보
                        if (auth.user != null)
                          _UserChip(
                            username: auth.user!.username,
                            onLogout: () => auth.logout(),
                            onSwitchAccount: () async {
                              await auth.logout();
                              if (mounted) _openLogin();
                            },
                          )
                        else
                          _LoginButton(onTap: _openLogin),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 검색바
                    _SearchBar(
                      controller: _searchController,
                      loading: wp.loading,
                      onSearch: _handleSearch,
                      onLocate: _handleLocate,
                      onChanged: (v) => setState(() => _showHistory = v.isEmpty),
                      onTap: () => setState(() => _showHistory = true),
                    ),

                    // 검색 기록 드롭다운
                    if (_showHistory && sp.history.isNotEmpty)
                      _HistoryDropdown(
                        history: sp.history,
                        favorites: sp.favorites.map((f) => f.city).toList(),
                        onSelect: _handleSearch,
                        onDelete: (city) => sp.deleteHistoryOne(city),
                      ),

                    const SizedBox(height: 12),

                    // 즐겨찾기 태그
                    if (sp.favorites.isNotEmpty)
                      SizedBox(
                        height: 36,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: sp.favorites.length,
                          separatorBuilder: (context, index) => const SizedBox(width: 8),
                          itemBuilder: (_, i) {
                            final fav = sp.favorites[i];
                            return GestureDetector(
                              onTap: () => _handleSearch(fav.city),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star, color: Color(0xFFFBBF24), size: 14),
                                    const SizedBox(width: 4),
                                    Text(fav.displayName, style: const TextStyle(fontSize: 13, color: Color(0xFF334155))),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // 로딩
            if (wp.loading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
                ),
              ),

            // 에러
            if (!wp.loading && wp.error != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      border: Border.all(color: const Color(0xFFFECACA)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(wp.error!, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // 날씨 카드들
            if (!wp.loading && wp.error == null && wp.weather != null)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    WeatherCard(
                      weather: wp.weather!,
                      isFavorite: sp.isFavorite(currentCityKey),
                      onToggleFavorite: () => sp.toggleFavorite(currentCityKey, wp.weather!.city),
                    ),
                    const SizedBox(height: 12),
                    OutfitCard(
                      weather: wp.weather!,
                      precipProb: wp.todayPrecipProb,
                      uvIndex: wp.todayUvIndex,
                      onLoginRequest: _openLogin,
                    ),
                    const SizedBox(height: 12),
                    LivingIndexCard(
                      weather: wp.weather!,
                      uvIndex: wp.todayUvIndex,
                      precipProb: wp.todayPrecipProb,
                    ),
                    const SizedBox(height: 12),
                    ForecastCard(forecast: wp.forecast),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final bool loading;
  final ValueChanged<String> onSearch;
  final VoidCallback onLocate;
  final ValueChanged<String> onChanged;
  final VoidCallback onTap;

  const _SearchBar({
    required this.controller,
    required this.loading,
    required this.onSearch,
    required this.onLocate,
    required this.onChanged,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onTap: onTap,
              onChanged: onChanged,
              onSubmitted: onSearch,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: '도시 이름 검색 (예: 서울, 부산)',
                hintStyle: TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
                prefixIcon: Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (loading)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            IconButton(
              onPressed: onLocate,
              icon: const Icon(Icons.my_location, color: Color(0xFF64748B), size: 20),
              tooltip: '현재 위치',
            ),
        ],
      ),
    );
  }
}

class _HistoryDropdown extends StatelessWidget {
  final List<String> history;
  final List<String> favorites;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onDelete;

  const _HistoryDropdown({
    required this.history,
    required this.favorites,
    required this.onSelect,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: history.map((city) {
          final isFav = favorites.contains(city);
          return ListTile(
            dense: true,
            leading: Icon(
              isFav ? Icons.star : Icons.history,
              size: 16,
              color: isFav ? const Color(0xFFFBBF24) : const Color(0xFF94A3B8),
            ),
            title: Text(city, style: const TextStyle(fontSize: 14)),
            trailing: IconButton(
              icon: const Icon(Icons.close, size: 14, color: Color(0xFF94A3B8)),
              onPressed: () => onDelete(city),
            ),
            onTap: () => onSelect(city),
          );
        }).toList(),
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LoginButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF3B82F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.login, color: Colors.white, size: 15),
            SizedBox(width: 5),
            Text(
              '로그인',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserChip extends StatelessWidget {
  final String username;
  final VoidCallback onLogout;
  final VoidCallback onSwitchAccount;
  const _UserChip({required this.username, required this.onLogout, required this.onSwitchAccount});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFFEFF6FF),
                  child: Text(
                    username.isNotEmpty ? username[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  username,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onSwitchAccount();
                    },
                    icon: const Icon(Icons.swap_horiz, size: 18),
                    label: const Text('계정 전환'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF3B82F6),
                      side: const BorderSide(color: Color(0xFFBFDBFE)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onLogout();
                    },
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('로그아웃'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0xFFFECACA)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 9,
              backgroundColor: const Color(0xFF3B82F6),
              child: Text(
                username.isNotEmpty ? username[0].toUpperCase() : '?',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              username,
              style: const TextStyle(
                  color: Color(0xFF1D4ED8),
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}