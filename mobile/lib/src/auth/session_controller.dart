import 'package:flutter/foundation.dart';

import '../api/api_exception.dart';
import '../api/models.dart';
import '../api/sugar_api.dart';
import 'token_store.dart';

enum SessionPhase { loading, signedOut, signedIn, failure }

/// Owns the JWT, the signed-in profile, and the one-time limit step.
class SessionController extends ChangeNotifier {
  SessionController({required this.api, required this.tokenStore});

  final SugarApi api;
  final TokenStore tokenStore;
  int _bootstrapGen = 0;

  SessionPhase phase = SessionPhase.loading;
  UserProfile? user;
  bool needsOnboarding = false;
  String? errorMessage;

  Future<void> bootstrap() async {
    final gen = ++_bootstrapGen;
    errorMessage = null;
    if (phase != SessionPhase.loading) {
      phase = SessionPhase.loading;
      notifyListeners();
    }
    try {
      final stored = await tokenStore.readToken();
      if (gen != _bootstrapGen) return;
      if (stored == null || stored.isEmpty) {
        api.token = null;
        phase = SessionPhase.signedOut;
        notifyListeners();
        return;
      }
      api.token = stored;
      user = await api.getMe();
      needsOnboarding = await tokenStore.readNeedsOnboarding();
      if (gen != _bootstrapGen) return;
      phase = SessionPhase.signedIn;
      errorMessage = null;
    } on ApiException catch (error) {
      if (gen != _bootstrapGen) return;
      if (error.isUnauthorized) {
        await _clearLocal();
        if (gen != _bootstrapGen) return;
        phase = SessionPhase.signedOut;
      } else {
        errorMessage = error.message;
        phase = SessionPhase.failure;
      }
    } catch (_) {
      if (gen != _bootstrapGen) return;
      errorMessage = 'Could not restore your session.';
      phase = SessionPhase.failure;
    }
    notifyListeners();
  }

  Future<void> login({required String email, required String password}) async {
    final session = await api.login(email: email, password: password);
    await _persist(session, onboarding: false);
  }

  Future<void> register({
    required String email,
    required String password,
  }) async {
    final session = await api.register(email: email, password: password);
    await _persist(session, onboarding: true);
  }

  Future<void> saveLimit(double grams) {
    return updateProfile(dailySugarLimitG: grams, finishOnboarding: true);
  }

  Future<void> updateTimezone(String timezone) {
    return updateProfile(timezone: timezone);
  }

  Future<void> updateProfile({
    double? dailySugarLimitG,
    String? timezone,
    bool finishOnboarding = false,
  }) async {
    try {
      user = await api.updateMe(
        dailySugarLimitG: dailySugarLimitG,
        timezone: timezone,
      );
    } on ApiException catch (error) {
      if (error.isUnauthorized) {
        await logout();
      }
      rethrow;
    }
    if (finishOnboarding && needsOnboarding) {
      needsOnboarding = false;
      await tokenStore.writeNeedsOnboarding(false);
    }
    notifyListeners();
  }

  Future<void> logout() async {
    _bootstrapGen++;
    await _clearLocal();
    phase = SessionPhase.signedOut;
    errorMessage = null;
    notifyListeners();
  }

  Future<void> _persist(AuthSession session, {required bool onboarding}) async {
    api.token = session.accessToken;
    await tokenStore.writeToken(session.accessToken);
    await tokenStore.writeNeedsOnboarding(onboarding);
    user = session.user;
    needsOnboarding = onboarding;
    phase = SessionPhase.signedIn;
    errorMessage = null;
    notifyListeners();
  }

  Future<void> _clearLocal() async {
    api.token = null;
    user = null;
    needsOnboarding = false;
    try {
      await tokenStore.clear();
    } catch (_) {
      // The in-memory session is already cleared.
    }
  }
}
