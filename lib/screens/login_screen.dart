import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  bool _obscure = true;
  bool _saveEmail = false;

  static const _kSavedEmail = 'saved_email';
  static const _kSaveEmailFlag = 'save_email_flag';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {}));
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final flag = prefs.getBool(_kSaveEmailFlag) ?? false;
    if (flag) {
      final email = prefs.getString(_kSavedEmail) ?? '';
      setState(() {
        _saveEmail = true;
        _emailCtrl.text = email;
      });
    }
  }

  Future<void> _persistEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    if (_saveEmail) {
      await prefs.setString(_kSavedEmail, email);
      await prefs.setBool(_kSaveEmailFlag, true);
    } else {
      await prefs.remove(_kSavedEmail);
      await prefs.setBool(_kSaveEmailFlag, false);
    }
  }

  @override
  void dispose() {
    _tab.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _usernameCtrl.dispose();
    super.dispose();
  }

  bool get _isLogin => _tab.index == 0;

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    final email = _emailCtrl.text.trim();
    bool ok;
    if (_isLogin) {
      ok = await auth.loginWithEmail(email, _passwordCtrl.text);
    } else {
      ok = await auth.registerWithEmail(
          email, _passwordCtrl.text, _usernameCtrl.text.trim());
    }
    if (ok) {
      await _persistEmail(email);
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _handleGoogle() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.loginWithGoogle();
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF64748B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '계정',
          style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          children: [
            // 앱 아이콘 + 타이틀
            const SizedBox(height: 8),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.wb_sunny_rounded, color: Colors.white, size: 34),
            ),
            const SizedBox(height: 14),
            const Text(
              '날씨별 코디',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'AI 코디 추천을 받으려면 로그인하세요',
              style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 28),

            // 탭바 (로그인 / 회원가입)
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(3),
              child: TabBar(
                controller: _tab,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(18),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: const Color(0xFF1E293B),
                unselectedLabelColor: const Color(0xFF94A3B8),
                labelStyle: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(text: '로그인'),
                  Tab(text: '회원가입'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 에러 메시지
            if (auth.error != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  border: Border.all(color: const Color(0xFFFECACA)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Color(0xFFEF4444), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        auth.error!,
                        style: const TextStyle(
                            color: Color(0xFFDC2626), fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            // 닉네임 (회원가입만)
            if (!_isLogin) ...[
              _Field(
                controller: _usernameCtrl,
                label: '닉네임',
                hint: '사용할 닉네임을 입력하세요',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 12),
            ],

            // 이메일
            _Field(
              controller: _emailCtrl,
              label: '이메일',
              hint: 'example@email.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),

            // 비밀번호
            _Field(
              controller: _passwordCtrl,
              label: '비밀번호',
              hint: '비밀번호를 입력하세요',
              icon: Icons.lock_outline,
              obscure: _obscure,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: const Color(0xFF94A3B8),
                  size: 20,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
              onSubmitted: (_) => _submit(),
            ),
            // 아이디 저장 (로그인 탭에서만 표시)
            if (_isLogin) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: _saveEmail,
                      onChanged: (v) => setState(() => _saveEmail = v ?? false),
                      activeColor: const Color(0xFF3B82F6),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _saveEmail = !_saveEmail),
                    child: const Text(
                      '아이디 저장',
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),

            // 로그인 / 회원가입 버튼
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: auth.loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFF93C5FD),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: auth.loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(
                        _isLogin ? '로그인' : '회원가입',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // 구분선
            Row(
              children: [
                const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    '또는',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),
                const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
              ],
            ),
            const SizedBox(height: 20),

            // Google 로그인 버튼
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: auth.loading ? null : _handleGoogle,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Google G 로고
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const _GoogleLogo(),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Google로 계속하기',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
            const Text(
              '로그인 없이도 날씨 확인은 가능해요.\nAI 코디 추천은 로그인 후 이용하세요.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFFCBD5E1), height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

// 입력 필드 공통 위젯
class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.suffixIcon,
    this.keyboardType,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          textInputAction:
              onSubmitted != null ? TextInputAction.done : TextInputAction.next,
          onSubmitted: onSubmitted,
          style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
            prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              borderSide:
                  const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// Google 로고 (커스텀 페인터)
class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    // 배경 원
    final bg = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(cx, cy), r, bg);

    // G 글자 색상 아크
    final colors = [
      const Color(0xFF4285F4), // 파랑
      const Color(0xFF34A853), // 초록
      const Color(0xFFFBBC05), // 노랑
      const Color(0xFFEA4335), // 빨강
    ];
    final angles = [
      [0.0, 1.57],
      [1.57, 1.57],
      [3.14, 0.79],
      [3.93, 1.57],
    ];

    for (int i = 0; i < 4; i++) {
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.22;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.72),
        angles[i][0],
        angles[i][1],
        false,
        paint,
      );
    }

    // 중앙 흰색 덮기
    canvas.drawCircle(Offset(cx, cy), r * 0.5, bg);

    // 오른쪽 파란 바
    final bluePaint = Paint()..color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(cx, cy - size.height * 0.12, r * 0.85, size.height * 0.24),
      bluePaint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}
