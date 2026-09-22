import 'package:shared_preferences/shared_preferences.dart';

abstract class KeyValueStore {
  String? read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}

class PrefsStore implements KeyValueStore {
  PrefsStore(this.prefs);

  final SharedPreferences prefs;

  @override
  String? read(String key) => prefs.getString(key);

  @override
  Future<void> write(String key, String value) => prefs.setString(key, value);

  @override
  Future<void> delete(String key) => prefs.remove(key);
}

class MemoryStore implements KeyValueStore {
  final Map<String, String> values = {};

  @override
  String? read(String key) => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }
}
