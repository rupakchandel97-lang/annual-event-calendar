import 'package:flutter/material.dart';

@immutable
class AppThemePalette extends ThemeExtension<AppThemePalette> {
  final String id;
  final String heading;
  final String name;
  final String description;
  final Brightness brightness;
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color textPrimary;
  final Color textMuted;
  final Color outline;
  final Color navBackground;
  final Color navIndicator;
  final Color heroOverlayStart;
  final Color heroOverlayEnd;
  final Color chipBackground;
  final Color badgeAdmin;
  final Color badgeMember;
  final Color success;
  final Color error;
  final List<Color> gradientColors;
  final List<Color> logoGradientColors;

  const AppThemePalette({
    required this.id,
    required this.heading,
    required this.name,
    required this.description,
    required this.brightness,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.textPrimary,
    required this.textMuted,
    required this.outline,
    required this.navBackground,
    required this.navIndicator,
    required this.heroOverlayStart,
    required this.heroOverlayEnd,
    required this.chipBackground,
    required this.badgeAdmin,
    required this.badgeMember,
    required this.success,
    required this.error,
    required this.gradientColors,
    required this.logoGradientColors,
  });

  bool get isDark => brightness == Brightness.dark;

  Color get onPrimary =>
      ThemeData.estimateBrightnessForColor(primary) == Brightness.dark
          ? Colors.white
          : Colors.black;

  Color get onSecondary =>
      ThemeData.estimateBrightnessForColor(secondary) == Brightness.dark
          ? Colors.white
          : Colors.black;

  Color get onAccent =>
      ThemeData.estimateBrightnessForColor(accent) == Brightness.dark
          ? Colors.white
          : Colors.black;

  Color get vibrantBackground => AppTheme._blend(
        background,
        AppTheme._blend(primary, accent, isDark ? 0.35 : 0.24),
        isDark ? 0.14 : 0.08,
      );

  Color get vibrantSurface => AppTheme._blend(
        surface,
        AppTheme._blend(primary, accent, 0.5),
        isDark ? 0.18 : 0.09,
      );

  Color get vibrantSurfaceAlt => AppTheme._blend(
        surfaceAlt,
        AppTheme._blend(secondary, accent, 0.45),
        isDark ? 0.22 : 0.12,
      );

  Color get vibrantOutline => AppTheme._blend(
        outline,
        primary,
        isDark ? 0.28 : 0.16,
      );

  Color get vibrantNavBackground => AppTheme._blend(
        navBackground,
        AppTheme._blend(primary, secondary, 0.45),
        isDark ? 0.18 : 0.22,
      );

  Color get vibrantNavIndicator => AppTheme._blend(
        navIndicator,
        accent,
        isDark ? 0.22 : 0.3,
      );

  Color get navSelectedContentColor =>
      AppTheme._foregroundFor(vibrantNavIndicator);

  Color get navUnselectedContentColor =>
      AppTheme._bestContrastingColor(vibrantNavBackground).withOpacity(
        isDark ? 0.9 : 0.92,
      );

