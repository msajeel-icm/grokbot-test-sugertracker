import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sugar_tracker/src/config/api_config.dart';

void main() {
  test('defaults to the Android emulator host', () {
    expect(
      resolveApiBaseUrl(platform: TargetPlatform.android),
      'http://10.0.2.2:8000',
    );
  });

  test('uses loopback off Android and when a define is set', () {
    expect(
      resolveApiBaseUrl(platform: TargetPlatform.iOS),
      'http://127.0.0.1:8000',
    );
    expect(
      resolveApiBaseUrl(platform: TargetPlatform.linux),
      'http://127.0.0.1:8000',
    );
    expect(
      resolveApiBaseUrl(isWeb: true, platform: TargetPlatform.android),
      'http://127.0.0.1:8000',
    );
    expect(
      resolveApiBaseUrl(
        dartDefine: ' http://192.168.1.20:8000 ',
        platform: TargetPlatform.android,
      ),
      'http://192.168.1.20:8000',
    );
  });

  test('strips a trailing slash from the base URL', () {
    expect(normalizeBaseUrl('http://10.0.2.2:8000/'), 'http://10.0.2.2:8000');
  });
}
