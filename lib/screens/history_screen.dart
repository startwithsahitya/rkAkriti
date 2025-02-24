import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/day_record.dart';
import '../providers/daily_counter_provider.dart';
import 'package:provider/provider.dart';

class HistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final dailyCounter =
        Provider.of<DailyCounterProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: Text('History')),
      body: FutureBuilder<List<DayRecord>>(
        future: dailyCounter.getHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading history'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No history available'));
          } else {
            List<DayRecord> history = snapshot.data!;
            return ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) {
                final record = history[index];
                return ListTile(
                  title: Text(DateFormat('yyyy-MM-dd').format(record.date)),
                  subtitle: Text(
                    record.groupCounts.entries
                        .map((e) => '${e.key}: ${e.value}')
                        .join(', '),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
