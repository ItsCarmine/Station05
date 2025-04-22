import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'task_model.dart'; // Import the new Task model
import 'dart:math'; // For generating random IDs
import 'package:hive_flutter/hive_flutter.dart'; // Import Hive Flutter
import 'package:path_provider/path_provider.dart'; // Import Path Provider
import 'focus_screen.dart'; // Import the FocusScreen
import 'statistics_screen.dart'; // Import the StatisticsScreen
import 'splash_screen.dart';
import 'duo_character.dart';
import 'package:flutter/services.dart'; // Import SystemChrome
import 'edit_task_screen.dart'; // Import the new edit screen

// Define box names
const String taskBoxName = 'tasks';
const String categoryBoxName = 'categories';


class NoTitle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: true,
      home: SplashToAppWrapper(), // Changed from direct todoScreen
    );
  }
}

class SplashToAppWrapper extends StatefulWidget {
  @override
  _SplashToAppWrapperState createState() => _SplashToAppWrapperState();
}


class _SplashToAppWrapperState extends State<SplashToAppWrapper> {
  bool _showSplash = true;
  bool _showCharacter = false;

  void _completeSplash() {
    setState(() {
      _showSplash = false;
      _showCharacter = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main app content (always present but behind splash)
        todoScreen(),

        // Splash screen (on top when active)
        if (_showSplash)
          SplashScreen(
            onAnimationComplete: _completeSplash,
          ),

        // Small character in corner (after splash)
        if (_showCharacter)
          Positioned(
            left: 40,
            bottom: 40,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DuoCharacter(size: 60, isJumping: true),
              ],
            ),
          ),
      ],
    );
  }
}

Future<void> main() async { // Make main async
  WidgetsFlutterBinding.ensureInitialized(); // Ensure bindings are initialized

  // --- Set Preferred Orientations ---
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  // ----------------------------------

  // Initialize Hive
  final appDocumentDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocumentDir.path);

  // --- START FIX: Delete old boxes before opening ---
  // Warning: This deletes existing data!
  await Hive.deleteBoxFromDisk(taskBoxName);
  await Hive.deleteBoxFromDisk(categoryBoxName);
  print("Cleared old Hive boxes (taskBoxName, categoryBoxName) for compatibility.");
  // --- END FIX ---

  // Register Adapter
  Hive.registerAdapter(TaskAdapter());

  // Open boxes (now guaranteed to be empty or compatible)
  await Hive.openBox<Task>(taskBoxName);
  await Hive.openBox<String>(categoryBoxName); // Box to store category names

  runApp(NoTitle());
}

// --- Move helper function outside class if it doesn't depend on instance state ---
// Helper to generate unique IDs for tasks (doesn't need instance state)
String _generateUniqueId() {
  return DateTime.now().millisecondsSinceEpoch.toString() + Random().nextInt(1000).toString();
}

// class NoTitle extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(debugShowCheckedModeBanner: true, home: todoScreen());
//   }
// }

class todoScreen extends StatefulWidget {
  @override
  todoScreenState createState() => todoScreenState();
}

