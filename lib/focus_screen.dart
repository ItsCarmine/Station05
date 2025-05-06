import 'dart:async';
import 'package:flutter/material.dart';
import 'task_model.dart';
import 'focus_log_model.dart';
import 'package:hive/hive.dart';
import 'main.dart';
import 'deep_focus_mode.dart';
// import 'package:intl/intl.dart'; // Not strictly needed here anymore

// Enum to represent Pomodoro phases
enum PomodoroPhase { work, shortBreak, longBreak }

// Enum to represent Focus Session types
enum FocusSessionType { pomodoro, flow }

class FocusScreen extends StatefulWidget {
  final Task task;

  const FocusScreen({super.key, required this.task});

  @override
  _FocusScreenState createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  Timer? _timer;
  int _currentSeconds = 0;
  bool _isTimerRunning = false;
  int _secondsElapsedThisSession = 0;
  bool _deepFocusEnabled = false; // Moved inside the class

  // Editable Durations
  late TextEditingController _workDurationController;
  late TextEditingController _breakDurationController;
  int _workDurationMinutes = 25;
  int _breakDurationMinutes = 5;

  // Simple state: are we timing work or break?
  bool _isWorkPhase = true; 

  // --- NEW STATE ---
  FocusSessionType? _sessionType; // To store the user's choice
  DateTime? _sessionStartTime; // <-- Store when the current timed segment started
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
      _saveFocusTime(true);
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
      _sessionStartTime = null; // <-- Reset start time
    });
  }

  void _toggleTimer() {
    if (_isTimerRunning) {
      _timer?.cancel();
      _saveFocusTime(false); // Save progress, but don't reset start time yet
    } else {
      // Ensure we have time remaining
      if (_currentSeconds <= 0) return;

      _sessionStartTime = DateTime.now(); // <-- Record start time

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
     _saveFocusTime(true); // Save progress and reset start time

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
     _saveFocusTime(true); // Save final time and reset
     if (mounted) { // Ensure widget is still mounted before popping
      Navigator.of(context).pop(); // Go back to task list
     }
  }

  // Modify the regular _saveFocusTime method to include status
  void _saveFocusTime(bool resetStartTime) {
    if (_secondsElapsedThisSession > 0 && (_isWorkPhase || _sessionType == FocusSessionType.flow)) {
      final logBox = Hive.box<FocusSessionLog>(focusLogBoxName);
      final logEntry = FocusSessionLog(
        id: generateUniqueId(),
        categoryName: widget.task.category,
        startTime: _sessionStartTime ?? DateTime.now().subtract(Duration(seconds: _secondsElapsedThisSession)),
        durationSeconds: _secondsElapsedThisSession,
        status: FocusSessionStatus.completed, // Default to completed for regular sessions
      );
      logBox.put(logEntry.id, logEntry);
    }
    
    _secondsElapsedThisSession = 0; 
    if(resetStartTime) {
      _sessionStartTime = null;
    }
  }

  // Implement this method properly
  void _saveFocusTimeWithStatus(bool resetStartTime, FocusSessionStatus status) {
    if (_secondsElapsedThisSession > 0 && (_isWorkPhase || _sessionType == FocusSessionType.flow)) {
      final logBox = Hive.box<FocusSessionLog>(focusLogBoxName);
      final logEntry = FocusSessionLog(
        id: generateUniqueId(),
        categoryName: widget.task.category,
        startTime: _sessionStartTime ?? DateTime.now().subtract(Duration(seconds: _secondsElapsedThisSession)),
        durationSeconds: _secondsElapsedThisSession,
        status: status, // Use the passed status
      );
      logBox.put(logEntry.id, logEntry);
    }
    
    _secondsElapsedThisSession = 0; 
    if(resetStartTime) {
      _sessionStartTime = null;
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


  // Add this method to start Deep Focus Mode
  void _startDeepFocusMode() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeepFocusMode(
          duration: _workDurationMinutes,
          onComplete: (status) {
            // Mark task as completed 
            if (widget.task.isRecurring) {
              if (!widget.task.completionDates.any((date) => DateUtils.isSameDay(date, DateTime.now()))) {
                widget.task.completionDates.add(DateTime.now());
                widget.task.save();
              }
            } else {
              widget.task.isCompleted = true;
              widget.task.save();
            }
            
            // Save the focus session log with status
            _saveFocusSessionWithStatus(status);
            
            // Navigate back to task list
            Navigator.of(context).popUntil((route) => route.isFirst);
            
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Task completed successfully!'), backgroundColor: Colors.green),
            );
          },
          onFail: (status) {
            // Save the focus session log with failed status
            _saveFocusSessionWithStatus(status);
            
            // Navigate back to task list
            Navigator.of(context).popUntil((route) => route.isFirst);
            
            // Show failure message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Task failed. You exited Deep Focus Mode.'), backgroundColor: Colors.red),
            );
          },
        ),
      ),
    );
  }

  // Add this new method to save with status
  void _saveFocusSessionWithStatus(FocusSessionStatus status) {
    final logBox = Hive.box<FocusSessionLog>(focusLogBoxName);
    
    // Calculate session duration based on status
    final sessionDuration = status == FocusSessionStatus.completed 
        ? _workDurationMinutes * 60 
        : (_workDurationMinutes * 60) - _currentSeconds; // Calculate actual time spent
    
    // Create the log entry with the correct status
    final logEntry = FocusSessionLog(
      id: generateUniqueId(),
      categoryName: widget.task.category,
      startTime: DateTime.now().subtract(Duration(seconds: sessionDuration)),
      durationSeconds: sessionDuration,
      status: status, // Use the passed status (completed or failed)
    );
    
    // Print debug information
    print("Saving focus session with status: ${status.toString()}");
    print("Duration: ${sessionDuration} seconds");
    
    // Save to Hive
    logBox.put(logEntry.id, logEntry);
  }


  // --- NEW: Show Session Type Selection Dialog ---
  Future<void> _showSessionTypeDialog() async {
  final selectedType = await showDialog<dynamic>(
    context: context,
    barrierDismissible: false, // User must choose
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Choose Focus Session Type'),
        content: Text('Select how you want to focus on "${widget.task.title}".'),
        actions: <Widget>[
          // Add Deep Focus option
          TextButton(
            child: Text('Deep Focus Pomodoro'),
            onPressed: () {
              Navigator.of(context).pop({
                'type': FocusSessionType.pomodoro,
                'deepFocus': true,
              });
            },
          ),
          // Regular Pomodoro
          TextButton(
            child: Text('Regular Pomodoro'),
            onPressed: () {
              Navigator.of(context).pop({
                'type': FocusSessionType.pomodoro,
                'deepFocus': false,
              });
            },
          ),
          TextButton(
            child: Text('Flow (Stopwatch)'),
            onPressed: () {
              Navigator.of(context).pop({
                'type': FocusSessionType.flow,
                'deepFocus': false,
              });
            },
          ),
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(), 
          ),
        ],
      );
    },
  );

  if (selectedType != null && mounted) {
    setState(() {
      if (selectedType is Map) {
        _sessionType = selectedType['type'];
        _deepFocusEnabled = selectedType['deepFocus'] ?? false;
      } else {
        _sessionType = selectedType;
        _deepFocusEnabled = false;
      }

      if (_sessionType == FocusSessionType.pomodoro) {
        _resetTimer();
      } else {
        _flowSecondsElapsed = 0;
        _isTimerRunning = false;
        _timer?.cancel();
        _sessionStartTime = null;
      }
    });

    // If deep focus mode is enabled, start it
    if (_deepFocusEnabled && _sessionType == FocusSessionType.pomodoro) {
      _startDeepFocusMode();
    }
  } else if (mounted) {
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

   // --- Implement proper Flow Timer Logic ---
   void _toggleFlowTimer() {
      if (_isTimerRunning) {
         _timer?.cancel(); // Pause the timer
         _saveFocusTime(false); // Save progress, don't reset start time
      } else {
         // Start the timer
         _sessionStartTime ??= DateTime.now(); // Record start time if not already set
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
      setState(() {
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