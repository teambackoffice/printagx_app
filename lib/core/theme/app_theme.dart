import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Brand constants taken from the Screen Arts logo: printer's ink + signal red.
class AppBrand {
  static const red = Color(0xFFD9301A);
  static const ink = Color(0xFF16161A);
  static const paper = Color(0xFFF6F5F2);
}

class AppSpace {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;

  /// Horizontal page padding.
  static const gutter = 20.0;
}

class AppRadius {
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 28.0;
  static const pill = 999.0;
}

class AppIconSize {
  static const sm = 16.0;
  static const md = 20.0;
  static const lg = 24.0;
}

class AppDurations {
  static const fast = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 250);
  static const slow = Duration(milliseconds: 400);
}

const tabularFigures = [FontFeature.tabularFigures()];

/// Semantic colour tokens. Read them with `context.palette`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final bool isDark;

  final Color background;
  final Color surface;
  final Color surfaceMuted;
  final Color border;

  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  final Color primary;
  final Color onPrimary;
  final Color primarySoft;

  /// Dark "ink slab" used for hero cards.
  final Color hero;
  final Color heroEnd;
  final Color onHero;
  final Color onHeroMuted;

  final Color success;
  final Color successSoft;
  final Color warning;
  final Color warningSoft;
  final Color info;
  final Color infoSoft;
  final Color danger;
  final Color dangerSoft;

  final Color shadow;

  const AppPalette({
    required this.isDark,
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.primary,
    required this.onPrimary,
    required this.primarySoft,
    required this.hero,
    required this.heroEnd,
    required this.onHero,
    required this.onHeroMuted,
    required this.success,
    required this.successSoft,
    required this.warning,
    required this.warningSoft,
    required this.info,
    required this.infoSoft,
    required this.danger,
    required this.dangerSoft,
    required this.shadow,
  });

  static const light = AppPalette(
    isDark: false,
    background: AppBrand.paper,
    surface: Colors.white,
    surfaceMuted: Color(0xFFF0EFEB),
    border: Color(0xFFE6E4DF),
    textPrimary: AppBrand.ink,
    textSecondary: Color(0xFF62616A),
    textMuted: Color(0xFF8E8D95),
    primary: AppBrand.red,
    onPrimary: Colors.white,
    primarySoft: Color(0xFFFCEBE7),
    hero: Color(0xFF1B1B20),
    heroEnd: Color(0xFF2C2C34),
    onHero: Colors.white,
    onHeroMuted: Color(0xB3FFFFFF),
    success: Color(0xFF1C8A57),
    successSoft: Color(0xFFE3F4EA),
    warning: Color(0xFFB06900),
    warningSoft: Color(0xFFFFF1D9),
    info: Color(0xFF3D59D6),
    infoSoft: Color(0xFFE9EDFC),
    danger: Color(0xFFC4281C),
    dangerSoft: Color(0xFFFBE9E7),
    shadow: Color(0x0F16161A),
  );

  static const dark = AppPalette(
    isDark: true,
    background: Color(0xFF0E0E11),
    surface: Color(0xFF18181C),
    surfaceMuted: Color(0xFF222227),
    border: Color(0xFF2C2C33),
    textPrimary: Color(0xFFF3F2EF),
    textSecondary: Color(0xFFA9A8B1),
    textMuted: Color(0xFF7A7982),
    primary: Color(0xFFE5402A),
    onPrimary: Colors.white,
    primarySoft: Color(0xFF3A1B16),
    hero: Color(0xFF212127),
    heroEnd: Color(0xFF2E2E36),
    onHero: Colors.white,
    onHeroMuted: Color(0xB3FFFFFF),
    success: Color(0xFF3CC488),
    successSoft: Color(0xFF15301F),
    warning: Color(0xFFF0A93B),
    warningSoft: Color(0xFF33270F),
    info: Color(0xFF8197F6),
    infoSoft: Color(0xFF1D2340),
    danger: Color(0xFFF26B5B),
    dangerSoft: Color(0xFF3A1A17),
    shadow: Color(0x00000000),
  );

  List<BoxShadow> get cardShadow => isDark
      ? const []
      : [
          BoxShadow(color: shadow, blurRadius: 18, offset: const Offset(0, 6)),
          BoxShadow(
            color: shadow.withValues(alpha: 0.03),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ];

  LinearGradient get heroGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [hero, heroEnd],
  );

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(AppPalette? other, double t) =>
      other == null || t < 0.5 ? this : other;
}

