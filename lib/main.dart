import 'package:flutter/material.dart';

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
  int selectedPage = 1;
  //empty list to hold the categories that we create when clicking the plus button on the bottom
  List<String> categories = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("To Do List", style: TextStyle(fontSize: 22)),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Under Construction!"),
                duration: Duration(seconds: 2),
                backgroundColor: Colors.blue,
              ),
            );
          },
        ),
      ),
      body: Column(
        children: [
          SizedBox(height: 20),
          buildPageSelect(),
          Expanded(
            child: Center(
              child: Text(
                "No tasks available",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        //when the button is pressed, it will show the dialog box ( in this case the dialog box is the categories)
        onPressed: () => _showCategoryDialog(context),
        child: Icon(Icons.add, size: 32),
      ),
    );
  }

  Widget buildPageSelect() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal, // Page number rowling
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_left),
            onPressed: selectedPage > 1
                ? () => setState(() => selectedPage--)
                : null,
          ),
          Row(
            children: List.generate(7, (index) {
              int page = index + 1;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    selectedPage == page ? Colors.blue : Colors.white,
                    foregroundColor:
                    selectedPage == page ? Colors.white : Colors.black,
                  ),
                  onPressed: () => setState(() => selectedPage = page),
                  child: Text("$page"),
                ),
              );
            }),
          ),
          IconButton(
            icon: Icon(Icons.arrow_right),
            onPressed: selectedPage < 7
                ? () => setState(() => selectedPage++)
                : null,
          ),
        ],
      ),
    );
  }
// this displays a dialog for selecting existing categories or creating a new one 
  void _showCategoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("To create a new task, please select a category or create a new one."),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Show existing categories if any
                ...categories.map((category) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF8D5353), // Brown color 
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 50),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _showCategoryOptionsDialog(context, category);
                    },
                    child: Text(category),
                  ),
                )),
                
                // Create New Category button - always shown
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

// this displays a dialog for example entering a new category name and adding it to the list
  void _showCreateCategoryDialog(BuildContext context) {
    String newCategory = '';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Create New Category"),
          content: TextField(
            onChanged: (value) {
              newCategory = value;
            },
            decoration: InputDecoration(hintText: "Enter category name"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showCategoryDialog(context); // Return to main dialog
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                if (newCategory.isNotEmpty) {
                  setState(() {
                    categories.add(newCategory);
                  });
                }
                Navigator.of(context).pop();
                _showCategoryDialog(context); // Return to main dialog
              },
              child: Text("Create"),
            ),
          ],
        );
      },
    );
  }

  void _showCategoryOptionsDialog(BuildContext context, String category) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(category),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Add Task button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 50),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  _showAddTaskDialog(context, category);
                },
                child: Text("Add Task"),
              ),
              
              SizedBox(height: 10),
              
              // Remove Category button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 50),
                ),
                onPressed: () {
                  setState(() {
                    categories.remove(category);
                  });
                  Navigator.of(context).pop();
                },
                child: Text("Remove Category"),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddTaskDialog(BuildContext context, String category) {
    String newTask = '';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Add Task to $category"),
          content: TextField(
            onChanged: (value) {
              newTask = value;
            },
            decoration: InputDecoration(hintText: "Enter task description"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showCategoryOptionsDialog(context, category);
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                if (newTask.isNotEmpty) {
                  // Here you would add the task to a tasks list
                  // For now, we'll just show a confirmation
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Task added to $category: $newTask"),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
                Navigator.of(context).pop();
              },
              child: Text("Add"),
            ),
          ],
        );
      },
    );
  }
}