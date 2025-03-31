import 'dart:async';
import 'package:flutter/material.dart';
import 'task_model.dart';
// import 'package:intl/intl.dart'; // Not strictly needed here anymore

// Enum to represent Pomodoro phases
enum PomodoroPhase { work, shortBreak, longBreak }

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

  // --- Pomodoro State --- 
  // TODO: Make these configurable later (e.g., via settings)
  final int _workDuration = 25 * 60; // 25 minutes in seconds
  final int _shortBreakDuration = 5 * 60; // 5 minutes
  final int _longBreakDuration = 15 * 60; // 15 minutes
  final int _pomodorosBeforeLongBreak = 4; // Number of work cycles before a long break

  int _pomodoroCycle = 0; // Number of work sessions completed in the current set
  PomodoroPhase _currentPhase = PomodoroPhase.work; // Start with a work session

  @override
  void initState() {
    super.initState();
    _resetPomodoro(); // Initialize timer display based on Pomodoro state
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Renamed from _resetTimer to be more specific
  void _resetPomodoro() {
    _timer?.cancel();
    setState(() {
      _currentPhase = PomodoroPhase.work;
      _currentSeconds = _workDuration;
      _isTimerRunning = false;
      _pomodoroCycle = 0;
    });
  }

  void _toggleTimer() {
    if (_isTimerRunning) {
      _timer?.cancel();
    } else {
       if (_currentSeconds <= 0) return; // Don't start if already finished
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        if (_currentSeconds <= 0) {
          timer.cancel();
          _handleTimerCompletion();
        } else {
          setState(() {
            _currentSeconds--;
          });
        }
      });
    }
    setState(() {
      _isTimerRunning = !_isTimerRunning;
    });
  }

  void _skipPhase() {
     _timer?.cancel();
     _handleTimerCompletion();
  }

  void _handleTimerCompletion() {
    // Optional: Add sound/notification here
    // E.g., using audioplayers package: AudioPlayer().play(AssetSource('sounds/alarm.mp3'));

    setState(() {
       _isTimerRunning = false;

      if (_currentPhase == PomodoroPhase.work) {
        _pomodoroCycle++;
        if (_pomodoroCycle >= _pomodorosBeforeLongBreak) {
          // Start Long Break
          _currentPhase = PomodoroPhase.longBreak;
          _currentSeconds = _longBreakDuration;
          _pomodoroCycle = 0; // Reset cycle count after long break
        } else {
          // Start Short Break
          _currentPhase = PomodoroPhase.shortBreak;
          _currentSeconds = _shortBreakDuration;
        }
      } else {
        // If it was a break (short or long), start next work session
        _currentPhase = PomodoroPhase.work;
        _currentSeconds = _workDuration;
      }
    });
  }

  String _formatTime(int totalSeconds) {
    final duration = Duration(seconds: totalSeconds);
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  String _getPhaseName(PomodoroPhase phase) {
     switch (phase) {
       case PomodoroPhase.work:
         return "Work Time";
       case PomodoroPhase.shortBreak:
         return "Short Break";
       case PomodoroPhase.longBreak:
         return "Long Break";
     }
  }

  Color _getPhaseColor(PomodoroPhase phase) {
     switch (phase) {
       case PomodoroPhase.work:
         return Colors.red.shade300;
       case PomodoroPhase.shortBreak:
         return Colors.green.shade300;
       case PomodoroPhase.longBreak:
         return Colors.blue.shade300;
     }
  }

  @override
  Widget build(BuildContext context) {
    // Get phase color for background or elements
    final phaseColor = _getPhaseColor(_currentPhase);

    return Scaffold(
      appBar: AppBar(
        title: Text("Focus: ${widget.task.title}"), // Add task title to app bar
        backgroundColor: phaseColor, // Color app bar based on phase
        leading: IconButton(
           icon: Icon(Icons.arrow_back),
           onPressed: () {
             // Optional: Show confirmation if timer is running?
             _timer?.cancel(); // Stop timer when leaving
             Navigator.of(context).pop();
           },
        ),
      ),
      // Optional: Color the whole background?
      // backgroundColor: phaseColor.withOpacity(0.1),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Display current phase
              Text(
                 _getPhaseName(_currentPhase),
                 style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: phaseColor),
              ),
              SizedBox(height: 10),
              // Display current task details (optional reminder)
              /* Text(
                widget.task.title,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ), 
              SizedBox(height: 8), 
              if (widget.task.description.isNotEmpty)
                Text(
                  widget.task.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ), */
              // Timer Display
              Text(
                _formatTime(_currentSeconds),
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                   fontWeight: FontWeight.bold,
                   fontSize: 80, // Make timer larger
                   color: phaseColor,
                ),
              ),
              SizedBox(height: 8),
              // Pomodoro Cycle Indicator (e.g., using dots)
               Row(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: List.generate(_pomodorosBeforeLongBreak, (index) {
                   return Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 4.0),
                     child: Icon(
                       index < _pomodoroCycle ? Icons.circle : Icons.circle_outlined,
                       color: phaseColor,
                       size: 16,
                     ),
                   );
                 }),
               ),
              SizedBox(height: 30),
              // Timer Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    icon: Icon(_isTimerRunning ? Icons.pause : Icons.play_arrow),
                    label: Text(_isTimerRunning ? 'Pause' : 'Start'),
                    onPressed: _toggleTimer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: phaseColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      textStyle: TextStyle(fontSize: 20),
                    ),
                  ),
                   // Add Reset Button
                   SizedBox(width: 15),
                   IconButton(
                     icon: Icon(Icons.refresh),
                     onPressed: _resetPomodoro,
                     tooltip: 'Reset Pomodoro',
                     color: phaseColor,
                     iconSize: 30,
                   ),
                ],
              ),
               SizedBox(height: 20),
              // Add Skip Button
               TextButton(
                  onPressed: _skipPhase,
                  child: Text("Skip Phase", style: TextStyle(color: phaseColor)),
                )
            ],
          ),
        ),
      ),
    );
  }
} 