  LinearGradient get pageGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppTheme._blend(gradientColors[0], primary, isDark ? 0.1 : 0.06),
          AppTheme._blend(
            gradientColors[1],
            AppTheme._blend(primary, accent, 0.45),
            isDark ? 0.14 : 0.1,
          ),
          AppTheme._blend(gradientColors[2], accent, isDark ? 0.18 : 0.12),
        ],
        stops: const [0.0, 0.5, 1.0],
      );

  @override
  AppThemePalette copyWith({
    String? id,
    String? heading,
    String? name,
    String? description,
    Brightness? brightness,
    Color? primary,
    Color? secondary,
    Color? accent,
    Color? background,
    Color? surface,
    Color? surfaceAlt,
    Color? textPrimary,
    Color? textMuted,
    Color? outline,
    Color? navBackground,
    Color? navIndicator,
    Color? heroOverlayStart,
    Color? heroOverlayEnd,
    Color? chipBackground,
    Color? badgeAdmin,
    Color? badgeMember,
    Color? success,
    Color? error,
    List<Color>? gradientColors,
    List<Color>? logoGradientColors,
  }) {
    return AppThemePalette(
      id: id ?? this.id,
      heading: heading ?? this.heading,
      name: name ?? this.name,
      description: description ?? this.description,
      brightness: brightness ?? this.brightness,
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      accent: accent ?? this.accent,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      textPrimary: textPrimary ?? this.textPrimary,
      textMuted: textMuted ?? this.textMuted,
      outline: outline ?? this.outline,
      navBackground: navBackground ?? this.navBackground,
      navIndicator: navIndicator ?? this.navIndicator,
      heroOverlayStart: heroOverlayStart ?? this.heroOverlayStart,
      heroOverlayEnd: heroOverlayEnd ?? this.heroOverlayEnd,
      chipBackground: chipBackground ?? this.chipBackground,
      badgeAdmin: badgeAdmin ?? this.badgeAdmin,
      badgeMember: badgeMember ?? this.badgeMember,
      success: success ?? this.success,
      error: error ?? this.error,
      gradientColors: gradientColors ?? this.gradientColors,
      logoGradientColors: logoGradientColors ?? this.logoGradientColors,
    );
  }

  @override
  AppThemePalette lerp(ThemeExtension<AppThemePalette>? other, double t) {
    if (other is! AppThemePalette) {
      return this;
    }

    Color lerpColor(Color a, Color b) => Color.lerp(a, b, t) ?? a;

    return copyWith(
      primary: lerpColor(primary, other.primary),
      secondary: lerpColor(secondary, other.secondary),
      accent: lerpColor(accent, other.accent),
      background: lerpColor(background, other.background),
      surface: lerpColor(surface, other.surface),
      surfaceAlt: lerpColor(surfaceAlt, other.surfaceAlt),
      textPrimary: lerpColor(textPrimary, other.textPrimary),
      textMuted: lerpColor(textMuted, other.textMuted),
      outline: lerpColor(outline, other.outline),
      navBackground: lerpColor(navBackground, other.navBackground),
      navIndicator: lerpColor(navIndicator, other.navIndicator),
      heroOverlayStart: lerpColor(heroOverlayStart, other.heroOverlayStart),
      heroOverlayEnd: lerpColor(heroOverlayEnd, other.heroOverlayEnd),
      chipBackground: lerpColor(chipBackground, other.chipBackground),
      badgeAdmin: lerpColor(badgeAdmin, other.badgeAdmin),
      badgeMember: lerpColor(badgeMember, other.badgeMember),
      success: lerpColor(success, other.success),
      error: lerpColor(error, other.error),
      gradientColors: [
        lerpColor(gradientColors[0], other.gradientColors[0]),
        lerpColor(gradientColors[1], other.gradientColors[1]),
        lerpColor(gradientColors[2], other.gradientColors[2]),
      ],
      logoGradientColors: [
        lerpColor(logoGradientColors[0], other.logoGradientColors[0]),
        lerpColor(logoGradientColors[1], other.logoGradientColors[1]),
      ],
    );
  }
}

class AppTheme {
  static const String defaultThemeId = 'current_default';
  static const String guestThemeId = 'theme_5_modern_professional';

