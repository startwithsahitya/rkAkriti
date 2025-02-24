import 'package:flutter/material.dart';
import '../models/day_record.dart';
import '../services/storage_service.dart';
import '../services/global_settings_service.dart';

class DailyCounterProvider with ChangeNotifier {
  DayRecord? _currentDay;
  final StorageService _storageService = StorageService();
  final GlobalSettingsService _globalSettingsService = GlobalSettingsService();

  DailyCounterProvider() {
    _initDayRecord();
  }

  DayRecord? get currentDay => _currentDay;

  Future<void> _initDayRecord() async {
    DateTime today = DateTime.now();
    DayRecord? record = await _storageService.loadDayRecord(today);
    if (record == null) {
      List<String> globalGroups =
          await _globalSettingsService.getGlobalGroupNames();
      Map<String, int> groupsMap = {for (var group in globalGroups) group: 0};
      _currentDay = DayRecord(date: today, groupCounts: groupsMap);
      await _storageService.saveDayRecord(_currentDay!);
    } else {
      _currentDay = record;
    }
    notifyListeners();
  }

  Future<void> changeDate(DateTime newDate) async {
    DayRecord? record = await _storageService.loadDayRecord(newDate);
    if (record == null) {
      List<String> globalGroups =
          await _globalSettingsService.getGlobalGroupNames();
      Map<String, int> groupsMap = {for (var group in globalGroups) group: 0};
      record = DayRecord(date: newDate, groupCounts: groupsMap);
      await _storageService.saveDayRecord(record);
    }
    _currentDay = record;
    notifyListeners();
  }

  void incrementGroup(String groupName) async {
    if (_currentDay == null) return;
    _currentDay!.groupCounts[groupName] =
        (_currentDay!.groupCounts[groupName] ?? 0) + 1;
    notifyListeners();
    await _storageService.saveDayRecord(_currentDay!);
  }

  Future<void> renameGroup(String oldName, String newName) async {
    if (_currentDay == null) return;
    if (_currentDay!.groupCounts.containsKey(newName))
      return; // avoid duplicates

    int count = _currentDay!.groupCounts[oldName] ?? 0;
    _currentDay!.groupCounts.remove(oldName);
    _currentDay!.groupCounts[newName] = count;

    // Update the global group names list.
    List<String> globalGroupNames =
        await _globalSettingsService.getGlobalGroupNames();
    int index = globalGroupNames.indexOf(oldName);
    if (index != -1) {
      globalGroupNames[index] = newName;
      await _globalSettingsService.setGlobalGroupNames(globalGroupNames);
    }
    notifyListeners();
    await _storageService.saveDayRecord(_currentDay!);
  }

  Future<void> addGroup(String newGroupName) async {
    if (_currentDay == null) return;
    List<String> globalGroupNames =
        await _globalSettingsService.getGlobalGroupNames();
    if (globalGroupNames.contains(newGroupName)) return;
    globalGroupNames.add(newGroupName);
    await _globalSettingsService.setGlobalGroupNames(globalGroupNames);

    _currentDay!.groupCounts[newGroupName] = 0;
    notifyListeners();
    await _storageService.saveDayRecord(_currentDay!);
  }

  Future<List<DayRecord>> getHistory() async {
    return await _storageService.getHistory();
  }

  // This method resets the current data by clearing the current day and reinitializing.
  Future<void> resetData() async {
    _currentDay = null;
    await _initDayRecord();
    notifyListeners();
  }
}
