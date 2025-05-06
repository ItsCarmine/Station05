import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart'; // For date formatting

import 'focus_log_model.dart';
import 'goal_model.dart'; // May need for category info if not passed
import 'main.dart'; // For box names & ID generator

// Move helper functions outside of classes to make them accessible globally
Widget getStatusIcon(FocusSessionStatus status) {
  switch (status) {
    case FocusSessionStatus.completed:
      return Icon(Icons.check_circle, color: Colors.green);
    case FocusSessionStatus.failed:
      return Icon(Icons.cancel, color: Colors.red);
    case FocusSessionStatus.inProgress:
      return Icon(Icons.timelapse, color: Colors.orange);
    case FocusSessionStatus.skipped:
      return Icon(Icons.skip_next, color: Colors.grey);
    default:
      return Icon(Icons.timer_outlined);
  }
}

Widget getStatusChip(FocusSessionStatus status) {
  Color chipColor;
  String label;
  
  switch (status) {
    case FocusSessionStatus.completed:
      chipColor = Colors.green.shade100;
      label = 'Completed';
      break;
    case FocusSessionStatus.failed:
      chipColor = Colors.red.shade100;
      label = 'Failed';
      break;
    case FocusSessionStatus.inProgress:
      chipColor = Colors.orange.shade100;
      label = 'In Progress';
      break;
    case FocusSessionStatus.skipped:
      chipColor = Colors.grey.shade200;
      label = 'Skipped';
      break;
    default:
      chipColor = Colors.blue.shade100;
      label = 'Unknown';
  }
  
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: chipColor,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 12),
    ),
  );
}

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  _LogScreenState createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  late Box<FocusSessionLog> logBox;
  late Box<String> categoryBox;

  @override
  void initState() {
    super.initState();
    logBox = Hive.box<FocusSessionLog>(focusLogBoxName);
    categoryBox = Hive.box<String>(categoryBoxName); // Needed for adding entries
  }

  // Helper to format duration
  String _formatDuration(int totalSeconds) {
    final duration = Duration(seconds: totalSeconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours h ${minutes.toString().padLeft(2, '0')} min';
    } else if (minutes > 0) {
      return '$minutes min ${seconds.toString().padLeft(2, '0')} sec';
    } else {
      return '$seconds sec';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Focus Log"),
        actions: [
          // Add filter option
          PopupMenuButton<String>(
            icon: Icon(Icons.filter_list),
            tooltip: 'Filter by Status',
            onSelected: (value) {
              setState(() {
                // Implement filter logic here if needed
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'all',
                child: Text('All Sessions'),
              ),
              PopupMenuItem<String>(
                value: 'completed',
                child: Text('Completed Only'),
              ),
              PopupMenuItem<String>(
                value: 'failed',
                child: Text('Failed Only'),
              ),
            ],
          )
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: logBox.listenable(),
        builder: (context, Box<FocusSessionLog> box, _) {
          if (box.values.isEmpty) {
            return Center(
              child: Text(
                "No focus sessions logged yet.\nUse the Focus Timer or tap '+' to add manually.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          // Sort logs by start time, newest first
          var sortedLogs = box.values.toList()
            ..sort((a, b) => b.startTime.compareTo(a.startTime));

          // Debug: Print all logs with their statuses
          for (var log in sortedLogs) {
            print("Log: ${log.id}, Category: ${log.categoryName}, Status: ${log.status}, Date: ${log.startTime}");
          }

          return ListView.builder(
            itemCount: sortedLogs.length,
            itemBuilder: (context, index) {
              final log = sortedLogs[index];
              
              // Background color based on status
              Color? backgroundColor;
              if (log.status == FocusSessionStatus.failed) {
                backgroundColor = Colors.red.shade50;
              } else if (log.status == FocusSessionStatus.completed) {
                backgroundColor = Colors.green.shade50;
              }
              
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: backgroundColor,
                child: ListTile(
                  leading: getStatusIcon(log.status), // Using the global function
                  title: Row(
                    children: [
                      Expanded(child: Text(log.categoryName)),
                      SizedBox(width: 8),
                      getStatusChip(log.status), // Using the global function
                    ],
                  ),
                  subtitle: Text(
                    "${DateFormat.yMd().add_jm().format(log.startTime)} - ${_formatDuration(log.durationSeconds)}",
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete_outline),
                    onPressed: () => _confirmDeleteLogEntry(context, log),
                  ),
                  onTap: () {
                    // Show details dialog if needed
                    _showLogDetailsDialog(context, log);
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add Manual Log Entry',
        onPressed: () => _showAddLogEntryDialog(context),
        child: Icon(Icons.add_comment_outlined),
      ),
    );
  }

  // New method to show log details
  void _showLogDetailsDialog(BuildContext context, FocusSessionLog log) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Focus Session Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                title: Text('Category'),
                subtitle: Text(log.categoryName),
              ),
              ListTile(
                title: Text('Date'),
                subtitle: Text(DateFormat.yMd().format(log.startTime)),
              ),
              ListTile(
                title: Text('Time'),
                subtitle: Text(DateFormat.jm().format(log.startTime)),
              ),
              ListTile(
                title: Text('Duration'),
                subtitle: Text(_formatDuration(log.durationSeconds)),
              ),
              ListTile(
                title: Text('Status'),
                subtitle: Row(
                  children: [
                    getStatusIcon(log.status), // Using the global function
                    SizedBox(width: 8),
                    Text(log.status.toString().split('.').last),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // --- Dialogs and Helper Functions --- 

  void _showAddLogEntryDialog(BuildContext context) {
    if (categoryBox.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please create a task category first.")),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Add Manual Log Entry"),
          content: _AddLogEntryDialogContent(
            availableCategories: categoryBox.values.toList(),
            onLogAdded: (category, date, durationMinutes, status) {
              final seconds = (durationMinutes * 60).round();
              // Use DateUtils.dateOnly to ensure startTime is at the beginning of the day
              final startTime = date;
              final newLog = FocusSessionLog(
                id: generateUniqueId(), // Use the global helper
                categoryName: category,
                startTime: startTime, 
                durationSeconds: seconds,
                status: status, // Use the provided status
              );
              logBox.put(newLog.id, newLog);
              Navigator.of(context).pop(); // Close dialog
              ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(content: Text('Manual log entry added for "$category".')), 
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteLogEntry(BuildContext context, FocusSessionLog log) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Text('Delete Log Entry?'),
          content: Text('Are you sure you want to delete this ${log.categoryName} entry from ${DateFormat.yMd().format(log.startTime)}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                logBox.delete(log.id);
                 ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Log entry deleted.'), duration: Duration(seconds: 2)),
                );
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}

// --- Helper Widget for Add Log Entry Dialog ---

class _AddLogEntryDialogContent extends StatefulWidget {
  final List<String> availableCategories;
  // Takes category, date, duration in minutes, and status
  final Function(String category, DateTime date, double durationMinutes, FocusSessionStatus status) onLogAdded;

  const _AddLogEntryDialogContent({
    super.key,
    required this.availableCategories,
    required this.onLogAdded,
  });

  @override
  _AddLogEntryDialogContentState createState() => _AddLogEntryDialogContentState();
}

class _AddLogEntryDialogContentState extends State<_AddLogEntryDialogContent> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now(); // Default to today
  TimeOfDay _selectedTime = TimeOfDay.now(); // Default to current time
  double? _durationMinutes;
  FocusSessionStatus _status = FocusSessionStatus.completed; // Default status

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000), 
      lastDate: DateTime.now().add(Duration(days: 1)), // Allow up to tomorrow for timezone safety?
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Category Dropdown
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              hint: Text("Select Category"),
              items: widget.availableCategories
                  .map((category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
              validator: (value) =>
                  value == null ? 'Please select a category' : null,
              onSaved: (value) => _selectedCategory = value,
            ),
            SizedBox(height: 16),
            // Date Picker
            Text("Date:"),
            InkWell(
              onTap: () => _pickDate(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 18),
                    SizedBox(width: 8),
                    Text(DateFormat.yMd().format(_selectedDate)),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            // Time Picker
            Text("Time:"),
            InkWell(
              onTap: () => _pickTime(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.access_time, size: 18),
                    SizedBox(width: 8),
                    Text(_selectedTime.format(context)),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            // Duration Input (Minutes)
            TextFormField(
              decoration: InputDecoration(labelText: 'Duration (minutes)'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter duration';
                }
                final minutes = double.tryParse(value);
                if (minutes == null || minutes <= 0) {
                  return 'Please enter a positive number for minutes';
                }
                return null;
              },
              onSaved: (value) => _durationMinutes = double.tryParse(value!),
            ),
            SizedBox(height: 16),
            // Status Selection
            Text("Session Status:"),
            DropdownButtonFormField<FocusSessionStatus>(
              value: _status,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _status = value;
                  });
                }
              },
              items: FocusSessionStatus.values.map((status) {
                String label = status.toString().split('.').last;
                // Capitalize first letter
                label = label[0].toUpperCase() + label.substring(1);
                
                return DropdownMenuItem<FocusSessionStatus>(
                  value: status,
                  child: Row(
                    children: [
                      getStatusIcon(status), // Using the global function
                      SizedBox(width: 8),
                      Text(label),
                    ],
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            // Add Button
            Center(
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    if (_selectedCategory != null && _durationMinutes != null) {
                      // Combine date and time
                      final combinedDateTime = DateTime(
                        _selectedDate.year,
                        _selectedDate.month,
                        _selectedDate.day,
                        _selectedTime.hour,
                        _selectedTime.minute,
                      );
                      
                      widget.onLogAdded(_selectedCategory!, combinedDateTime, _durationMinutes!, _status);
                    }
                  }
                },
                child: Text("Add Log Entry"),
              ),
            )
          ],
        ),
      ),
    );
  }
}

