import 'package:flutter/material.dart';

import 'src/api/api_client.dart';
import 'src/app.dart';
import 'src/auth/session_controller.dart';
import 'src/auth/token_store.dart';
import 'src/config/api_config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final config = ApiConfig.fromEnvironment();
  final session = SessionController(
    api: ApiClient(baseUrl: config.baseUrl),
    tokenStore: const SecureTokenStore(),
  );
  runApp(SugarTrackerApp(session: session, apiBaseUrl: config.baseUrl));
}
