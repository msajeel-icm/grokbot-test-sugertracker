import 'package:flutter/foundation.dart';

/// Where the app sends API requests.
///
/// Android emulators reach the host machine at `10.0.2.2`. iOS Simulator,
/// desktop targets, and web use loopback. Override either with
/// `--dart-define=API_BASE_URL=http://host:8000`.
class ApiConfig {
  const ApiConfig({required this.baseUrl});

  final String baseUrl;

  factory ApiConfig.fromEnvironment() {
    return ApiConfig(
      baseUrl: resolveApiBaseUrl(
        dartDefine: const String.fromEnvironment('API_BASE_URL'),
        isWeb: kIsWeb,
        platform: defaultTargetPlatform,
      ),
    );
  }
}

String resolveApiBaseUrl({
  String dartDefine = '',
  bool isWeb = false,
  TargetPlatform platform = TargetPlatform.android,
}) {
  final override = dartDefine.trim();
  if (override.isNotEmpty) return override;
  if (isWeb) return 'http://127.0.0.1:8000';
  if (platform == TargetPlatform.android) return 'http://10.0.2.2:8000';
  return 'http://127.0.0.1:8000';
}

String normalizeBaseUrl(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    throw ArgumentError.value(value, 'baseUrl', 'API base URL is empty');
  }
  return trimmed.endsWith('/')
      ? trimmed.substring(0, trimmed.length - 1)
      : trimmed;
}
