import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:async';

class ApiService {
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:3001';
    return 'http://10.0.2.2:3001';
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
    final response = await http.get(
      Uri.parse('$baseUrl/api/history'),
      headers: _headers(token),
    );
    if (response.statusCode != 200) return [];
    final data = jsonDecode(response.body);
    if (data is List) return data.cast<Map<String, dynamic>>();
    return [];
  }

  Future<void> addHistory(String city, String? token) async {
    await http.post(
      Uri.parse('$baseUrl/api/history'),
      headers: _headers(token),
      body: jsonEncode({'city': city}),
    );
  }

  Future<void> deleteHistory(String? token) async {
    await http.delete(
      Uri.parse('$baseUrl/api/history'),
      headers: _headers(token),
    );
  }

  Future<void> deleteHistoryItem(int id, String? token) async {
    await http.delete(
      Uri.parse('$baseUrl/api/history/$id'),
      headers: _headers(token),
    );
  }

  Future<List<Map<String, dynamic>>> getFavorites(String? token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/favorites'),
      headers: _headers(token),
    );
    if (response.statusCode != 200) return [];
    final data = jsonDecode(response.body);
    if (data is List) return data.cast<Map<String, dynamic>>();
    return [];
  }

  Future<void> addFavorite(
      String city, String displayName, String? token) async {
    await http.post(
      Uri.parse('$baseUrl/api/favorites'),
      headers: _headers(token),
      body: jsonEncode({'city': city, 'displayName': displayName}),
    );
  }

  Future<void> removeFavorite(int id, String? token) async {
    await http.delete(
      Uri.parse('$baseUrl/api/favorites/$id'),
      headers: _headers(token),
    );
  }

  Future<void> clearFavorites(String? token) async {
    await http.delete(
      Uri.parse('$baseUrl/api/favorites'),
      headers: _headers(token),
    );
  }

  Stream<String> streamAiOutfit({
    required String city,
    required double temperature,
    required double feelsLike,
    required String condition,
    required String description,
    required int humidity,
    required double windSpeed,
    required int precipProb,
    required double uvIndex,
  }) async* {
    final client = http.Client();
    try {
      final request = http.Request('POST', Uri.parse('$baseUrl/api/ai/outfit'));
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode({
        'city': city,
        'temperature': temperature,
        'feelsLike': feelsLike,
        'condition': condition,
        'description': description,
        'humidity': humidity,
        'windSpeed': windSpeed,
        'precipProb': precipProb,
        'uvIndex': uvIndex,
      });

      final streamedResponse = await client.send(request);
      if (streamedResponse.statusCode != 200) {
        final body = await streamedResponse.stream.bytesToString();
        throw Exception(
            jsonDecode(body)['error'] as String? ?? 'AI 추천 오류');
      }

      await for (final chunk
          in streamedResponse.stream.transform(utf8.decoder)) {
        yield chunk;
      }
    } finally {
      client.close();
    }
  }

}