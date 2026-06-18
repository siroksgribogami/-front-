import 'package:flutter/material.dart';

import '../../config/brand_colors.dart';
import '../../config/text_theme.dart';
import 'brand_runtime.dart';

/// Переиспользуемые элементы брендбука «При деле».
abstract final class BrandUi {
  static const double pad = BrandColors.screenPadding;
  static const BorderRadius cardRadius =
      BorderRadius.all(Radius.circular(BrandColors.radiusCard));
  static const BorderRadius buttonRadius =
      BorderRadius.all(Radius.circular(BrandColors.radiusButton));
  static const BorderRadius chipRadius =
      BorderRadius.all(Radius.circular(BrandColors.radiusChip));

  static TextStyle inter({
    double fontSize = 15,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double? height,
    List<FontFeature>? fontFeatures,
  }) =>
      TextStyle(
        fontFamily: 'Inter',
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color ?? BrandRuntime.ink,
        height: height ?? 1.35,
        fontFeatures: fontFeatures,
      );

  static TextStyle monoLabel({
    double fontSize = 10,
    Color? color,
  }) =>
      TextStyle(
        fontFamily: 'monospace',
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.8,
        color: color ?? BrandRuntime.inkFaint,
      );

  static TextStyle displayTitle({
    double fontSize = 28,
    Color? color,
  }) =>
      pochaevsk(
        fontSize: fontSize,
        color: color ?? (BrandRuntime.isDark ? BrandRuntime.ink : BrandColors.needles),
        height: 1.1,
      );

  static BoxDecoration cardDecoration({Color? color}) => BoxDecoration(
        color: color ?? BrandRuntime.card,
        borderRadius: cardRadius,
        border: Border.all(color: BrandRuntime.border.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(BrandRuntime.isDark ? 0.18 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      );

  static BoxDecoration foremanBubbleDecoration() => BoxDecoration(
        color: BrandRuntime.card,
        borderRadius: BorderRadius.circular(BrandColors.radiusCard),
        border: const Border(
          left: BorderSide(color: BrandColors.clay, width: 3),
        ),
      );

  static InputDecoration inputDecoration({
    String? hint,
    Widget? prefix,
    Widget? suffix,
  }) =>
      InputDecoration(
        filled: true,
        fillColor: BrandRuntime.card,
        hintText: hint,
        hintStyle: inter(fontSize: 15, color: BrandRuntime.inkFaint),
        prefixIcon: prefix,
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: buttonRadius,
          borderSide: BorderSide(color: BrandRuntime.borderStrong),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: buttonRadius,
          borderSide: BorderSide(color: BrandRuntime.borderStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: buttonRadius,
          borderSide: BorderSide(color: BrandRuntime.needles, width: 2),
        ),
      );
}

/// Основная кнопка (хвоя).
class BrandPrimaryButton extends StatelessWidget {
  const BrandPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final child = FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: BrandColors.needles,
        foregroundColor: BrandColors.onNeedles,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: const RoundedRectangleBorder(borderRadius: BrandUi.buttonRadius),
        textStyle: BrandUi.inter(fontWeight: FontWeight.w600),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
          Text(label),
        ],
      ),
    );
    return expanded ? SizedBox(width: double.infinity, child: child) : child;
  }
}

/// Акцентная кнопка (глина) — одна на экран.
class BrandAccentButton extends StatelessWidget {
  const BrandAccentButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.circular = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool circular;

  @override
  Widget build(BuildContext context) {
    if (circular) {
      return Material(
        color: BrandColors.clay,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon ?? Icons.send, color: BrandColors.onClay, size: 20),
          ),
        ),
      );
    }
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: BrandColors.clay,
        foregroundColor: BrandColors.onClay,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: const RoundedRectangleBorder(borderRadius: BrandUi.buttonRadius),
        textStyle: BrandUi.inter(fontWeight: FontWeight.w600),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
          Text(label),
        ],
      ),
    );
  }
}

