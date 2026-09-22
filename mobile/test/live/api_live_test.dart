import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:sugar_tracker/api/http_sugar_api.dart';
import 'package:sugar_tracker/api/sugar_api.dart';
import 'package:sugar_tracker/state/key_value_store.dart';

void main() {
  final enabled = Platform.environment['SUGAR_LIVE_API'] == '1';
  final base = Platform.environment['API_BASE_URL'] ??
      Platform.environment['API_BASE'] ??
      'http://127.0.0.1:8000';

  test('demo login, kcal estimate, register, and timezone against the API', () async {
    final health = await http.get(Uri.parse('$base/health'));
    expect(health.statusCode, 200, reason: health.body);

    final demo = HttpSugarApi(baseUrl: base, store: MemoryStore());
    final session = await demo.login('demo@sugar.app', 'demo1234');
    expect(session.email, 'demo@sugar.app');
    expect(session.dailySugarLimitG, 15);
    expect(session.timezone, 'UTC');

    final cookie = await demo.analyze(hint: 'chocolate chip cookie');
    expect(cookie.label, 'chocolate chip cookie');
    expect(cookie.sugarG, 12);
    expect(cookie.kcal, 160);
    expect(cookie.fractionSugarG['1/3'], 4);
    expect(cookie.fractionKcal['1/3'], 53.33);

    final created = HttpSugarApi(baseUrl: base, store: MemoryStore());
    final user = await created.register(
      'm4-${DateTime.now().microsecondsSinceEpoch}@sugar.app',
      'password1',
    );
    expect(user.dailySugarLimitG, 15);
    final logged = await created.logMeal(label: 'cookie (1/3)', sugarG: 4, kcal: 53.33);
    expect(logged.kcal, 53.33);
    final board = await created.dashboard();
    expect(board.consumedG, 4);
    expect(board.consumedKcal, 53.33);
    expect(board.remainingG, 11);

    await expectLater(
      created.updateTimezone('Not/AZone'),
      throwsA(isA<ApiException>().having((error) => error.statusCode, 'status', 422)),
    );
  }, skip: enabled ? false : 'Set SUGAR_LIVE_API=1 to run against a local API');
}
