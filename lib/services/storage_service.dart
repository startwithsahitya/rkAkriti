import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/day_record.dart';

class StorageService {
  static const String historyKey = 'day_record_history';

  Future<DayRecord?> loadDayRecord(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    String? historyJson = prefs.getString(historyKey);
    if (historyJson != null) {
      List<dynamic> jsonList = json.decode(historyJson);
      List<DayRecord> history =
          jsonList.map((e) => DayRecord.fromJson(e)).toList();
      try {
        return history.firstWhere((record) =>
            record.date.year == date.year &&
            record.date.month == date.month &&
            record.date.day == date.day);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<void> saveDayRecord(DayRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    List<DayRecord> history = await getHistory();
    // Remove any existing record for the same day.
    history.removeWhere((r) =>
        r.date.year == record.date.year &&
        r.date.month == record.date.month &&
        r.date.day == record.date.day);
    history.add(record);
    String jsonStr = json.encode(history.map((r) => r.toJson()).toList());
    await prefs.setString(historyKey, jsonStr);
  }

  Future<List<DayRecord>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    String? historyJson = prefs.getString(historyKey);
    if (historyJson != null) {
      List<dynamic> jsonList = json.decode(historyJson);
      return jsonList.map((e) => DayRecord.fromJson(e)).toList();
    }
    return [];
  }
}