/// Вторичная кнопка (ghost).
class BrandGhostButton extends StatelessWidget {
  const BrandGhostButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: BrandRuntime.ink,
        backgroundColor: BrandRuntime.card,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        side: BorderSide(color: BrandRuntime.borderStrong, width: 1.5),
        shape: const RoundedRectangleBorder(borderRadius: BrandUi.buttonRadius),
        textStyle: BrandUi.inter(fontWeight: FontWeight.w600),
      ),
      child: Text(label),
    );
  }
}

/// Чип быстрого ответа / комнаты.
class BrandChip extends StatelessWidget {
  const BrandChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? BrandColors.needles : BrandRuntime.card,
          borderRadius: BrandUi.chipRadius,
          border: Border.all(
            color: selected ? BrandColors.needles : BrandRuntime.borderStrong,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: BrandUi.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? BrandColors.onNeedles : BrandRuntime.ink,
          ),
        ),
      ),
    );
  }
}

/// Разделитель «линейка-ромб».
class BrandLineDivider extends StatelessWidget {
  const BrandLineDivider({super.key, this.margin});

  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin ?? const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(height: 1, color: BrandRuntime.border),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Transform.rotate(
              angle: 0.785398,
              child: Container(
                width: 6,
                height: 6,
                color: BrandColors.clay.withOpacity(0.85),
              ),
            ),
          ),
          Expanded(
            child: Container(height: 1, color: BrandRuntime.border),
          ),
        ],
      ),
    );
  }
}

/// Карточка контента на холсте.
class BrandCard extends StatelessWidget {
  const BrandCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BrandUi.cardDecoration(color: color),
      child: child,
    );
  }
}

/// AppBar маркетплейса: молоко + заголовок Inter, опционально display.
class BrandMarketplaceAppBar extends StatelessWidget implements PreferredSizeWidget {
  const BrandMarketplaceAppBar({
    super.key,
    required this.title,
    this.displayPrefix,
    this.actions,
    this.leading,
  });

  final String title;
  final String? displayPrefix;
  final List<Widget>? actions;
  final Widget? leading;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: BrandRuntime.card,
      foregroundColor: BrandRuntime.ink,
      leading: leading,
      actions: actions,
      title: displayPrefix != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayPrefix!,
                  style: BrandUi.displayTitle(fontSize: 18),
                ),
                Text(
                  title,
                  style: BrandUi.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: BrandRuntime.inkSoft,
                  ),
                ),
              ],
            )
          : Text(
              title,
              style: BrandUi.inter(fontSize: 17, fontWeight: FontWeight.w800),
            ),
    );
  }
}

/// FAB: глина (главное действие экрана).
class BrandAccentFab extends StatelessWidget {
  const BrandAccentFab({
    super.key,
    required this.onPressed,
    this.icon = Icons.add,
    this.tooltip,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      tooltip: tooltip,
      backgroundColor: BrandColors.clay,
      foregroundColor: BrandColors.onClay,
      elevation: 2,
      shape: const CircleBorder(),
      child: Icon(icon),
    );
  }
}

/// Обёртка экрана: фон холст + SafeArea.
class BrandScreen extends StatelessWidget {
  const BrandScreen({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.padding,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandRuntime.canvas,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: ColoredBox(
        color: BrandRuntime.canvas,
        child: padding != null
            ? Padding(padding: padding!, child: body)
            : body,
      ),
    );
  }
}

/// Прогресс опроса / шагов — глина.
class BrandProgressBar extends StatelessWidget {
  const BrandProgressBar({super.key, required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1),
        minHeight: 4,
        backgroundColor: BrandRuntime.surface,
        valueColor: const AlwaysStoppedAnimation(BrandColors.clay),
      ),
    );
  }
}

/// Material chip theme для FilterChip / ChoiceChip.
class BrandChipTheme {
  static ChipThemeData of(BuildContext context) {
    return ChipThemeData(
      backgroundColor: BrandRuntime.card,
      selectedColor: BrandColors.needles,
      disabledColor: BrandRuntime.surface,
      labelStyle: BrandUi.inter(fontSize: 13, fontWeight: FontWeight.w600),
      secondaryLabelStyle: BrandUi.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: BrandColors.onNeedles,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BrandUi.chipRadius,
        side: BorderSide(color: BrandRuntime.borderStrong, width: 1.5),
      ),
      showCheckmark: false,
    );
  }
}

