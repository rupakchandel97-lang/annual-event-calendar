import 'package:flutter/material.dart';

class EventIconAvatar extends StatelessWidget {
  final String? assetPath;
  final Color backgroundColor;
  final double radius;
  final double iconSize;

  const EventIconAvatar({
    Key? key,
    required this.assetPath,
    required this.backgroundColor,
    this.radius = 20,
    this.iconSize = 20,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final diameter = radius * 2;

    if (assetPath != null && assetPath!.isNotEmpty) {
      return Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: backgroundColor.withOpacity(0.4)),
        ),
        child: ClipOval(
          child: Padding(
            padding: EdgeInsets.all(radius * 0.2),
            child: Image.asset(
              assetPath!,
              fit: BoxFit.contain,
            ),
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      child: Icon(
        Icons.event,
        color: Colors.white,
        size: iconSize,
      ),
    );
  }
}
