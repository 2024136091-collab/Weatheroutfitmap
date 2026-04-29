import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

String get baseUrl {
  if (kIsWeb) return 'http://localhost:3001';
  try {
    if (Platform.isAndroid) return 'http://10.0.2.2:3001';
  } catch (_) {}
  return 'http://localhost:3001';
}

class AuthUser {
  final int id;
  final String email;
  final String username;

  const AuthUser({required this.id, required this.email, required this.username});

  factory AuthUser.fromJson(Map<String, dynamic> j) => AuthUser(
        id: j['id'] as int,
        email: j['email'] as String,
        username: j['username'] as String,
      );

  Map<String, dynamic> toJson() => {'id': id, 'email': email, 'username': username};
}

Future<({String token, AuthUser user})> loginWithEmail(String email, String password) async {
  final res = await http.post(
    Uri.parse('$baseUrl/auth/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': email, 'password': password}),
  );
  final data = jsonDecode(res.body) as Map<String, dynamic>;
  if (res.statusCode != 200) throw Exception(data['error'] ?? '로그인 실패');
  return (token: data['token'] as String, user: AuthUser.fromJson(data['user'] as Map<String, dynamic>));
}

Future<({String token, AuthUser user})> registerWithEmail(
    String email, String password, String username) async {
  final res = await http.post(
    Uri.parse('$baseUrl/auth/register'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': email, 'password': password, 'username': username}),
  );
  final data = jsonDecode(res.body) as Map<String, dynamic>;
  if (res.statusCode != 200) throw Exception(data['error'] ?? '회원가입 실패');
  return (token: data['token'] as String, user: AuthUser.fromJson(data['user'] as Map<String, dynamic>));
}

Future<({String token, AuthUser user})> loginWithGoogle(String idToken) async {
  final res = await http.post(
    Uri.parse('$baseUrl/auth/social/google'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'credential': idToken}),
  );
  final data = jsonDecode(res.body) as Map<String, dynamic>;
  if (res.statusCode != 200) throw Exception(data['error'] ?? '구글 로그인 실패');
  return (token: data['token'] as String, user: AuthUser.fromJson(data['user'] as Map<String, dynamic>));
}

Future<({String token, AuthUser user})> loginWithGoogleAccessToken(String accessToken) async {
  final res = await http.post(
    Uri.parse('$baseUrl/auth/social/google'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'accessToken': accessToken}),
  );
  final data = jsonDecode(res.body) as Map<String, dynamic>;
  if (res.statusCode != 200) throw Exception(data['error'] ?? '구글 로그인 실패');
  return (token: data['token'] as String, user: AuthUser.fromJson(data['user'] as Map<String, dynamic>));
}

Future<String> fetchAiOutfit({
  required String token,
  required String city,
  required double temperature,
  required double feelsLike,
  required String condition,
  required String description,
  required int humidity,
  required double windSpeed,
  required int precipProb,
  required double uvIndex,
  String tpo = '일상/캐주얼',
  required void Function(String chunk) onChunk,
}) async {
  final res = await http.post(
    Uri.parse('$baseUrl/api/ai/outfit'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({
      'city': city,
      'temperature': temperature,
      'feelsLike': feelsLike,
      'condition': condition,
      'description': description,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'precipProb': precipProb,
      'uvIndex': uvIndex,
      'tpo': tpo,
    }),
  );
  if (res.statusCode != 200) {
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    throw Exception(data['error'] ?? 'AI 추천 실패');
  }
  final text = res.body;
  onChunk(text);
  return text;
}