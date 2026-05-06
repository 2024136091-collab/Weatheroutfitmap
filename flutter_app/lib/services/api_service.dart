import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  static String get baseUrl {
    // Android 에뮬레이터에서는 10.0.2.2, 실기기/iOS/기타에서는 localhost
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:3001';
      }
    } catch (_) {}
    return 'http://localhost:3001';
  }

  Map<String, String> _headers(String? token) {
    final h = <String, String>{'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers(null),
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception(data['error'] ?? data['message'] ?? '로그인 실패');
    }
    return data;
  }

  Future<Map<String, dynamic>> register(
      String email, String password, String username) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _headers(null),
      body: jsonEncode({'email': email, 'password': password, 'username': username}),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(data['error'] ?? data['message'] ?? '회원가입 실패');
    }
    return data;
  }

  Future<Map<String, dynamic>> googleLogin(String accessToken) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/social/google'),
      headers: _headers(null),
      body: jsonEncode({'accessToken': accessToken}),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception(data['error'] ?? data['message'] ?? 'Google 로그인 실패');
    }
    return data;
  }

  Future<List<Map<String, dynamic>>> getHistory(String? token) async {
    if (token == null || token.isEmpty) return [];
    final response = await http.get(
      Uri.parse('$baseUrl/api/history'),
      headers: _headers(token),
    );
    if (response.statusCode == 401) return [];
    if (response.statusCode != 200) return [];
    final data = jsonDecode(response.body);
    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<void> addHistory(String city, String? token) async {
    if (token == null || token.isEmpty) return;
    await http.post(
      Uri.parse('$baseUrl/api/history'),
      headers: _headers(token),
      body: jsonEncode({'city': city}),
    );
  }

  Future<void> deleteHistory(String? token) async {
    if (token == null || token.isEmpty) return;
    await http.delete(
      Uri.parse('$baseUrl/api/history'),
      headers: _headers(token),
    );
  }

  Future<void> deleteHistoryItem(int id, String? token) async {
    if (token == null || token.isEmpty) return;
    await http.delete(
      Uri.parse('$baseUrl/api/history/$id'),
      headers: _headers(token),
    );
  }

  Future<List<Map<String, dynamic>>> getFavorites(String? token) async {
    if (token == null || token.isEmpty) return [];
    final response = await http.get(
      Uri.parse('$baseUrl/api/favorites'),
      headers: _headers(token),
    );
    if (response.statusCode == 401) return [];
    if (response.statusCode != 200) return [];
    final data = jsonDecode(response.body);
    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<void> addFavorite(
      String city, String displayName, String? token) async {
    if (token == null || token.isEmpty) return;
    await http.post(
      Uri.parse('$baseUrl/api/favorites'),
      headers: _headers(token),
      body: jsonEncode({'city': city, 'displayName': displayName}),
    );
  }

  Future<void> removeFavorite(int id, String? token) async {
    if (token == null || token.isEmpty) return;
    await http.delete(
      Uri.parse('$baseUrl/api/favorites/$id'),
      headers: _headers(token),
    );
  }

  Future<void> clearFavorites(String? token) async {
    if (token == null || token.isEmpty) return;
    await http.delete(
      Uri.parse('$baseUrl/api/favorites'),
      headers: _headers(token),
    );
  }

  Stream<String> streamAiOutfit(
      Map<String, dynamic> data, String? token) async* {
    final request = http.Request(
      'POST',
      Uri.parse('$baseUrl/api/ai/outfit'),
    );
    request.headers.addAll(_headers(token));
    request.body = jsonEncode(data);

    final client = http.Client();
    try {
      final streamedResponse = await client.send(request);
      if (streamedResponse.statusCode == 401) {
        yield '로그인이 필요합니다.';
        return;
      }
      if (streamedResponse.statusCode != 200) {
        yield 'AI 추천 오류 (${streamedResponse.statusCode})';
        return;
      }
      await for (final chunk in streamedResponse.stream) {
        yield utf8.decode(chunk, allowMalformed: true);
      }
    } finally {
      client.close();
    }
  }
}