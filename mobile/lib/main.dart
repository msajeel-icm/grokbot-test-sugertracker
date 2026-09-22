import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api/http_sugar_api.dart';
import 'api/photo_picker.dart';
import 'app.dart';
import 'state/app_model.dart';
import 'state/key_value_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final store = PrefsStore(prefs);
  const baseUrl = String.fromEnvironment('API_BASE', defaultValue: 'http://127.0.0.1:8000');
  final model = AppModel(
    api: HttpSugarApi(baseUrl: baseUrl, store: store),
    store: store,
  );
  await model.boot();
  runApp(SugarTrackerApp(model: model, pickPhoto: pickMealPhoto));
}
