import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fl_chart/fl_chart.dart'; // Import fl_chart
import 'dart:math'; // For random colors

import 'task_model.dart';
import 'focus_log_model.dart'; // <-- Import Log Model
import 'main.dart'; // Import to access boxNames
import 'notification.dart'; // Import NotificationService

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  int touchedIndex = -1; // For Pie Chart interaction
  Map<String, double> categoryFocusTime = {};
  double totalFocusSeconds = 0;
  final Map<String, Color> _categoryColors = {}; // Store category colors here

  @override
  void initState() {
    super.initState();
    // Calculate initial times and assign initial colors
    _calculateFocusTimesAndAssignColors();
  }

  // Combined method to calculate times and assign persistent colors
  void _calculateFocusTimesAndAssignColors() {
    final Box<FocusSessionLog> logBox = Hive.box<FocusSessionLog>(
      focusLogBoxName,
    );
    final allLogs = logBox.values;
    categoryFocusTime.clear();
    totalFocusSeconds = 0;
    // Temporary set to keep track of categories encountered in this calculation
    Set<String> currentCategories = {};

    for (var log in allLogs) {
      currentCategories.add(log.categoryName);
      categoryFocusTime.update(
        log.categoryName,
        (value) => value + log.durationSeconds,
        ifAbsent: () => log.durationSeconds.toDouble(),
      );
      totalFocusSeconds += log.durationSeconds;

      // Assign color only if category is new and doesn't have one
      if (!_categoryColors.containsKey(log.categoryName)) {
        _categoryColors[log.categoryName] = _getRandomColor();
      }
    }
    // Optional: Remove colors for categories that no longer exist (if needed)
    // _categoryColors.removeWhere((key, value) => !currentCategories.contains(key));

    // Sort categoryFocusTime by category name for consistent color assignment order if needed
    // Or sort by value later if desired for display order
    /* categoryFocusTime = Map.fromEntries(
        categoryFocusTime.entries.toList()
        ..sort((e1, e2) => e1.key.compareTo(e2.key))
     ); */

    // No need to call setState here if only called from initState initially
    // If called later to update, would need setState
  }

  // Helper to generate random colors for pie chart sections
  final _random = Random();

  Color _getRandomColor() {
    return Color.fromRGBO(
      _random.nextInt(200) + 55, // Avoid very dark colors
      _random.nextInt(200) + 55,
      _random.nextInt(200) + 55,
      1,
    );
  }

  String get _summaryText {
    if (categoryFocusTime.isEmpty) {
      return 'No focus time was spent!';
    }

    final parts =
        categoryFocusTime.entries.map((entry) {
          final minutes = (entry.value / 60).toStringAsFixed(1);
          return '${entry.key}: ${minutes}minutes';
        }).toList();
    return 'The time you focused: ${parts.join('，')}'
        ' Keep up the good work!';
  }

  void _sendSummaryNotification() {
    NotificationService().showNotification(
      id: 200,
      title: 'Weekly Report!',
      body: _summaryText,
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- Recalculate Focus Times ---
    // Calculation based on logs needs to happen here or be triggered by ValueListenableBuilder
    // For simplicity on build for now:
    _calculateFocusTimesAndAssignColors();

    // --- Calculate Task Stats (Still need Task Box) ---
    final Box<Task> taskBox = Hive.box<Task>(taskBoxName);
    final allTasks = taskBox.values.toList();
    final totalTasks = allTasks.length;
    final completedTasks = allTasks.where((task) => task.isCompleted).length;
    final completionRate =
        totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0.0;

    // Declare sortedCategories here, outside the if block
    List<String> sortedCategories = [];

    // Generate Pie Chart Data
    List<PieChartSectionData> pieSections = [];
    if (totalFocusSeconds > 0) {
      // Populate sortedCategories inside the if block
      sortedCategories = categoryFocusTime.keys.toList();
      // Optional: Sort categories alphabetically or by time for consistent display
      // sortedCategories.sort((a, b) => a.compareTo(b)); // Alphabetical sort example

      for (int i = 0; i < sortedCategories.length; i++) {
        String category = sortedCategories[i];
        double seconds = categoryFocusTime[category]!;
        final isTouched = i == touchedIndex;
        final fontSize = isTouched ? 18.0 : 14.0;
        final radius = isTouched ? 60.0 : 50.0;
        final value = (seconds / totalFocusSeconds) * 100;
        // Use the stored color
        final color =
            _categoryColors[category] ??
            _getRandomColor(); // Fallback just in case

        pieSections.add(
          PieChartSectionData(
            color: color,
            value: value,
            title: '${value.toStringAsFixed(1)}%',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: const Color(0xffffffff),
              shadows: [
                Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 2),
              ],
            ),
            badgeWidget:
                isTouched ? _buildCategoryBadge(category, color) : null,
            badgePositionPercentageOffset: .98,
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text("Statistics")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: <Widget>[
            Text(
              "Task Overview",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.list_alt),
              title: Text("Total Tasks Created"),
              trailing: Text(
                "$totalTasks",
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ListTile(
              leading: Icon(Icons.check_circle_outline),
              title: Text("Tasks Completed"),
              trailing: Text(
                "$completedTasks",
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ListTile(
              leading: Icon(Icons.show_chart),
              title: Text("Completion Rate"),
              trailing: Text(
                "${completionRate.toStringAsFixed(1)}%",
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Divider(height: 32),

            Text(
              "Focus Time by Category",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 16),
            if (totalFocusSeconds > 0)
              SizedBox(
                height: 200, // Define height for the chart
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            touchedIndex = -1;
                            return;
                          }
                          touchedIndex =
                              pieTouchResponse
                                  .touchedSection!
                                  .touchedSectionIndex;
                        });
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: pieSections,
                  ),
                  swapAnimationDuration: Duration(milliseconds: 150),
                  // Optional
                  swapAnimationCurve: Curves.linear, // Optional
                ),
              )
            else
              Center(
                child: Text(
                  "No focus time recorded yet.",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            SizedBox(height: 16),
            // Now sortedCategories is accessible here
            if (totalFocusSeconds > 0)
              ..._buildLegend(pieSections, sortedCategories),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Trigger notification
          _sendSummaryNotification();
        },
        child: Icon(Icons.notifications),
        tooltip: "Send Weekly Summary",
      ),
    );
  }

  // Helper to build category badge on touch
  Widget _buildCategoryBadge(String category, Color color) {
    return Material(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      color: color,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          category,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Updated _buildLegend to potentially use sorted categories
  List<Widget> _buildLegend(
    List<PieChartSectionData> sections,
    List<String> categories,
  ) {
    List<Widget> legendItems = [];
    for (int i = 0; i < sections.length; i++) {
      // Ensure index is valid for categories list
      if (i < categories.length) {
        String category = categories[i];
        legendItems.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Row(
              children: [
                Container(width: 16, height: 16, color: sections[i].color),
                SizedBox(width: 8),
                Text(category),
                Spacer(),
                // Use category name to lookup time, ensuring it exists
                Text(
                  "${(categoryFocusTime[category]! / 60).toStringAsFixed(1)} min",
                ),
              ],
            ),
          ),
        );
      }
    }
    return legendItems;
  }
}
