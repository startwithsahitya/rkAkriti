import 'package:shared_preferences/shared_preferences.dart';

class ResetService {
  // Keys used by your app.
  static const String historyKey = 'day_record_history';
  static const String globalGroupKey = 'global_group_names';

  /// Clears all app-specific persistent data.
  Future<void> resetAppData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(historyKey);
    await prefs.remove(globalGroupKey);
  }
}
