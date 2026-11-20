import 'dart:async';

import 'package:flutter/material.dart';

import 'package:designwear/presentation/styles/styles.dart';

/// An icon button that repeats while it is held (for nudging an element a pixel at a time, or many).
/// [onStep] runs on the press and then, after a short wait, about every 70 ms; [onEnd] runs once on release.
class HoldButton extends StatefulWidget {
  const HoldButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onStep,
    this.onEnd,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onStep;
  final VoidCallback? onEnd;

  @override
  State<HoldButton> createState() => _HoldButtonState();
}

class _HoldButtonState extends State<HoldButton> {
  Timer? _wait;
  Timer? _repeat;
  bool _down = false;

  void _start() {
    _down = true;
    widget.onStep();
    _wait = Timer(const Duration(milliseconds: 350), () {
      _repeat = Timer.periodic(
        const Duration(milliseconds: 70),
        (_) => widget.onStep(),
      );
    });
    setState(() {});
  }

  void _stop() {
    if (!_down) return;
    _down = false;
    _wait?.cancel();
    _repeat?.cancel();
    widget.onEnd?.call();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _wait?.cancel();
    _repeat?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: widget.tooltip,
      child: Listener(
        onPointerDown: (_) => _start(),
        onPointerUp: (_) => _stop(),
        onPointerCancel: (_) => _stop(),
        child: Container(
          padding: const EdgeInsets.all(5),
          margin: const EdgeInsets.all(1.5),
          decoration: BoxDecoration(
            color: _down
                ? AppColors.marigold.withValues(alpha: 0.18)
                : cs.onSurface.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(widget.icon, size: 20, color: cs.onSurface),
        ),
      ),
    );
  }
}
