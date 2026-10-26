import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printagx_app/core/theme/app_theme.dart';
import 'package:printagx_app/views/widgets/app_button.dart';
import 'package:printagx_app/views/widgets/app_card.dart';

// ── Snackbar ────────────────────────────────────────────────────────────────

void showAppSnack(BuildContext context, String message, {bool error = false}) {
  final p = context.palette;
  if (error) HapticFeedback.mediumImpact();
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      backgroundColor: error ? p.danger : null,
      margin: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        0,
        AppSpace.lg,
        AppSpace.lg,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.lg,
        vertical: 14,
      ),
      duration: const Duration(milliseconds: 2400),
      content: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: error ? 0.2 : 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              error ? Icons.priority_high_rounded : Icons.check_rounded,
              color: error ? Colors.white : const Color(0xFF6BE3A8),
              size: 16,
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(child: Text(message)),
        ],
      ),
    ),
  );
}

// ── Confirmation sheet ──────────────────────────────────────────────────────

enum ConfirmTone { primary, success, danger }

/// Bottom-sheet confirmation. Resolves to true when the user confirms.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required IconData icon,
  ConfirmTone tone = ConfirmTone.primary,
}) async {
  HapticFeedback.selectionClick();
  final result = await showModalBottomSheet<bool>(
    context: context,
    builder: (ctx) {
      final p = ctx.palette;
      final (color, soft, variant) = switch (tone) {
        ConfirmTone.primary => (
          p.primary,
          p.primarySoft,
          AppButtonVariant.primary,
        ),
        ConfirmTone.success => (
          p.success,
          p.successSoft,
          AppButtonVariant.success,
        ),
        ConfirmTone.danger => (p.danger, p.dangerSoft, AppButtonVariant.danger),
      };
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.xxl,
            0,
            AppSpace.xxl,
            AppSpace.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpace.sm),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: soft.withValues(alpha: 0.5),
                ),
                child: IconBadge(
                  icon: icon,
                  color: color,
                  background: soft,
                  size: 56,
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              Text(
                title,
                textAlign: TextAlign.center,
                style: ctx.text.headlineSmall,
              ),
              const SizedBox(height: AppSpace.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: ctx.text.bodyMedium,
              ),
              const SizedBox(height: AppSpace.xxl),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Cancel',
                      variant: AppButtonVariant.tonal,
                      onPressed: () => Navigator.pop(ctx, false),
                    ),
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: AppButton(
                      label: confirmLabel,
                      variant: variant,
                      onPressed: () => Navigator.pop(ctx, true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
  return result ?? false;
}

// ── Loading skeleton ────────────────────────────────────────────────────────

/// Placeholder block with a sweeping shimmer.
class SkeletonBox extends StatefulWidget {
  final double height;
  final double? width;
  final double radius;
  const SkeletonBox({
    super.key,
    required this.height,
    this.width,
    this.radius = AppRadius.sm,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final base = p.isDark ? p.surfaceMuted : const Color(0xFFEDEBE6);
    final highlight = p.isDark ? p.border : const Color(0xFFF7F6F3);

    return Semantics(
      label: 'Loading',
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, _) {
          final dx = _ctrl.value * 3 - 1.5;
          return Container(
            height: widget.height,
            width: widget.width,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.radius),
              gradient: LinearGradient(
                begin: Alignment(dx - 1, -0.3),
                end: Alignment(dx + 1, 0.3),
                colors: [base, highlight, base],
                stops: const [0.25, 0.5, 0.75],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Empty / error states ────────────────────────────────────────────────────

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  final Color? accent;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.accent,
  });

  /// Network / load failure with a retry button.
  factory EmptyState.error({
    Key? key,
    required String title,
    required String message,
    required VoidCallback onRetry,
  }) => EmptyState(
    key: key,
    icon: Icons.cloud_off_rounded,
    title: title,
    message: message,
    action: _RetryButton(onRetry: onRetry),
  );

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = accent ?? p.textMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.xxxl,
        vertical: AppSpace.xxxl + AppSpace.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Layered rings read as a soft illustration without image assets.
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: p.surfaceMuted.withValues(alpha: 0.6),
            ),
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: p.surface,
                border: Border.all(color: p.border),
                boxShadow: p.cardShadow,
              ),
              child: Icon(icon, size: 32, color: color),
            ),
          ),
          const SizedBox(height: AppSpace.xl),
          Text(
            title,
            textAlign: TextAlign.center,
            style: context.text.titleLarge,
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: context.text.bodyMedium,
          ),
          if (action != null) ...[
            const SizedBox(height: AppSpace.xxl),
            action!,
          ],
        ],
      ),
    );
  }
}

class _RetryButton extends StatelessWidget {
  final VoidCallback onRetry;
  const _RetryButton({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: AppButton(
        label: 'Try again',
        icon: Icons.refresh_rounded,
        compact: true,
        variant: AppButtonVariant.outline,
        onPressed: onRetry,
      ),
    );
  }
}

/// Inline note shown inside a section when a list has nothing to show yet.
class InlineEmpty extends StatelessWidget {
  final String message;
  final IconData icon;
  const InlineEmpty(
    this.message, {
    super.key,
    this.icon = Icons.history_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: p.border, width: 1.2),
        color: p.surface.withValues(alpha: 0.5),
      ),
      child: Row(
        children: [
          IconBadge(
            icon: icon,
            color: p.textMuted,
            background: p.surfaceMuted,
            size: 36,
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(child: Text(message, style: context.text.bodyMedium)),
        ],
      ),
    );
  }
}
