import 'package:flutter/material.dart';

class BarLoader extends StatefulWidget {
  const BarLoader({
    super.key,
    this.barWidth = 3,
    this.baseHeight = 20,
    this.tallHeight = 35,
    this.gap = 5,
    this.color = Colors.white,
    this.inactiveOpacity = 0.5,
    this.duration = const Duration(milliseconds: 1000),
  });

  final double barWidth;
  final double baseHeight;
  final double tallHeight;
  final double gap;
  final Color color;
  final double inactiveOpacity;
  final Duration duration;

  @override
  State<BarLoader> createState() => _BarLoaderState();
}

class _BarLoaderState extends State<BarLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _pulse(double t, double delay) {
    final x = (t - delay) % 1.0;
    if (x < 0) return 0;
    if (x < 0.2) return x / 0.2;
    if (x < 0.4) return 1 - ((x - 0.2) / 0.2);
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final t = _controller.value;
        final p1 = _pulse(t, 0.0);
        final p2 = _pulse(t, 0.25);
        final p3 = _pulse(t, 0.5);

        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _bar(p1, widget.baseHeight),
            SizedBox(width: widget.gap),
            _bar(p2, widget.tallHeight),
            SizedBox(width: widget.gap),
            _bar(p3, widget.baseHeight),
          ],
        );
      },
    );
  }

  Widget _bar(double pulse, double height) {
    final scale = 1.0 + (0.5 * pulse);
    final color = widget.color.withOpacity(
      widget.inactiveOpacity + ((1 - widget.inactiveOpacity) * pulse),
    );

    return Transform.scale(
      alignment: Alignment.bottomCenter,
      scaleY: scale,
      child: Container(
        width: widget.barWidth,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