class todoScreenState extends State<todoScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();

  // Get Hive boxes
  late Box<Task> taskBox;
  late Box<String> categoryBox;

  // Keep the map for easy access in UI, but populate from Hive
  Map<String, List<Task>> tasksByCategory = {};

  @override
  void initState() {
    super.initState();
    taskBox = Hive.box<Task>(taskBoxName);
    categoryBox = Hive.box<String>(categoryBoxName);
    _loadTasksAndCategories();
  }

  void _loadTasksAndCategories() {
    // Clear existing map
    tasksByCategory.clear();

    // Load categories
    List<String> categories = categoryBox.values.toList();

    // Load tasks and group them by category
    final allTasks = taskBox.values.toList();

    for (String category in categories) {
      tasksByCategory[category] = allTasks.where((task) => task.category == category).toList();
    }
    // Ensure all categories from tasks are present, even if the category name wasn't explicitly saved
    // (This handles potential data inconsistency if categoryBox wasn't updated)
    for (Task task in allTasks) {
        if (!tasksByCategory.containsKey(task.category)) {
            tasksByCategory[task.category] = [task];
            // Optionally, add the missing category name to categoryBox here if desired
            // if (!categoryBox.values.contains(task.category)) { 
            //    categoryBox.add(task.category);
            // } 
        }
    }

    // Trigger a rebuild if needed after loading
    setState(() {}); 
  }

  // Get tasks for the currently selected date
  List<Task> _getTasksForSelectedDate() {
    return taskBox.values.where((task) {
      // Only include top-level tasks initially
      if (task.parentId != null) {
        return false;
      }

      final selectedDay = _selectedDate;

      if (task.isRecurring) {
        // Show if:
        // 1. It was completed on the selected day.
        // OR
        // 2. The selected day is a valid recurrence instance date according to the schedule.
        final bool wasCompletedOnSelectedDay = task.completionDates.any((d) => DateUtils.isSameDay(d, selectedDay));
        final bool isScheduledForSelectedDay = _isDateARecurrenceInstance(task, selectedDay);

        return wasCompletedOnSelectedDay || isScheduledForSelectedDay;

      } else {
        // Non-recurring: Show if its due date is the selected date
        return DateUtils.isSameDay(task.dueDate, selectedDay);
      }
    }).toList();
  }

  // --- Helper to check if a date is a valid recurrence instance --- 
  bool _isDateARecurrenceInstance(Task task, DateTime dateToCheck) {
      if (!task.isRecurring) return false;
      if (DateUtils.isSameDay(dateToCheck, task.dueDate)) return true; // Always show on the current due date
      if (dateToCheck.isBefore(task.dueDate) && task.completionDates.any((d) => DateUtils.isSameDay(d, dateToCheck)) ){
         // If checking a past date that was completed, it was an instance
         return true;
      }
      
      // More robust check based on original due date (or first completion?) and rules
      // This requires knowing the *original* start date, which we don't explicitly store.
      // Let's assume the *first* completion date or the current due date if no completions yet,
      // gives us a reference point.
      DateTime referenceDate = task.completionDates.isNotEmpty 
          ? task.completionDates.first // Use first completion as anchor?
          : task.dueDate; // Or current due date if never completed
      
      // Adjust referenceDate to be on or before dateToCheck
      if(referenceDate.isAfter(dateToCheck)) {
         // This scenario is complex - trying to determine past instances without a fixed start date.
         // For now, let's rely on the primary checks above (is current due date or was completed).
         // A true start date field would be needed for full historical accuracy.
         return DateUtils.isSameDay(dateToCheck, task.dueDate);
      }

      if (task.recurrenceType == 'daily') {
          int daysDifference = dateToCheck.difference(referenceDate).inDays;
          return daysDifference >= 0 && daysDifference % task.recurrenceInterval == 0;
      } else if (task.recurrenceType == 'weekly') {
          if (!task.recurrenceDaysOfWeek.contains(dateToCheck.weekday)) {
             return false; // Doesn't fall on a selected weekday
          }
          DateTime startOfWeekReference = referenceDate.subtract(Duration(days: referenceDate.weekday - 1));
          DateTime startOfWeekToCheck = dateToCheck.subtract(Duration(days: dateToCheck.weekday - 1));
          int weeksDifference = startOfWeekToCheck.difference(startOfWeekReference).inDays ~/ 7;
          return weeksDifference >= 0 && weeksDifference % task.recurrenceInterval == 0;
      }

      return false; // Should not happen if isRecurring is true
  }
  // --------------------------------------------------------------

  // Helper to check if a date has any tasks
  bool _dateHasTasks(DateTime date) {
    return tasksByCategory.values.any((taskList) => taskList.any((task) => DateUtils.isSameDay(task.dueDate, date)));
  }

  DateTime _getStartOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  DateTime _getEndOfWeek(DateTime date) {
    return date.add(Duration(days: DateTime.daysPerWeek - date.weekday));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("To Do List", style: TextStyle(fontSize: 22)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: _selectDate,
            tooltip: 'Select Date',
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            SizedBox(height: 20.0),
            ListTile(
              leading: Icon(Icons.list),
              title: Text('To Do List'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
              },
            ),
            ListTile(
              leading: Icon(Icons.bar_chart),
              title: Text('Statistics'),
              onTap: () {
                Navigator.pop(context); // Close the drawer first
                // Navigate to the Statistics Screen
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const StatisticsScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Settings coming soon!"),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          SizedBox(height: 20),
          buildPageSelect(),
          Expanded(
            // Display tasks for the selected date
            child: _buildTaskList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryDialog(context),
        child: Icon(Icons.add, size: 32),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _focusedDate = picked;
      });
    }
  }

  Widget buildPageSelect() {
    final startOfWeek = _getStartOfWeek(_focusedDate);
    final daysInWeek = List.generate(7, (index) => startOfWeek.add(Duration(days: index)));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        ...daysInWeek.map((day) {
          final bool isSelected = DateUtils.isSameDay(_selectedDate, day);
          final bool isToday = DateUtils.isSameDay(DateTime.now(), day);
          final bool hasTasks = _dateHasTasks(day); // Check if the date has tasks

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 1.0),
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected ? Colors.blue : (isToday ? Colors.blue.shade100 : Colors.white),
                      foregroundColor: isSelected ? Colors.white : Colors.black,
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      shape: CircleBorder(),
                    ).copyWith(elevation: MaterialStateProperty.all(isSelected ? 4 : 1)),
                    onPressed: () => setState(() {
                      _selectedDate = day;
                      _focusedDate = day;
                    }),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(DateFormat.E().format(day).substring(0,1), style: TextStyle(fontSize: 10)),
                        Text(DateFormat.d().format(day), style: TextStyle(fontSize: 14, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                      ],
                    ),
                  ),
                  if (hasTasks)
                    Positioned(
                      top: 4,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  // Build the list of tasks for the selected date
  Widget _buildTaskList() {
    final topLevelTasks = _getTasksForSelectedDate();

    if (topLevelTasks.isEmpty) {
      return Center(
        child: Text(
          "No tasks for ${DateFormat.yMd().format(_selectedDate)}",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    // Helper function to build the list recursively or flattened
    List<Widget> buildTaskTree(List<Task> tasks, int depth) {
        // print('[buildTaskTree] Building tree at depth $depth for ${tasks.length} tasks.');
        List<Widget> taskWidgets = [];
        for (final task in tasks) {
            // print('[buildTaskTree] Processing task: ${task.title} (ID: ${task.id}, Parent: ${task.parentId})');
            // Build the main task tile
            taskWidgets.add(_buildTaskTile(task, depth));

            // Recursively build subtask tiles if any exist
            if (task.subtaskIds.isNotEmpty) {
                // print('[buildTaskTree] Task ${task.title} has subtask IDs: ${task.subtaskIds}');
                List<Task> subtasks = [];
                for (String id in task.subtaskIds) {
                    Task? subtask = taskBox.get(id); // This should now work with String ID
                    // print('[buildTaskTree] Attempting to fetch subtask ID: $id. Found: ${subtask?.title ?? 'NULL'}');
                    if (subtask != null) {
                       subtasks.add(subtask);
                    } else {
                       // print('[buildTaskTree] WARNING: Subtask with ID $id not found in taskBox!');
                    }
                }
                // Ensure subtasks list isn't empty after fetching
                if (subtasks.isNotEmpty) {
                   // print('[buildTaskTree] Adding ${subtasks.length} subtasks for ${task.title} recursively.');
                   taskWidgets.addAll(buildTaskTree(subtasks, depth + 1));
                // } else {
                //    print('[buildTaskTree] No valid subtasks found to add for ${task.title}.');
                }
            // } else {
            //     print('[buildTaskTree] Task ${task.title} has no subtasks.');
            }
        }
        // print('[buildTaskTree] Finished depth $depth. Total widgets: ${taskWidgets.length}');
        return taskWidgets;
    }

    return ListView(
       children: buildTaskTree(topLevelTasks, 0),
    );
  }

  // --- New Helper: Build a single task tile --- 
  Widget _buildTaskTile(Task task, int depth) {
    // Determine if this task instance (for the selected date) is completed
    final bool isInstanceCompleted;
    if (task.isRecurring) {
      isInstanceCompleted = task.completionDates.any((date) => DateUtils.isSameDay(date, _selectedDate));
    } else {
      isInstanceCompleted = task.isCompleted;
    }

    // Calculate indentation based on depth
    final double indentation = depth * 30.0; // Adjust multiplier as needed
    // print('[_buildTaskTile] Building tile for: ${task.title} (ID: ${task.id}) at depth $depth with indent $indentation');

    return Padding(
      padding: EdgeInsets.only(left: indentation),
      child: ListTile(
        leading: Checkbox(
          value: isInstanceCompleted, // Use instance completion status
          onChanged: (bool? value) {
            // Only allow checking if it's the actual due date or already completed today
            // Prevents checking off future recurring instances shown historically
            if (DateUtils.isSameDay(task.dueDate, _selectedDate) || isInstanceCompleted) {
                 _updateTaskCompletion(task, value ?? false);
            }
          },
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                task.title,
                maxLines: 1, // Limit title to 1 line
                overflow: TextOverflow.ellipsis, // Add ellipsis if overflow
                style: TextStyle(
                  // Apply strikethrough based on instance completion
                  decoration: isInstanceCompleted ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            if (task.isRecurring)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Icon(Icons.repeat, size: 16, color: Colors.grey),
              ),
          ],
        ),
        subtitle: task.description.isNotEmpty 
          ? Text(
              task.description, 
              maxLines: 2, // Limit description to 2 lines
              overflow: TextOverflow.ellipsis, // Add ellipsis if overflow
            )
          : null, // Hide subtitle if empty
        trailing: Row(
           mainAxisSize: MainAxisSize.min,
           children: [
              SizedBox( // Wrap with SizedBox for max width
                width: 60, // Set a max width (adjust as needed)
                child: Text(
                  task.category, 
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                  maxLines: 1, // Limit to 1 line
                  overflow: TextOverflow.ellipsis, // Add ellipsis
                  softWrap: false, // Prevent wrapping before ellipsis
                ),
              ),
              SizedBox(width: 4),
              // --- Add Subtask Button ---
              IconButton(
                 icon: Icon(Icons.add_circle_outline, size: 20, color: Colors.green),
                 tooltip: 'Add Subtask',
                 onPressed: () {
                   _showAddSubtaskDialog(context, task); // Pass parent task
                 },
                 padding: EdgeInsets.zero,
                 constraints: BoxConstraints(), // Remove default padding
              ),
              // -------------------------
              SizedBox(width: 4), // Spacing
              Material(
                 type: MaterialType.transparency,
                 child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                             builder: (context) => FocusScreen(task: task),
                          ),
                        );
                     },
                     child: Padding(
                       padding: const EdgeInsets.all(8.0),
                       child: Icon(
                         Icons.center_focus_strong,
                         size: 24,
                         color: Colors.blueAccent,
                       ),
                     ),
                  ),
              ),
           ]
        ),
        onTap: () async { // Make async to handle potential refresh
          // Navigate and wait for a potential result (e.g., true if saved/deleted)
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditTaskScreen(task: task, taskBox: taskBox),
            ),
          );
          // If the edit screen indicated a change, refresh the list
          if (result == true && mounted) { 
            setState(() {
              // Could potentially optimize by only reloading if necessary
              _loadTasksAndCategories(); 
            });
          }
        },
         onLongPress: () {
            showDialog(
                context: context,
                builder: (BuildContext ctx) {
                   return AlertDialog(
                      title: Text('Delete Task'),
                      content: Text('Are you sure you want to delete "${task.title}"? This will also delete its subtasks.'),
                      actions: [
                         TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: Text('Cancel'),
                         ),
                         TextButton(
                            onPressed: () {
                               _deleteTask(task); // Updated delete function needed
                               Navigator.of(ctx).pop();
                            },
                            child: Text('Delete', style: TextStyle(color: Colors.red)),
                         ),
                      ],
                   );
                },
            );
         },
      ),
    );
  }
  // --- End Task Tile Helper ---

  // --- Add Subtask Dialog Implementation ---
  void _showAddSubtaskDialog(BuildContext context, Task parentTask) {
    // --- Prevent adding subtask to recurring task ---
    if (parentTask.isRecurring) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot add subtasks to recurring tasks.')),
      );
      return; // Do not show the dialog
    }
    // ------------------------------------------------

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Add Subtask to ${parentTask.title}",
            maxLines: 2, // Limit dialog title
            overflow: TextOverflow.ellipsis, // Add ellipsis
          ),
          content: _AddSubtaskDialogContent(
            parentTask: parentTask,
            onSubtaskAdded: (newSubtask) async { // Make async
              // print('[AddSubtask] Adding subtask: ${newSubtask.title} to parent: ${parentTask.title}');
              // 1. Save the new subtask using its ID as the key
              await taskBox.put(newSubtask.id, newSubtask);
              // print('[AddSubtask] New subtask ${newSubtask.id} put into box.');
              
              // 2. Update parent task's subtask list
              // Ensure parentTask is still valid/managed if necessary
              // If parentTask is directly from the box, modification and save should work.
              parentTask.subtaskIds.add(newSubtask.id);
              await parentTask.save(); 
              // print('[AddSubtask] Parent task ${parentTask.id} updated and saved.');

              // 3. Refresh UI by reloading all data
              setState(() { 
                  // print('[AddSubtask] Calling _loadTasksAndCategories inside setState...');
                  _loadTasksAndCategories(); // Reload data
                  // print('[AddSubtask] State update triggered after adding subtask.');
              }); 
              Navigator.of(context).pop(); // Close dialog
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Subtask "${newSubtask.title}" added.'), duration: Duration(seconds: 2)),
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
  // --- End Add Subtask Dialog Implementation ---

  void _showCategoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Select or Create Category"),
          content: Container(
            width: double.maxFinite,
            // Use ListView for better scrolling if categories grow
            child: ListView(
              shrinkWrap: true, // Prevent unbounded height
              children: [
                // --- Existing Categories with Delete Buttons ---
                ...tasksByCategory.keys.map((category) => ListTile(
                  title: Text(category),
                  onTap: () {
                     Navigator.of(context).pop();
                     _showAddTaskDialog(context, category);
                  },
                  trailing: IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.redAccent),
                    tooltip: 'Delete Category',
                    onPressed: () {
                      // Close the current dialog before showing confirmation
                      Navigator.of(context).pop(); 
                      _confirmDeleteCategory(context, category); // Show confirmation dialog
                    },
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8.0), // Adjust padding
                )).toList(), // Convert map result to list
                // ---------------------------------------------
                SizedBox(height: 10),
                // --- Create New Category Button ---
                ListTile(
                  leading: Icon(Icons.add_circle_outline), 
                  title: Text("Create New Category"),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showCreateCategoryDialog(context);
                  },
                  contentPadding: EdgeInsets.symmetric(horizontal: 8.0),
                ),
                // ---------------------------------
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Confirmation Dialog for Category Deletion ---
  void _confirmDeleteCategory(BuildContext context, String category) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Text('Delete Category "$category"?'),
          content: Text('Are you sure? Deleting this category will also delete all associated tasks permanently.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(), // Just close the confirmation dialog
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop(); // Close the confirmation dialog
                _deleteCategory(category); // Proceed with deletion
                 ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(content: Text('Category "$category" deleted.'), duration: Duration(seconds: 2)),
                 );
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
  // -------------------------------------------------

  void _showCreateCategoryDialog(BuildContext context) {
    String newCategory = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Create New Category"),
          content: TextField(
            onChanged: (value) {
              newCategory = value.trim(); // Trim whitespace
            },
            decoration: InputDecoration(hintText: "Enter category name"),
            maxLength: 20, // Enforce 20 character limit
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Don't automatically reopen the category dialog
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                if (newCategory.isNotEmpty && !categoryBox.values.contains(newCategory)) { // Check categoryBox
                  // Add to Hive first
                  categoryBox.add(newCategory);
                  // Update local state map
                  setState(() {
                    tasksByCategory[newCategory] = [];
                  });
                  Navigator.of(context).pop();
                  _showAddTaskDialog(context, newCategory);
                } else if (categoryBox.values.contains(newCategory)){
                    ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(content: Text('Category "$newCategory" already exists.'), duration: Duration(seconds: 2)),
                    );
                } else {
                   ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(content: Text('Category name cannot be empty.'), duration: Duration(seconds: 2)),
                    );
                }
              },
              child: Text("Create & Add Task"),
            ),
          ],
        );
      },
    );
  }

  // Helper method to show the add task dialog
  void _showAddTaskDialog(BuildContext context, String category) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Pass category and initial date to the stateful dialog content
        return AlertDialog(
          title: Text("Add New Task to $category"),
          // Use a dedicated StatefulWidget for the content and state management
          content: _AddTaskDialogContent(
            category: category,
            initialDueDate: _selectedDate,
            onTaskAdded: (newTask) async { // Make async
               // Callback when task is successfully added
               await taskBox.put(newTask.id, newTask); // Use put with task ID as key
               setState(() {
                 if (tasksByCategory.containsKey(category)) {
                   tasksByCategory[category]!.add(newTask);
                 } else {
                   tasksByCategory[category] = [newTask];
                   if(!categoryBox.values.contains(category)) {
                     categoryBox.add(category);
                   }
                 }
               });
               Navigator.of(context).pop(); // Close dialog on success
               ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(content: Text('Task "${newTask.title}" added to $category.'), duration: Duration(seconds: 2)),
               );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cancel"),
            ),
            // The "Add Task" button logic is now inside _AddTaskDialogContent
          ],
        );
      },
    );
  }

  // Update task completion status in Hive
  void _updateTaskCompletion(Task task, bool isChecked) {
    final DateTime interactionDate = _selectedDate; // Use the currently viewed date

    if (task.isRecurring) {
      if (isChecked) {
        // --- Mark recurring task complete for this date ---
        if (!task.completionDates.any((date) => DateUtils.isSameDay(date, interactionDate))) {
          task.completionDates.add(interactionDate);
          task.completionDates.sort(); // Keep completion dates ordered

          DateTime nextDueDate = _calculateNextDueDate(task, interactionDate);
          task.dueDate = nextDueDate;
          task.isCompleted = false; 
          print("[UpdateComplete] New Due Date for ${task.title}: ${DateFormat.yMd().format(nextDueDate)}");

          // --- Reset ALL subtasks for the next occurrence ---
          for (String subtaskId in task.subtaskIds) {
            Task? subtask = taskBox.get(subtaskId);
            if (subtask != null) {
               // Reset regardless of previous state
               subtask.isCompleted = false;
               subtask.save(); 
               print("[UpdateComplete] Resetting subtask: ${subtask.title}");
            }
          }
          // --------------------------------------------
        }
      } else {
        // --- Un-checking a recurring task instance ---
        // ONLY remove the completion date. Do NOT change dueDate.
        task.completionDates.removeWhere((date) => DateUtils.isSameDay(date, interactionDate));
        print("[UpdateComplete] Unchecked ${task.title} for ${DateFormat.yMd().format(interactionDate)}. Due date remains ${DateFormat.yMd().format(task.dueDate)}");
      }
    } else {
      // --- Non-recurring task --- 
      task.isCompleted = isChecked;
    }

    task.save(); // Save the updated task object to Hive

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  // --- Helper to Calculate Next Due Date --- 
  DateTime _calculateNextDueDate(Task task, DateTime completedDate) {
    DateTime current = completedDate;

    if (task.recurrenceType == 'daily') {
      return current.add(Duration(days: task.recurrenceInterval));
    } 
    else if (task.recurrenceType == 'weekly') {
      if (task.recurrenceDaysOfWeek.isEmpty) {
          // Handle case where weekly is selected but no days are - fallback to daily?
          print("Warning: Weekly task ${task.title} has no selected days. Calculating next due date like daily.");
          return current.add(Duration(days: 7 * task.recurrenceInterval)); // Or maybe just 1 day?
      }

      DateTime nextPotentialDate = current; // Start checking from the day after completion
      int daysChecked = 0; // Safety break
      
      while (daysChecked < 365 * 5) { // Limit search to prevent infinite loops
        daysChecked++;
        nextPotentialDate = nextPotentialDate.add(Duration(days: 1));
        int currentWeekday = nextPotentialDate.weekday; // 1 (Mon) to 7 (Sun)

        // Is this weekday selected?
        if (task.recurrenceDaysOfWeek.contains(currentWeekday)) {
            // Does it align with the weekly interval?
            // Calculate weeks passed since the *completed* date's week start.
            DateTime startOfWeekCompleted = completedDate.subtract(Duration(days: completedDate.weekday - 1));
            DateTime startOfWeekPotential = nextPotentialDate.subtract(Duration(days: nextPotentialDate.weekday - 1));
            int weeksPassed = startOfWeekPotential.difference(startOfWeekCompleted).inDays ~/ 7;

            if (weeksPassed >= 0 && weeksPassed % task.recurrenceInterval == 0) {
               // This is the next valid date
               return nextPotentialDate;
            }
        }
      }
       // Fallback if loop finishes (shouldn't normally happen with < 5 year limit)
       print("Warning: Could not find next weekly due date for ${task.title} within 5 years. Defaulting to daily calculation.");
       return current.add(Duration(days: 7 * task.recurrenceInterval));
    } 
    else { // 'none' or unexpected type
      return task.dueDate; // No change if not recurring
    }
  }
  // --------------------------------------

  // Optional: Add delete task functionality
  void _deleteTask(Task task) {
     // --- Recursive Deletion Logic --- 
     List<String> subtaskIdsToDelete = List.from(task.subtaskIds); // Copy list
     taskBox.delete(task.id); // Delete the task itself using its String ID as the key

     // Recursively delete subtasks
     for (String subtaskId in subtaskIdsToDelete) {
        Task? subtask = taskBox.get(subtaskId);
        if (subtask != null) {
           _deleteTask(subtask); // Recursive call
        }
     }

     // Remove from parent's subtask list (if applicable)
     if (task.parentId != null) {
        Task? parentTask = taskBox.get(task.parentId);
        if (parentTask != null) {
           parentTask.subtaskIds.remove(task.id);
           parentTask.save();
        }
     }
     // --- End Recursive Deletion --- 

     // Original logic (partially redundant now or needs adjustment)
     // tasksByCategory[task.category]?.removeWhere((t) => t.id == task.id);
     // If category becomes empty, remove it (optional)
     // if (tasksByCategory[task.category]?.isEmpty ?? false) {
     //     tasksByCategory.remove(task.category);
     //     // Also remove from categoryBox
     //     categoryBox.deleteAt(categoryBox.values.toList().indexOf(task.category));
     // }

     // Refresh UI (might need more sophisticated state update)
     setState(() { _loadTasksAndCategories(); }); 
  }

  // Optional: Add delete category functionality
  void _deleteCategory(String category) {
      // Get tasks in the category
      List<Task> tasksToDelete = taskBox.values.where((task) => task.category == category).toList();
      // Delete tasks from taskBox
      for (var task in tasksToDelete) {
          task.delete();
      }
      // Delete category name from categoryBox
      categoryBox.deleteAt(categoryBox.values.toList().indexOf(category));
      // Update local state
      setState(() {
          tasksByCategory.remove(category);
      });
  }
}

