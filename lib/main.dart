import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'task_model.dart'; // Import the new Task model
import 'dart:math'; // For generating random IDs

void main() {
  runApp(NoTitle());
}

class NoTitle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: true, home: todoScreen());
  }
}

class todoScreen extends StatefulWidget {
  @override
  todoScreenState createState() => todoScreenState();
}

class todoScreenState extends State<todoScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();

  // Replace categories list with a map to store tasks per category
  // List<String> categories = [];
  Map<String, List<Task>> tasksByCategory = {};

  // Helper to generate unique IDs for tasks
  String _generateUniqueId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + Random().nextInt(1000).toString();
  }

  // Helper to get tasks for the selected date
  List<Task> _getTasksForSelectedDate() {
    List<Task> tasks = [];
    tasksByCategory.values.forEach((taskList) {
      tasks.addAll(taskList.where((task) => DateUtils.isSameDay(task.dueDate, _selectedDate)));
    });
    // Sort tasks, e.g., by completion status or title
    tasks.sort((a, b) {
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1; // Uncompleted tasks first
      }
      return a.title.compareTo(b.title);
    });
    return tasks;
  }

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
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    child: Icon(Icons.person, size: 40),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'User Profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
            ),
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
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Statistics coming soon!"),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.account_circle),
              title: Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Profile coming soon!"),
                    duration: Duration(seconds: 2),
                  ),
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

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_left),
            onPressed: () {
              setState(() {
                _focusedDate = _focusedDate.subtract(Duration(days: 7));
              });
            },
          ),
          Row(
            children: daysInWeek.map((day) {
              final bool isSelected = DateUtils.isSameDay(_selectedDate, day);
              final bool isToday = DateUtils.isSameDay(DateTime.now(), day);
              final bool hasTasks = _dateHasTasks(day); // Check if the date has tasks

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: Stack( // Use Stack to overlay the dot
                  alignment: Alignment.topCenter, // Position dot at the top center
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected ? Colors.blue : (isToday ? Colors.blue.shade100 : Colors.white),
                        foregroundColor: isSelected ? Colors.white : Colors.black,
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        shape: CircleBorder(),
                        minimumSize: Size(45, 45), // Slightly larger to accommodate dot
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
                    // Add a dot if the date has tasks
                    if (hasTasks)
                      Positioned(
                        top: 4, // Adjust position as needed
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : Colors.blue, // Contrast color
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
          IconButton(
            icon: Icon(Icons.arrow_right),
            onPressed: () {
              setState(() {
                _focusedDate = _focusedDate.add(Duration(days: 7));
              });
            },
          ),
        ],
      ),
    );
  }

  // New widget to build the task list
  Widget _buildTaskList() {
    final tasks = _getTasksForSelectedDate();

    if (tasks.isEmpty) {
      return Center(
        child: Text(
          "No tasks for ${DateFormat.yMd().format(_selectedDate)}",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return ListTile(
          leading: Checkbox(
            value: task.isCompleted,
            onChanged: (bool? value) {
              setState(() {
                task.isCompleted = value ?? false;
              });
            },
          ),
          title: Text(
            task.title,
            style: TextStyle(
              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: Text(task.description),
          trailing: Text(task.category, style: TextStyle(color: Colors.grey, fontSize: 12)),
          // Optional: Add onTap to edit task, onLongPress to delete?
        );
      },
    );
  }

  void _showCategoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Select or Create Category"),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Use tasksByCategory.keys for existing categories
                ...tasksByCategory.keys.map((category) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF8D5353),
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 50),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Go directly to add task dialog for the selected category
                      _showAddTaskDialog(context, category);
                    },
                    child: Text(category),
                  ),
                )),

                SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black,
                    minimumSize: Size(double.infinity, 50),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showCreateCategoryDialog(context);
                  },
                  child: Text("Create New Category"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

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
                if (newCategory.isNotEmpty && !tasksByCategory.containsKey(newCategory)) {
                  setState(() {
                    tasksByCategory[newCategory] = []; // Add new category with empty task list
                  });
                  Navigator.of(context).pop();
                  // After creating, immediately open the add task dialog for the new category
                  _showAddTaskDialog(context, newCategory);
                } else if (tasksByCategory.containsKey(newCategory)){
                    // Optional: Show error if category already exists
                    ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(content: Text('Category "$newCategory" already exists.'), duration: Duration(seconds: 2)),
                    );
                } else {
                   // Optional: Handle empty input
                   ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(content: Text('Category name cannot be empty.'), duration: Duration(seconds: 2)),
                    );
                }
              },
              child: Text("Create & Add Task"), // Changed button text
            ),
          ],
        );
      },
    );
  }

  // Modify Add Task Dialog to include Title, Description, and Due Date
  void _showAddTaskDialog(BuildContext context, String category) {
    final _formKey = GlobalKey<FormState>(); // For validation
    String taskTitle = '';
    String taskDescription = '';
    DateTime? taskDueDate = _selectedDate; // Default to selected date

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Add Task to $category"),
          content: StatefulBuilder( // Use StatefulBuilder for the date picker update
            builder: (BuildContext context, StateSetter setStateDialog) {
              return SingleChildScrollView( // Prevent overflow
                child: Form(
                   key: _formKey,
                   child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          decoration: InputDecoration(labelText: "Title"),
                          validator: (value) => value == null || value.isEmpty ? 'Please enter a title' : null,
                          onSaved: (value) => taskTitle = value!,
                        ),
                        SizedBox(height: 8),
                        TextFormField(
                          decoration: InputDecoration(labelText: "Description"),
                          maxLines: 3, // Allow multi-line description
                          onSaved: (value) => taskDescription = value ?? '',
                        ),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Due Date: ${DateFormat.yMd().format(taskDueDate!)}"),
                            TextButton(
                              child: Text("Select Date"),
                              onPressed: () async {
                                final DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: taskDueDate!, // Use current task due date
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2101),
                                );
                                if (picked != null && picked != taskDueDate) {
                                  setStateDialog(() { // Update dialog state
                                     taskDueDate = picked;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                   ),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                   _formKey.currentState!.save(); // Save form field values

                   final newTask = Task(
                      id: _generateUniqueId(),
                      category: category,
                      title: taskTitle,
                      description: taskDescription,
                      dueDate: taskDueDate!,
                   );

                   setState(() { // Update main screen state
                      if (tasksByCategory.containsKey(category)) {
                        tasksByCategory[category]!.add(newTask);
                      } else {
                        // This case should ideally not happen with the current flow
                        // but good to handle defensively.
                        tasksByCategory[category] = [newTask];
                      }
                   });
                   Navigator.of(context).pop(); // Close the dialog
                   ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(content: Text('Task "${newTask.title}" added to $category.'), duration: Duration(seconds: 2)),
                   );
                }
              },
              child: Text("Add Task"),
            ),
          ],
        );
      },
    );
  }
}