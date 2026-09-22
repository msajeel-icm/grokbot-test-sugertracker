import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:sugar_tracker/src/api/api_client.dart';
import 'package:sugar_tracker/src/api/api_exception.dart';
import 'package:sugar_tracker/src/api/models.dart';

void main() {
  final enabled = Platform.environment['SUGAR_LIVE_API'] == '1';
  final base = Platform.environment['API_BASE_URL'] ?? 'http://127.0.0.1:8000';

  test('demo login, analyze, and confirm against the API', () async {
    final health = await http.get(Uri.parse('$base/health'));
    expect(health.statusCode, 200, reason: health.body);

    final demo = ApiClient(baseUrl: base);
    final session = await demo.login(
      email: 'demo@sugar.app',
      password: 'demo1234',
    );
    demo.token = session.accessToken;
    expect(session.user.email, 'demo@sugar.app');
    expect(session.user.dailySugarLimitG, 15);
    expect(session.user.timezone, 'UTC');
    expect(session.user.currentStreak, greaterThanOrEqualTo(0));
    expect(session.user.bestStreak, greaterThanOrEqualTo(0));

    final board = await demo.dashboard();
    expect(board.limitG, 15);
    expect(board.currentStreak, session.user.currentStreak);
    expect(board.bestStreak, session.user.bestStreak);
    expect(board.date, matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));

    await expectLater(
      demo.login(email: 'demo@sugar.app', password: 'not-the-password'),
      throwsA(
        isA<ApiException>().having((error) => error.statusCode, 'status', 401),
      ),
    );

    final api = ApiClient(baseUrl: base);
    final created = await api.register(
      email: 'm3-${DateTime.now().microsecondsSinceEpoch}@sugar.app',
      password: 'password1',
    );
    api.token = created.accessToken;
    expect(created.user.dailySugarLimitG, 15);

    final today = (await api.dashboard()).date;
    expect(await api.mealsOn(today), isEmpty);

    final cookie = await api.analyzeMeal(hint: 'chocolate chip cookie');
    expect(cookie.label, 'chocolate chip cookie');
    expect(cookie.sugarG, 12);
    expect(cookie.wouldExceed, isFalse);
    expect(cookie.suggestion.fractions, ['1/3', '1/2']);
    expect(cookie.suggestion.fractionSugarG['1/3'], 4);
    expect(cookie.suggestion.fractionSugarG['1/2'], 6);
    expect(cookie.suggestion.alternatives.length, greaterThanOrEqualTo(2));
    expect(await api.mealsOn(today), isEmpty);

    final third = cookie.suggestion.fractionSugarG['1/3']!;
    final logged = await api.logMeal(
      sugarG: third,
      label: '${cookie.label} (1/3)',
      notes: 'chocolate chip cookie',
    );
    expect(logged.sugarG, third);
    expect(logged.status, 'logged');
    expect(logged.localDate, today);

    final afterThird = await api.dashboard();
    expect(afterThird.consumedG, third);
    expect(afterThird.remainingG, 15 - third);
    expect(afterThird.meals.map((meal) => meal.id), [logged.id]);
    expect(afterThird.currentStreak, 1);
    expect(afterThird.bestStreak, 1);
    expect((await api.mealsOn(today)).map((meal) => meal.label), [
      '${cookie.label} (1/3)',
    ]);

    final cola = await api.analyzeMeal(hint: 'cola');
    expect(cola.label, 'cola');
    expect(cola.sugarG, 39);
    expect(cola.wouldExceed, isTrue);
    final names = [for (final item in cola.suggestion.alternatives) item.label];
    expect(names, contains('grilled chicken'));
    expect(names, contains('cucumber'));
    expect((await api.mealsOn(today)).length, 1);

    final photo = await api.analyzeMeal(
      hint: 'cucumber',
      photo: MealPhoto(
        bytes: Uint8List.fromList([9, 8, 7, 6]),
        filename: 'plate.jpg',
      ),
    );
    expect(photo.label, 'cucumber');
    expect(photo.sugarG, 1.7);
    expect((await api.mealsOn(today)).length, 1);

    final full = await api.logMeal(sugarG: cookie.sugarG, label: cookie.label);
    final done = await api.dashboard();
    expect(done.consumedG, third + cookie.sugarG);
    expect(done.remainingG, 15 - done.consumedG);
    expect(done.meals.map((meal) => meal.id), [logged.id, full.id]);
    expect(done.currentStreak, 0);
    expect(done.bestStreak, 0);

    final me = await api.getMe();
    expect(me.currentStreak, 0);
    expect(me.bestStreak, 0);

    await api.updateMe(dailySugarLimitG: 12);
    expect((await api.getMe()).dailySugarLimitG, 12);
    await expectLater(
      api.updateMe(timezone: 'Not/AZone'),
      throwsA(
        isA<ApiException>().having((error) => error.statusCode, 'status', 422),
      ),
    );
  }, skip: enabled ? false : 'Set SUGAR_LIVE_API=1 to run against a local API');
}