// ---------- Add Subtask Dialog Widget ----------
class _AddSubtaskDialogContent extends StatefulWidget {
  final Task parentTask;
  final Function(Task) onSubtaskAdded;

  const _AddSubtaskDialogContent({
    Key? key,
    required this.parentTask,
    required this.onSubtaskAdded,
  }) : super(key: key);

  @override
  _AddSubtaskDialogContentState createState() => _AddSubtaskDialogContentState();
}

class _AddSubtaskDialogContentState extends State<_AddSubtaskDialogContent> {
  final _formKey = GlobalKey<FormState>();
  String subtaskTitle = '';
  String subtaskDescription = '';

  void _addSubtask() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final newSubtask = Task(
        id: _generateUniqueId(), // Generate unique ID
        parentId: widget.parentTask.id, // Link to parent
        category: widget.parentTask.category, // Inherit category
        title: subtaskTitle,
        description: subtaskDescription,
        dueDate: widget.parentTask.dueDate, // Inherit due date
        // Subtasks are not recurring by default
        isRecurring: false,
        recurrenceType: 'none',
        recurrenceInterval: 1,
        completionDates: [],
        subtaskIds: [], // Subtasks don't have their own subtasks (for now)
        recurrenceDaysOfWeek: [], // Initialize new field
      );

