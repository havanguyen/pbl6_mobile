import 'package:flutter/material.dart';

class CustomButtonBlue extends StatelessWidget {
  final VoidCallback onTap;
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final Color textColor;

  const CustomButtonBlue({
    super.key,
    required this.onTap,
    required this.text,
    this.fontSize = 18,
    this.fontWeight = FontWeight.w400,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade200, Colors.blue.shade500],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 15),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: fontSize,
                fontWeight: fontWeight,
              ),
            ),
          ),
        ),
      ),
    );
  }
}