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
        onPressed: () {},
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
}