      widget.onSubtaskAdded(newSubtask);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextFormField(
              decoration: InputDecoration(labelText: 'Subtask Title'),
              validator: (value) => value == null || value.isEmpty ? 'Please enter a title' : null,
              onSaved: (value) => subtaskTitle = value!,
            ),
            SizedBox(height: 8),
            TextFormField(
              decoration: InputDecoration(labelText: 'Description'),
              onSaved: (value) => subtaskDescription = value ?? '',
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addSubtask,
              child: Text("Add Subtask"),
            )
          ],
        ),
      ),
    );
  }
}

// ---------- Add Task Dialog Widgets (Moved Outside) ----------

// Internal StatefulWidget for Add Task Dialog Content
class _AddTaskDialogContent extends StatefulWidget {
  final String category;
  final DateTime initialDueDate;
  final Function(Task) onTaskAdded; // Callback to add task

  const _AddTaskDialogContent({
    Key? key,
    required this.category,
    required this.initialDueDate,
    required this.onTaskAdded,
  }) : super(key: key); // Correct super call

  @override
  _AddTaskDialogContentState createState() => _AddTaskDialogContentState();
}

class _AddTaskDialogContentState extends State<_AddTaskDialogContent> {
  final _formKey = GlobalKey<FormState>();
  String taskTitle = '';
  String taskDescription = '';
  late DateTime taskDueDate;

