import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  final String photoUrl;
  final double radius;
  final double iconSize;

  const ProfileAvatar({
    super.key,
    required this.photoUrl,
    this.radius = 40,
    this.iconSize = 40,
  });

  @override
  Widget build(BuildContext context) {
    final trimmedUrl = photoUrl.trim();
    final hasPhoto = trimmedUrl.isNotEmpty;

    return CircleAvatar(
      radius: radius,
      backgroundImage: hasPhoto ? NetworkImage(trimmedUrl) : null,
      onBackgroundImageError: hasPhoto ? (_, __) {} : null,
      child: hasPhoto ? null : Icon(Icons.person, size: iconSize),
    );
  }
}
