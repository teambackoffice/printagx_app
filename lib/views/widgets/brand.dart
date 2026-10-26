import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:printagx_app/core/theme/app_theme.dart';
import 'package:printagx_app/core/utils/formatters.dart';

/// Halftone dot texture that fades towards the bottom-left — a nod to print.
class Halftone extends StatelessWidget {
  final double opacity;
  final Color color;
  const Halftone({super.key, this.opacity = 0.1, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ExcludeSemantics(
        child: CustomPaint(
          painter: _HalftonePainter(color.withValues(alpha: opacity)),
        ),
      ),
    );
  }
}

class _HalftonePainter extends CustomPainter {
  final Color color;
  _HalftonePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    const step = 11.0;
    final paint = Paint()..color = color;
    final maxD = math.sqrt(size.width * size.width + size.height * size.height);
    for (var y = step / 2; y < size.height; y += step) {
      final rowShift = ((y / step).floor().isOdd) ? step / 2 : 0;
      for (var x = step / 2 + rowShift; x < size.width; x += step) {
        // Distance from the top-right corner drives the dot size.
        final d = math.sqrt(math.pow(size.width - x, 2) + math.pow(y, 2));
        final r = 2.6 * (1 - d / maxD * 1.25);
        if (r > 0.3) canvas.drawCircle(Offset(x, y), r, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_HalftonePainter old) => old.color != color;
}

/// Initials avatar on an ink gradient with a red accent ring.
class InitialsAvatar extends StatelessWidget {
  final String name;
  final double size;
  final Widget? child;
  const InitialsAvatar({
    super.key,
    required this.name,
    this.size = 44,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.05),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: p.primary, width: size * 0.045),
      ),
      child: Container(
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2C2C34), AppBrand.ink],
          ),
        ),
        child:
            child ??
            Text(
              initialsOf(name),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: size * 0.34,
                letterSpacing: 0.5,
              ),
            ),
      ),
    );
  }
}
