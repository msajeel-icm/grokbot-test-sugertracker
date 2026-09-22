import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sugar_tracker/src/api/api_client.dart';
import 'package:sugar_tracker/src/api/api_exception.dart';
import 'package:sugar_tracker/src/api/models.dart';

const _user = {
  'id': 1,
  'email': 'demo@sugar.app',
  'daily_sugar_limit_g': 15,
  'timezone': 'UTC',
  'created_at': '2026-09-01T00:00:00Z',
  'current_streak': 0,
  'best_streak': 0,
};

void main() {
  test('login posts credentials and keeps the token off the request', () async {
    late http.Request captured;
    final client = ApiClient(
      baseUrl: 'http://127.0.0.1:8000/',
      httpClient: MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'access_token': 'jwt',
            'token_type': 'bearer',
            'user': _user,
          }),
          200,
        );
      }),
    );

    final session = await client.login(
      email: 'demo@sugar.app',
      password: 'demo1234',
    );

    expect(client.baseUrl, 'http://127.0.0.1:8000');
    expect(session.accessToken, 'jwt');
    expect(captured.method, 'POST');
    expect(captured.url.path, '/api/v1/auth/login');
    expect(captured.headers['authorization'], isNull);
    expect(jsonDecode(captured.body), {
      'email': 'demo@sugar.app',
      'password': 'demo1234',
    });
  });

  test('authenticated calls send the bearer token and field names', () async {
    final requests = <http.Request>[];
    final client = ApiClient(
      baseUrl: 'http://10.0.2.2:8000',
      token: 'secret',
      httpClient: MockClient((request) async {
        requests.add(request);
        if (request.url.path == '/api/v1/meals') {
          return http.Response(
            jsonEncode([
              {
                'id': 3,
                'label': 'oatmeal',
                'sugar_g': 1,
                'logged_at': '2026-09-22T08:00:00Z',
                'local_date': '2026-09-22',
                'status': 'logged',
                'notes': null,
                'photo_path_or_url': null,
              },
            ]),
            200,
          );
        }
        return http.Response(
          jsonEncode({..._user, 'daily_sugar_limit_g': 12}),
          200,
        );
      }),
    );

    await client.updateMe(dailySugarLimitG: 12);
    final meals = await client.mealsOn('2026-09-22');

    expect(requests.first.headers['authorization'], 'Bearer secret');
    expect(requests.first.method, 'PATCH');
    expect(requests.first.url.path, '/api/v1/me');
    expect(jsonDecode(requests.first.body), {'daily_sugar_limit_g': 12});
    expect(requests.last.url.path, '/api/v1/meals');
    expect(requests.last.url.queryParameters['date'], '2026-09-22');
    expect(meals.single.label, 'oatmeal');
  });

  test('analyze sends JSON for a hint and multipart for a photo', () async {
    final requests = <http.Request>[];
    final client = ApiClient(
      baseUrl: 'http://127.0.0.1:8000',
      token: 'secret',
      httpClient: MockClient((request) async {
        requests.add(request);
        return http.Response(
          jsonEncode({
            'sugar_g': 1.7,
            'label': 'cucumber',
            'confidence': 0.89,
            'remaining_budget_g': 15,
            'would_exceed': false,
            'suggestion': {
              'fractions': ['1/3', '1/2'],
              'fraction_sugar_g': {'1/3': 0.57, '1/2': 0.85},
              'alternatives': [],
            },
          }),
          200,
        );
      }),
    );

    await client.analyzeMeal(hint: ' cookie ');
    await client.analyzeMeal(
      hint: 'cucumber',
      photo: MealPhoto(
        bytes: Uint8List.fromList([65, 66, 67]),
        filename: 'plate.jpg',
      ),
    );

    expect(requests.first.url.path, '/api/v1/meals/analyze');
    expect(jsonDecode(requests.first.body), {'hint': 'cookie'});
    expect(
      requests.last.headers['content-type'],
      contains('multipart/form-data'),
    );
    expect(requests.last.headers['authorization'], 'Bearer secret');
    final body = latin1.decode(requests.last.bodyBytes);
    expect(body, contains('name="hint"'));
    expect(body, contains('cucumber'));
    expect(body, contains('name="image"'));
    expect(body, contains('plate.jpg'));
    expect(body, contains('ABC'));
  });

  test('surfaces FastAPI detail strings and validation messages', () async {
    final client = ApiClient(
      baseUrl: 'http://127.0.0.1:8000',
      httpClient: MockClient((request) async {
        if (request.url.path.endsWith('/login')) {
          return http.Response(
            jsonEncode({'detail': 'Invalid email or password'}),
            401,
          );
        }
        return http.Response(
          jsonEncode({
            'detail': [
              {'msg': 'String should have at least 8 characters'},
            ],
          }),
          422,
        );
      }),
    );

    await expectLater(
      client.login(email: 'demo@sugar.app', password: 'nope'),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'status', 401)
            .having(
              (error) => error.message,
              'message',
              'Invalid email or password',
            ),
      ),
    );
    await expectLater(
      client.register(email: 'a@b.co', password: 'password1'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          contains('at least 8 characters'),
        ),
      ),
    );
  });

  test(
    'empty analyze and network failures do not pretend to succeed',
    () async {
      final client = ApiClient(
        baseUrl: 'http://127.0.0.1:8000',
        httpClient: MockClient((request) async {
          throw http.ClientException('down', request.url);
        }),
      );

      await expectLater(
        client.analyzeMeal(),
        throwsA(
          isA<ApiException>().having(
            (error) => error.message,
            'message',
            contains('photo'),
          ),
        ),
      );
      await expectLater(
        client.login(email: 'demo@sugar.app', password: 'demo1234'),
        throwsA(
          isA<ApiException>().having(
            (error) => error.message,
            'message',
            contains('Cannot reach the API'),
          ),
        ),
      );
    },
  );
}
