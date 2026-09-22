import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sugar_tracker/src/api/models.dart';
import 'package:sugar_tracker/src/app.dart';
import 'package:sugar_tracker/src/auth/session_controller.dart';
import 'package:sugar_tracker/src/auth/token_store.dart';
import 'package:sugar_tracker/src/meals/log_meal_screen.dart';

import 'support/fake_sugar_api.dart';

void main() {
  Future<SessionController> pumpApp(
    WidgetTester tester, {
    required FakeSugarApi api,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    final session = SessionController(api: api, tokenStore: MemoryTokenStore());
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      session.dispose();
    });
    await tester.pumpWidget(
      SugarTrackerApp(session: session, apiBaseUrl: 'http://127.0.0.1:8000'),
    );
    await tester.pumpAndSettle();
    return session;
  }

  Future<void> signIn(WidgetTester tester) async {
    await tester.enterText(
      find.byKey(const Key('login-email')),
      'demo@sugar.app',
    );
    await tester.enterText(find.byKey(const Key('login-password')), 'demo1234');
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();
  }

  String textOf(WidgetTester tester, Key key) {
    return tester.widget<Text>(find.byKey(key)).data!;
  }

  testWidgets('login shows the dashboard and a cancelled review does not log', (
    tester,
  ) async {
    final api = FakeSugarApi();
    await pumpApp(tester, api: api);

    expect(find.text('API http://127.0.0.1:8000'), findsOneWidget);
    expect(find.text('Demo: demo@sugar.app / demo1234'), findsOneWidget);

    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Enter your email.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('login-password')), 'wrong');
    await tester.enterText(
      find.byKey(const Key('login-email')),
      'demo@sugar.app',
    );
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Invalid email or password'), findsOneWidget);

    await signIn(tester);
    expect(textOf(tester, const Key('consumed-value')), '0');
    expect(textOf(tester, const Key('limit-value')), '15');
    expect(textOf(tester, const Key('remaining-value')), '15 g left');
    expect(textOf(tester, const Key('streak-current')), '2');
    expect(textOf(tester, const Key('streak-best')), '4');
    expect(find.byKey(const Key('meals-empty')), findsOneWidget);
    expect(find.text('Tuesday, September 22'), findsOneWidget);

    await tester.tap(find.byKey(const Key('log-meal')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('analyze')));
    await tester.pumpAndSettle();
    expect(find.text('Add a photo or describe the meal.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('meal-hint')), 'cookie');
    await tester.tap(find.byKey(const Key('analyze')));
    await tester.pumpAndSettle();
    expect(textOf(tester, const Key('review-label')), 'chocolate chip cookie');
    expect(textOf(tester, const Key('review-sugar')), '12 g');
    expect(find.textContaining('4.01'), findsOneWidget);
    expect(find.byKey(const Key('review-exceed')), findsNothing);
    expect(find.text('grilled chicken'), findsOneWidget);

    await tester.tap(find.byKey(const Key('log-half')));
    await tester.pumpAndSettle();

    expect(api.logCalls, 1);
    expect(api.lastLoggedSugar, 6);
    expect(api.lastLoggedLabel, 'chocolate chip cookie (1/2)');
    expect(textOf(tester, const Key('consumed-value')), '6');
    expect(textOf(tester, const Key('remaining-value')), '9 g left');
    expect(textOf(tester, const Key('streak-current')), '3');
    expect(find.text('chocolate chip cookie (1/2)'), findsOneWidget);
    expect(find.byKey(const Key('meals-empty')), findsNothing);

    await tester.tap(find.byKey(const Key('log-meal')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('meal-hint')), 'cookie');
    await tester.tap(find.byKey(const Key('analyze')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('review-exceed')), findsOneWidget);

    await tester.tap(find.byKey(const Key('cancel-log')));
    await tester.pumpAndSettle();
    expect(api.logCalls, 1);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(textOf(tester, const Key('consumed-value')), '6');
    expect(find.text('chocolate chip cookie (1/2)'), findsOneWidget);
  });

  testWidgets('register then a 12 g limit opens the dashboard', (tester) async {
    final api = FakeSugarApi();
    await pumpApp(tester, api: api);

    await tester.tap(find.byKey(const Key('go-register')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('register-email')),
      'new@sugar.app',
    );
    await tester.enterText(find.byKey(const Key('register-password')), 'short');
    await tester.tap(find.byKey(const Key('register-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Use at least 8 characters.'), findsOneWidget);
    expect(api.registerCalls, 0);

    await tester.enterText(
      find.byKey(const Key('register-password')),
      'password1',
    );
    await tester.tap(find.byKey(const Key('register-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Set your daily limit'), findsOneWidget);

    await tester.tap(find.byKey(const Key('preset-12')));
    await tester.tap(find.byKey(const Key('save-limit')));
    await tester.pumpAndSettle();
    expect(textOf(tester, const Key('limit-value')), '12');
    expect(api.limitG, 12);
  });

  testWidgets('settings save a custom limit and log out', (tester) async {
    final api = FakeSugarApi();
    await pumpApp(tester, api: api);
    await signIn(tester);

    await tester.tap(find.byKey(const Key('settings')));
    await tester.pumpAndSettle();
    expect(find.text('demo@sugar.app'), findsOneWidget);

    await tester.tap(find.byKey(const Key('preset-custom')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('custom-limit')), '20');
    await tester.tap(find.byKey(const Key('save-limit')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Daily limit saved'), findsOneWidget);
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(textOf(tester, const Key('limit-value')), '20');

    await tester.tap(find.byKey(const Key('settings')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('logout')));
    await tester.tap(find.byKey(const Key('logout')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('login-email')), findsOneWidget);
  });

  testWidgets('an over-limit day says how far over', (tester) async {
    final api = FakeSugarApi()
      ..consumedG = 20
      ..limitG = 15;
    await pumpApp(tester, api: api);
    await signIn(tester);
    expect(textOf(tester, const Key('remaining-value')), '5 g over');
    expect(textOf(tester, const Key('consumed-value')), '20');
  });

  testWidgets('a picked photo is sent with the estimate', (tester) async {
    final api = FakeSugarApi();
    final session = SessionController(api: api, tokenStore: MemoryTokenStore());
    addTearDown(session.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: LogMealScreen(
          session: session,
          pickPhoto: () async => MealPhoto(
            bytes: Uint8List.fromList([1, 2, 3]),
            filename: 'plate.jpg',
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('pick-photo')));
    await tester.pumpAndSettle();
    expect(find.text('plate.jpg'), findsOneWidget);
    expect(find.text('Photo attached'), findsOneWidget);

    await tester.tap(find.byKey(const Key('analyze')));
    await tester.pumpAndSettle();
    expect(api.lastPhotoFilename, 'plate.jpg');
    expect(api.lastHint, isNull);
    expect(find.byKey(const Key('review-label')), findsOneWidget);
  });
}