  @override
  void initState() {
    super.initState();
    taskDueDate = widget.initialDueDate; // Access widget property here
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _addTask() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final newTask = Task(
        id: _generateUniqueId(), // Use the top-level function
        category: widget.category,
        title: taskTitle,
        description: taskDescription,
        dueDate: taskDueDate,
        isRecurring: false,
        recurrenceType: 'none',
        recurrenceInterval: 1,
        completionDates: [],
        parentId: null, // Explicitly null for top-level tasks
        subtaskIds: [], // Explicitly empty for new tasks
        recurrenceDaysOfWeek: [], // Initialize new field
      );

      widget.onTaskAdded(newTask); // Use the callback via widget property
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextFormField(
              decoration: InputDecoration(labelText: 'Task Title'),
              validator: (value) => value == null || value.isEmpty ? 'Please enter a title' : null,
              onSaved: (value) => taskTitle = value!,
            ),
            SizedBox(height: 8),
            TextFormField(
              decoration: InputDecoration(labelText: 'Description'),
              onSaved: (value) => taskDescription = value ?? '',
            ),
            SizedBox(height: 8),
            // Due Date Picker
            Row(
              children: [
                Expanded(
                  child: Text("Due: ${DateFormat.yMd().format(taskDueDate)}"),
                ),
                IconButton(
                  icon: Icon(Icons.calendar_today),
                  tooltip: 'Select Due Date',
                  onPressed: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: taskDueDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                    if (picked != null && picked != taskDueDate) {
                      setState(() { // Use standard setState
                         taskDueDate = picked;
                      });
                    }
                  },
                ),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
                onPressed: _addTask, // Call the internal add task method
                child: Text("Add Task"),
            )
          ],
        ),
      ),
    );
  }
}