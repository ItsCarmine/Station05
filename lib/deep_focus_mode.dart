import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'focus_log_model.dart';
import 'package:confetti/confetti.dart';

// Make sure to adjust the platform channel to match your app's package name
const platform = MethodChannel('com.station5.station5/deepfocus');

class DeepFocusMode extends StatefulWidget {
  final int duration; 
  final Function(FocusSessionStatus) onComplete; 
  final Function(FocusSessionStatus) onFail; 

  const DeepFocusMode({
    super.key, 
    required this.duration, 
    required this.onComplete, 
    required this.onFail
  });

  @override
  _DeepFocusModeState createState() => _DeepFocusModeState();
}

class _DeepFocusModeState extends State<DeepFocusMode> with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late Timer _timer;
  int _secondsRemaining = 0;
  bool _isActive = false;
  DateTime? _lastPaused;
  
  // Animation controller for the hourglass
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  
  // Confetti controller for celebration
  late ConfettiController _confettiController;

  // List of motivational quotes to display
  final List<String> _motivationalQuotes = [
    "Stay focused, and the magic will happen!",
    "One task at a time leads to great achievements.",
    "Your future self will thank you for focusing now.",
    "Deep focus is a superpower.",
    "The present moment is where magic happens.",
    "Concentration is the secret of strength.",
    "Flow state activated! Keep going!",
    "Every minute of focus builds your success.",
    "You're making progress with every focused second.",
    "Digital distractions fade, your potential shines.",
    "Your mind gets stronger with every focused minute.",
    "The reward for discipline is freedom.",
    "Focus turns problems into opportunities.",
    "This focused time is an investment in yourself.",
    "Today's focus becomes tomorrow's success.",
  ];
  
  // Current quote index
  int _currentQuoteIndex = 0;
  bool _showCongratulations = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _secondsRemaining = widget.duration * 60;
    
    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );
    
    // Create a rotation animation for the hourglass
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * pi,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Start animation and repeat
    _animationController.repeat();
    
    // Initialize confetti controller
    _confettiController = ConfettiController(duration: const Duration(seconds: 5));
    
    // Start timer to cycle through quotes
    Timer.periodic(Duration(seconds: 20), (timer) {
      if (mounted) {
        setState(() {
          _currentQuoteIndex = (_currentQuoteIndex + 1) % _motivationalQuotes.length;
        });
      }
    });
    
    _startTimer();
    _enableDeepFocusMode();
  }
  
  @override
  void dispose() {
    _disableDeepFocusMode();
    WidgetsBinding.instance.removeObserver(this);
    _timer.cancel();
    _animationController.dispose();
    _confettiController.dispose();
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
  
  // ensure the status is passed back
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
        
        // Show celebration
        setState(() {
          _showCongratulations = true;
        });
        
        // Play confetti
        _confettiController.play();
        
        // After celebration, call onComplete
        Future.delayed(Duration(seconds: 5), () {
          widget.onComplete(FocusSessionStatus.completed); // Pass the status
        });
      }
    });
  }

  void _failTask() {
    _timer.cancel();
    setState(() {
      _isActive = false;
    });
    _disableDeepFocusMode();
    // Make sure we're explicitly passing the failed status
    widget.onFail(FocusSessionStatus.failed); 
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
        body: Stack(
          children: [
            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (!_showCongratulations) ...[
                    // Animated hourglass
                    AnimatedBuilder(
                      animation: _rotationAnimation,
                      builder: (context, child) {
                        return Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..rotateZ(_rotationAnimation.value),
                          child: Icon(
                            Icons.hourglass_bottom,
                            color: Colors.amber,
                            size: 80,
                          ),
                        );
                      },
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
                    
                    // Motivational quote with animation
                    AnimatedSwitcher(
                      duration: Duration(milliseconds: 500),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                      child: Container(
                        key: ValueKey<int>(_currentQuoteIndex),
                        padding: EdgeInsets.all(20),
                        margin: EdgeInsets.symmetric(vertical: 20, horizontal: 30),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          _motivationalQuotes[_currentQuoteIndex],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontStyle: FontStyle.italic,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 20),
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text('Give Up (Fail Task)', style: TextStyle(fontSize: 16)),
                    ),
                  ],
                  
                  // Show congratulations when timer completes
                  if (_showCongratulations) ...[
                    Icon(
                      Icons.celebration,
                      color: Colors.amber,
                      size: 100,
                    ),
                    SizedBox(height: 20),
                    Text(
                      'CONGRATULATIONS!',
                      style: TextStyle(
                        fontSize: 30, 
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'You completed your focus session successfully!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.green.shade700,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Every focused session builds your productivity muscles!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: () {
                        widget.onComplete(FocusSessionStatus.completed);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text('Return to Tasks', style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ],
              ),
            ),
            
            // Confetti overlay
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: pi / 2, // Straight up
                emissionFrequency: 0.05,
                numberOfParticles: 20,
                maxBlastForce: 100,
                minBlastForce: 50,
                gravity: 0.2,
                shouldLoop: false,
                colors: const [
                  Colors.green,
                  Colors.blue,
                  Colors.pink,
                  Colors.orange,
                  Colors.purple,
                  Colors.yellow,
                ],
              ),
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