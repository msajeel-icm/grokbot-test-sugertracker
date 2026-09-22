import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../state/key_value_store.dart';
import 'models.dart';
import 'sugar_api.dart';

class HttpSugarApi implements SugarApi {
  HttpSugarApi({
    required this.baseUrl,
    required this.store,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final KeyValueStore store;
  final http.Client _client;

  static const _tokenKey = 'access_token';

  String get _root {
    final trimmed = baseUrl.trim();
    return trimmed.endsWith('/') ? trimmed.substring(0, trimmed.length - 1) : trimmed;
  }

  Uri _uri(String path) => Uri.parse('$_root$path');

  @override
  Future<UserProfile?> restore() async {
    final token = store.read(_tokenKey);
    if (token == null || token.isEmpty) return null;
    try {
      return await me();
    } on ApiException {
      await store.delete(_tokenKey);
      return null;
    }
  }

  @override
  Future<UserProfile> login(String email, String password) async {
    final body = await _decode(
      await _send(
        http.Request('POST', _uri('/api/v1/auth/login'))
          ..headers['Content-Type'] = 'application/json'
          ..body = jsonEncode({'email': email, 'password': password}),
      ),
    );
    final token = body['access_token'] as String?;
    if (token == null || token.isEmpty) {
      throw ApiException('Sign-in did not return a token.');
    }
    await store.write(_tokenKey, token);
    return UserProfile.fromJson(body['user'] as Map<String, dynamic>);
  }

  @override
  Future<void> logout() => store.delete(_tokenKey);

  @override
  Future<UserProfile> me() async {
    final body = await _decode(await _send(_authed(http.Request('GET', _uri('/api/v1/me')))));
    return UserProfile.fromJson(body);
  }

  @override
  Future<UserProfile> updateLimit(double dailySugarLimitG) async {
    final request = _authed(http.Request('PATCH', _uri('/api/v1/me')))
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode({'daily_sugar_limit_g': dailySugarLimitG});
    final body = await _decode(await _send(request));
    return UserProfile.fromJson(body);
  }

  @override
  Future<Dashboard> dashboard() async {
    final body = await _decode(await _send(_authed(http.Request('GET', _uri('/api/v1/dashboard')))));
    return Dashboard.fromJson(body);
  }

  @override
  Future<AnalyzeResult> analyze({String? hint, List<int>? image, String? imageName}) async {
    final cleaned = hint?.trim();
    final http.Request request;
    if (image != null && image.isNotEmpty) {
      final multipart = http.MultipartRequest('POST', _uri('/api/v1/meals/analyze'));
      final token = store.read(_tokenKey);
      if (token != null) multipart.headers['Authorization'] = 'Bearer $token';
      if (cleaned != null && cleaned.isNotEmpty) multipart.fields['hint'] = cleaned;
      multipart.files.add(
        http.MultipartFile.fromBytes('image', image, filename: imageName ?? 'meal.jpg'),
      );
      final streamed = await _send(multipart);
      return AnalyzeResult.fromJson(await _decode(streamed));
    }
    request = _authed(http.Request('POST', _uri('/api/v1/meals/analyze')))
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode({
        if (cleaned != null && cleaned.isNotEmpty) 'hint': cleaned,
      });
    return AnalyzeResult.fromJson(await _decode(await _send(request)));
  }

  @override
  Future<Meal> logMeal({
    required String label,
    required double sugarG,
    required double kcal,
    String? photoRef,
  }) async {
    final request = _authed(http.Request('POST', _uri('/api/v1/meals')))
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode({
        'label': label,
        'sugar_g': sugarG,
        'kcal': kcal,
        if (photoRef != null && photoRef.isNotEmpty) 'photo_ref': photoRef,
      });
    return Meal.fromJson(await _decode(await _send(request)));
  }

  http.Request _authed(http.Request request) {
    final token = store.read(_tokenKey);
    if (token == null || token.isEmpty) {
      throw ApiException('Sign in again.', statusCode: 401);
    }
    request.headers['Authorization'] = 'Bearer $token';
    return request;
  }

  Future<http.Response> _send(http.BaseRequest request) async {
    try {
      final streamed = await _client.send(request).timeout(const Duration(seconds: 20));
      return await http.Response.fromStream(streamed);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException('The server took too long to respond.');
    } catch (_) {
      throw ApiException("Can't reach the server.");
    }
  }

  Future<Map<String, dynamic>> _decode(http.Response response) async {
    Map<String, dynamic>? body;
    if (response.body.isNotEmpty) {
      final raw = jsonDecode(response.body);
      if (raw is Map<String, dynamic>) body = raw;
    }
    if (response.statusCode >= 400) {
      throw ApiException(_errorMessage(response.statusCode, body), statusCode: response.statusCode);
    }
    return body ?? <String, dynamic>{};
  }

  String _errorMessage(int status, Map<String, dynamic>? body) {
    final detail = body?['detail'];
    if (detail is String && detail.isNotEmpty) return detail;
    if (status == 401) return 'Those credentials did not match.';
    if (status == 422) return 'Check the values and try again.';
    return 'Something went wrong ($status).';
  }
}