/// Звёзды рейтинга (Stars в app-kit.jsx).
class BrandStars extends StatelessWidget {
  const BrandStars({
    super.key,
    required this.value,
    this.size = 13,
    this.color = BrandColors.gilded,
  });

  final double value;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < value.round();
        return Padding(
          padding: EdgeInsets.only(right: i < 4 ? 2 : 0),
          child: Icon(
            filled ? Icons.star_rounded : Icons.star_outline_rounded,
            size: size,
            color: color,
          ),
        );
      }),
    );
  }
}

/// Поле поиска: молоко + иконка лупы (FindMasters / Catalog в app-kit).
class BrandSearchField extends StatelessWidget {
  const BrandSearchField({
    super.key,
    this.controller,
    this.hint,
    this.onChanged,
    this.autofocus = false,
  });

  final TextEditingController? controller;
  final String? hint;
  final ValueChanged<String>? onChanged;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      autofocus: autofocus,
      style: BrandUi.inter(fontSize: 15),
      decoration: BrandUi.inputDecoration(
        hint: hint,
        prefix: Icon(
          Icons.search_rounded,
          size: 18,
          color: BrandRuntime.inkSoft,
        ),
      ),
    );
  }
}

/// Сегментированный переключатель: paper2-трек, milk-пилюля (market-customer.jsx).
class BrandSegmentedControl extends StatelessWidget {
  const BrandSegmentedControl({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: BrandRuntime.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: index == i ? BrandRuntime.card : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: index == i
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(BrandRuntime.isDark ? 0.25 : 0.08),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    labels[i],
                    style: BrandUi.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: index == i
                          ? (BrandRuntime.isDark ? BrandRuntime.ink : BrandColors.needlesDark)
                          : BrandRuntime.inkSoft,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Kicker — uppercase label (`.kicker` в brand.css).
class BrandKicker extends StatelessWidget {
  const BrandKicker(
    this.text, {
    super.key,
    this.color,
    this.fontSize = 11,
    this.onDark = false,
  });

  final String text;
  final Color? color;
  final double fontSize;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: BrandUi.inter(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: color ??
            (onDark ? BrandColors.dawn : BrandColors.clay),
      ).copyWith(letterSpacing: fontSize * 0.02),
    );
  }
}

enum BrandStatusKind { draft, active, market, done, gold }

/// Status pill (`.tag` / Status в app-kit.jsx).
class BrandStatus extends StatelessWidget {
  const BrandStatus({
    super.key,
    required this.label,
    this.kind = BrandStatusKind.draft,
  });

  final String label;
  final BrandStatusKind kind;

  static BrandStatusKind fromProjectStatus(String status) {
    final s = status.trim().toLowerCase();
    if (s.contains('бирж') || s.contains('market')) {
      return BrandStatusKind.market;
    }
    if (s.contains('работ') || s.contains('active')) {
      return BrandStatusKind.active;
    }
    if (s.contains('готов') || s.contains('done')) {
      return BrandStatusKind.done;
    }
    if (s.contains('чернов') || s.contains('draft')) {
      return BrandStatusKind.draft;
    }
    return BrandStatusKind.active;
  }

