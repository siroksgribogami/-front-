import 'package:flutter/material.dart';

import 'arthouse_scroll_behavior.dart';

/// iOS-подобная реакция на нажатие: лёгкая просадка масштаба и opacity.
/// Использует одиночный [AnimationController] и [Transform.scale] —
/// это в десятки раз дешевле, чем [InkWell] с splash на mid-range Android.
///
/// Пример:
/// ```dart
/// PressableScale(
///   onTap: _save,
///   child: const Text('Сохранить'),
/// )
/// ```
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = 0.96,
    this.duration = const Duration(milliseconds: 110),
    this.haptic = true,
    this.behavior = HitTestBehavior.opaque,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final Duration duration;
  final bool haptic;
  final HitTestBehavior behavior;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: widget.duration,
    reverseDuration: const Duration(milliseconds: 160),
    lowerBound: 0,
    upperBound: 1,
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _down(_) => _ctrl.forward();
  void _up(_) => _ctrl.reverse();
  void _cancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null || widget.onLongPress != null;
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: enabled ? _down : null,
      onTapUp: enabled ? _up : null,
      onTapCancel: enabled ? _cancel : null,
      onTap: enabled
          ? () {
              if (widget.haptic) ArthouseHaptics.select();
              widget.onTap?.call();
            }
          : null,
      onLongPress: widget.onLongPress == null
          ? null
          : () {
              if (widget.haptic) ArthouseHaptics.tap();
              widget.onLongPress!();
            },
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          final t = Curves.easeOutCubic.transform(_ctrl.value);
          final s = 1.0 - (1.0 - widget.scale) * t;
          return Opacity(
            opacity: 1.0 - 0.08 * t,
            child: Transform.scale(scale: s, child: child),
          );
        },
        child: widget.child,
      ),
    );
  }
}
