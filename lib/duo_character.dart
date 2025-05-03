import 'package:flutter/material.dart';

class DuoCharacter extends StatefulWidget {
  final double size;
  final bool isJumping;
  final bool shouldAnimateSmile; // New property

  const DuoCharacter({
    Key? key,
    this.size = 100,
    this.isJumping = false,
    this.shouldAnimateSmile = false, // Default to false
  }) : super(key: key);

  @override
  _DuoCharacterState createState() => _DuoCharacterState();
}

class _DuoCharacterState extends State<DuoCharacter> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _jumpAnimation;
  late Animation<double> _smileAnimation; 

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    if (widget.isJumping) {
      _controller.repeat(reverse: true);
    }
    
    _jumpAnimation = Tween<double>(begin: 0, end: -15).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
    
    // New smile animation
    _smileAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
    
    if (widget.shouldAnimateSmile) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _jumpAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, widget.isJumping ? _jumpAnimation.value : 0),
              child: child,
            );
          },
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Eyes
                Positioned(
                  top: widget.size * 0.3,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: widget.size * 0.15,
                        height: widget.size * 0.15,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: widget.size * 0.2),
                      Container(
                        width: widget.size * 0.15,
                        height: widget.size * 0.15,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
                // Smile - Now animated
                Positioned(
                  top: widget.size * 0.5,
                  child: AnimatedBuilder(
                    animation: _smileAnimation,
                    builder: (context, child) {
                      return Container(
                        width: widget.size * (0.3 + 0.1 * _smileAnimation.value),
                        height: widget.size * (0.05 + 0.05 * _smileAnimation.value),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                            topLeft: Radius.circular(_smileAnimation.value * 10),
                            topRight: Radius.circular(_smileAnimation.value * 10),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        // Added text below character
        SizedBox(height: 10),
        Text(
          "Howdy?",
          style: TextStyle(
            fontSize: widget.size * 0.2,
            fontWeight: FontWeight.bold,
            color: Colors.green[800],
          ),
        ),
      ],
    );
  }
}