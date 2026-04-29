import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/weather_data.dart';
import '../providers/auth_provider.dart';
import '../services/auth_api.dart' as authApi;

// ── TPO ──────────────────────────────────────────────────
const _tpoOptions = [
  ('일상/캐주얼', '캐주얼'),
  ('출근/비즈니스', '출근'),
  ('데이트/외출', '데이트'),
  ('운동/야외활동', '운동'),
];

// ── 기본 코디 계산 ─────────────────────────────────────────

class _OutfitItem {
  final String emoji;
  final String name;
  const _OutfitItem(this.emoji, this.name);
}

class _OutfitResult {
  final String title;
  final List<_OutfitItem> items;
  final List<_OutfitItem> extras;
  final String tip;
  const _OutfitResult({required this.title, required this.items, required this.extras, required this.tip});
}

_OutfitResult _getOutfit(double temp, String condition, int humidity, double windSpeed) {
  String title;
  List<_OutfitItem> items;
  String tip;

  if (temp < 5) {
    title = '매우 추운 날씨';
    items = [const _OutfitItem('🧥', '패딩'), const _OutfitItem('🧣', '목도리'), const _OutfitItem('🧤', '장갑'), const _OutfitItem('🧢', '모자')];
    tip = '두꺼운 겨울옷 필수! 레이어드로 보온하세요.';
  } else if (temp < 10) {
    title = '쌀쌀한 날씨';
    items = [const _OutfitItem('🧥', '코트'), const _OutfitItem('👕', '니트'), const _OutfitItem('👖', '두꺼운 바지'), const _OutfitItem('👟', '운동화')];
    tip = '겉옷은 필수, 레이어드가 효과적이에요.';
  } else if (temp < 15) {
    title = '선선한 날씨';
    items = [const _OutfitItem('🧥', '자켓'), const _OutfitItem('👕', '가디건'), const _OutfitItem('👕', '긴팔티'), const _OutfitItem('👖', '청바지')];
    tip = '아침저녁으로 쌀쌀하니 가벼운 겉옷을 챙기세요.';
  } else if (temp < 20) {
    title = '쾌적한 날씨';
    items = [const _OutfitItem('👕', '긴팔티'), const _OutfitItem('👕', '셔츠'), const _OutfitItem('👖', '면바지'), const _OutfitItem('👟', '스니커즈')];
    tip = '야외활동하기 딱 좋은 날씨예요!';
  } else if (temp < 25) {
    title = '따뜻한 날씨';
    items = [const _OutfitItem('👕', '반팔티'), const _OutfitItem('👕', '얇은 셔츠'), const _OutfitItem('👖', '면바지'), const _OutfitItem('👟', '스니커즈')];
    tip = '가볍고 편한 옷차림이 좋아요.';
  } else {
    title = '더운 날씨';
    items = [const _OutfitItem('👕', '반팔티'), const _OutfitItem('👖', '반바지'), const _OutfitItem('👕', '린넨셔츠'), const _OutfitItem('👡', '샌들')];
    tip = '통풍이 잘 되는 시원한 소재를 선택하세요.';
  }

  final extras = <_OutfitItem>[];
  if (['Rain', 'Drizzle', 'Thunderstorm'].contains(condition)) {
    extras.addAll([const _OutfitItem('☂️', '우산'), const _OutfitItem('🧥', '방수자켓')]);
    tip += ' 비 소식이 있으니 우산 필수!';
  }
  if (condition == 'Snow') { extras.add(const _OutfitItem('👢', '방한부츠')); tip += ' 눈길 미끄럼 조심하세요.'; }
  if (temp > 22 || (condition == 'Clear' && temp > 18)) extras.add(const _OutfitItem('🕶️', '선글라스'));
  if (windSpeed > 7) { extras.add(const _OutfitItem('🧥', '바람막이')); tip += ' 바람이 강해요.'; }
  if (humidity > 80) extras.add(const _OutfitItem('💧', '통풍의류'));

  return _OutfitResult(title: title, items: items, extras: extras, tip: tip);
}

// ── 카드 위젯 ──────────────────────────────────────────────

class OutfitCard extends StatefulWidget {
  final WeatherData weather;
  final int precipProb;
  final double uvIndex;
  final VoidCallback? onLoginRequest;

  const OutfitCard({
    super.key,
    required this.weather,
    this.precipProb = 0,
    this.uvIndex = 0,
    this.onLoginRequest,
  });

