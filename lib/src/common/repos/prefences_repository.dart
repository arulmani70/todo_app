import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

class PreferencesRepository {
  final SharedPreferences sharedPreferences;
  final log = Logger();

  PreferencesRepository(this.sharedPreferences);

  Future<void> savePreference(String key, String value) async {
    await sharedPreferences.setString(key, value);
  }

  Future<void> saveSelectedLanguage(String key, String language) async {
    await sharedPreferences.setString(key, language);
  }

  String? getPreference(String key) {
    return sharedPreferences.getString(key);
  }

  Future<void> removePreference(String key) async {
    await sharedPreferences.remove(key);
  }

  Map<String, String> getAllPreferences() {
    return sharedPreferences
        .getKeys()
        .map((key) => MapEntry(key, sharedPreferences.getString(key) ?? ''))
        .toMap();
  }

  Future<void> clearAllPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}

extension on Iterable<MapEntry<String, String>> {
  Map<String, String> toMap() {
    return Map.fromEntries(this);
  }
}
