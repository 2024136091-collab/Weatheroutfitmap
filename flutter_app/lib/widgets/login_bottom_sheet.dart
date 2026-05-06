import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../providers/auth_provider.dart';
import '../providers/weather_provider.dart';

class LoginBottomSheet extends StatefulWidget {
  const LoginBottomSheet({super.key});

  @override
  State<LoginBottomSheet> createState() => _LoginBottomSheetState();
}

class _LoginBottomSheetState extends State<LoginBottomSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMsg;
  bool _loading = false;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMsg = '이메일과 비밀번호를 입력해주세요.');
      return;
    }
    setState(() {
      _loading = true;
      _errorMsg = null;
    });
    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.login(email, password);
      if (mounted) {
        final weatherProvider = context.read<WeatherProvider>();
        await weatherProvider.loadHistory(authProvider.token);
        await weatherProvider.loadFavorites(authProvider.token);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleRegister() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final username = _usernameController.text.trim();
    if (email.isEmpty || password.isEmpty || username.isEmpty) {
      setState(() => _errorMsg = '모든 항목을 입력해주세요.');
      return;
    }
    setState(() {
      _loading = true;
      _errorMsg = null;
    });
    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.register(email, password, username);
      if (mounted) {
        final weatherProvider = context.read<WeatherProvider>();
        await weatherProvider.loadHistory(authProvider.token);
        await weatherProvider.loadFavorites(authProvider.token);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _loading = true;
      _errorMsg = null;
    });
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _loading = false);
        return;
      }
      final auth = await googleUser.authentication;
      final accessToken = auth.accessToken;
      if (accessToken == null) {
        setState(() {
          _loading = false;
          _errorMsg = 'Google 액세스 토큰을 가져올 수 없습니다.';
        });
        return;
      }
      final authProvider = context.read<AuthProvider>();
      await authProvider.googleLogin(accessToken);
      if (mounted) {
        final weatherProvider = context.read<WeatherProvider>();
        await weatherProvider.loadHistory(authProvider.token);
        await weatherProvider.loadFavorites(authProvider.token);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 드래그 핸들
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '날씨 코디',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '로그인하여 모든 기능을 이용하세요',
              style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 16),
            // 탭
            TabBar(
              controller: _tabController,
              labelColor: Colors.purple,
              unselectedLabelColor: const Color(0xFF94A3B8),
              indicatorColor: Colors.purple,
              onTap: (_) => setState(() => _errorMsg = null),
              tabs: const [
                Tab(text: '로그인'),
                Tab(text: '회원가입'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 240,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // 로그인 탭
                  _buildLoginForm(),
                  // 회원가입 탭
                  _buildRegisterForm(),
                ],
              ),
            ),
            if (_errorMsg != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Text(
                  _errorMsg!,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFFEF4444)),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const SizedBox(height: 12),
            // Google 로그인
            OutlinedButton.icon(
              onPressed: _loading ? null : _handleGoogleSignIn,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 46),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Text('G',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4285F4))),
              label: const Text(
                'Google로 계속하기',
                style: TextStyle(
                    color: Color(0xFF374151), fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        _InputField(
          controller: _emailController,
          label: '이메일',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 10),
        _InputField(
          controller: _passwordController,
          label: '비밀번호',
          obscure: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                size: 18,
                color: const Color(0xFF94A3B8)),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Text('로그인',
                    style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Column(
      children: [
        _InputField(
          controller: _usernameController,
          label: '닉네임',
        ),
        const SizedBox(height: 8),
        _InputField(
          controller: _emailController,
          label: '이메일',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 8),
        _InputField(
          controller: _passwordController,
          label: '비밀번호',
          obscure: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                size: 18,
                color: const Color(0xFF94A3B8)),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _handleRegister,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Text('회원가입',
                    style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final bool obscure;
  final Widget? suffixIcon;

  const _InputField({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.obscure = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.purple),
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }
}