  static final List<AppThemePalette> themes = [
    const AppThemePalette(
      id: defaultThemeId,
      heading: 'CURRENT THEME (DEFAULT)',
      name: 'Golden Harvest',
      description: 'The current warm, family-friendly look of the app.',
      brightness: Brightness.light,
      primary: Color(0xFFE5A65B),
      secondary: Color(0xFF5E5145),
      accent: Color(0xFFF2D47C),
      background: Color(0xFFF9F6F1),
      surface: Color(0xFFFFFFFF),
      surfaceAlt: Color(0xFFFFF1E1),
      textPrimary: Color(0xFF5E5145),
      textMuted: Color(0xFF8D7F72),
      outline: Color(0xFFE2D8CB),
      navBackground: Color(0xFFC98236),
      navIndicator: Color(0xFF8F5A24),
      heroOverlayStart: Color(0x14000000),
      heroOverlayEnd: Color(0x47000000),
      chipBackground: Color(0x33F2D47C),
      badgeAdmin: Color(0xFFFFD59E),
      badgeMember: Color(0xFFC7DCF8),
      success: Color(0xFF4E8F55),
      error: Color(0xFFB15F4A),
      gradientColors: [
        Color(0xFFFFFFFF),
        Color(0xFFFFF1E1),
        Color(0xFFFFF8DB),
      ],
      logoGradientColors: [
        Color(0xFF7A6755),
        Color(0xFF405A72),
      ],
    ),
    const AppThemePalette(
      id: 'theme_1_user_profile_palette',
      heading: 'THEME 1 - USER PROFILE PALETTE',
      name: 'Lingering Lilac',
      description: 'Soft lilac surfaces with iris accents and deep ink text.',
      brightness: Brightness.light,
      primary: Color(0xFF8692D2),
      secondary: Color(0xFF905772),
      accent: Color(0xFFC17596),
      background: Color(0xFFE2DDF6),
      surface: Color(0xFFF8F5FD),
      surfaceAlt: Color(0xFFC0A5D6),
      textPrimary: Color(0xFF201D23),
      textMuted: Color(0xFF6E6073),
      outline: Color(0xFFD2C5E5),
      navBackground: Color(0xFF905772),
      navIndicator: Color(0xFFC17596),
      heroOverlayStart: Color(0x10000000),
      heroOverlayEnd: Color(0x44000000),
      chipBackground: Color(0x26C17596),
      badgeAdmin: Color(0xFFFFD6E7),
      badgeMember: Color(0xFFD7DDFC),
      success: Color(0xFF6F8F7B),
      error: Color(0xFF8A355A),
      gradientColors: [
        Color(0xFFF7F4FC),
        Color(0xFFE2DDF6),
        Color(0xFFC0A5D6),
      ],
      logoGradientColors: [
        Color(0xFF905772),
        Color(0xFF8692D2),
      ],
    ),
    const AppThemePalette(
      id: 'theme_2_app_color_palette',
      heading: 'THEME 2 - APP COLOR PALETTE',
      name: 'Urban Grove',
      description: 'Balanced green, stone, and spice tones for a grounded UI.',
      brightness: Brightness.light,
      primary: Color(0xFF66B43E),
      secondary: Color(0xFF55575A),
      accent: Color(0xFFB96A29),
      background: Color(0xFFF3F5F2),
      surface: Color(0xFFFFFFFF),
      surfaceAlt: Color(0xFFB8BAB8),
      textPrimary: Color(0xFF272628),
      textMuted: Color(0xFF6B7175),
      outline: Color(0xFFD3D5D2),
      navBackground: Color(0xFF272628),
      navIndicator: Color(0xFF66B43E),
      heroOverlayStart: Color(0x12000000),
      heroOverlayEnd: Color(0x50000000),
      chipBackground: Color(0x2466B43E),
      badgeAdmin: Color(0xFFFFD7B2),
      badgeMember: Color(0xFFD2E8C5),
      success: Color(0xFF4E944F),
      error: Color(0xFF9A4E1D),
      gradientColors: [
        Color(0xFFFFFFFF),
        Color(0xFFE5E8E3),
        Color(0xFFB8BAB8),
      ],
      logoGradientColors: [
        Color(0xFF272628),
        Color(0xFF66B43E),
      ],
    ),
    const AppThemePalette(
      id: 'theme_3_icon_color_palette',
      heading: 'THEME 3 - ICON COLOR PALETTE',
      name: 'Gallery Stone',
      description: 'Calm porcelain neutrals with a museum-grade accent mix.',
      brightness: Brightness.light,
      primary: Color(0xFFBAC8E0),
      secondary: Color(0xFF8F917C),
      accent: Color(0xFFD0BEA3),
      background: Color(0xFFF5F4F7),
      surface: Color(0xFFFFFFFF),
      surfaceAlt: Color(0xFFEBDBD3),
      textPrimary: Color(0xFF1F1F1F),
      textMuted: Color(0xFF6B6D63),
      outline: Color(0xFFD9D6DD),
      navBackground: Color(0xFF8F917C),
      navIndicator: Color(0xFFBAC8E0),
      heroOverlayStart: Color(0x10000000),
      heroOverlayEnd: Color(0x42000000),
      chipBackground: Color(0x26D0BEA3),
      badgeAdmin: Color(0xFFF1DFC8),
      badgeMember: Color(0xFFD9E3F4),
      success: Color(0xFF7A8C69),
      error: Color(0xFF8B5C4A),
      gradientColors: [
        Color(0xFFFFFFFF),
        Color(0xFFF5F4F7),
        Color(0xFFEBDBD3),
      ],
      logoGradientColors: [
        Color(0xFF8F917C),
        Color(0xFFBAC8E0),
      ],
    ),
    const AppThemePalette(
      id: 'theme_5_modern_professional',
      heading: 'THEME 5 - MODERN PROFESSIONAL',
      name: 'Studio Spectrum',
      description: 'Bright modern accents arranged in a crisp professional shell.',
      brightness: Brightness.light,
      primary: Color(0xFF00A4EF),
      secondary: Color(0xFF7FBA00),
      accent: Color(0xFFF25022),
      background: Color(0xFFF8FBFF),
      surface: Color(0xFFFFFFFF),
      surfaceAlt: Color(0xFFEAF4FB),
      textPrimary: Color(0xFF19313F),
      textMuted: Color(0xFF55707E),
      outline: Color(0xFFD3E4EE),
      navBackground: Color(0xFF0B5E8E),
      navIndicator: Color(0xFFFFB900),
      heroOverlayStart: Color(0x12003247),
      heroOverlayEnd: Color(0x55003247),
      chipBackground: Color(0x1FFFB900),
      badgeAdmin: Color(0xFFFFE1C2),
      badgeMember: Color(0xFFD8F0BE),
      success: Color(0xFF5E9F21),
      error: Color(0xFFD94F28),
      gradientColors: [
        Color(0xFFFFFFFF),
        Color(0xFFE9F8FF),
        Color(0xFFFFF0C8),
      ],
      logoGradientColors: [
        Color(0xFF00A4EF),
        Color(0xFF7FBA00),
      ],
    ),
    const AppThemePalette(
      id: 'theme_6_eco_friendly_balanced',
      heading: 'THEME 6 - ECO-FRIENDLY/BALANCED',
      name: 'Sage Linen',
      description: 'Natural olive and linen tones with a calm editorial feel.',
      brightness: Brightness.light,
      primary: Color(0xFF556B2F),
      secondary: Color(0xFFA4B88F),
      accent: Color(0xFFFAF0E6),
      background: Color(0xFFF5F0E9),
      surface: Color(0xFFFFFCF7),
      surfaceAlt: Color(0xFFE3EAD8),
      textPrimary: Color(0xFF31401D),
      textMuted: Color(0xFF70805B),
      outline: Color(0xFFD5D9C8),
      navBackground: Color(0xFF556B2F),
      navIndicator: Color(0xFFA4B88F),
      heroOverlayStart: Color(0x10000000),
      heroOverlayEnd: Color(0x42000000),
      chipBackground: Color(0x24A4B88F),
      badgeAdmin: Color(0xFFEAD7BC),
      badgeMember: Color(0xFFDCE8D0),
      success: Color(0xFF557A46),
      error: Color(0xFF8B4C3C),
      gradientColors: [
        Color(0xFFFFFCF7),
        Color(0xFFFAF0E6),
        Color(0xFFA4B88F),
      ],
      logoGradientColors: [
        Color(0xFF556B2F),
        Color(0xFFA4B88F),
      ],
    ),
    const AppThemePalette(
      id: 'theme_7_energetic_playful',
      heading: 'THEME 7 - ENERGETIC & PLAYFUL',
      name: 'Sunburst Pop',
      description: 'Cheerful reds and yellows for a lively household planner.',
      brightness: Brightness.light,
      primary: Color(0xFFFF6B6B),
      secondary: Color(0xFFFFD93D),
      accent: Color(0xFFFFB86B),
      background: Color(0xFFFFFBF6),
      surface: Color(0xFFFFFFFF),
      surfaceAlt: Color(0xFFFFF3C2),
      textPrimary: Color(0xFF4A3030),
      textMuted: Color(0xFF8F6B2E),
      outline: Color(0xFFF1DFC4),
      navBackground: Color(0xFFFF6B6B),
      navIndicator: Color(0xFFFFD93D),
      heroOverlayStart: Color(0x0C000000),
      heroOverlayEnd: Color(0x39000000),
      chipBackground: Color(0x2BFFD93D),
      badgeAdmin: Color(0xFFFFD2A8),
      badgeMember: Color(0xFFFFF0A3),
      success: Color(0xFF4B9C63),
      error: Color(0xFFCC4A4A),
      gradientColors: [
        Color(0xFFFFFFFF),
        Color(0xFFFFF2D9),
        Color(0xFFFFE2E2),
      ],
      logoGradientColors: [
        Color(0xFFFF6B6B),
        Color(0xFFFFD93D),
      ],
    ),
    const AppThemePalette(
      id: 'theme_8_dark_mode_modern',
      heading: 'THEME 8 - DARK MODE MODERN',
      name: 'Midnight Modern',
      description: 'A dark interface with elevated surfaces and vivid purple focus.',
      brightness: Brightness.dark,
      primary: Color(0xFFBB86FC),
      secondary: Color(0xFF1E1E1E),
      accent: Color(0xFF03DAC6),
      background: Color(0xFF121212),
      surface: Color(0xFF1E1E1E),
      surfaceAlt: Color(0xFF2A2A2A),
      textPrimary: Color(0xFFF4EEFF),
      textMuted: Color(0xFFB9AEC9),
      outline: Color(0xFF37313E),
      navBackground: Color(0xFF1E1E1E),
      navIndicator: Color(0xFFBB86FC),
      heroOverlayStart: Color(0x22000000),
      heroOverlayEnd: Color(0x7A000000),
      chipBackground: Color(0x29BB86FC),
      badgeAdmin: Color(0xFF5A4031),
      badgeMember: Color(0xFF2A4661),
      success: Color(0xFF57D694),
      error: Color(0xFFEF9A9A),
      gradientColors: [
        Color(0xFF121212),
        Color(0xFF18141F),
        Color(0xFF241A31),
      ],
      logoGradientColors: [
        Color(0xFF1E1E1E),
        Color(0xFFBB86FC),
      ],
    ),
    const AppThemePalette(
      id: 'theme_9_electric_wave',
      heading: 'THEME 9 - ELECTRIC WAVE',
      name: 'Electric Wave',
      description:
          'Glossy cobalt, aqua mist, and neon bloom accents inspired by modern wellness and delivery apps.',
      brightness: Brightness.light,
      primary: Color(0xFF4A7DFF),
      secondary: Color(0xFF2142B8),
      accent: Color(0xFFF07BD8),
      background: Color(0xFFEAF3FF),
      surface: Color(0xFFFDFEFF),
      surfaceAlt: Color(0xFFCFE2FF),
      textPrimary: Color(0xFF19305D),
      textMuted: Color(0xFF6983B8),
      outline: Color(0xFFAFC7F2),
      navBackground: Color(0xFF2948C6),
      navIndicator: Color(0xFF7DDCFF),
      heroOverlayStart: Color(0x08102A7A),
      heroOverlayEnd: Color(0x4D16388F),
      chipBackground: Color(0x33AEE9FF),
      badgeAdmin: Color(0xFFFFD4F2),
      badgeMember: Color(0xFFD6F5FF),
      success: Color(0xFF2FBF9F),
      error: Color(0xFFD95B8A),
      gradientColors: [
        Color(0xFFFDFEFF),
        Color(0xFFDCEBFF),
        Color(0xFFB9D0FF),
      ],
      logoGradientColors: [
        Color(0xFF4A7DFF),
        Color(0xFFF07BD8),
      ],
    ),
  ];

