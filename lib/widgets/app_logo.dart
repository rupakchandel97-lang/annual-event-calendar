import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool compact;

  const AppLogo({
    Key? key,
    this.size = 124,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.of(context);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 28 : 36),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette.logoGradientColors,
        ),
        boxShadow: [
          BoxShadow(
            color: palette.logoGradientColors.first.withOpacity(0.24),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -size * 0.16,
            left: -size * 0.04,
            child: Container(
              width: size * 0.72,
              height: size * 0.44,
              decoration: BoxDecoration(
                color: palette.primary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(120),
                  bottomRight: Radius.circular(120),
                ),
              ),
            ),
          ),
          Positioned(
            right: size * 0.1,
            top: size * 0.14,
            child: Container(
              width: size * 0.2,
              height: size * 0.2,
              decoration: BoxDecoration(
                color: palette.accent,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: size * 0.17,
            bottom: size * 0.15,
            child: Container(
              width: size * 0.18,
              height: size * 0.18,
              decoration: BoxDecoration(
                color: palette.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              transform: Matrix4.rotationZ(0.8),
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: EdgeInsets.all(compact ? 14 : 18),
              child: Icon(
                Icons.event_available_rounded,
                size: compact ? 26 : 34,
                color: palette.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
