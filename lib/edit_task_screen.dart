import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import 'task_model.dart';
import 'main.dart'; // To access taskBoxName, _deleteTask (needs refactor?)

// Helper to get weekday names
const List<String> _weekDayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

class EditTaskScreen extends StatefulWidget {
  final Task task;
  final Box<Task> taskBox; // Pass the box for saving/deleting
  final Box<String> categoryBox; // <-- Add category box

  const EditTaskScreen({
    Key? key,
    required this.task,
    required this.taskBox,
    required this.categoryBox, // <-- Add to constructor
  }) : super(key: key);

  @override
  _EditTaskScreenState createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _intervalController;

  late String _editedTitle;
  late String _editedDescription;
  late DateTime _editedDueDate;
  late bool _editedIsRecurring;
  late String _editedRecurrenceType;
  late int _editedRecurrenceInterval;
  late List<int> _editedRecurrenceDaysOfWeek;
  late String _editedCategory; // <-- Add category state

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    // Initialize state from the task passed to the widget
    _editedTitle = widget.task.title;
    _editedDescription = widget.task.description;
    _editedDueDate = widget.task.dueDate;
    _editedIsRecurring = widget.task.isRecurring;
    _editedRecurrenceType = widget.task.recurrenceType;
    _editedRecurrenceInterval = widget.task.recurrenceInterval;
    _editedRecurrenceDaysOfWeek = List<int>.from(widget.task.recurrenceDaysOfWeek); // Copy list
    _editedCategory = widget.task.category; // <-- Initialize category state

