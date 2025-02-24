import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/day_record.dart';
import '../providers/daily_counter_provider.dart';
import 'history_screen.dart';

// Service to clear all app data from SharedPreferences.
class DataResetService {
  Future<void> clearAllAppData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Default selected group is "HK"
  String _selectedGroup = "HK";

  // Dialog to reset all data after verifying the password.
  void _showResetDialog(BuildContext context) {
    TextEditingController _passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Reset Data"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Enter password to reset all data:"),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: "Password"),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: Text("Reset"),
              onPressed: () async {
                if (_passwordController.text == "Sahitya@2005") {
                  await DataResetService().clearAllAppData();
                  await Provider.of<DailyCounterProvider>(context,
                          listen: false)
                      .resetData();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Data has been reset.")),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Incorrect password.")),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Dialog to rename an existing group.
  void _showRenameDialog(BuildContext context, String oldName) {
    TextEditingController _controller = TextEditingController(text: oldName);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Rename Group"),
          content: TextField(
            controller: _controller,
            decoration: InputDecoration(labelText: "New Group Name"),
          ),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: Text("Rename"),
              onPressed: () {
                String newName = _controller.text.trim();
                if (newName.isNotEmpty) {
                  Provider.of<DailyCounterProvider>(context, listen: false)
                      .renameGroup(oldName, newName);
                  if (_selectedGroup == oldName) {
                    setState(() {
                      _selectedGroup = newName;
                    });
                  }
                }
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  // Dialog to add a new group.
  void _showAddGroupDialog(BuildContext context) {
    TextEditingController _controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Add New Group"),
          content: TextField(
            controller: _controller,
            decoration: InputDecoration(labelText: "Group Name"),
          ),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: Text("Add"),
              onPressed: () {
                String newGroup = _controller.text.trim();
                if (newGroup.isNotEmpty) {
                  Provider.of<DailyCounterProvider>(context, listen: false)
                      .addGroup(newGroup);
                  setState(() {
                    _selectedGroup = newGroup;
                  });
                }
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  // Helper method to compute total counts across all records.
  Map<String, int> _computeTotalCounts(List<DayRecord> history) {
    Map<String, int> totals = {};
    for (var record in history) {
      record.groupCounts.forEach((group, count) {
        totals[group] = (totals[group] ?? 0) + count;
      });
    }
    return totals;
  }

  @override
  Widget build(BuildContext context) {
    final dailyCounter = Provider.of<DailyCounterProvider>(context);

    if (dailyCounter.currentDay == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Daily Counter')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    int currentCount =
        dailyCounter.currentDay!.groupCounts[_selectedGroup] ?? 0;
    String formattedDate =
        DateFormat('yyyy-MM-dd').format(dailyCounter.currentDay!.date);

    return Scaffold(
      appBar: AppBar(title: Text('Daily Counter')),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Drawer header.
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text('Options',
                  style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            // ExpansionTile for selecting and renaming groups.
            ExpansionTile(
              title: Text('Select Group'),
              children:
                  dailyCounter.currentDay!.groupCounts.keys.map((groupName) {
                return ListTile(
                  title: Text(groupName),
                  selected: groupName == _selectedGroup,
                  trailing: IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () => _showRenameDialog(context, groupName),
                  ),
                  onTap: () {
                    setState(() {
                      _selectedGroup = groupName;
                    });
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
            // Option to add a new group.
            ListTile(
              leading: Icon(Icons.add),
              title: Text('Add Group'),
              onTap: () {
                Navigator.pop(context);
                _showAddGroupDialog(context);
              },
            ),
            // ExpansionTile to display total counts by group.
            ExpansionTile(
              title: const Text('Total Count by Group'),
              children: [
                FutureBuilder<List<DayRecord>>(
                  future: dailyCounter.getHistory(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const ListTile(title: Text("Loading totals..."));
                    } else if (snapshot.hasError) {
                      return const ListTile(
                          title: Text("Error loading totals"));
                    } else {
                      List<DayRecord> history = snapshot.data!;
                      Map<String, int> totals = _computeTotalCounts(history);
                      return Column(
                        children: totals.entries.map((entry) {
                          return ListTile(
                              title: Text('${entry.key}: ${entry.value}'));
                        }).toList(),
                      );
                    }
                  },
                ),
              ],
            ),
            // Option to change the date.
            ListTile(
              leading: Icon(Icons.date_range),
              title: Text('Change Date'),
              onTap: () async {
                Navigator.pop(context);
                DateTime? selectedDate = await showDatePicker(
                  context: context,
                  initialDate: dailyCounter.currentDay!.date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (selectedDate != null) {
                  await dailyCounter.changeDate(selectedDate);
                  setState(() {
                    if (!dailyCounter.currentDay!.groupCounts
                        .containsKey(_selectedGroup)) {
                      _selectedGroup =
                          dailyCounter.currentDay!.groupCounts.keys.first;
                    }
                  });
                }
              },
            ),
            // Option to view history.
            ListTile(
              leading: Icon(Icons.history),
              title: Text('View History'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => HistoryScreen()),
                );
              },
            ),
            // Reset Data option requiring a password.
            ListTile(
              leading: Icon(Icons.delete),
              title: Text('Reset Data'),
              onTap: () {
                Navigator.pop(context);
                _showResetDialog(context);
              },
            ),
          ],
        ),
      ),
      // Full-screen GestureDetector: any tap increases the count.
      body: GestureDetector(
        onTap: () {
          dailyCounter.incrementGroup(_selectedGroup);
        },
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.transparent,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Date: $formattedDate', style: TextStyle(fontSize: 24)),
                SizedBox(height: 20),
                Text('Group: $_selectedGroup', style: TextStyle(fontSize: 24)),
                SizedBox(height: 20),
                Text('Count: $currentCount',
                    style:
                        TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
