import 'package:flutter/material.dart';
import '../models/weather_model.dart';
import '../services/api_service.dart';

class AiOutfitCard extends StatefulWidget {
  final WeatherData weather;
  final int precipProb;
  final double uvIndex;
  final bool isLoggedIn;
  final VoidCallback onLoginTap;

  const AiOutfitCard({
    super.key,
    required this.weather,
    required this.precipProb,
    required this.uvIndex,
    required this.isLoggedIn,
    required this.onLoginTap,
  });

  @override
  State<AiOutfitCard> createState() => _AiOutfitCardState();
}

class _AiOutfitCardState extends State<AiOutfitCard> {
  final ApiService _api = ApiService();
  String _text = '';
  bool _loading = false;
  bool _done = false;
  String? _error;

  Future<void> _fetchRecommendation() async {
    setState(() {
      _loading = true;
      _done = false;
      _text = '';
      _error = null;
    });

    try {
      final stream = _api.streamAiOutfit(
        city: widget.weather.city,
        temperature: widget.weather.temperature,
        feelsLike: widget.weather.feelsLike,
        condition: widget.weather.condition,
        description: widget.weather.description,
        humidity: widget.weather.humidity,
        windSpeed: widget.weather.windSpeed,
        precipProb: widget.precipProb,
        uvIndex: widget.uvIndex,
      );

      await for (final chunk in stream) {
        if (!mounted) return;
        setState(() => _text += chunk);
      }

      if (mounted) setState(() => _done = true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _done = false;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _reset() {
    setState(() {
      _text = '';
      _done = false;
      _error = null;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('✨', style: TextStyle(fontSize: 12)),
                      SizedBox(width: 4),
                      Text(
                        'AI 코디 추천',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (_done)
                  GestureDetector(
                    onTap: _reset,
                    child: const Text(
                      '다시 추천받기',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8B5CF6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // 콘텐츠
            if (!widget.isLoggedIn)
              _LockedState(onLoginTap: widget.onLoginTap)
            else if (_error != null)
              _ErrorState(message: _error!, onRetry: _fetchRecommendation)
            else if (!_loading && !_done && _text.isEmpty)
              _IdleState(onTap: _fetchRecommendation)
            else
              _ResponseState(
                text: _text,
                isLoading: _loading,
              ),
          ],
        ),
      ),
    );
  }
}

class _IdleState extends StatelessWidget {
  final VoidCallback onTap;
  const _IdleState({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8B5CF6),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        icon: const Text('🤖', style: TextStyle(fontSize: 16)),
        label: const Text(
          'AI에게 코디 추천받기',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
    );
  }
}

class _LockedState extends StatelessWidget {
  final VoidCallback onLoginTap;
  const _LockedState({required this.onLoginTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Text('🔒', style: TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          const Text(
            '로그인 후 AI 코디 추천을 받을 수 있어요',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onLoginTap,
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 9),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('로그인하기',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _ResponseState extends StatelessWidget {
  final String text;
  final bool isLoading;
  const _ResponseState({required this.text, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (text.isNotEmpty)
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1E293B),
              height: 1.7,
            ),
          ),
        if (isLoading) ...[
          if (text.isNotEmpty) const SizedBox(height: 8),
          const Row(
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  color: Color(0xFF8B5CF6),
                  strokeWidth: 2,
                ),
              ),
              SizedBox(width: 8),
              Text(
                'AI가 추천 중...',
                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFECACA)),
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline,
                  color: Color(0xFFEF4444), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFFDC2626)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('다시 시도'),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF8B5CF6),
          ),
        ),
      ],
    );
  }
}