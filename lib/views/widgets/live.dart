import 'dart:async';

import 'package:flutter/material.dart';

/// Rebuilds [builder] every second while [active] is true (for live timers).
class Ticking extends StatefulWidget {
  final bool active;
  final WidgetBuilder builder;
  const Ticking({super.key, required this.active, required this.builder});

  @override
  State<Ticking> createState() => _TickingState();
}

class _TickingState extends State<Ticking> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(Ticking oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) _sync();
  }

  void _sync() {
    _timer?.cancel();
    _timer = widget.active
        ? Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}))
        : null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}

/// Dot with an expanding halo, used to signal something is live.
class LiveDot extends StatefulWidget {
  final Color color;
  final double size;
  const LiveDot({
    super.key,
    this.color = const Color(0xFFFF5A43),
    this.size = 8,
  });

  @override
  State<LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<LiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, _) {
              final t = Curves.easeOut.transform(_ctrl.value);
              return Container(
                width: size * (1 + 1.6 * t),
                height: size * (1 + 1.6 * t),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: 0.45 * (1 - t)),
                ),
              );
            },
          ),
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
