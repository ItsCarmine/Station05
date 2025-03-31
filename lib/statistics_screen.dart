import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'task_model.dart';
import 'main.dart'; // Import to access taskBoxName

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Access the Hive box directly
    final Box<Task> taskBox = Hive.box<Task>(taskBoxName);
    final allTasks = taskBox.values.toList();

    // Calculate statistics
    final totalTasks = allTasks.length;
    final completedTasks = allTasks.where((task) => task.isCompleted).length;
    final completionRate = totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0.0;

    // --- More stats ideas ---
    // - Tasks completed today/this week
    // - Tasks per category
    // - Average completion time (would need to store start/end times)
    // - Pomodoro sessions completed (would need to store focus session data)

    return Scaffold(
      appBar: AppBar(
        title: Text("Statistics"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView( // Use ListView for potential future expansion
          children: <Widget>[
            Text(
              "Task Overview",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.list_alt),
              title: Text("Total Tasks Created"),
              trailing: Text("$totalTasks", style: Theme.of(context).textTheme.titleLarge),
            ),
            ListTile(
              leading: Icon(Icons.check_circle_outline),
              title: Text("Tasks Completed"),
              trailing: Text("$completedTasks", style: Theme.of(context).textTheme.titleLarge),
            ),
            ListTile(
              leading: Icon(Icons.show_chart),
              title: Text("Completion Rate"),
              trailing: Text("${completionRate.toStringAsFixed(1)}%", style: Theme.of(context).textTheme.titleLarge),
            ),
            Divider(height: 32),
            // Add more stats sections here later
             Text(
              "More statistics coming soon!",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
} 