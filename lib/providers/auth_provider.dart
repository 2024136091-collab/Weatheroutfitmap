import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_api.dart' as authApi;
import '../utils/google_web.dart' if (dart.library.io) '../utils/google_web_stub.dart';

final _googleSignIn = GoogleSignIn(
  clientId: '440354179334-1fq5m5uaqj9kin549lga5gpvd6cscvei.apps.googleusercontent.com',
  scopes: ['email', 'profile'],
);

class AuthProvider extends ChangeNotifier {
  authApi.AuthUser? user;
  String? token;
  bool loading = false;
  String? error;

  Future<void> loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final t = prefs.getString('auth_token');
    final u = prefs.getString('auth_user');
    if (t != null && u != null) {
      token = t;
      user = authApi.AuthUser.fromJson(jsonDecode(u) as Map<String, dynamic>);
      notifyListeners();
    }
  }

  Future<bool> loginWithEmail(String email, String password) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final result = await authApi.loginWithEmail(email, password);
      await _save(result.token, result.user);
      loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerWithEmail(String email, String password, String username) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final result = await authApi.registerWithEmail(email, password, username);
      await _save(result.token, result.user);
      loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithGoogle() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      if (kIsWeb) {
        // Flutter 웹: GIS OAuth2 팝업 (access token)
        final accessToken = await signInWithGoogleWeb();
        if (accessToken == null) {
          loading = false;
          notifyListeners();
          return false;
        }
        final result = await authApi.loginWithGoogleAccessToken(accessToken);
        await _save(result.token, result.user);
      } else {
        // 모바일: google_sign_in 패키지 사용
        final account = await _googleSignIn.signIn();
        if (account == null) {
          loading = false;
          notifyListeners();
          return false;
        }
        final auth = await account.authentication;
        final idToken = auth.idToken;
        final accessToken = auth.accessToken;

        late ({String token, authApi.AuthUser user}) result;
        if (idToken != null) {
          result = await authApi.loginWithGoogle(idToken);
        } else if (accessToken != null) {
          result = await authApi.loginWithGoogleAccessToken(accessToken);
        } else {
          throw Exception('구글 인증 토큰을 가져올 수 없습니다');
        }
        await _save(result.token, result.user);
      }
      loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _googleSignIn.signOut().catchError((_) {});
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_user');
    token = null;
    user = null;
    notifyListeners();
  }

  Future<void> _save(String t, authApi.AuthUser u) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', t);
    await prefs.setString('auth_user', jsonEncode(u.toJson()));
    token = t;
    user = u;
  }
}