import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'api_exception.dart';
import 'models.dart';
import 'sugar_api.dart';

/// JSON and multipart client for the FastAPI backend.
class ApiClient implements SugarApi {
  ApiClient({required String baseUrl, http.Client? httpClient, this.token})
    : baseUrl = normalizeBaseUrl(baseUrl),
      _http = httpClient ?? http.Client();

  static const _timeout = Duration(seconds: 20);
  static const _maxImageBytes = 8 * 1024 * 1024;
  static const _unreachable =
      'Cannot reach the API. Start the backend and check the API URL.';

  final String baseUrl;
  final http.Client _http;

  @override
  String? token;

  @override
  Future<AuthSession> login({required String email, required String password}) {
    return _auth('/api/v1/auth/login', email: email, password: password);
  }

  @override
  Future<AuthSession> register({
    required String email,
    required String password,
  }) {
    return _auth('/api/v1/auth/register', email: email, password: password);
  }

  Future<AuthSession> _auth(
    String path, {
    required String email,
    required String password,
  }) async {
    final body = await _json(
      'POST',
      path,
      jsonBody: {'email': email, 'password': password},
      authenticated: false,
    );
    return _parse(() => AuthSession.fromJson(body));
  }

  @override
  Future<UserProfile> getMe() async {
    final body = await _json('GET', '/api/v1/me');
    return _parse(() => UserProfile.fromJson(body));
  }

  @override
  Future<UserProfile> updateMe({
    double? dailySugarLimitG,
    String? timezone,
  }) async {
    final payload = <String, dynamic>{};
    if (dailySugarLimitG != null) {
      payload['daily_sugar_limit_g'] = dailySugarLimitG;
    }
    if (timezone != null) payload['timezone'] = timezone;
    final body = await _json('PATCH', '/api/v1/me', jsonBody: payload);
    return _parse(() => UserProfile.fromJson(body));
  }

  @override
  Future<AnalyzeResult> analyzeMeal({String? hint, MealPhoto? photo}) async {
    final cleaned = hint?.trim();
    final hasHint = cleaned != null && cleaned.isNotEmpty;
    if (!hasHint && photo == null) {
      throw ApiException(message: 'Add a photo or describe the meal.');
    }
    if (photo != null && photo.bytes.length > _maxImageBytes) {
      throw ApiException(message: 'That photo is larger than 8 MB.');
    }
    if (photo == null) {
      final body = await _json(
        'POST',
        '/api/v1/meals/analyze',
        jsonBody: {'hint': cleaned!},
      );
      return _parse(() => AnalyzeResult.fromJson(body));
    }

    final request = http.MultipartRequest(
      'POST',
      _uri('/api/v1/meals/analyze'),
    );
    request.headers.addAll(_headers(json: false));
    if (cleaned != null && cleaned.isNotEmpty) {
      request.fields['hint'] = cleaned;
    }
    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        photo.bytes,
        filename: photo.filename.trim().isEmpty ? 'meal.jpg' : photo.filename,
      ),
    );
    final streamed = await _send(() => _http.send(request));
    final response = await http.Response.fromStream(streamed);
    final decoded = _decode(response);
    return _parse(() => AnalyzeResult.fromJson(_asMap(decoded)));
  }

  @override
  Future<Meal> logMeal({
    required double sugarG,
    required String label,
    String? localDate,
    String? photoRef,
    String? notes,
  }) async {
    final payload = <String, dynamic>{'sugar_g': sugarG, 'label': label};
    if (localDate != null && localDate.isNotEmpty) {
      payload['local_date'] = localDate;
    }
    if (photoRef != null && photoRef.isNotEmpty) {
      payload['photo_ref'] = photoRef;
    }
    if (notes != null && notes.isNotEmpty) {
      payload['notes'] = notes;
    }
    final body = await _json('POST', '/api/v1/meals', jsonBody: payload);
    return _parse(() => Meal.fromJson(body));
  }

  @override
  Future<List<Meal>> mealsOn(String date) async {
    final decoded = await _request(
      'GET',
      '/api/v1/meals',
      query: {'date': date},
    );
    if (decoded is! List) {
      throw ApiException(message: 'Unexpected response from the server.');
    }
    return _parse(
      () => [for (final item in decoded) Meal.fromJson(_asMap(item))],
    );
  }

  @override
  Future<DashboardData> dashboard() async {
    final body = await _json('GET', '/api/v1/dashboard');
    return _parse(() => DashboardData.fromJson(body));
  }

  Future<Map<String, dynamic>> _json(
    String method,
    String path, {
    Map<String, dynamic>? jsonBody,
    Map<String, String>? query,
    bool authenticated = true,
  }) async {
    final decoded = await _request(
      method,
      path,
      jsonBody: jsonBody,
      query: query,
      authenticated: authenticated,
    );
    return _asMap(decoded);
  }

  Future<Object?> _request(
    String method,
    String path, {
    Map<String, dynamic>? jsonBody,
    Map<String, String>? query,
    bool authenticated = true,
  }) async {
    final headers = _headers(
      json: jsonBody != null,
      authenticated: authenticated,
    );
    final uri = _uri(path, query);
    final encoded = jsonBody == null ? null : jsonEncode(jsonBody);
    final Future<http.Response> future = switch (method) {
      'GET' => _http.get(uri, headers: headers),
      'POST' => _http.post(uri, headers: headers, body: encoded),
      'PATCH' => _http.patch(uri, headers: headers, body: encoded),
      _ => throw ArgumentError('Unsupported method $method'),
    };
    final response = await _send(() => future);
    return _decode(response);
  }

  Map<String, String> _headers({
    required bool json,
    bool authenticated = true,
  }) {
    return {
      'Accept': 'application/json',
      if (json) 'Content-Type': 'application/json',
      if (authenticated && token != null && token!.isNotEmpty)
        'Authorization': 'Bearer $token',
    };
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final uri = Uri.parse('$baseUrl$path');
    if (query == null || query.isEmpty) return uri;
    return uri.replace(queryParameters: query);
  }

  Future<T> _send<T>(Future<T> Function() action) async {
    try {
      return await action().timeout(_timeout);
    } on TimeoutException {
      throw ApiException(message: 'The server took too long to respond.');
    } on SocketException {
      throw ApiException(message: _unreachable);
    } on http.ClientException {
      throw ApiException(message: _unreachable);
    }
  }

  Object? _decode(http.Response response) {
    Object? decoded;
    if (response.body.isNotEmpty) {
      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        decoded = response.body;
      }
    }
    final status = response.statusCode;
    if (status >= 200 && status < 300) return decoded;
    throw ApiException(
      statusCode: status,
      message: messageFromBody(decoded, status),
    );
  }

  Map<String, dynamic> _asMap(Object? body) {
    if (body is Map<String, dynamic>) return body;
    if (body is Map) return Map<String, dynamic>.from(body);
    throw ApiException(message: 'Unexpected response from the server.');
  }

  T _parse<T>(T Function() parse) {
    try {
      return parse();
    } on FormatException {
      throw ApiException(message: 'Unexpected response from the server.');
    } on TypeError {
      throw ApiException(message: 'Unexpected response from the server.');
    }
  }
}
