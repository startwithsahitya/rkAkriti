class DayRecord {
  DateTime date;
  Map<String, int> groupCounts;

  DayRecord({required this.date, required this.groupCounts});

  factory DayRecord.fromJson(Map<String, dynamic> json) {
    return DayRecord(
      date: DateTime.parse(json['date']),
      groupCounts: Map<String, int>.from(json['groupCounts']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'groupCounts': groupCounts,
    };
  }
}