extension AppThemeContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
  TextTheme get text => Theme.of(this).textTheme;
}

class AppTheme {
  static ThemeData get light => _build(AppPalette.light);
  static ThemeData get dark => _build(AppPalette.dark);

  static ThemeData _build(AppPalette p) {
    final brightness = p.isDark ? Brightness.dark : Brightness.light;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppBrand.red,
      brightness: brightness,
      primary: p.primary,
      onPrimary: p.onPrimary,
      surface: p.surface,
      onSurface: p.textPrimary,
      error: p.danger,
      outline: p.border,
      outlineVariant: p.border,
    );
    final typography = Typography.material2021();
    final text = (p.isDark ? typography.white : typography.black).merge(
      _textTheme(p),
    );

    OutlineInputBorder inputBorder(Color c, [double w = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: c, width: w),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.background,
      canvasColor: p.background,
      textTheme: text,
      extensions: [p],
      splashFactory: InkSparkle.splashFactory,
      dividerTheme: DividerThemeData(color: p.border, thickness: 1, space: 1),
      iconTheme: IconThemeData(color: p.textSecondary, size: AppIconSize.lg),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: p.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        systemOverlayStyle: p.isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        hintStyle: text.bodyLarge?.copyWith(color: p.textMuted),
        prefixIconColor: WidgetStateColor.resolveWith(
          (s) => s.contains(WidgetState.focused) ? p.primary : p.textMuted,
        ),
        suffixIconColor: p.textSecondary,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 17,
          horizontal: AppSpace.lg,
        ),
        border: inputBorder(p.border),
        enabledBorder: inputBorder(p.border),
        focusedBorder: inputBorder(p.primary, 1.6),
        errorBorder: inputBorder(p.danger),
        focusedErrorBorder: inputBorder(p.danger, 1.6),
        errorStyle: text.bodySmall?.copyWith(color: p.danger),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: p.primary,
        selectionColor: p.primary.withValues(alpha: 0.25),
        selectionHandleColor: p.primary,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.primary,
          textStyle: text.labelLarge?.copyWith(fontSize: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.isDark ? p.surfaceMuted : AppBrand.ink,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        dragHandleColor: p.border,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.primary,
        linearTrackColor: p.primarySoft,
        refreshBackgroundColor: p.surface,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: p.isDark ? p.surfaceMuted : AppBrand.ink,
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        textStyle: text.bodySmall?.copyWith(color: Colors.white),
      ),
    );
  }

  static TextTheme _textTheme(AppPalette p) {
    TextStyle s(
      double size,
      FontWeight weight, {
      double spacing = 0,
      double? height,
      Color? color,
    }) => TextStyle(
      fontSize: size,
      fontWeight: weight,
      letterSpacing: spacing,
      height: height,
      color: color ?? p.textPrimary,
    );

    return TextTheme(
      // Live timers.
      displayMedium: s(52, FontWeight.w800, spacing: -2, height: 1),
      displaySmall: s(40, FontWeight.w800, spacing: -1.4, height: 1),
      // Screen titles.
      headlineMedium: s(30, FontWeight.w800, spacing: -1, height: 1.1),
      headlineSmall: s(24, FontWeight.w800, spacing: -0.6, height: 1.15),
      // Card and section titles.
      titleLarge: s(19, FontWeight.w700, spacing: -0.4, height: 1.25),
      titleMedium: s(16, FontWeight.w700, spacing: -0.2, height: 1.3),
      titleSmall: s(14, FontWeight.w700, spacing: -0.1, height: 1.3),
      bodyLarge: s(16, FontWeight.w400, height: 1.45),
      bodyMedium: s(14, FontWeight.w400, height: 1.45, color: p.textSecondary),
      bodySmall: s(12.5, FontWeight.w500, height: 1.4, color: p.textSecondary),
      labelLarge: s(15, FontWeight.w700, spacing: 0.1),
      labelMedium: s(12.5, FontWeight.w600, color: p.textSecondary),
      // Overlines.
      labelSmall: s(11, FontWeight.w700, spacing: 1.2, color: p.textMuted),
    );
  }
}
