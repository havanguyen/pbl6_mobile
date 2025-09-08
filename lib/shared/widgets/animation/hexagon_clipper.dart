
import 'package:flutter/material.dart';

class HexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final double width = size.width;
    final double height = size.height;

    path.moveTo(width / 2, 0);
    path.lineTo(width, height * 0.25);
    path.lineTo(width, height * 0.75);
    path.lineTo(width / 2, height);
    path.lineTo(0, height * 0.75);
    path.lineTo(0, height * 0.25);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
