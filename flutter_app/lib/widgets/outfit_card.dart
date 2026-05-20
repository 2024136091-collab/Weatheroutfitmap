import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/weather_model.dart';

class OutfitCard extends StatefulWidget {
  final WeatherData weather;
  final int precipProb;
  final int uvIndex;
  final AirQuality? airQuality;

  const OutfitCard({
    super.key,
    required this.weather,
    this.precipProb = 0,
    this.uvIndex = 0,
    this.airQuality,
  });

  @override
  State<OutfitCard> createState() => _OutfitCardState();
}

class _OutfitCardState extends State<OutfitCard> {
  String _selectedTpo = '캐주얼';
  String _result = '';

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
    if (c == 'rain' || c == 'drizzle' || c == 'thunderstorm' || widget.precipProb >= 60) {
      extras.add({'emoji': '☂️', 'label': '우산'});
    }
    if (c == 'snow') {
      extras.add({'emoji': '🥾', 'label': '방수 부츠'});
    }
    if (c == 'clear' && widget.uvIndex >= 6) {
      extras.add({'emoji': '🕶️', 'label': '선글라스'});
    }
    if (weather.windSpeed >= 7) {
      extras.add({'emoji': '🧥', 'label': '바람막이'});
    }
    final pm25 = widget.airQuality?.pm25;
    if (pm25 != null && pm25 > 35) {
      extras.add({'emoji': '😷', 'label': '마스크'});
    }
    return extras;
  }

  String _generateRecommendation() {
    final w = widget.weather;
    final temp = w.temperature.round();
    final feels = w.feelsLike.round();
    final c = w.condition.toLowerCase();
    final isRainy = c == 'rain' || c == 'drizzle' || c == 'thunderstorm';
    final isSnowy = c == 'snow';
    final isClear = c == 'clear';
    final isWindy = w.windSpeed >= 7;
    final isHumid = w.humidity > 75;
    final pm25 = widget.airQuality?.pm25;

    // 날씨 요약
    final feelsDiff = (temp - feels).abs() >= 3 ? ' (체감 $feels°C)' : '';
    var summary = '오늘 ${w.city}은(는) 기온 $temp°C$feelsDiff에 ${w.description}입니다.';
    if (isRainy && widget.precipProb > 0) summary += ' 강수확률 ${widget.precipProb}%.';

    // TPO별 코디
    final Map<String, List<String>> tpoOutfit = {
      '캐주얼': _casualOutfit(temp, isRainy),
      '출근':   _workOutfit(temp),
      '데이트': _dateOutfit(temp, isRainy, isClear),
      '운동':   _sportOutfit(temp),
      '여행':   _travelOutfit(temp),
    };
    final outfit = tpoOutfit[_selectedTpo] ?? _casualOutfit(temp, isRainy);
    final outfitLine = '추천 코디: ${outfit.join(' → ')}';

    // 추가 경고
    final addons = <String>[];
    if (isRainy || widget.precipProb >= 60) addons.add('우산·방수 자켓 필수');
    if (isSnowy) addons.add('방한부츠 착용 권장');
    if (isWindy) addons.add('바람막이 추가');
    if (isClear && widget.uvIndex >= 6) addons.add('선글라스·자외선차단제 챙기기');
    else if (widget.uvIndex >= 3) addons.add('자외선차단제 권장');
    if (pm25 != null && pm25 > 75) addons.add('미세먼지 매우나쁨 — 마스크 필수');
    else if (pm25 != null && pm25 > 35) addons.add('미세먼지 나쁨 — 마스크 권장');

    // TPO 팁
    final String tip;
    switch (_selectedTpo) {
      case '캐주얼':
        tip = temp < 15
            ? '포인트 팁: 레이어드로 온도 변화에 유연하게 대응하세요.'
            : isHumid
                ? '포인트 팁: 땀 흡수 잘 되는 면 소재를 선택하면 쾌적해요.'
                : '포인트 팁: 편안함에 포인트 아이템 하나만 더하면 완성!';
      case '출근':
        tip = '포인트 팁: 네이비·그레이 색상 조합이 무난하고 깔끔해 보여요.';
      case '데이트':
        tip = isClear
            ? '포인트 팁: 밝고 화사한 색상으로 설레는 분위기를 연출해 보세요!'
            : isRainy
                ? '포인트 팁: 비 오는 날엔 컬러풀한 우산으로 포인트를 주세요.'
                : '포인트 팁: 향수 하나 추가하면 특별한 인상을 남길 수 있어요.';
      case '운동':
        tip = temp >= 20
            ? '포인트 팁: 수분 보충 자주 해주시고 자외선 차단도 잊지 마세요.'
            : '포인트 팁: 체온이 오르면 겉옷을 벗어 온도를 조절하세요.';
      case '여행':
        tip = '포인트 팁: 걷기 편한 신발이 최우선! 레이어드로 짐을 줄이세요.';
      default:
        tip = '';
    }

    final parts = [summary, outfitLine];
    if (addons.isNotEmpty) parts.add(addons.join(', '));
    parts.add(tip);
    return parts.join('\n');
  }

  List<String> _casualOutfit(int temp, bool rainy) {
    if (temp < 5)  return ['두꺼운 패딩', '기모 슬랙스', '워커'];
    if (temp < 10) return ['울 코트', '니트', '청바지', '두꺼운 스니커즈'];
    if (temp < 15) return ['가벼운 자켓', '긴팔티', '슬림 청바지', '운동화'];
    if (temp < 20) return ['오버핏 셔츠', '슬랙스', '로퍼·스니커즈'];
    if (temp < 25) return ['면 반팔티', '와이드 팬츠', '스니커즈'];
    return ['린넨 반팔티', '반바지·라이트 팬츠', '샌들'];
  }

  List<String> _workOutfit(int temp) {
    if (temp < 5)  return ['울 코트', '정장 셔츠', '슬랙스', '구두'];
    if (temp < 10) return ['트렌치코트', '니트', '슬랙스', '구두'];
    if (temp < 15) return ['블레이저', '셔츠', '슬랙스', '로퍼'];
    if (temp < 20) return ['가벼운 자켓', '버튼다운 셔츠', '슬랙스', '로퍼'];
    if (temp < 25) return ['셔츠', '치노 팬츠', '더비슈즈'];
    return ['통풍 잘 되는 셔츠', '라이트 슬랙스', '로퍼'];
  }

  List<String> _dateOutfit(int temp, bool rainy, bool clear) {
    if (temp < 5)  return ['롱패딩', '터틀넥 니트', '스키니진', '첼시부츠'];
    if (temp < 10) return ['코트', '밝은 색 니트', '스트레이트 데님', '첼시부츠'];
    if (temp < 15) return ['트렌치코트', '스트라이프 셔츠', '슬림 팬츠', '화이트 스니커즈'];
    if (temp < 20) return ['가디건', '파스텔 반팔', '와이드 팬츠', '스니커즈'];
    if (temp < 25) return ['플로럴 원피스·반팔 셔츠', '숏팬츠', '스니커즈·샌들'];
    return ['시원한 소재 원피스·블라우스', '숏팬츠', '샌들'];
  }

  List<String> _sportOutfit(int temp) {
    if (temp < 5)  return ['방한 기능성 상의', '기모 운동복', '등산화'];
    if (temp < 10) return ['운동용 집업', '긴팔 기능성', '조거팬츠', '러닝화'];
    if (temp < 15) return ['바람막이', '반팔 기능성', '트레이닝 팬츠', '러닝화'];
    if (temp < 20) return ['반팔 기능성', '조거팬츠', '러닝화'];
    if (temp < 25) return ['드라이핏 반팔', '반바지', '러닝화'];
    return ['통풍 기능성 반팔', '러닝 반바지', '가벼운 러닝화'];
  }

  List<String> _travelOutfit(int temp) {
    if (temp < 5)  return ['경량 패딩', '후드티', '기능성 팬츠', '워커'];
    if (temp < 10) return ['코트·경량 패딩', '니트', '편한 팬츠', '워킹화'];
    if (temp < 15) return ['바람막이', '기본 긴팔', '편한 팬츠', '스니커즈'];
    if (temp < 20) return ['가벼운 자켓', '반팔', '편한 팬츠', '스니커즈'];
    if (temp < 25) return ['반팔', '편한 팬츠·원피스', '스니커즈·샌들'];
    return ['시원한 반팔', '반바지·가벼운 원피스', '샌들·슬리퍼'];
  }

  void _onRecommend() {
    setState(() => _result = _generateRecommendation());
  }

  void _copyResult() {
    if (_result.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _result));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('코디 추천 내용이 복사되었습니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            // 코디 추천 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _onRecommend,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Text('✨', style: TextStyle(fontSize: 16)),
                label: Text(
                  _result.isEmpty
                      ? '코디 추천 받기 ($_selectedTpo)'
                      : '다시 추천 받기 ($_selectedTpo)',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            // 추천 결과
            if (_result.isNotEmpty) ...[
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
                          '코디 추천',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF7C3AED),
                          ),
                        ),
                        GestureDetector(
                          onTap: _copyResult,
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
                      _result,
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