  @override
  State<OutfitCard> createState() => _OutfitCardState();
}

class _OutfitCardState extends State<OutfitCard> {
  String _selectedTpo = '일상/캐주얼';
  String _aiText = '';
  bool _aiLoading = false;
  String _aiError = '';

  Future<void> _handleAi() async {
    final auth = context.read<AuthProvider>();
    if (auth.user == null) {
      widget.onLoginRequest?.call();
      return;
    }
    setState(() { _aiText = ''; _aiError = ''; _aiLoading = true; });
    try {
      await authApi.fetchAiOutfit(
        token: auth.token!,
        city: widget.weather.city,
        temperature: widget.weather.temperature,
        feelsLike: widget.weather.feelsLike,
        condition: widget.weather.condition,
        description: widget.weather.description,
        humidity: widget.weather.humidity,
        windSpeed: widget.weather.windSpeed,
        precipProb: widget.precipProb,
        uvIndex: widget.uvIndex,
        tpo: _selectedTpo,
        onChunk: (chunk) => setState(() => _aiText += chunk),
      );
    } catch (e) {
      setState(() => _aiError = 'AI 추천을 불러올 수 없습니다. 서버 연결을 확인해 주세요.');
    } finally {
      setState(() => _aiLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final result = _getOutfit(widget.weather.temperature, widget.weather.condition, widget.weather.humidity, widget.weather.windSpeed);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('오늘의 코디', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B), letterSpacing: 0.5)),
              Text(result.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF334155))),
            ],
          ),
          const SizedBox(height: 12),

          // 기본 코디 칩
          Wrap(spacing: 8, runSpacing: 8, children: result.items.map((i) => _OutfitChip(item: i, isExtra: false)).toList()),
          if (result.extras.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: result.extras.map((i) => _OutfitChip(item: i, isExtra: true)).toList()),
          ],
          const SizedBox(height: 12),
          Text('💡 ${result.tip}', style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), height: 1.5)),

          // 구분선
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Color(0xFFF1F5F9)),
          ),

          // TPO 선택
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _tpoOptions.map((opt) {
              final selected = _selectedTpo == opt.$1;
              return GestureDetector(
                onTap: _aiLoading ? null : () => setState(() { _selectedTpo = opt.$1; _aiText = ''; _aiError = ''; }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFFF3E8FF) : const Color(0xFFF8FAFC),
                    border: Border.all(color: selected ? const Color(0xFFD8B4FE) : const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    opt.$2,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                      color: selected ? const Color(0xFF7C3AED) : const Color(0xFF64748B),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // AI 추천 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _aiLoading ? null : _handleAi,
              icon: _aiLoading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Icon(auth.user == null ? Icons.login : (_aiText.isNotEmpty ? Icons.refresh : Icons.auto_awesome), size: 16),
              label: Text(
                auth.user == null
                    ? '로그인 후 AI 코디 추천 받기'
                    : _aiLoading
                        ? 'AI가 추천 중...'
                        : _aiText.isNotEmpty
                            ? 'AI 추천 다시 받기'
                            : 'AI 코디 추천 받기',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: auth.user == null
                    ? const Color(0xFFF8FAFC)
                    : const Color(0xFF7C3AED),
                foregroundColor: auth.user == null ? const Color(0xFF94A3B8) : Colors.white,
                disabledBackgroundColor: const Color(0xFFEDE9FE),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: auth.user == null ? const Color(0xFFE2E8F0) : Colors.transparent),
                ),
              ),
            ),
          ),

          // AI 응답
          if (_aiError.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(_aiError, style: const TextStyle(fontSize: 12, color: Color(0xFFEF4444))),
            ),
          if (_aiText.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF5FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE9D5FF)),
              ),
              child: Text(
                _aiText,
                style: const TextStyle(fontSize: 13, color: Color(0xFF6D28D9), height: 1.6),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OutfitChip extends StatelessWidget {
  final _OutfitItem item;
  final bool isExtra;
  const _OutfitChip({required this.item, required this.isExtra});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isExtra ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
        border: Border.all(color: isExtra ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(item.emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(item.name, style: TextStyle(fontSize: 13, color: isExtra ? const Color(0xFF1D4ED8) : const Color(0xFF334155))),
        ],
      ),
    );
  }
}