import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Make sure to adjust the platform channel to match your app's package name
const platform = MethodChannel('com.station5.station5/deepfocus');

class DeepFocusMode extends StatefulWidget {
  final int duration; // Duration in minutes
  final Function onComplete; // Success callback
  final Function onFail; // Failure callback

  const DeepFocusMode({
    super.key, 
    required this.duration, 
    required this.onComplete, 
    required this.onFail
  });

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
    _enableDeepFocusMode();
  }
  
  @override
  void dispose() {
    _disableDeepFocusMode();
    WidgetsBinding.instance.removeObserver(this);
    _timer.cancel();
    super.dispose();
  }
  
  Future<void> _enableDeepFocusMode() async {
    try {
      await platform.invokeMethod('enableLockTask');
    } on PlatformException catch (e) {
      print("Failed to enable deep focus mode: ${e.message}");
    }
  }
  
  Future<void> _disableDeepFocusMode() async {
    try {
      await platform.invokeMethod('disableLockTask');
    } on PlatformException catch (e) {
      print("Failed to disable deep focus mode: ${e.message}");
    }
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
        _disableDeepFocusMode();
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
        _showFailWarningDialog();
      }
    }
  }
  
  void _failTask() {
    _timer.cancel();
    setState(() {
      _isActive = false;
    });
    _disableDeepFocusMode();
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
          backgroundColor: Colors.red.shade400, // Use a distinctive color
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.do_not_disturb_on_rounded,
                color: Colors.red.shade400,
                size: 60,
              ),
              SizedBox(height: 20),
              Text(
                'DEEP FOCUS MODE',
                style: TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade400
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Leaving this screen will fail your task!',
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
              SizedBox(height: 40),
              // Timer Display
              Text(
                'Time Remaining',
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 10),
              Text(
                '$minutes:${seconds.toString().padLeft(2, '0')}',
                style: TextStyle(fontSize: 72, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  _showExitWarningDialog();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                child: Text('Give Up (Fail Task)', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
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
              },
              child: Text('Give Up', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
  
  void _showFailWarningDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Focus Lost!'),
          content: Text('You left the app during deep focus mode. Your task will be marked as failed.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                _failTask();
              },
              child: Text('I Understand', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}