    _titleController = TextEditingController(text: _editedTitle);
    _descriptionController = TextEditingController(text: _editedDescription);
    _intervalController = TextEditingController(text: _editedRecurrenceInterval.toString());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _intervalController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _editedDueDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _editedDueDate) {
      setState(() {
        _editedDueDate = picked;
      });
    }
  }

  void _saveTask() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save(); // Trigger onSaved callbacks

      // Update the original task object with edited values
      widget.task.title = _editedTitle;
      widget.task.description = _editedDescription;
      widget.task.dueDate = _editedDueDate;
      widget.task.category = _editedCategory; // <-- Save edited category
      widget.task.isRecurring = _editedIsRecurring;
      // Only update recurrence details if it's actually recurring
      if (_editedIsRecurring) {
        widget.task.recurrenceType = _editedRecurrenceType;
        widget.task.recurrenceInterval = _editedRecurrenceInterval;
        if (_editedRecurrenceType == 'weekly') {
          widget.task.recurrenceDaysOfWeek = _editedRecurrenceDaysOfWeek;
        } else {
          widget.task.recurrenceDaysOfWeek = []; // Clear days if not weekly
        }
      } else {
        // Reset recurrence fields if disabled
        widget.task.recurrenceType = 'none';
        widget.task.recurrenceInterval = 1;
        widget.task.recurrenceDaysOfWeek = [];
      }

      widget.task.save(); // Save changes to Hive

      Navigator.pop(context, true); // Pop screen and indicate save happened
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Task "${widget.task.title.substring(0, 15)}" updated.')),
      );
    }
  }
  
  // TODO: Refactor delete logic - maybe pass a callback?
  void _deleteTask() {
     showDialog(
        context: context,
        builder: (BuildContext ctx) {
           return AlertDialog(
              title: Text('Delete Task'),
              content: Text('Are you sure you want to delete "${widget.task.title}"? This will also delete its subtasks.'),
              actions: [
                 TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text('Cancel'),
                 ),
                 TextButton(
                    onPressed: () {
                       // How to call the _deleteTask from main.dart safely?
                       // Option 1: Make _deleteTask static or top-level (needs taskBox)
                       // Option 2: Pass delete callback from main screen
                       // Option 3: Pass the taskBox and call delete directly (chosen here)
                       
                       _deleteTaskRecursive(widget.taskBox, widget.task); 
                       
                       Navigator.of(ctx).pop(); // Close confirmation dialog
                       Navigator.of(context).pop(true); // Close edit screen, indicate change
                       ScaffoldMessenger.of(context).showSnackBar(
                         SnackBar(content: Text('Task "${widget.task.title}" deleted.')),
                       );
                    },
                    child: Text('Delete', style: TextStyle(color: Colors.red)),
                 ),
              ],
           );
        },
    );
  }
  
  // Helper for recursive deletion (could be moved to a utility class)
  void _deleteTaskRecursive(Box<Task> box, Task task) {
     List<String> subtaskIdsToDelete = List.from(task.subtaskIds);
     box.delete(task.id); 

     for (String subtaskId in subtaskIdsToDelete) {
        Task? subtask = box.get(subtaskId);
        if (subtask != null) {
           _deleteTaskRecursive(box, subtask); 
        }
     }

     if (task.parentId != null) {
        Task? parentTask = box.get(task.parentId);
        if (parentTask != null) {
           parentTask.subtaskIds.remove(task.id);
           parentTask.save();
        }
     }
  }


  @override
  Widget build(BuildContext context) {
    final bool isSubtask = widget.task.parentId != null;
    final bool hasSubtasks = widget.task.subtaskIds.isNotEmpty; // Check if it has subtasks
    final List<String> availableCategories = widget.categoryBox.values.toList();

    // Ensure the current task's category is in the list, even if deleted from categoryBox
    if (!availableCategories.contains(_editedCategory)) {
      availableCategories.add(_editedCategory);
      availableCategories.sort(); // Keep it sorted if adding
    }

    return Scaffold(
      backgroundColor: Color(0xFFF9F5F1), // Match main screen background
      appBar: AppBar(
        backgroundColor: Color(0xFFF9F5F1), // Match body background
        elevation: 0, // Remove shadow for seamless look
        title: Text("Edit Task"),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline),
            tooltip: 'Delete Task',
            onPressed: _deleteTask,
          ),
          IconButton(
            icon: Icon(Icons.save),
            tooltip: 'Save Changes',
            onPressed: _saveTask,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(12),
                margin: EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Color(0xFFF9F7F3), // Subtle contrast
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Title ---
                    TextFormField(
                      controller: _titleController,
                      style: TextStyle(color: Colors.black87),
                      decoration: InputDecoration(
                        labelText: 'Title',
                        labelStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Please enter a title' : null,
                      onSaved: (value) => _editedTitle = value!,
                    ),
                    SizedBox(height: 16),
                    // --- Description ---
                    TextFormField(
                      controller: _descriptionController,
                      style: TextStyle(color: Colors.black87),
                      decoration: InputDecoration(
                        labelText: 'Description',
                        labelStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                      ),
                      maxLines: 3,
                      onSaved: (value) => _editedDescription = value ?? '',
                    ),
                    SizedBox(height: 16),
                    // --- Category ---
                    DropdownButtonFormField<String>(
                      value: _editedCategory,
                      items: availableCategories
                          .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value, style: TextStyle(color: Colors.black87)),
                          );
                      }).toList(),
                      onChanged: (String? newValue) {
                          if (newValue != null) {
                              setState(() {
                                  _editedCategory = newValue;
                              });
                          }
                      },
                      onSaved: (value) => _editedCategory = value ?? widget.task.category, // Fallback just in case
                      decoration: InputDecoration(
                        labelText: 'Category',
                        labelStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                      ),
                    ),
                    SizedBox(height: 16), // <-- Add space after category dropdown
                    // --- Due Date ---
                    ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text("Due Date"),
                        subtitle: Text(DateFormat.yMd().format(_editedDueDate)),
                        trailing: Icon(Icons.calendar_today),
                        onTap: () => _selectDueDate(context),
                    ),
                    Divider(),
                    // --- Recurrence Settings ---
                    SwitchListTile(
                       contentPadding: EdgeInsets.zero,
                       title: Text("Recurring Task" + 
                                    (isSubtask ? " (Not available for subtasks)" : 
                                    (hasSubtasks ? " (Not available for tasks with subtasks)" : ""))), 
                       value: (isSubtask || hasSubtasks) ? false : _editedIsRecurring, // Show false if subtask or has subtasks
                       onChanged: (isSubtask || hasSubtasks) // Disable if subtask OR has subtasks
                         ? null 
                         : (bool value) {
                           setState(() {
                             _editedIsRecurring = value;
                             if (!_editedIsRecurring) {
                               _editedRecurrenceType = 'none'; // Reset if turned off
                             } else if (_editedIsRecurring && _editedRecurrenceType == 'none'){
                               _editedRecurrenceType = 'daily'; // Default to daily if turned on
                             }
                           });
                         },
                    ),
                    // --- Conditionally show recurrence options --- 
                    if (!isSubtask && !hasSubtasks && _editedIsRecurring) ...[
                        SizedBox(height: 8),
                        // Recurrence Type (Daily/Weekly)
                        DropdownButtonFormField<String>(
                            value: _editedRecurrenceType,
                            items: <String>['daily', 'weekly']
                                .map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value == 'daily' ? 'Daily' : 'Weekly'),
                                );
                            }).toList(),
                            onChanged: (String? newValue) {
                                setState(() {
                                    _editedRecurrenceType = newValue!;
                                    // Clear days if switching away from weekly
                                    if(_editedRecurrenceType != 'weekly') {
                                      _editedRecurrenceDaysOfWeek.clear();
                                    }
                                });
                            },
                            decoration: InputDecoration(labelText: 'Repeats'),
                        ),
                        SizedBox(height: 16),
                        // Recurrence Interval
                        Row(
                          children: [
                            Text("Every "),
                            SizedBox(
                              width: 60,
                              child: TextFormField(
                                controller: _intervalController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Inv.';
                                  final n = int.tryParse(value);
                                  if (n == null || n < 1) return 'Inv.';
                                  return null;
                                },
                                onSaved: (value) => _editedRecurrenceInterval = int.parse(value!),
                              ),
                            ),
                            Text(_editedRecurrenceType == 'daily' ? " days" : " weeks"),
                          ],
                        ),
                        SizedBox(height: 16),
                        // Days of Week (Only for Weekly)
                        if (_editedRecurrenceType == 'weekly') ...[
                            Text("On Days:", style: Theme.of(context).textTheme.titleSmall),
                            SizedBox(height: 8),
                            Wrap(
                              spacing: 8.0,
                              runSpacing: 4.0,
                              children: List<Widget>.generate(7, (int index) {
                                int dayValue = index + 1; // 1 = Mon, 7 = Sun
                                bool isSelected = _editedRecurrenceDaysOfWeek.contains(dayValue);
                                return ChoiceChip(
                                  label: Text(_weekDayNames[index]),
                                  selected: isSelected,
                                  onSelected: (bool selected) {
                                    setState(() {
                                      if (selected) {
                                        _editedRecurrenceDaysOfWeek.add(dayValue);
                                        _editedRecurrenceDaysOfWeek.sort(); // Keep order consistent
                                      } else {
                                        _editedRecurrenceDaysOfWeek.remove(dayValue);
                                      }
                                    });
                                  },
                                );
                              }),
                            ),
                            // Validation for weekly recurrence (at least one day selected)
                            if (_editedRecurrenceDaysOfWeek.isEmpty)
                               Padding(
                                 padding: const EdgeInsets.only(top: 8.0),
                                 child: Text(
                                    'Please select at least one day for weekly recurrence.',
                                    style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                                 ),
                               ),
                            SizedBox(height: 16),
                        ],
                    ], // End recurrence section
                    Divider(),
                    // --- Subtasks (Display Only for now) ---
                    if (_editedIsRecurring)
                       Padding(
                         padding: const EdgeInsets.only(bottom: 8.0),
                         child: Text(
                           "Subtasks cannot be added to recurring tasks.", 
                           style: TextStyle(color: Colors.grey, fontSize: 12)
                         ),
                       ),
                    Text("Subtasks", style: Theme.of(context).textTheme.titleLarge),
                    SizedBox(height: 8),
                    if (widget.task.subtaskIds.isEmpty)
                      Text("No subtasks yet."),
                    ...widget.task.subtaskIds.map((subtaskId) {
                       final subtask = widget.taskBox.get(subtaskId);
                       if (subtask == null) return SizedBox.shrink(); // Handle missing subtask
                       return ListTile(
                          dense: true,
                          leading: Icon(Icons.subdirectory_arrow_right),
                          title: Text(subtask.title, style: TextStyle(decoration: subtask.isCompleted ? TextDecoration.lineThrough : null)),
                          // TODO: Add tap to edit subtask? Delete subtask?
                       );
                    }),
                    SizedBox(height: 8),
                  ],
                ),
              ),
              SizedBox(height: 24),
              Center(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: Icon(Icons.delete),
                  label: Text('Delete Task'),
                  onPressed: _deleteTask,
                ),
              ),
              SizedBox(height: 16),
              Center(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: Icon(Icons.save),
                  label: Text('Save Changes'),
                  onPressed: _saveTask,
                ),
              ),
              SizedBox(height: 60), // Spacer at bottom
            ],
          ),
        ),
      ),
    );
  }
} 