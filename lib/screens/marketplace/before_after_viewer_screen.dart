import 'package:flutter/material.dart';

import '../../core/theme/app_text_style.dart';
import '../../core/theme/marketplace_colors.dart';

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
  double _ratio = 0.5;

  @override
  Widget build(BuildContext context) {
    final bg = MarketplaceColors.backgroundFor(context);
    final card = MarketplaceColors.cardFor(context);
    final textPrimary = MarketplaceColors.textPrimaryFor(context);
    final textSecondary = MarketplaceColors.textSecondaryFor(context);
    final textMuted = MarketplaceColors.textMutedFor(context);
    final horizontalPad = MarketplaceColors.horizontalPaddingFor(context);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: card,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: textPrimary),
        title: Text(
          widget.title,
          style: TextStyle(
            fontFamily: AppTextStyle.fontFamily,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(horizontalPad, 8, horizontalPad, 0),
              child: Text(
                'Ползунок сравнивает состояние «до» и «после». Полноценная 3D-сцена подключится отдельно.',
                style: TextStyle(fontSize: 13, color: textSecondary, height: 1.35),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPad),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _layer(
                            label: 'ПОСЛЕ',
                            color: MarketplaceColors.bluePrimary.withOpacity(0.85),
                            align: Alignment.centerRight,
                          ),
                          ClipRect(
                            clipper: _RatioClipper(_ratio),
                            child: _layer(
                              label: 'ДО',
                              color: textMuted.withOpacity(0.75),
                              align: Alignment.centerLeft,
                            ),
                          ),
                          Positioned(
                            left: constraints.maxWidth * _ratio - 2,
                            top: 0,
                            bottom: 0,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onHorizontalDragUpdate: (d) {
                                setState(() {
                                  _ratio = (_ratio +
                                          d.delta.dx / constraints.maxWidth)
                                      .clamp(0.05, 0.95);
                                });
                              },
                              child: Container(
                                width: 4,
                                color: Colors.white,
                                child: Center(
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: MarketplaceColors.ctaOrange,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.35),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.drag_handle,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(horizontalPad, 12, horizontalPad, 8),
              child: Row(
                children: [
                  Text('ДО', style: TextStyle(color: textMuted)),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: MarketplaceColors.ctaOrange,
                        inactiveTrackColor: textMuted.withOpacity(0.35),
                        thumbColor: MarketplaceColors.ctaOrange,
                      ),
                      child: Slider(
                        value: _ratio,
                        onChanged: (v) => setState(() => _ratio = v),
                      ),
                    ),
                  ),
                  Text('ПОСЛЕ', style: TextStyle(color: textMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _layer({
    required String label,
    required Color color,
    required Alignment align,
  }) {
    return Container(
      color: color,
      alignment: align,
      padding: const EdgeInsets.all(20),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withOpacity(0.85),
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
      ),
    );
  }
}

class _RatioClipper extends CustomClipper<Rect> {
  final double ratio;

  _RatioClipper(this.ratio);

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width * ratio, size.height);

  @override
  bool shouldReclip(covariant _RatioClipper oldClipper) => oldClipper.ratio != ratio;
}
