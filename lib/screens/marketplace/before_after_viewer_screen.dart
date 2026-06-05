import 'package:flutter/material.dart';

import '../../config/brand_colors.dart';
import '../../core/theme/brand_ui.dart';

/// Визуализация «до / после» с ползунком (превью в приложении).
class BeforeAfterViewerScreen extends StatefulWidget {
  final String title;

  const BeforeAfterViewerScreen({
    super.key,
    this.title = 'Визуализация объекта',
  });

  @override
  State<BeforeAfterViewerScreen> createState() => _BeforeAfterViewerScreenState();
}

class _BeforeAfterViewerScreenState extends State<BeforeAfterViewerScreen> {
  double _ratio = 0.48;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColors.tar,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _afterLayer(),
          ClipRect(
            clipper: _RatioClipper(_ratio),
            child: _beforeLayer(),
          ),
          _dividerHandle(),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 10,
            left: 18,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
              decoration: BoxDecoration(
                color: BrandColors.clay,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'ДО РЕМОНТА',
                style: BrandUi.monoLabel(
                  fontSize: 11,
                  color: BrandColors.onClay,
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 10,
            right: 18,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
              decoration: BoxDecoration(
                color: BrandColors.needles,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'ПОСЛЕ',
                style: BrandUi.monoLabel(
                  fontSize: 11,
                  color: BrandColors.onNeedles,
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 6,
            left: 16,
            child: BrandIconButton(
              onPressed: () => Navigator.of(context).pop(),
              onDark: true,
              size: 40,
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: BrandColors.onNeedles,
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.paddingOf(context).bottom + 20,
            child: BrandOverlayBottomCard(
              title: widget.title,
              subtitle: 'Визуализация для мастера · смета 1,18 млн ₽',
              avatarName: 'Игорь Мельник',
              actions: [
                Expanded(
                  child: BrandGhostButton(
                    label: 'Обсудить',
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: BrandAccentButton(
                    label: 'Открыть 3D',
                    icon: Icons.view_in_ar_outlined,
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _afterLayer() {
    return Stack(
      fit: StackFit.expand,
      children: [
        const BrandStripedPlaceholder(
          label: 'ПОСЛЕ · визуализация',
          height: double.infinity,
          radius: 0,
          dark: true,
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                BrandColors.needles.withOpacity(0.25),
                BrandColors.needlesDeep.withOpacity(0.45),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _beforeLayer() {
    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(painter: _ClayStripePainter()),
        ColoredBox(color: BrandColors.surik.withOpacity(0.35)),
      ],
    );
  }

  Widget _dividerHandle() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final x = constraints.maxWidth * _ratio;
        return Stack(
          children: [
            Positioned(
              left: x - 1.25,
              top: 0,
              bottom: 0,
              child: Container(
                width: 2.5,
                color: BrandColors.milk,
                child: Align(
                  alignment: Alignment.center,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragUpdate: (d) {
                      setState(() {
                        _ratio = (_ratio + d.delta.dx / constraints.maxWidth)
                            .clamp(0.05, 0.95);
                      });
                    },
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: BrandColors.milk,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: BrandColors.tar.withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.compare_arrows_rounded,
                        color: BrandColors.needles,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ClayStripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = BrandColors.surik;
    const step = 18.0;
    for (var i = -size.height; i < size.width + size.height; i += step) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
    final shade = Paint()..color = Colors.black.withOpacity(0.12);
    for (var i = step / 2; i < size.width + size.height; i += step) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        shade,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RatioClipper extends CustomClipper<Rect> {
  final double ratio;

  _RatioClipper(this.ratio);

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width * ratio, size.height);

  @override
  bool shouldReclip(covariant _RatioClipper oldClipper) => oldClipper.ratio != ratio;
}
