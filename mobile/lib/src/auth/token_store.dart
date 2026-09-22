import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the JWT and whether the account still needs a sugar-limit choice.
abstract class TokenStore {
  Future<String?> readToken();
  Future<void> writeToken(String token);
  Future<bool> readNeedsOnboarding();
  Future<void> writeNeedsOnboarding(bool value);
  Future<void> clear();
}

class MemoryTokenStore implements TokenStore {
  String? _token;
  bool _needsOnboarding = false;

  @override
  Future<void> clear() async {
    _token = null;
    _needsOnboarding = false;
  }

  @override
  Future<bool> readNeedsOnboarding() async => _needsOnboarding;

  @override
  Future<String?> readToken() async => _token;

  @override
  Future<void> writeNeedsOnboarding(bool value) async {
    _needsOnboarding = value;
  }

  @override
  Future<void> writeToken(String token) async {
    _token = token;
  }
}

class SecureTokenStore implements TokenStore {
  const SecureTokenStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'access_token';
  static const _onboardingKey = 'needs_onboarding';

  final FlutterSecureStorage _storage;

  @override
  Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _onboardingKey);
  }

  @override
  Future<bool> readNeedsOnboarding() async {
    return (await _storage.read(key: _onboardingKey)) == '1';
  }

  @override
  Future<String?> readToken() => _storage.read(key: _tokenKey);

  @override
  Future<void> writeNeedsOnboarding(bool value) {
    return _storage.write(key: _onboardingKey, value: value ? '1' : '0');
  }

  @override
  Future<void> writeToken(String token) {
    return _storage.write(key: _tokenKey, value: token);
  }
}
