import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Use hive_flutter for builders
import 'goal_model.dart';
import 'task_model.dart'; // <-- No longer needed for totalSecondsFocused
import 'focus_log_model.dart'; // <-- Import Log model
import 'main.dart'; // For box names
import 'package:intl/intl.dart';

// Helper function to get the start of the current week (Monday)
DateTime _getStartOfWeek(DateTime date) {
  int daysToSubtract = date.weekday - DateTime.monday;
  if (daysToSubtract < 0) {
    daysToSubtract += 7; // Adjust if today is Sunday
  }
  return DateUtils.dateOnly(date.subtract(Duration(days: daysToSubtract)));
}

// Helper function to get the end of the current week (Sunday)
DateTime _getEndOfWeek(DateTime date) {
  int daysToAdd = DateTime.sunday - date.weekday;
  if (daysToAdd < 0) {
    daysToAdd += 7; // Adjust if today is Sunday
  }
  // Add 1 day to make it inclusive until the end of Sunday
  return DateUtils.dateOnly(date.add(Duration(days: daysToAdd + 1))); 
}

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  _GoalsScreenState createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  late Box<Goal> goalBox;
  late Box<String> categoryBox;
  late Box<FocusSessionLog> logBox;

  late DateTime _displayWeekStart; // <-- Add state for displayed week

  @override
  void initState() {
    super.initState();
    goalBox = Hive.box<Goal>(goalBoxName);
    categoryBox = Hive.box<String>(categoryBoxName);
    logBox = Hive.box<FocusSessionLog>(focusLogBoxName);
    _displayWeekStart = _getStartOfWeek(DateTime.now()); // <-- Initialize to current week
  }

  @override
  Widget build(BuildContext context) {
    // Determine if the displayed week is the current week
    final bool isCurrentWeek = _getStartOfWeek(DateTime.now()) == _displayWeekStart;
    // Calculate the end date for display purposes (Sunday of the displayed week)
    final displayWeekEnd = _displayWeekStart.add(Duration(days: 6)); 

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Weekly Goals"),
            Text(
              "Week: ${DateFormat.Md().format(_displayWeekStart)} - ${DateFormat.Md().format(displayWeekEnd)}",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.chevron_left),
            tooltip: 'Previous Week',
            onPressed: () {
              setState(() {
                _displayWeekStart = _displayWeekStart.subtract(Duration(days: 7));
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.chevron_right),
            tooltip: 'Next Week',
            // Disable if viewing the current week
            onPressed: isCurrentWeek ? null : () {
              setState(() {
                _displayWeekStart = _displayWeekStart.add(Duration(days: 7));
              });
            },
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: goalBox.listenable(),
        builder: (context, Box<Goal> goalBoxSnapshot, _) {
          return ValueListenableBuilder(
            valueListenable: logBox.listenable(),
            builder: (context, Box<FocusSessionLog> logBoxSnapshot, _) {
              // Get displayed week boundaries
              final startOfWeek = _displayWeekStart; // Use state variable
              // Use the helper to get the end, ensures correct handling across year/month boundaries
              final endOfWeek = _getEndOfWeek(_displayWeekStart); 

              if (goalBoxSnapshot.values.isEmpty) {
                return Center(
                  child: Text(
                    "No goals set yet.\nTap '+' to add your first goal!",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                );
              }

              // Build the list of goals here
              return ListView.builder(
                itemCount: goalBoxSnapshot.values.length,
                itemBuilder: (context, index) {
                  final goal = goalBoxSnapshot.getAt(index);
                  if (goal == null) return SizedBox.shrink(); // Should not happen

                  // --- Calculate Weekly Focus Time ---
                  final logsThisWeekForCategory = logBoxSnapshot.values.where((log) => 
                      log.categoryName == goal.categoryName && 
                      log.startTime.isAfter(startOfWeek) && 
                      log.startTime.isBefore(endOfWeek)
                  );

                  int totalSecondsFocusedThisWeek = logsThisWeekForCategory
                      .fold(0, (sum, log) => sum + log.durationSeconds);
                  double totalHoursFocusedThisWeek = totalSecondsFocusedThisWeek / 3600.0;
                  // ------------------------------------

                  // Calculate progress (clamp between 0.0 and 1.0)
                  double progress = 0.0;
                  if (goal.weeklyTargetSeconds > 0) {
                    progress = (totalSecondsFocusedThisWeek / goal.weeklyTargetSeconds).clamp(0.0, 1.0);
                  }

                  // Display goal information
                  return ListTile(
                    title: Text(goal.categoryName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${goal.weeklyTargetHours.toStringAsFixed(1)} hours / week goal"),
                        SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                          minHeight: 6, // Make the bar a bit thicker
                        ),
                        SizedBox(height: 4),
                        Text(
                          // Updated text to be more generic
                          "${totalHoursFocusedThisWeek.toStringAsFixed(1)} hours logged for week", 
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline, color: Colors.redAccent),
                      tooltip: 'Delete Goal',
                      onPressed: () => _confirmDeleteGoal(context, goal),
                    ),
                    // TODO: Add onTap to edit?
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add New Goal',
        onPressed: () => _showAddGoalDialog(context),
        child: Icon(Icons.add),
      ),
    );
  }

  // --- Dialogs and Helper Functions (Implement Below) ---

  void _showAddGoalDialog(BuildContext context) {
    // Get available categories (those not already having a goal)
    final existingGoalCategories = goalBox.keys.cast<String>().toSet();
    final availableCategories = categoryBox.values
        .where((category) => !existingGoalCategories.contains(category))
        .toList();

    if (availableCategories.isEmpty && categoryBox.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("All categories already have goals set.")),
      );
      return;
    } else if (categoryBox.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please create a task category first.")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Add Weekly Goal"),
          content: _AddGoalDialogContent(
            availableCategories: availableCategories,
            onGoalAdded: (category, hours) {
              final seconds = (hours * 3600).round(); // Convert hours to seconds
              final newGoal = Goal(
                id: category, // Use category name as ID
                categoryName: category,
                weeklyTargetSeconds: seconds,
              );
              goalBox.put(newGoal.id, newGoal);
              Navigator.of(context).pop(); // Close dialog
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Goal added for "$category".')), 
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

  void _confirmDeleteGoal(BuildContext context, Goal goal) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Text('Delete Goal for "${goal.categoryName}"?'),
          content: Text('Are you sure you want to delete this weekly goal?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(), // Just close the confirmation
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop(); // Close the confirmation
                goalBox.delete(goal.id); // Delete using categoryName as ID
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Goal for "${goal.categoryName}" deleted.'), duration: Duration(seconds: 2)),
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

// --- Helper Widget for Add Goal Dialog Content ---

class _AddGoalDialogContent extends StatefulWidget {
  final List<String> availableCategories;
  final Function(String category, double hours) onGoalAdded;

  const _AddGoalDialogContent({
    super.key,
    required this.availableCategories,
    required this.onGoalAdded,
  });

  @override
  _AddGoalDialogContentState createState() => _AddGoalDialogContentState();
}

class _AddGoalDialogContentState extends State<_AddGoalDialogContent> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedCategory;
  double? _targetHours;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            // Target Hours Input
            TextFormField(
              decoration: InputDecoration(labelText: 'Weekly Target Hours'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter target hours';
                }
                final hours = double.tryParse(value);
                if (hours == null || hours <= 0) {
                  return 'Please enter a positive number for hours';
                }
                return null;
              },
              onSaved: (value) => _targetHours = double.tryParse(value!),
            ),
            SizedBox(height: 20),
            // Add Button (within dialog)
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  if (_selectedCategory != null && _targetHours != null) {
                    widget.onGoalAdded(_selectedCategory!, _targetHours!); 
                  }
                }
              },
              child: Text("Add Goal"),
            )
          ],
        ),
      ),
    );
  }
} 