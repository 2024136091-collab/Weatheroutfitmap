import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthUser {
  final int id;
  final String email;
  final String username;

  AuthUser({required this.id, required this.email, required this.username});

  factory AuthUser.fromMap(Map<String, dynamic> map) {
    return AuthUser(
      id: (map['id'] as num?)?.toInt() ?? 0,
      email: map['email'] as String? ?? '',
      username: map['username'] as String? ?? map['name'] as String? ?? '',
    );
  }
}

class AuthProvider extends ChangeNotifier {
  AuthUser? _user;
  String? _token;
  bool _loading = false;
  String? _error;

  final ApiService _api = ApiService();

  AuthUser? get user => _user;
  String? get token => _token;
  bool get loading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _user != null && _token != null;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('token');
    final savedEmail = prefs.getString('user_email');
    final savedUsername = prefs.getString('user_username');
    final savedId = prefs.getInt('user_id');

    if (savedToken != null && savedEmail != null) {
      _token = savedToken;
      _user = AuthUser(
        id: savedId ?? 0,
        email: savedEmail,
        username: savedUsername ?? '',
      );
      notifyListeners();
    }
  }

  Future<void> _saveToPrefs(AuthUser user, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('user_email', user.email);
    await prefs.setString('user_username', user.username);
    await prefs.setInt('user_id', user.id);
  }

  Future<void> _clearPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user_email');
    await prefs.remove('user_username');
    await prefs.remove('user_id');
  }

  Future<void> login(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.login(email, password);
      _token = data['token'] as String?;
      final userMap = data['user'] as Map<String, dynamic>? ?? data;
      _user = AuthUser.fromMap(userMap);
      if (_token != null && _user != null) {
        await _saveToPrefs(_user!, _token!);
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> register(String email, String password, String username) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.register(email, password, username);
      _token = data['token'] as String?;
      final userMap = data['user'] as Map<String, dynamic>? ?? data;
      _user = AuthUser.fromMap(userMap);
      if (_token != null && _user != null) {
        await _saveToPrefs(_user!, _token!);
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> googleLogin(String accessToken) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.googleLogin(accessToken);
      _token = data['token'] as String?;
      final userMap = data['user'] as Map<String, dynamic>? ?? data;
      _user = AuthUser.fromMap(userMap);
      if (_token != null && _user != null) {
        await _saveToPrefs(_user!, _token!);
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void logout() {
    _user = null;
    _token = null;
    _error = null;
    _clearPrefs();
    notifyListeners();
  }
}