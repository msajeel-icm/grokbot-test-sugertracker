import 'package:flutter/material.dart';

import '../api/models.dart';
import '../api/sugar_api.dart';
import 'key_value_store.dart';

class AppModel extends ChangeNotifier {
  AppModel({required this.api, required this.store});

  final SugarApi api;
  final KeyValueStore store;

  static const _themeKey = 'theme_mode';

  ThemeMode themeMode = ThemeMode.system;
  bool ready = false;
  UserProfile? user;
  Dashboard? dashboard;
  String? dashboardError;
  bool dashboardLoading = false;

  Future<void> boot() async {
    themeMode = _themeFrom(store.read(_themeKey));
    user = await api.restore();
    if (user != null) {
      await refresh();
    }
    ready = true;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    user = await api.login(email.trim(), password);
    await refresh();
  }

  Future<void> logout() async {
    await api.logout();
    user = null;
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
