import 'package:flutter/material.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';

Widget CustomCircularButton(
    BuildContext context, {
      required double size,
      required IconData icon,
      required String label,
      required VoidCallback onTap,
    }) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Colors.blue.shade200, Colors.blue],
          begin: Alignment.bottomLeft,
          end: Alignment.topCenter,
        ),
        border: Border.all(
          color: context.theme.blue.withOpacity(0.2),
          width: 10,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: size * 0.25,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.11,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ),
  );
}