  @override
  Widget build(BuildContext context) {
    final (bg, fg, dot) = switch (kind) {
      BrandStatusKind.draft => (
          BrandRuntime.surface,
          BrandRuntime.inkSoft,
          BrandRuntime.inkFaint,
        ),
      BrandStatusKind.active => (
          BrandRuntime.surface.withOpacity(0.6),
          BrandColors.needles,
          BrandColors.needlesLight,
        ),
      BrandStatusKind.market => (
          BrandColors.sandstone,
          BrandColors.surik,
          BrandColors.clay,
        ),
      BrandStatusKind.done => (
          BrandRuntime.surface.withOpacity(0.6),
          BrandColors.needles,
          BrandColors.needles,
        ),
      BrandStatusKind.gold => (
          BrandColors.gilded.withOpacity(0.16),
          const Color(0xFF8A6A21),
          BrandColors.gilded,
        ),
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 5, 10, 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: BrandUi.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

/// Кнопка «назад» в квадрате с обводкой.
class BrandBackButton extends StatelessWidget {
  const BrandBackButton({
    super.key,
    required this.onPressed,
    this.onDark = false,
  });

  final VoidCallback onPressed;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final fg = onDark ? BrandColors.onNeedles : BrandRuntime.ink;
    final border = onDark
        ? BrandColors.onNeedles.withOpacity(0.25)
        : BrandRuntime.border;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: border, width: 1.5),
          ),
          child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: fg),
        ),
      ),
    );
  }
}

/// Круглая/квадратная icon-кнопка.
class BrandIconButton extends StatelessWidget {
  const BrandIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.onDark = false,
    this.accent = false,
    this.size = 38,
  });

  final Widget icon;
  final VoidCallback? onPressed;
  final bool onDark;
  final bool accent;
  final double size;

  @override
  Widget build(BuildContext context) {
    final bg = accent
        ? BrandColors.clay
        : (onDark
            ? BrandColors.onNeedles.withOpacity(0.1)
            : BrandRuntime.card);
    final border = accent
        ? Colors.transparent
        : (onDark
            ? BrandColors.onNeedles.withOpacity(0.2)
            : BrandRuntime.border);

    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(11),
        side: BorderSide(color: border, width: accent ? 0 : 1.5),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(11),
        child: SizedBox(
          width: size,
          height: size,
          child: Center(child: icon),
        ),
      ),
    );
  }
}

enum BrandAvatarTone { green, clay, sand }

/// Аватар с инициалами на tinted tile.
class BrandAvatar extends StatelessWidget {
  const BrandAvatar({
    super.key,
    required this.name,
    this.size = 44,
    this.radius = 14,
    this.tone = BrandAvatarTone.green,
    this.image,
  });

  final String name;
  final double size;
  final double radius;
  final BrandAvatarTone tone;
  final ImageProvider? image;

  @override
  Widget build(BuildContext context) {
    final init = name
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0])
        .take(2)
        .join()
        .toUpperCase();

    final bg = switch (tone) {
      BrandAvatarTone.clay => BrandColors.sandstone,
      BrandAvatarTone.sand => BrandRuntime.surface,
      BrandAvatarTone.green => BrandRuntime.surface.withOpacity(0.85),
    };
    final fg = tone == BrandAvatarTone.clay
        ? BrandColors.surik
        : BrandColors.needles;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: BrandRuntime.border),
        image: image != null
            ? DecorationImage(image: image!, fit: BoxFit.cover)
            : null,
      ),
      alignment: Alignment.center,
      child: image == null
          ? Text(
              init.isEmpty ? '?' : init,
              style: pochaevsk(fontSize: size * 0.38, color: fg),
            )
          : null,
    );
  }
}

/// In-screen AppBar из app-kit.jsx.
class BrandAppBar extends StatelessWidget {
  const BrandAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.kicker,
    this.onBack,
    this.actions,
    this.big = false,
  });

  final String title;
  final String? subtitle;
  final String? kicker;
  final VoidCallback? onBack;
  final Widget? actions;
  final bool big;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (onBack != null) ...[
            BrandBackButton(onPressed: onBack!),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (kicker != null) ...[
                  BrandKicker(kicker!, fontSize: 10),
                  const SizedBox(height: 2),
                ],
                Text(
                  title,
                  style: big
                      ? pochaevsk(
                          fontSize: 26,
                          color: BrandRuntime.ink,
                          height: 1.05,
                        )
                      : BrandUi.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: BrandRuntime.ink,
                        ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: BrandUi.inter(
                      fontSize: 12.5,
                      color: BrandRuntime.inkSoft,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (actions != null) actions!,
        ],
      ),
    );
  }
}

/// Прогресс шагов — точки (Steps в app-kit.jsx).
class BrandSteps extends StatelessWidget {
  const BrandSteps({
    super.key,
    required this.total,
    required this.active,
    this.onDark = false,
  });

