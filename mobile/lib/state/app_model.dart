import 'package:flutter/material.dart';

import '../api/models.dart';
import '../api/sugar_api.dart';
import 'key_value_store.dart';

class AppModel extends ChangeNotifier {
  AppModel({required this.api, required this.store, this.apiBaseUrl = ''});

  final SugarApi api;
  final KeyValueStore store;
  final String apiBaseUrl;

  static const _themeKey = 'theme_mode';
  static const _onboardingKey = 'needs_onboarding';

  ThemeMode themeMode = ThemeMode.system;
  bool ready = false;
  bool needsOnboarding = false;
  UserProfile? user;
  Dashboard? dashboard;
  String? dashboardError;
  bool dashboardLoading = false;

  Future<void> boot() async {
    themeMode = _themeFrom(store.read(_themeKey));
    user = await api.restore();
    needsOnboarding = user != null && store.read(_onboardingKey) == '1';
    if (user != null && !needsOnboarding) {
      await refresh();
    }
    ready = true;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    user = await api.login(email.trim(), password);
    needsOnboarding = false;
    await store.write(_onboardingKey, '0');
    await refresh();
  }

  Future<void> register(String email, String password) async {
    user = await api.register(email.trim(), password);
    needsOnboarding = true;
    await store.write(_onboardingKey, '1');
    notifyListeners();
  }

  Future<void> finishOnboarding(double grams) async {
    await setLimit(grams);
    needsOnboarding = false;
    await store.write(_onboardingKey, '0');
    notifyListeners();
  }

  Future<void> logout() async {
    await api.logout();
    await store.delete(_onboardingKey);
    user = null;
    needsOnboarding = false;
    dashboard = null;
    dashboardError = null;
    notifyListeners();
  }

  Future<void> refresh() async {
    dashboardLoading = dashboard == null;
    dashboardError = null;
    notifyListeners();
    try {
      dashboard = await api.dashboard();
      user = await api.me();
    } on ApiException catch (error) {
      dashboardError = error.message;
    } catch (_) {
      dashboardError = "Couldn't load today.";
    } finally {
      dashboardLoading = false;
      notifyListeners();
    }
  }

  Future<void> setLimit(double grams) async {
    user = await api.updateLimit(grams);
    await refresh();
  }

  Future<void> setTimezone(String timezone) async {
    user = await api.updateTimezone(timezone.trim());
    notifyListeners();
  }

  Future<void> setTheme(ThemeMode mode) async {
    themeMode = mode;
    notifyListeners();
    await store.write(_themeKey, mode.name);
  }

  ThemeMode _themeFrom(String? value) {
    for (final mode in ThemeMode.values) {
      if (mode.name == value) return mode;
    }
    return ThemeMode.system;
  }
}
