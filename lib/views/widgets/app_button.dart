import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printagx_app/core/theme/app_theme.dart';

enum AppButtonVariant {
  /// Brand red, the screen's main action.
  primary,
  success,
  danger,

  /// Neutral filled.
  tonal,

  /// Hairline outline.
  outline,

  /// White button for use on dark hero cards.
  inverse,
}

class AppButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool loading;
  final bool compact;

  const AppButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.loading = false,
    this.compact = false,
  });

  (Color bg, Color fg, BorderSide side) _colors(
    AppPalette p,
  ) => switch (variant) {
    AppButtonVariant.primary => (p.primary, p.onPrimary, BorderSide.none),
    AppButtonVariant.success => (p.success, _onAccent(p), BorderSide.none),
    AppButtonVariant.danger => (p.danger, _onAccent(p), BorderSide.none),
    AppButtonVariant.tonal => (p.surfaceMuted, p.textPrimary, BorderSide.none),
    AppButtonVariant.outline => (
      p.surface,
      p.textPrimary,
      BorderSide(color: p.border, width: 1.4),
    ),
    AppButtonVariant.inverse => (Colors.white, AppBrand.ink, BorderSide.none),
  };

  /// Dark-mode accents are bright, so they take ink text instead of white.
  static Color _onAccent(AppPalette p) =>
      p.isDark ? AppBrand.ink : Colors.white;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (bg, fg, side) = _colors(p);
    final enabled = onPressed != null && !loading;

    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: compact ? 46 : 56,
        minWidth: double.infinity,
      ),
      child: FilledButton(
        onPressed: enabled
            ? () {
                HapticFeedback.lightImpact();
                onPressed!();
              }
            : null,
        style: FilledButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          disabledBackgroundColor: loading ? bg : p.surfaceMuted,
          disabledForegroundColor: loading ? fg : p.textMuted,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: side,
          ),
          textStyle: context.text.labelLarge,
        ),
        child: AnimatedSwitcher(
          duration: AppDurations.fast,
          child: loading
              ? SizedBox(
                  key: const ValueKey('loading'),
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4, color: fg),
                )
              : Row(
                  key: const ValueKey('label'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: AppIconSize.md),
                      const SizedBox(width: AppSpace.sm),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Round icon button with a surface background, for headers.
class AppIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  const AppIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: p.surface,
        foregroundColor: p.textPrimary,
        minimumSize: const Size(44, 44),
        side: BorderSide(color: p.border),
      ),
      icon: Icon(icon, size: AppIconSize.md),
    );
  }
}