  final int total;
  final int active;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final on = i < active;
        final isCurrent = i == active - 1;
        return Expanded(
          flex: isCurrent ? 24 : 10,
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: i < total - 1 ? 6 : 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              color: on
                  ? (onDark ? BrandColors.dawn : BrandColors.clay)
                  : (onDark
                      ? BrandColors.onNeedles.withOpacity(0.2)
                      : BrandRuntime.border),
            ),
          ),
        );
      }),
    );
  }
}

/// Placeholder изображения с диагональной штриховкой.
class BrandStripedPlaceholder extends StatelessWidget {
  const BrandStripedPlaceholder({
    super.key,
    this.label = 'фото',
    this.height = 160,
    this.radius = 14,
    this.dark = false,
  });

  final String label;
  final double height;
  final double radius;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: CustomPaint(
        painter: _StripePainter(dark: dark),
        child: Container(
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: dark
                  ? BrandColors.onNeedles.withOpacity(0.1)
                  : BrandRuntime.border,
            ),
          ),
          child: Text(
            label.toUpperCase(),
            style: BrandUi.monoLabel(
              fontSize: 10,
              color: dark
                  ? BrandColors.onNeedles.withOpacity(0.55)
                  : BrandRuntime.inkFaint,
            ),
          ),
        ),
      ),
    );
  }
}

class _StripePainter extends CustomPainter {
  const _StripePainter({required this.dark});

  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final base = dark ? BrandColors.needlesDeep : BrandRuntime.surface;
    final stripe = dark
        ? BrandColors.onNeedles.withOpacity(0.05)
        : BrandColors.needles.withOpacity(0.05);
    canvas.drawRect(Offset.zero & size, Paint()..color = base);
    final paint = Paint()..color = stripe;
    const step = 18.0;
    for (var i = -size.height; i < size.width + size.height; i += step) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StripePainter oldDelegate) =>
      oldDelegate.dark != dark;
}

/// Плитка статистики (summary strip).
class BrandStatTile extends StatelessWidget {
  const BrandStatTile({
    super.key,
    required this.value,
    required this.label,
    this.accent = false,
    this.centered = false,
  });

  final String value;
  final String label;
  final bool accent;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: BrandRuntime.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BrandRuntime.border),
      ),
      child: Column(
        crossAxisAlignment:
            centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Text(
            value,
            textAlign: centered ? TextAlign.center : null,
            style: pochaevsk(
              fontSize: 26,
              color: accent ? BrandColors.clay : BrandColors.needles,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: centered ? TextAlign.center : null,
            style: BrandUi.inter(
              fontSize: 11.5,
              color: BrandRuntime.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}

/// FAB с подписью (глина).
class BrandAccentFabExtended extends StatelessWidget {
  const BrandAccentFabExtended({
    super.key,
    required this.onPressed,
    this.label = 'Новый проект',
    this.icon = Icons.add_rounded,
  });

  final VoidCallback? onPressed;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BrandColors.clay,
      elevation: 4,
      shadowColor: BrandColors.clay.withOpacity(0.5),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 22, 0),
          child: SizedBox(
            height: 54,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: BrandColors.onClay, size: 22),
                const SizedBox(width: 9),
                Text(
                  label,
                  style: BrandUi.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: BrandColors.onClay,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Группа настроек (SGroup в profile.jsx).
class BrandSettingsGroup extends StatelessWidget {
  const BrandSettingsGroup({
    super.key,
    this.header,
    required this.children,
  });

  final String? header;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (header != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text(
              header!.toUpperCase(),
              style: BrandUi.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: BrandRuntime.inkFaint,
              ).copyWith(letterSpacing: 0.6),
            ),
          ),
        ],
        Container(
          decoration: BoxDecoration(
            color: BrandRuntime.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: BrandRuntime.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(children: children),
        ),
      ],
    );
  }
}

