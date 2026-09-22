import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sugar_tracker/api/models.dart';
import 'package:sugar_tracker/app.dart';
import 'package:sugar_tracker/state/app_model.dart';
import 'package:sugar_tracker/state/key_value_store.dart';
import 'package:sugar_tracker/theme/tokens.dart';

import 'fake_sugar_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<({AppModel model, FakeSugarApi api})> launch(
    WidgetTester tester, {
    FakeSugarApi? api,
    Future<MealPhoto?> Function()? pickPhoto,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final fake = api ?? FakeSugarApi();
    final model = AppModel(api: fake, store: MemoryStore());
    await model.boot();
    await tester.pumpWidget(
      SugarTrackerApp(model: model, pickPhoto: pickPhoto ?? () async => null),
    );
    await tester.pumpAndSettle();
    return (model: model, api: fake);
  }

  Future<void> reveal(WidgetTester tester, Finder finder) async {
    for (var i = 0; i < 8 && finder.evaluate().isEmpty; i++) {
      await tester.drag(find.byType(ListView).first, const Offset(0, -320));
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('demo login reaches the sugar home screen', (tester) async {
    await launch(tester);

    expect(find.textContaining('demo@sugar.app'), findsWidgets);
    await tester.tap(find.byKey(const Key('use-demo')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('sign-in')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('sugar-ring')), findsOneWidget);
    expect(find.byKey(const Key('sugar-consumed')), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('sugar-consumed'))).data, '0');
    expect(find.text('15 g left'), findsOneWidget);
    expect(find.text('0 kcal today'), findsOneWidget);
    await reveal(tester, find.byKey(const Key('meals-empty')));
    expect(find.byKey(const Key('meals-empty')), findsOneWidget);
    expect(find.byKey(const Key('open-log')), findsOneWidget);
  });

  testWidgets('typed demo credentials sign in and a mismatch stays on login', (tester) async {
    await launch(tester);

    await tester.enterText(find.byKey(const Key('email')), 'demo@sugar.app');
    await tester.enterText(find.byKey(const Key('password')), 'wrong-password');
    await tester.tap(find.byKey(const Key('sign-in')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('login-error')), findsOneWidget);
    expect(find.text('Those credentials did not match.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('password')), 'demo1234');
    await tester.tap(find.byKey(const Key('sign-in')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('open-log')), findsOneWidget);
  });

  testWidgets('home shows sugar first and kcal as a secondary line', (tester) async {
    final api = FakeSugarApi(startLoggedIn: true)
      ..currentStreak = 2
      ..bestStreak = 5
      ..meals.add(
        const Meal(
          id: 1,
          label: 'oatmeal',
          sugarG: 1,
          kcal: 150,
          localDate: '2026-09-22',
          status: 'logged',
        ),
      );
    await launch(tester, api: api);

    expect(find.text('Tuesday, Sep 22'), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('sugar-consumed'))).data, '1');
    expect(find.text('of 15 g'), findsOneWidget);
    expect(find.text('14 g left'), findsOneWidget);
    expect(find.text('150 kcal today'), findsOneWidget);
    await reveal(tester, find.text('oatmeal'));
    expect(find.text('oatmeal'), findsOneWidget);
    expect(find.text('1 g'), findsWidgets);
    expect(find.text('150 kcal'), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('streak-current'))).data, '2');
    expect(tester.widget<Text>(find.byKey(const Key('streak-best'))).data, '5');
  });

  testWidgets('over-sugar warning offers scaled portions and cancel does not log', (tester) async {
    final api = FakeSugarApi(startLoggedIn: true)
      ..meals.add(
        const Meal(
          id: 1,
          label: 'yogurt',
          sugarG: 10,
          kcal: 80,
          localDate: '2026-09-22',
          status: 'logged',
        ),
      );
    await launch(tester, api: api);
    expect(find.text('80 kcal today'), findsOneWidget);

    await tester.tap(find.byKey(const Key('open-log')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('hint')), 'cookie');
    await tester.tap(find.byKey(const Key('estimate')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('over-budget')), findsOneWidget);
    expect(find.byKey(const Key('within-budget')), findsNothing);
    expect(tester.widget<Text>(find.byKey(const Key('sugar-estimate'))).data, '12');
    expect(find.text('160 kcal'), findsWidgets);
    expect(find.text('Log full · 12 g · 160 kcal'), findsOneWidget);
    expect(find.text('Log 1/3 · 4 g · 53.33 kcal'), findsOneWidget);
    expect(find.text('grilled chicken'), findsOneWidget);
    await reveal(tester, find.text('Log 1/2 · 6 g · 80 kcal'));
    expect(find.text('Log 1/2 · 6 g · 80 kcal'), findsOneWidget);

    await reveal(tester, find.byKey(const Key('cancel-log')));
    await tester.tap(find.byKey(const Key('cancel-log')));
    await tester.pumpAndSettle();
    expect(api.logCalls, 0);
    expect(find.text('5 g left'), findsOneWidget);
    expect(find.text('80 kcal today'), findsOneWidget);

    await tester.tap(find.byKey(const Key('open-log')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('hint')), 'cookie');
    await tester.tap(find.byKey(const Key('estimate')));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const Key('log-third')));
    await tester.tap(find.byKey(const Key('log-third')));
    await tester.pumpAndSettle();

    expect(api.logCalls, 1);
    expect(api.lastLog?.sugarG, 4);
    expect(api.lastLog?.kcal, 53.33);
    expect(api.lastLog?.label, '1/3 chocolate chip cookie');
    expect(tester.widget<Text>(find.byKey(const Key('sugar-consumed'))).data, '14');
    expect(find.text('1 g left'), findsOneWidget);
    expect(find.text('133.33 kcal today'), findsOneWidget);
    await reveal(tester, find.text('1/3 chocolate chip cookie'));
    expect(find.text('1/3 chocolate chip cookie'), findsOneWidget);
  });

  testWidgets('high calories and zero sugar stay inside the sugar budget', (tester) async {
    final api = FakeSugarApi(startLoggedIn: true)
      ..meals.add(
        const Meal(
          id: 1,
          label: 'full',
          sugarG: 15,
          kcal: 999,
          localDate: '2026-09-22',
          status: 'logged',
        ),
      );
    await launch(tester, api: api);
    expect(find.text('At the sugar limit'), findsOneWidget);
    expect(find.text('999 kcal today'), findsOneWidget);

    await tester.tap(find.byKey(const Key('open-log')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('hint')), 'grilled chicken');
    await tester.tap(find.byKey(const Key('estimate')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('within-budget')), findsOneWidget);
    expect(find.byKey(const Key('over-budget')), findsNothing);
    expect(tester.widget<Text>(find.byKey(const Key('sugar-estimate'))).data, '0');
    expect(find.text('165 kcal'), findsOneWidget);
    expect(find.text('Log full · 0 g · 165 kcal'), findsOneWidget);
    await reveal(tester, find.text('Log 1/2 · 0 g · 82.5 kcal'));
    expect(find.text('Log 1/3 · 0 g · 55 kcal'), findsOneWidget);
    expect(find.text('Log 1/2 · 0 g · 82.5 kcal'), findsOneWidget);
  });

  testWidgets('a photo is sent with the estimate and an analyze error is visible', (tester) async {
    final api = FakeSugarApi(startLoggedIn: true);
    const photo = MealPhoto(bytes: [1, 2, 3, 4], name: 'plate.jpg');
    await launch(tester, api: api, pickPhoto: () async => photo);

    await tester.tap(find.byKey(const Key('open-log')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('estimate')));
    await tester.pumpAndSettle();
    expect(find.text('Add a hint or a photo first.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('add-photo')));
    await tester.pumpAndSettle();
    expect(find.text('plate.jpg'), findsOneWidget);

    api.analyzeError = "Couldn't estimate that meal.";
    await tester.tap(find.byKey(const Key('estimate')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('log-error')), findsOneWidget);

    api.analyzeError = null;
    await tester.tap(find.byKey(const Key('estimate')));
    await tester.pumpAndSettle();
    expect(api.lastImage, photo.bytes);
    expect(find.byKey(const Key('sugar-estimate')), findsOneWidget);
  });

  testWidgets('settings presets and theme toggle update the home surface', (tester) async {
    await launch(tester, api: FakeSugarApi(startLoggedIn: true)..currentStreak = 1);

    await tester.tap(find.byKey(const Key('open-settings')));
    await tester.pumpAndSettle();
    expect(find.text('WHO added sugar'), findsOneWidget);
    await tester.tap(find.byKey(const Key('preset-25')));
    await tester.pumpAndSettle();

    await reveal(tester, find.text('demo@sugar.app'));
    expect(find.text('demo@sugar.app'), findsOneWidget);

    await reveal(tester, find.byKey(const Key('theme-dark')));
    await tester.tap(find.byKey(const Key('theme-dark')));
    await tester.pumpAndSettle();
    final darkContext = tester.element(find.text('Appearance'));
    expect(Theme.of(darkContext).brightness, Brightness.dark);
    expect(Theme.of(darkContext).scaffoldBackgroundColor, AppTokens.nearBlack);

    await tester.tap(find.byKey(const Key('theme-light')));
    await tester.pumpAndSettle();
    final lightContext = tester.element(find.text('Appearance'));
    expect(Theme.of(lightContext).brightness, Brightness.light);
    expect(Theme.of(lightContext).scaffoldBackgroundColor, AppTokens.offWhite);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('of 25 g'), findsOneWidget);
    expect(find.text('25 g left'), findsOneWidget);
  });

  testWidgets('dashboard failure shows an error and retry recovers', (tester) async {
    final api = FakeSugarApi(startLoggedIn: true)..failDashboard = true;
    await launch(tester, api: api);

    expect(find.text("Couldn't load today."), findsOneWidget);
    expect(find.byKey(const Key('dashboard-error')), findsOneWidget);
    expect(find.byKey(const Key('open-log')), findsOneWidget);

    api.failDashboard = false;
    await tester.tap(find.byKey(const Key('retry')));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const Key('meals-empty')));
    expect(find.byKey(const Key('meals-empty')), findsOneWidget);
    expect(find.text('15 g left'), findsOneWidget);
  });
}
