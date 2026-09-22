import 'package:flutter_test/flutter_test.dart';
import 'package:sugar_tracker/src/auth/session_controller.dart';
import 'package:sugar_tracker/src/auth/token_store.dart';

import 'support/fake_sugar_api.dart';

void main() {
  test('login stores the token and register asks for a limit', () async {
    final store = MemoryTokenStore();
    final api = FakeSugarApi();
    final session = SessionController(api: api, tokenStore: store);

    await session.login(email: 'demo@sugar.app', password: 'demo1234');
    expect(session.phase, SessionPhase.signedIn);
    expect(session.needsOnboarding, isFalse);
    expect(await store.readToken(), 'token');

    await session.register(email: 'new@sugar.app', password: 'password1');
    expect(session.needsOnboarding, isTrue);
    expect(await store.readNeedsOnboarding(), isTrue);

    await session.saveLimit(12);
    expect(session.needsOnboarding, isFalse);
    expect(session.user?.dailySugarLimitG, 12);
    expect(await store.readNeedsOnboarding(), isFalse);

    await session.logout();
    expect(session.phase, SessionPhase.signedOut);
    expect(await store.readToken(), isNull);
    session.dispose();
  });

  test('a stored token restores the profile, and 401 clears it', () async {
    final store = MemoryTokenStore();
    await store.writeToken('stale');
    final api = FakeSugarApi()..unauthorized = true;
    final session = SessionController(api: api, tokenStore: store);

    await session.bootstrap();
    expect(session.phase, SessionPhase.signedOut);
    expect(await store.readToken(), isNull);

    await store.writeToken('ok');
    api.unauthorized = false;
    api.offline = true;
    await session.bootstrap();
    expect(session.phase, SessionPhase.failure);
    expect(await store.readToken(), 'ok');
    session.dispose();
  });
}