/// Переключатель настроек (Toggle в profile.jsx).
class BrandToggle extends StatelessWidget {
  const BrandToggle({
    super.key,
    required this.value,
    this.onChanged,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    return GestureDetector(
      onTap: enabled ? () => onChanged!(!value) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 46,
        height: 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: value
              ? BrandColors.needles
              : (enabled
                  ? BrandRuntime.borderStrong
                  : BrandRuntime.borderStrong.withOpacity(0.6)),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 150),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: BrandRuntime.card,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Поле ввода с подписью (Field в app-kit.jsx).
class BrandLabeledField extends StatelessWidget {
  const BrandLabeledField({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.trailing,
    this.onTap,
  });

  final String label;
  final String value;
  final Widget? icon;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final field = Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: BrandRuntime.card,
        borderRadius: BrandUi.buttonRadius,
        border: Border.all(color: BrandRuntime.borderStrong, width: 1.5),
      ),
      child: Row(
        children: [
          if (icon != null) ...[icon!, const SizedBox(width: 10)],
          Expanded(
            child: Text(
              value,
              style: BrandUi.inter(
                fontSize: 15,
                color: value.isEmpty
                    ? BrandRuntime.inkFaint
                    : BrandRuntime.ink,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: BrandUi.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: BrandRuntime.inkSoft,
          ),
        ),
        const SizedBox(height: 6),
        onTap != null
            ? GestureDetector(onTap: onTap, child: field)
            : field,
      ],
    );
  }
}

/// Строка настроек (SRow).
class BrandSettingsRow extends StatelessWidget {
  const BrandSettingsRow({
    super.key,
    this.icon,
    required this.label,
    this.value,
    this.trailing,
    this.onTap,
    this.danger = false,
    this.showChevron = true,
    this.last = false,
  });

  final Widget? icon;
  final String label;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool danger;
  final bool showChevron;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
      child: Row(
        children: [
          if (icon != null) ...[icon!, const SizedBox(width: 13)],
          Expanded(
            child: Text(
              label,
              style: BrandUi.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: danger ? BrandColors.surik : BrandRuntime.ink,
              ),
            ),
          ),
          if (value != null)
            Text(
              value!,
              style: BrandUi.inter(
                fontSize: 14,
                color: BrandRuntime.inkSoft,
              ),
            ),
          if (trailing != null) trailing!
          else if (showChevron && onTap != null)
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: BrandRuntime.inkFaint,
            ),
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: last
                ? null
                : Border(
                    bottom: BorderSide(color: BrandRuntime.border),
                  ),
          ),
          child: content,
        ),
      ),
    );
  }
}

/// Три ромба-crest (splash / welcome).
class BrandCrest extends StatelessWidget {
  const BrandCrest({super.key, this.size = 9});

  final double size;

  @override
  Widget build(BuildContext context) {
    Widget gem(Color color) => Transform.rotate(
          angle: 0.785398,
          child: Container(
            width: size,
            height: size,
            color: color,
          ),
        );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        gem(BrandColors.dawn),
        SizedBox(width: size * 0.75),
        gem(BrandColors.gilded),
        SizedBox(width: size * 0.75),
        gem(BrandColors.dawn),
      ],
    );
  }
}

/// Угловые метки (CornerTicks).
class BrandCornerTicks extends StatelessWidget {
  const BrandCornerTicks({
    super.key,
    this.color = BrandColors.clay,
    this.size = 13,
    this.inset = 8,
  });

  final Color color;
  final double size;
  final double inset;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _tick(Alignment.topLeft),
        _tick(Alignment.topRight, flipH: true),
        _tick(Alignment.bottomLeft, flipV: true),
        _tick(Alignment.bottomRight, flipH: true, flipV: true),
      ],
    );
  }

  Widget _tick(Alignment align, {bool flipH = false, bool flipV = false}) {
    return Positioned.fill(
      child: Align(
        alignment: align,
        child: Padding(
          padding: EdgeInsets.only(
            top: align.y < 0 ? inset : 0,
            bottom: align.y > 0 ? inset : 0,
            left: align.x < 0 ? inset : 0,
            right: align.x > 0 ? inset : 0,
          ),
          child: CustomPaint(
            size: Size(size, size),
            painter: _CornerTickPainter(
              color: color,
              flipH: flipH,
              flipV: flipV,
            ),
          ),
        ),
      ),
    );
  }
}

