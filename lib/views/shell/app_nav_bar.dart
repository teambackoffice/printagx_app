import 'package:flutter/material.dart';
import 'package:printagx_app/core/theme/app_theme.dart';

class AppNavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  /// Shows a small status dot on the icon when set.
  final Color? badgeColor;

  const AppNavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    this.badgeColor,
  });
}

/// Floating ink capsule. The active tab expands into a red pill with its
/// label; the others collapse to icons (label available via tooltip).
class AppNavBar extends StatelessWidget {
  final List<AppNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelect;

  const AppNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final barColor = p.isDark ? p.surfaceMuted : AppBrand.ink;

    return ColoredBox(
      color: p.background,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: AppSpace.md),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.lg,
            AppSpace.xs,
            AppSpace.lg,
            AppSpace.xs,
          ),
          child: Container(
            height: 68,
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: p.isDark ? Border.all(color: p.border) : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: p.isDark ? 0.4 : 0.22),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (var i = 0; i < items.length; i++)
                  i == currentIndex
                      ? Flexible(
                          child: _NavButton(
                            key: ValueKey('nav-${items[i].label}'),
                            item: items[i],
                            selected: true,
                            barColor: barColor,
                            onTap: () => onSelect(i),
                          ),
                        )
                      : _NavButton(
                          key: ValueKey('nav-${items[i].label}'),
                          item: items[i],
                          selected: false,
                          barColor: barColor,
                          onTap: () => onSelect(i),
                        ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final AppNavItem item;
  final bool selected;
  final Color barColor;
  final VoidCallback onTap;

  const _NavButton({
    super.key,
    required this.item,
    required this.selected,
    required this.barColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fg = selected ? Colors.white : Colors.white.withValues(alpha: 0.55);

    final icon = Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedSwitcher(
          duration: AppDurations.fast,
          transitionBuilder: (child, anim) =>
              ScaleTransition(scale: anim, child: child),
          child: Icon(
            selected ? item.activeIcon : item.icon,
            key: ValueKey(selected),
            color: fg,
            size: 23,
          ),
        ),
        if (item.badgeColor != null)
          Positioned(
            top: -1,
            right: -2,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                // Over the red pill the dot needs a white core to stay visible.
                color: selected ? Colors.white : item.badgeColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? p.primary : barColor,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );

    final button = Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          splashColor: Colors.white.withValues(alpha: 0.12),
          highlightColor: Colors.white.withValues(alpha: 0.06),
          child: AnimatedContainer(
            duration: AppDurations.normal,
            curve: Curves.easeOutCubic,
            height: 48,
            constraints: const BoxConstraints(minWidth: 52),
            padding: EdgeInsets.symmetric(horizontal: selected ? 18 : 14),
            decoration: BoxDecoration(
              color: selected ? p.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: p.primary.withValues(alpha: 0.45),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: AnimatedSize(
              duration: AppDurations.normal,
              curve: Curves.easeOutCubic,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  icon,
                  if (selected) ...[
                    const SizedBox(width: AppSpace.sm),
                    Flexible(
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.labelLarge?.copyWith(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return selected ? button : Tooltip(message: item.label, child: button);
  }
}
