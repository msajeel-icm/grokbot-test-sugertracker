import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api/http_sugar_api.dart';
import 'api/photo_picker.dart';
import 'app.dart';
import 'config/api_config.dart';
import 'state/app_model.dart';
import 'state/key_value_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final store = PrefsStore(prefs);
  final config = ApiConfig.fromEnvironment();
  final model = AppModel(
    api: HttpSugarApi(baseUrl: config.baseUrl, store: store),
    store: store,
    apiBaseUrl: config.baseUrl,
  );
  await model.boot();
  runApp(SugarTrackerApp(model: model, pickPhoto: pickMealPhoto));
}