class _CornerTickPainter extends CustomPainter {
  const _CornerTickPainter({
    required this.color,
    this.flipH = false,
    this.flipV = false,
  });

  final Color color;
  final bool flipH;
  final bool flipV;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.square;

    canvas.save();
    if (flipH) canvas.translate(size.width, 0);
    if (flipV) canvas.translate(0, size.height);
    if (flipH) canvas.scale(-1, 1);
    if (flipV) canvas.scale(1, -1);

    canvas.drawLine(Offset.zero, Offset(size.width, 0), paint);
    canvas.drawLine(Offset.zero, Offset(0, size.height), paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CornerTickPainter oldDelegate) => false;
}

/// Зелёная сцена FloorStage (map.jsx / Unity3D).
class BrandFloorStage extends StatelessWidget {
  const BrandFloorStage({
    super.key,
    this.height = 300,
    this.afterMode = false,
    this.label = 'UNITY · ЧЕРНОВИК',
    this.status = 'СБОР ДАННЫХ',
    this.showReadouts = true,
    this.borderRadius = 0,
  });

  final double height;
  final bool afterMode;
  final String label;
  final String status;
  final bool showReadouts;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: _FloorStagePainter(afterMode: afterMode)),
            const BrandCornerTicks(
              color: Color(0xA6D28B75),
              size: 13,
              inset: 6,
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 22,
              child: Row(
                children: List.generate(16, (i) {
                  return Expanded(
                    child: Container(
                      height: i % 4 == 0 ? 9 : 5,
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(
                            color: BrandColors.dawn.withOpacity(0.28),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Center(
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0018)
                  ..rotateX(0.87)
                  ..rotateZ(-0.035),
                child: Container(
                  width: 196,
                  height: 122,
                  decoration: BoxDecoration(
                    color: afterMode
                        ? BrandColors.needlesLight.withOpacity(0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(
                      color: afterMode ? BrandColors.needlesLight : BrandColors.dawn,
                      width: 1.5,
                      style: afterMode ? BorderStyle.solid : BorderStyle.solid,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.6),
                        blurRadius: 40,
                        offset: const Offset(0, 26),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 30,
              left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: BrandColors.dawn.withOpacity(0.4)),
                ),
                child: Text(
                  label,
                  style: BrandUi.monoLabel(
                    fontSize: 9.5,
                    color: BrandColors.dawn.withOpacity(0.9),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 30,
              right: 14,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: BrandColors.dawn,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: BrandColors.clay.withOpacity(0.8),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    status,
                    style: BrandUi.monoLabel(
                      fontSize: 9.5,
                      color: BrandColors.dawn.withOpacity(0.75),
                    ),
                  ),
                ],
              ),
            ),
            if (showReadouts)
              Positioned(
                left: 16,
                right: 16,
                bottom: 14,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _readout('ПЛОЩАДЬ', afterMode ? '28.4 м²' : '—— м²', alignEnd: false),
                    _readout('КОМНАТ', afterMode ? '3' : '1', alignEnd: false),
                    _readout('СМЕТА', afterMode ? '1.18 млн' : '—— ₽', alignEnd: true),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _readout(String key, String value, {required bool alignEnd}) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          key,
          style: BrandUi.monoLabel(
            fontSize: 9.5,
            color: BrandColors.dawn.withOpacity(0.55),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: BrandUi.monoLabel(
            fontSize: 15,
            color: BrandRuntime.card,
          ),
        ),
      ],
    );
  }
}

class _FloorStagePainter extends CustomPainter {
  const _FloorStagePainter({required this.afterMode});

  final bool afterMode;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.68),
          radius: 1.2,
          colors: [
            BrandColors.needlesLight,
            BrandColors.needles,
            BrandColors.needlesDeep,
          ],
          stops: const [0, 0.46, 1],
        ).createShader(rect),
    );

    canvas.save();
    canvas.translate(size.width * 0.5, size.height);
    final gridMatrix = Matrix4.identity()
      ..setEntry(3, 2, 0.0024)
      ..rotateX(1.08)
      ..translate(-size.width * 0.5, -size.height * 0.82);
    canvas.transform(gridMatrix.storage);
    final gridPaint = Paint()
      ..color = const Color(0x21AAC8AA)
      ..strokeWidth = 1;
    const step = 34.0;
    for (var x = -size.width; x < size.width * 2; x += step) {
      canvas.drawLine(
        Offset(x, size.height * 0.78),
        Offset(x, -size.height),
        gridPaint,
      );
    }
    for (var y = -size.height; y < size.height; y += step) {
      canvas.drawLine(
        Offset(-size.width, y),
        Offset(size.width * 2, y),
        gridPaint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FloorStagePainter oldDelegate) =>
      oldDelegate.afterMode != afterMode;
}

/// Сегмент «До / После» (map.jsx MapEditor).
class BrandBeforeAfterSegment extends StatelessWidget {
  const BrandBeforeAfterSegment({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: BrandRuntime.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (var i = 0; i < 2; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: selectedIndex == i ? BrandRuntime.card : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: selectedIndex == i
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    i == 0 ? 'До' : 'После',
                    style: BrandUi.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: selectedIndex == i
                          ? (i == 1 ? BrandColors.needles : BrandColors.surik)
                          : BrandRuntime.inkSoft,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Карточка действия на экране карты.
class BrandMapActionCard extends StatelessWidget {
  const BrandMapActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.accent = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: BrandRuntime.card,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: accent ? BrandColors.clay : BrandRuntime.border,
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: accent ? BrandColors.clay : BrandRuntime.surface,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: accent ? BrandColors.onClay : BrandColors.needles,
                  ),
                ),
                const SizedBox(height: 11),
                Text(
                  title,
                  style: BrandUi.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: BrandUi.inter(
                    fontSize: 11.5,
                    color: BrandRuntime.inkSoft,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Холст с сеткой для эскиза / плана сверху.
class BrandGridCanvas extends StatelessWidget {
  const BrandGridCanvas({
    super.key,
    required this.child,
    this.borderRadius = 18,
    this.showCornerTicks = true,
  });

  final Widget child;
  final double borderRadius;
  final bool showCornerTicks;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: BrandRuntime.border),
          color: BrandRuntime.card,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: _GridCanvasPainter()),
            child,
            if (showCornerTicks)
              const BrandCornerTicks(
                color: BrandColors.clay,
                size: 14,
                inset: 10,
              ),
          ],
        ),
      ),
    );
  }
}