  static AppThemePalette paletteFor(String? id) {
    return themes.firstWhere(
      (theme) => theme.id == id,
      orElse: () => themes.first,
    );
  }

  static ThemeData themeDataFor(String? id) {
    final palette = paletteFor(id);
    final backgroundColor = palette.vibrantBackground;
    final surfaceColor = palette.vibrantSurface;
    final surfaceAltColor = palette.vibrantSurfaceAlt;
    final outlineColor = palette.vibrantOutline;
    final navBackgroundColor = palette.vibrantNavBackground;
    final navIndicatorColor = palette.vibrantNavIndicator;
    final colorScheme = ColorScheme(
      brightness: palette.brightness,
      primary: palette.primary,
      onPrimary: palette.onPrimary,
      secondary: palette.secondary,
      onSecondary: palette.onSecondary,
      error: palette.error,
      onError: palette.isDark ? Colors.black : Colors.white,
      background: backgroundColor,
      onBackground: palette.textPrimary,
      surface: surfaceColor,
      onSurface: palette.textPrimary,
      surfaceTint: surfaceAltColor,
      outline: outlineColor,
      outlineVariant: outlineColor.withOpacity(0.7),
      shadow: palette.isDark ? Colors.black54 : const Color(0x22000000),
      scrim: const Color(0x66000000),
      inverseSurface: palette.textPrimary,
      onInverseSurface: backgroundColor,
      inversePrimary: palette.accent,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: palette.brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.transparent,
      fontFamily: 'Poppins',
      extensions: [palette],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: palette.textPrimary,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        surfaceTintColor: surfaceColor,
        elevation: palette.isDark ? 0 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: outlineColor.withOpacity(0.75)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: navBackgroundColor,
        indicatorColor: navIndicatorColor,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          final color = isSelected
              ? palette.navSelectedContentColor
              : palette.navUnselectedContentColor;
          return IconThemeData(
            color: color,
            size: isSelected ? 26 : 24,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return TextStyle(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? palette.navSelectedContentColor
                : palette.navUnselectedContentColor,
          );
        }),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        elevation: 8,
        height: 72,
        surfaceTintColor: navBackgroundColor,
        shadowColor: palette.isDark ? Colors.black54 : const Color(0x26000000),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: palette.primary,
        foregroundColor: palette.onPrimary,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.secondary,
          foregroundColor: palette.onSecondary,
          elevation: 0,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.textPrimary,
          minimumSize: const Size.fromHeight(56),
          side: BorderSide(color: palette.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceAltColor.withOpacity(palette.isDark ? 0.52 : 0.56),
        hintStyle: TextStyle(color: palette.textMuted),
        prefixIconColor: palette.secondary,
        suffixIconColor: palette.secondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: outlineColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: palette.primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: palette.error),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.secondary,
        contentTextStyle: TextStyle(color: palette.onSecondary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: DividerThemeData(
        color: outlineColor.withOpacity(0.7),
      ),
      expansionTileTheme: ExpansionTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: palette.secondary,
        textColor: palette.textPrimary,
      ),
      textTheme: ThemeData(
        brightness: palette.brightness,
        fontFamily: 'Poppins',
      ).textTheme.apply(
            bodyColor: palette.textPrimary,
            displayColor: palette.textPrimary,
          ),
    );
  }

  static BoxDecoration backgroundDecorationFor(String? id) {
    final palette = paletteFor(id);
    return BoxDecoration(gradient: palette.pageGradient);
  }

  static AppThemePalette of(BuildContext context) {
    return Theme.of(context).extension<AppThemePalette>() ?? themes.first;
  }

  static Color _foregroundFor(Color background) {
    return ThemeData.estimateBrightnessForColor(background) == Brightness.dark
        ? Colors.white
        : Colors.black;
  }

  static Color _mutedForegroundFor(Color background) {
    return _foregroundFor(background).withOpacity(0.84);
  }

  static Color _blend(Color base, Color overlay, double amount) {
    final overlayOpacity = amount.clamp(0.0, 1.0);
    return Color.alphaBlend(overlay.withOpacity(overlayOpacity), base);
  }

  static Color _bestContrastingColor(Color background) {
    const white = Colors.white;
    const black = Colors.black;
    final whiteContrast = _contrastRatio(background, white);
    final blackContrast = _contrastRatio(background, black);
    return whiteContrast >= blackContrast ? white : black;
  }

  static double _contrastRatio(Color a, Color b) {
    final l1 = a.computeLuminance();
    final l2 = b.computeLuminance();
    final lighter = l1 > l2 ? l1 : l2;
    final darker = l1 > l2 ? l2 : l1;
    return (lighter + 0.05) / (darker + 0.05);
  }
}
