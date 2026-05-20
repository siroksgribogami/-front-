import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// iOS-подобный скролл по всему приложению: «резиновый» overscroll,
/// без зелёного Material-glow. Поддержка тача, трекпада и мыши.
class ArthouseScrollBehavior extends MaterialScrollBehavior {
  const ArthouseScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    // Cupertino физика: pull-to-bounce, плавная инерция, очень дешёво по GPU.
    return const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    // Никакого зелёного glow по краю — это и не-iOS, и лишняя отрисовка.
    return child;
  }

  @override
  Set<PointerDeviceKind> get dragDevices => <PointerDeviceKind>{
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus,
      };
}

/// Лёгкие хаптики на ключевые действия (нижняя навигация, CTA, тоггл-чипы).
/// На Android-устройствах с виброотдачей даёт ощущение «живого» интерфейса
/// без лагов и тяжёлых анимаций.
abstract final class ArthouseHaptics {
  ArthouseHaptics._();

  /// Лёгкий тик — переключение вкладки / выбор чипа.
  static Future<void> select() async {
    if (kIsWeb) return;
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {
      // Платформа без поддержки — игнорируем.
    }
  }

  /// Чуть сильнее — нажатие на главную CTA (Сохранить, Готово).
  static Future<void> tap() async {
    if (kIsWeb) return;
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }
}
