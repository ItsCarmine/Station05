import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DeepFocusMode extends StatefulWidget {
  final int duration; // Duration in minutes
  final Function onComplete; // Success callback
  final Function onFail; // Failure callback

  const DeepFocusMode({
    Key? key, 
    required this.duration, 
    required this.onComplete, 
    required this.onFail
  }) : super(key: key);

  @override
  _DeepFocusModeState createState() => _DeepFocusModeState();
}

class _DeepFocusModeState extends State<DeepFocusMode> with WidgetsBindingObserver {
  late Timer _timer;
  int _secondsRemaining = 0;
  bool _isActive = false;
  DateTime? _lastPaused;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _secondsRemaining = widget.duration * 60;
    _startTimer();
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer.cancel();
    super.dispose();
  }
  
  void _startTimer() {
    setState(() {
      _isActive = true;
    });
    
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer.cancel();
        widget.onComplete();
      }
    });
  }
  
  // This monitors app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // User is trying to leave the app
      _lastPaused = DateTime.now();
      _showFailDialogWhenReturned();
    } else if (state == AppLifecycleState.resumed && _lastPaused != null) {
      // User has returned to the app
      _handleAppReturn();
    }
  }
  
  void _handleAppReturn() {
    if (_isActive) {
      // Calculate how long the user was away
      final timeAway = DateTime.now().difference(_lastPaused!);
      if (timeAway.inSeconds > 3) { // Give a small grace period
        _failTask();
      }
    }
  }
  
  void _showFailDialogWhenReturned() {
    // This will be shown when they return
    // We'll implement the actual dialog in _handleAppReturn
  }
  
  void _failTask() {
    _timer.cancel();
    setState(() {
      _isActive = false;
    });
    widget.onFail();
  }
  
  @override
  Widget build(BuildContext context) {
    // Convert seconds to minutes:seconds format
    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;
    
    return WillPopScope(
      // Prevent using back button to exit
      onWillPop: () async {
        _showExitWarningDialog();
        return false; // Prevents back navigation
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Deep Focus Mode'),
          automaticallyImplyLeading: false, // Hide back button
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Focus Time Remaining',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),
            Text(
              '$minutes:${seconds.toString().padLeft(2, '0')}',
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 40),
            Text(
              'Leaving this screen will fail your task!',
              style: TextStyle(color: Colors.red, fontSize: 16),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _showExitWarningDialog();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text('Give Up (Fail Task)'),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showExitWarningDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Are you sure?'),
          content: Text('Leaving deep focus mode will fail your current task. All progress will be lost.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: Text('Stay Focused'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                _failTask();
                Navigator.of(context).pop(); // Exit deep focus screen
              },
              child: Text('Give Up', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}