import 'package:flutter/material.dart';

class ScaleAnimatedButton extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double scaleFactor;

  const ScaleAnimatedButton({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 0),
    this.scaleFactor = 0.95,
  });

  @override
  ScaleAnimatedButtonState createState() => ScaleAnimatedButtonState();
}

class ScaleAnimatedButtonState extends State<ScaleAnimatedButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (details) => setState(() => _isPressed = true),
      onPointerUp: (details) => setState(() => _isPressed = false),
      onPointerCancel: (details) => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? widget.scaleFactor : 1.0,
        duration: widget.duration,
        child: widget.child,
      ),
    );
  }
}