import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../config/brand_colors.dart';
import '../../../config/brand_assets.dart';
import '../../../core/theme/app_text_style.dart';

/// Рамка с логотипом и кнопками «Вход» / «Регистрация» внутри.
/// По нажатию кнопки — увеличение и растворение, затем действие.
class BrandFrameSplash extends StatefulWidget {
  const BrandFrameSplash({
    super.key,
    required this.onLogin,
    this.onRegister,
  });

  final VoidCallback onLogin;
  final VoidCallback? onRegister;

  @override
  State<BrandFrameSplash> createState() => _BrandFrameSplashState();
}

class _BrandFrameSplashState extends State<BrandFrameSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _exitCtrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;
  bool _exiting = false;

  @override
  void initState() {
    super.initState();
    _exitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    _scale = Tween<double>(begin: 1, end: 1.42).animate(
      CurvedAnimation(parent: _exitCtrl, curve: Curves.easeInCubic),
    );
    _opacity = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _exitCtrl,
        curve: const Interval(0.15, 1, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _exitCtrl.dispose();
    super.dispose();
  }

  Future<void> _exitThen(VoidCallback? action) async {
    if (_exiting || action == null) return;
    setState(() => _exiting = true);
    await _exitCtrl.forward();
    if (mounted) action();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _exitCtrl,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.scale(
            scale: _scale.value,
            child: child,
          ),
        );
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxH = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : MediaQuery.sizeOf(context).height * 0.82;
          final frameHeight = maxH.clamp(320.0, 580.0);
          final innerH = frameHeight * 0.52;

          return SizedBox(
            height: frameHeight,
            width: innerH,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(
                  BrandAssets.frameVertical,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    frameHeight * 0.13,
                    frameHeight * 0.22,
                    frameHeight * 0.13,
                    frameHeight * 0.20,
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        flex: 5,
                        child: SvgPicture.asset(
                          BrandAssets.logoPriDele,
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        flex: 3,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _FramePillButton(
                              label: 'Вход',
                              enabled: !_exiting,
                              onTap: () => _exitThen(widget.onLogin),
                            ),
                            const SizedBox(height: 8),
                            _FramePillButton(
                              label: 'Регистрация',
                              outlined: true,
                              enabled: !_exiting && widget.onRegister != null,
                              onTap: () => _exitThen(widget.onRegister),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FramePillButton extends StatelessWidget {
  const _FramePillButton({
    required this.label,
    required this.onTap,
    this.outlined = false,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onTap;
  final bool outlined;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: outlined ? Colors.transparent : Colors.white,
            borderRadius: BorderRadius.circular(100),
            border: outlined
                ? Border.all(color: Colors.white.withOpacity(0.55), width: 1.5)
                : null,
            boxShadow: outlined
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: outlined ? Colors.white : BrandColors.needles,
              fontFamily: AppTextStyle.uiFontFamily,
              letterSpacing: 0.3,
              height: 1.1,
            ),
          ),
        ),
      ),
    );
  }
}