class _GridCanvasPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const step = 24.0;
    final paint = Paint()..color = BrandColors.needles.withOpacity(0.06);
    for (var y = step; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (var x = step; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Полупрозрачная кнопка поверх тёмной сцены (Unity / BeforeAfter).
class BrandGlassPill extends StatelessWidget {
  const BrandGlassPill({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: BrandColors.needlesDeep.withOpacity(0.6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: BrandColors.onNeedles.withOpacity(0.18)),
      ),
      child: child,
    );
    if (onTap == null) return box;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: box,
      ),
    );
  }
}

/// Нижняя карточка на полноэкранных сценах.
class BrandOverlayBottomCard extends StatelessWidget {
  const BrandOverlayBottomCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.avatarName,
    this.actions,
  });

  final String title;
  final String subtitle;
  final String? avatarName;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BrandRuntime.card.withOpacity(0.96),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: BrandColors.needlesDeep.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: pochaevsk(
                        fontSize: 20,
                        color: BrandRuntime.ink,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: BrandUi.inter(
                        fontSize: 12.5,
                        color: BrandRuntime.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              if (avatarName != null)
                BrandAvatar(
                  name: avatarName!,
                  size: 40,
                  radius: 12,
                  tone: BrandAvatarTone.clay,
                ),
            ],
          ),
          if (actions != null) ...[
            const SizedBox(height: 14),
            Row(children: actions!),
          ],
        ],
      ),
    );
  }
}
