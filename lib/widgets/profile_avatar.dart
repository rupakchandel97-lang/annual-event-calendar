import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
    final resolvedUrl = _resolveDisplayableUrl(photoUrl);
    final diameter = radius * 2;

    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: ClipOval(
        child: resolvedUrl == null
            ? _buildFallbackIcon(context)
            : CachedNetworkImage(
                imageUrl: resolvedUrl,
                fit: BoxFit.cover,
                width: diameter,
                height: diameter,
                errorWidget: (_, __, ___) => _buildFallbackIcon(context),
                placeholder: (_, __) => _buildFallbackIcon(context),
              ),
      ),
    );
  }

  String? _resolveDisplayableUrl(String rawUrl) {
    final trimmedUrl = rawUrl.trim();
    if (trimmedUrl.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(trimmedUrl);
    if (uri == null || !uri.hasScheme) {
      return null;
    }

    if (uri.scheme == 'http' || uri.scheme == 'https') {
      return trimmedUrl;
    }

    return null;
  }

  Widget _buildFallbackIcon(BuildContext context) {
    return Center(
      child: Icon(
        Icons.person,
        size: iconSize,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
