import 'package:flutter/material.dart';
import 'dart:math';

class Joystick extends StatefulWidget {
  final Function(Offset) onChange;
  
  const Joystick({super.key, required this.onChange});

  @override
  State<Joystick> createState() => _JoystickState();
}

class _JoystickState extends State<Joystick> {
  Offset _position = Offset.zero;
  final double _size = 100.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        final localPosition = details.localPosition;
        final center = Offset(_size / 2, _size / 2);
        Offset delta = localPosition - center;
        
        double distance = delta.distance;
        if (distance > _size / 2) {
          delta = Offset.fromDirection(delta.direction, _size / 2);
        }
        
        setState(() {
          _position = delta;
        });
        
        // Normalize output to -1.0 to 1.0
        widget.onChange(Offset(
          _position.dx / (_size / 2),
          _position.dy / (_size / 2),
        ));
      },
      onPanEnd: (_) {
        setState(() {
          _position = Offset.zero;
        });
        widget.onChange(Offset.zero);
      },
      child: Container(
        width: _size,
        height: _size,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Transform.translate(
            offset: _position,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
