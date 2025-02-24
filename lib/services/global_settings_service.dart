import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class GlobalSettingsService {
  static const String globalGroupKey = 'global_group_names';

  Future<List<String>> getGlobalGroupNames() async {
    final prefs = await SharedPreferences.getInstance();
    String? jsonString = prefs.getString(globalGroupKey);
    if (jsonString != null) {
      List<dynamic> list = json.decode(jsonString);
      return list.cast<String>();
    } else {
      // Default groups if none are saved.
      return ['HK', 'R'];
    }
  }

  Future<void> setGlobalGroupNames(List<String> groupNames) async {
    final prefs = await SharedPreferences.getInstance();
    String jsonString = json.encode(groupNames);
    await prefs.setString(globalGroupKey, jsonString);
  }
}
