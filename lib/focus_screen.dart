import 'dart:async';
import 'package:flutter/material.dart';
import 'task_model.dart';
// import 'package:intl/intl.dart'; // Not strictly needed here anymore

// Enum to represent Pomodoro phases
enum PomodoroPhase { work, shortBreak, longBreak }

// Enum to represent Focus Session types
enum FocusSessionType { pomodoro, flow }

class FocusScreen extends StatefulWidget {
  final Task task;

  const FocusScreen({Key? key, required this.task}) : super(key: key);

  @override
  _FocusScreenState createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  Timer? _timer;
  int _currentSeconds = 0;
  bool _isTimerRunning = false;
  int _secondsElapsedThisSession = 0;

  // Editable Durations
  late TextEditingController _workDurationController;
  late TextEditingController _breakDurationController;
  int _workDurationMinutes = 25;
  int _breakDurationMinutes = 5;

  // Simple state: are we timing work or break?
  bool _isWorkPhase = true; 

  // --- NEW STATE ---
  FocusSessionType? _sessionType; // To store the user's choice
  int _flowSecondsElapsed = 0; // Stopwatch timer for flow mode
  // ---------------

  @override
  void initState() {
    super.initState();
    // Initialize controllers with default values
    _workDurationController = TextEditingController(text: _workDurationMinutes.toString());
    _breakDurationController = TextEditingController(text: _breakDurationMinutes.toString());
    // Don't reset timer here, wait for session type selection
    // _resetTimer();

    // --- Show selection dialog shortly after build ---
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_sessionType == null && mounted) { // Check if mounted
        _showSessionTypeDialog();
      }
    });
    // ------------------------------------------------
  }

  @override
  void dispose() {
    _timer?.cancel();
    _workDurationController.dispose();
    _breakDurationController.dispose();
    // IMPORTANT: Save elapsed time if user backs out while timer was running
    if (_secondsElapsedThisSession > 0) {
      _saveFocusTime();
    }
    super.dispose();
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      // Set timer to work duration initially
      _currentSeconds = _workDurationMinutes * 60;
      _isTimerRunning = false;
      _isWorkPhase = true;
      _secondsElapsedThisSession = 0; // Reset session counter
    });
  }

  void _toggleTimer() {
    if (_isTimerRunning) {
      _timer?.cancel();
    } else {
      // Ensure we have time remaining
      if (_currentSeconds <= 0) return;

      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        if (_currentSeconds <= 0) {
          timer.cancel();
          _handleTimerCompletion();
        } else {
          setState(() {
            _currentSeconds--;
            // Only increment session time if it's a work phase
            if (_isWorkPhase) {
                _secondsElapsedThisSession++;
            }
          });
        }
      });
    }
    setState(() {
      _isTimerRunning = !_isTimerRunning;
    });
  }

  void _handleTimerCompletion() {
     // Timer finished, switch phase
     _timer?.cancel();
     setState(() {
        _isTimerRunning = false;
        _isWorkPhase = !_isWorkPhase; // Toggle between work and break
        _currentSeconds = (_isWorkPhase ? _workDurationMinutes : _breakDurationMinutes) * 60;
     });
     // Optional: Play a sound notification
  }

  // Function to end the session and save time
  void _endSession() {
     _timer?.cancel();
     _saveFocusTime();
     Navigator.of(context).pop(); // Go back to task list
  }

  void _saveFocusTime() {
     if (_secondsElapsedThisSession > 0 && widget.task.isInBox) { // Check if task is still in Hive box
        widget.task.totalSecondsFocused += _secondsElapsedThisSession;
        widget.task.save(); // Save updated task to Hive
        print("Saved ${_secondsElapsedThisSession} seconds to task ${widget.task.title}");
        _secondsElapsedThisSession = 0; // Reset after saving
     }
  }

  String _formatTime(int totalSeconds) {
    final duration = Duration(seconds: totalSeconds);
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  // Function to update duration from text field input
  void _updateDuration(String value, bool isWork) {
      final minutes = int.tryParse(value);
      if (minutes != null && minutes > 0) {
         setState(() {
            if (isWork) {
               _workDurationMinutes = minutes;
            } else {
               _breakDurationMinutes = minutes;
            }
            // If timer isn't running, update the current display
            if (!_isTimerRunning) {
               _currentSeconds = (_isWorkPhase == isWork ? minutes : (_isWorkPhase ? _workDurationMinutes : _breakDurationMinutes)) * 60;
            }
         });
      }
   }

  // --- NEW: Show Session Type Selection Dialog ---
  Future<void> _showSessionTypeDialog() async {
    final selectedType = await showDialog<FocusSessionType>(
      context: context,
      barrierDismissible: false, // User must choose
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Choose Focus Session Type'),
          content: Text('Select how you want to focus on "${widget.task.title}".'),
          actions: <Widget>[
            TextButton(
              child: Text('Pomodoro'),
              onPressed: () {
                Navigator.of(context).pop(FocusSessionType.pomodoro);
              },
            ),
            TextButton(
              child: Text('Flow (Stopwatch)'),
              onPressed: () {
                Navigator.of(context).pop(FocusSessionType.flow);
              },
            ),
            // Optional: Cancel button if you want to allow backing out
            // TextButton(
            //   child: Text('Cancel'),
            //   onPressed: () => Navigator.of(context).pop(null), // Or pop the screen
            // ),
          ],
        );
      },
    );

    if (selectedType != null && mounted) { // Check if mounted after async gap
      setState(() {
        _sessionType = selectedType;
        if (_sessionType == FocusSessionType.pomodoro) {
          _resetTimer(); // Initialize Pomodoro timer
        } else {
          // Initialize Flow timer state (starts at 0, not running)
          _flowSecondsElapsed = 0;
          _isTimerRunning = false;
          _timer?.cancel(); // Ensure no previous timer is running
        }
      });
    } else if (mounted) {
       // Handle case where dialog is dismissed without selection (e.g., back button)
       // Pop the focus screen itself if no choice is made
       Navigator.of(context).pop();
    }
  }
  // -------------------------------------------

  @override
  Widget build(BuildContext context) {
    // --- Conditionally build UI based on session type ---
    if (_sessionType == null) {
      // Show loading or placeholder while dialog is potentially showing
      return Scaffold(
        appBar: AppBar(title: Text("Focus: ${widget.task.title}")),
        body: Center(child: CircularProgressIndicator()),
      );
    } else if (_sessionType == FocusSessionType.pomodoro) {
      return _buildPomodoroUI(context);
    } else { // _sessionType == FocusSessionType.flow
      return _buildFlowUI(context);
    }
    // ----------------------------------------------------
  }

  // --- Refactored Pomodoro UI Builder ---
  Widget _buildPomodoroUI(BuildContext context) {
     final phaseColor = _isWorkPhase ? Colors.red.shade300 : Colors.green.shade300;
     final phaseName = _isWorkPhase ? "Work Phase" : "Break Phase";

     return Scaffold(
       appBar: AppBar(
         title: Text("Focus: ${widget.task.title} (Pomodoro)"),
         backgroundColor: phaseColor,
         leading: IconButton(
           icon: Icon(Icons.arrow_back),
           onPressed: _endSession, // Use end session logic for back button too
         ),
       ),
       body: Padding(
         padding: const EdgeInsets.all(16.0),
         child: SingleChildScrollView( // Allow scrolling if content overflows
           child: Column(
             mainAxisAlignment: MainAxisAlignment.center,
             children: <Widget>[
               // Editable Durations
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                 children: [
                    _buildDurationEditor("Work (min)", _workDurationController, true),
                    _buildDurationEditor("Break (min)", _breakDurationController, false),
                 ],
               ),
               SizedBox(height: 30),

               // Phase Indicator
               Text(
                 phaseName,
                 style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: phaseColor),
               ),
               SizedBox(height: 10),

               // Timer Display
               Text(
                 _formatTime(_currentSeconds),
                 style: Theme.of(context).textTheme.displayLarge?.copyWith(
                   fontWeight: FontWeight.bold,
                   fontSize: 80,
                   color: phaseColor,
                 ),
               ),
               SizedBox(height: 30),

               // Timer Controls (Start/Pause)
               ElevatedButton.icon(
                 icon: Icon(_isTimerRunning ? Icons.pause : Icons.play_arrow),
                 label: Text(_isTimerRunning ? 'Pause' : 'Start'),
                 onPressed: _toggleTimer, // Uses Pomodoro logic
                 style: ElevatedButton.styleFrom(
                   backgroundColor: phaseColor,
                   foregroundColor: Colors.white,
                   padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                   textStyle: TextStyle(fontSize: 20),
                 ),
               ),
               SizedBox(height: 40),

               // End Session Button
               OutlinedButton.icon(
                 icon: Icon(Icons.stop_circle_outlined),
                 label: Text("End Focus Session"),
                 onPressed: _endSession,
                 style: OutlinedButton.styleFrom(
                   foregroundColor: Colors.grey[700],
                   side: BorderSide(color: Colors.grey.shade400),
                   padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                 ),
               )
             ],
           ),
         ),
       ),
     );
   }
   // ------------------------------------

   // --- NEW: Flow Session UI Builder ---
   Widget _buildFlowUI(BuildContext context) {
     // Flow mode specific UI
     return Scaffold(
       appBar: AppBar(
         title: Text("Focus: ${widget.task.title} (Flow)"),
         backgroundColor: Colors.indigo.shade300, // Different color for flow
         leading: IconButton(
           icon: Icon(Icons.arrow_back),
           onPressed: _endSession, // Use the same end session logic
         ),
       ),
       body: Padding(
         padding: const EdgeInsets.all(16.0),
         child: Center( // Center the Column horizontally
           child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center, // Center children horizontally
            children: <Widget>[
               Text(
                 "Flow Session Timer",
                 style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.indigo),
               ),
               SizedBox(height: 10),

               // Timer Display (Counting Up)
               Text(
                 _formatTime(_flowSecondsElapsed), // Format the elapsed flow time
                 style: Theme.of(context).textTheme.displayLarge?.copyWith(
                   fontWeight: FontWeight.bold,
                   fontSize: 80,
                   color: Colors.indigo,
                 ),
               ),
               SizedBox(height: 30),

               // Timer Controls (Start/Pause)
               ElevatedButton.icon(
                 icon: Icon(_isTimerRunning ? Icons.pause : Icons.play_arrow),
                 label: Text(_isTimerRunning ? 'Pause' : 'Start'),
                 onPressed: _toggleFlowTimer, // Need to implement this
                 style: ElevatedButton.styleFrom(
                   backgroundColor: Colors.indigo.shade300,
                   foregroundColor: Colors.white,
                   padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                   textStyle: TextStyle(fontSize: 20),
                 ),
               ),
               SizedBox(height: 40),

               // End Session Button
               OutlinedButton.icon(
                 icon: Icon(Icons.stop_circle_outlined),
                 label: Text("End Flow Session"),
                 onPressed: _endSession, // Reuse end session logic
                 style: OutlinedButton.styleFrom(
                   foregroundColor: Colors.grey[700],
                   side: BorderSide(color: Colors.grey.shade400),
                   padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                 ),
               )
             ],
           ),
         ),
       ),
     );
   }
   // ---------------------------------

   // --- Flow Timer Logic ---
   void _toggleFlowTimer() {
      setState(() {
         if (_isTimerRunning) {
            _timer?.cancel(); // Pause the timer
         } else {
            // Start the timer
            _timer = Timer.periodic(Duration(seconds: 1), (timer) {
               if (!mounted) { // Check if widget is still mounted
                  timer.cancel();
                  return;
               }
               setState(() {
                  _flowSecondsElapsed++;
                  _secondsElapsedThisSession++; // Also track total time for saving
               });
            });
         }
         _isTimerRunning = !_isTimerRunning; // Toggle the running state
      });
   }
   // ---------------------------------------

   // Helper Widget for Duration Editor
   Widget _buildDurationEditor(String label, TextEditingController controller, bool isWork) {
      return Column(
         children: [
            Text(label, style: TextStyle(fontSize: 16)),
            SizedBox(height: 4),
            SizedBox(
               width: 80,
               child: TextField(
                  controller: controller,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                     contentPadding: EdgeInsets.symmetric(vertical: 8),
                     border: OutlineInputBorder(),
                     isDense: true,
                  ),
                  onChanged: (value) => _updateDuration(value, isWork),
                  // Prevent editing while timer is running?
                  // enabled: !_isTimerRunning, 
               ),
            ),
         ],
      );
   }
} 