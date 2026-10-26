import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printagx_app/core/theme/app_theme.dart';
import 'package:printagx_app/views/widgets/brand.dart';
import 'package:printagx_app/views/widgets/motion.dart';

/// Standard white card: hairline border, soft shadow, optional tap.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final double radius;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpace.lg),
    this.onTap,
    this.color,
    this.borderColor,
    this.radius = AppRadius.lg,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: borderColor ?? p.border, width: 0.8),
    );

    return PressableScale(
      enabled: onTap != null,
      child: DecoratedBox(
        decoration: ShapeDecoration(shape: shape, shadows: p.cardShadow),
        child: Material(
          color: color ?? p.surface,
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap == null
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    onTap!();
                  },
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

/// Dark "ink slab" card with a faint halftone texture, for the key figure on
/// a screen. Pass [color] to tint it (e.g. green while checked in).
class HeroCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  const HeroCard({
    super.key,
    required this.child,
    this.color,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpace.xl),
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final gradient = color == null
        ? p.heroGradient
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            // Bright dark-mode accents are deepened to keep white text legible.
            colors: [
              Color.lerp(color, Colors.black, p.isDark ? 0.42 : 0)!,
              Color.lerp(color, Colors.black, p.isDark ? 0.58 : 0.22)!,
            ],
          );
    final radius = BorderRadius.circular(AppRadius.xl);

    return PressableScale(
      enabled: onTap != null,
      child: AnimatedContainer(
        duration: AppDurations.slow,
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: radius,
          border: p.isDark && color == null
              ? Border.all(color: p.border)
              : null,
          boxShadow: p.isDark
              ? null
              : [
                  BoxShadow(
                    color: (color ?? p.hero).withValues(alpha: 0.28),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap == null
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    onTap!();
                  },
            child: Stack(
              children: [
                const Positioned(
                  top: 0,
                  right: 0,
                  width: 180,
                  height: 140,
                  child: Halftone(opacity: 0.09),
                ),
                Padding(padding: padding, child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Section title with an optional trailing action.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? trailing;

  const SectionHeader(
    this.title, {
    super.key,
    this.actionLabel,
    this.onAction,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpace.xs,
        bottom: AppSpace.md,
        top: AppSpace.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: context.text.titleMedium,
              semanticsLabel: title,
            ),
          ),
          ?trailing,
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(actionLabel!),
                  const SizedBox(width: 2),
                  const Icon(Icons.chevron_right_rounded, size: 18),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Rounded-square icon tile.
class IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;
  final double size;
  const IconBadge({
    super.key,
    required this.icon,
    required this.color,
    required this.background,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppDurations.normal,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}

/// Label / value row used inside grouped cards.
class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool showDivider;
  final Widget? trailing;

  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.showDivider = true,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: p.border.withValues(alpha: 0.7)))
            : null,
      ),
      child: Row(
        children: [
          Icon(icon, size: AppIconSize.md, color: p.textMuted),
          const SizedBox(width: AppSpace.md),
          Text(label, style: context.text.bodyMedium),
          const SizedBox(width: AppSpace.lg),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              textAlign: TextAlign.right,
              style: context.text.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpace.sm),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// Bar pinned to the bottom of a pushed screen for its primary action.
class BottomActionBar extends StatelessWidget {
  final Widget child;
  const BottomActionBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.gutter,
            AppSpace.md,
            AppSpace.gutter,
            AppSpace.md,
          ),
          child: AnimatedSwitcher(
            duration: AppDurations.normal,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: ScaleTransition(
                scale: Tween(begin: 0.96, end: 1.0).animate(anim),
                child: child,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Large screen title used at the top of each tab.
class PageHeader extends StatelessWidget {
  final String title;
  final String? overline;
  final String? subtitle;
  final Widget? trailing;

  const PageHeader({
    super.key,
    required this.title,
    this.overline,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (overline != null) ...[
                Text(overline!.toUpperCase(), style: context.text.labelSmall),
                const SizedBox(height: AppSpace.sm),
              ],
              Text(title, style: context.text.headlineMedium),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpace.xs),
                Text(subtitle!, style: context.text.bodyMedium),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}
