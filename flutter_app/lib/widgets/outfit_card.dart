import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/weather_model.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class OutfitCard extends StatefulWidget {
  final WeatherData weather;

  const OutfitCard({super.key, required this.weather});

  @override
  State<OutfitCard> createState() => _OutfitCardState();
}

class _OutfitCardState extends State<OutfitCard> {
  String _selectedTpo = '캐주얼';
  bool _loadingAi = false;
  String _aiResult = '';
  final ApiService _api = ApiService();

  static const List<String> _tpoOptions = ['캐주얼', '출근', '데이트', '운동', '여행'];

  List<Map<String, String>> _getBaseOutfit(double temp) {
    final items = <Map<String, String>>[];
    if (temp < 5) {
      items.add({'emoji': '🧥', 'label': '패딩'});
      items.add({'emoji': '🧣', 'label': '목도리'});
      items.add({'emoji': '🧤', 'label': '장갑'});
      items.add({'emoji': '🧢', 'label': '방한 모자'});
    } else if (temp < 10) {
      items.add({'emoji': '🧥', 'label': '코트'});
      items.add({'emoji': '🧣', 'label': '목도리'});
      items.add({'emoji': '👖', 'label': '두꺼운 바지'});
    } else if (temp < 15) {
      items.add({'emoji': '🧣', 'label': '자켓'});
      items.add({'emoji': '👕', 'label': '니트'});
      items.add({'emoji': '👖', 'label': '청바지'});
    } else if (temp < 20) {
      items.add({'emoji': '👕', 'label': '긴팔 티셔츠'});
      items.add({'emoji': '👖', 'label': '면바지'});
    } else if (temp < 25) {
      items.add({'emoji': '👕', 'label': '반팔 티셔츠'});
      items.add({'emoji': '👖', 'label': '면바지'});
    } else {
      items.add({'emoji': '👕', 'label': '반팔 티셔츠'});
      items.add({'emoji': '🩳', 'label': '반바지'});
      items.add({'emoji': '👟', 'label': '샌들'});
    }
    return items;
  }

  List<Map<String, String>> _getExtraItems(WeatherData weather) {
    final extras = <Map<String, String>>[];
    final c = weather.condition.toLowerCase();
    if (c == 'rain' || c == 'drizzle') {
      extras.add({'emoji': '☂️', 'label': '우산'});
    }
    if (c == 'snow') {
      extras.add({'emoji': '🥾', 'label': '방수 부츠'});
    }
    if (weather.temperature >= 28) {
      extras.add({'emoji': '🕶️', 'label': '선글라스'});
    }
    if (weather.windSpeed >= 7) {
      extras.add({'emoji': '🧥', 'label': '바람막이'});
    }
    return extras;
  }

  Future<void> _requestAiOutfit(String? token) async {
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI 코디 추천은 로그인 후 이용 가능합니다.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _loadingAi = true;
      _aiResult = '';
    });

    try {
      final data = {
        'temperature': widget.weather.temperature,
        'condition': widget.weather.condition,
        'description': widget.weather.description,
        'humidity': widget.weather.humidity,
        'windSpeed': widget.weather.windSpeed,
        'tpo': _selectedTpo,
        'city': widget.weather.district ?? widget.weather.city,
      };

      final stream = _api.streamAiOutfit(data, token);
      await for (final chunk in stream) {
        if (mounted) {
          setState(() {
            _aiResult += chunk;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _aiResult = 'AI 추천 중 오류가 발생했습니다: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingAi = false;
        });
      }
    }
  }

  void _copyAiResult() {
    if (_aiResult.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _aiResult));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('AI 추천 내용이 복사되었습니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final temp = widget.weather.temperature;
    final baseItems = _getBaseOutfit(temp);
    final extraItems = _getExtraItems(widget.weather);

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
            // 헤더
            const Row(
              children: [
                Text('👗', style: TextStyle(fontSize: 20)),
                SizedBox(width: 8),
                Text(
                  '오늘의 코디 추천',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 온도 기반 기본 아이템
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: baseItems.map((item) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(item['emoji']!,
                          style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                      Text(
                        item['label']!,
                        style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF475569),
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            // 추가 아이템 (날씨/온도 조건)
            if (extraItems.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: extraItems.map((item) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE9FE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(item['emoji']!,
                            style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 4),
                        Text(
                          item['label']!,
                          style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF7C3AED),
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 16),
            // TPO 선택
            const Text(
              'TPO 선택',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _tpoOptions.map((tpo) {
                  final isSelected = _selectedTpo == tpo;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedTpo = tpo),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.purple
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tpo,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            // AI 추천 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loadingAi
                    ? null
                    : () => _requestAiOutfit(authProvider.token),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _loadingAi
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('✨', style: TextStyle(fontSize: 16)),
                label: Text(
                  _loadingAi
                      ? 'AI가 코디 중...'
                      : authProvider.isLoggedIn
                          ? 'AI 코디 추천 받기 ($_selectedTpo)'
                          : 'AI 코디 추천 (로그인 필요)',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            // AI 결과
            if (_aiResult.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF5FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE9D5FF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'AI 코디 추천',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF7C3AED),
                          ),
                        ),
                        GestureDetector(
                          onTap: _copyAiResult,
                          child: const Row(
                            children: [
                              Icon(Icons.copy,
                                  size: 14, color: Color(0xFF7C3AED)),
                              SizedBox(width: 3),
                              Text(
                                '복사',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF7C3AED)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _aiResult,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF374151), height: 1.6),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}