import 'package:flutter/material.dart';

import '../../core/theme/app_text_style.dart';
import '../../core/theme/marketplace_colors.dart';
import 'ai_foreman_chat_tab.dart';

class CreateProjectForemanPanel extends StatefulWidget {
  final bool expanded;
  final ValueChanged<bool> onExpandedChanged;
  final Widget chatChild;

  const CreateProjectForemanPanel({
    super.key,
    required this.expanded,
    required this.onExpandedChanged,
    required this.chatChild,
  });

  @override
  State<CreateProjectForemanPanel> createState() => _CreateProjectForemanPanelState();
}

class _CreateProjectForemanPanelState extends State<CreateProjectForemanPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _heightFactor;

  static const _headerHeight = 60.0;
  static const _collapsedBody = 6.0;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _heightFactor = CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic);
    if (widget.expanded) {
      _anim.value = 1;
    }
  }

  @override
  void didUpdateWidget(CreateProjectForemanPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expanded != widget.expanded) {
      if (widget.expanded) {
        _anim.forward();
      } else {
        _anim.reverse();
      }
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _toggle() => widget.onExpandedChanged(!widget.expanded);

  @override
  Widget build(BuildContext context) {
    final card = MarketplaceColors.cardFor(context);
    final textPrimary = MarketplaceColors.textPrimaryFor(context);
    final textSecondary = MarketplaceColors.textSecondaryFor(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final screenH = MediaQuery.sizeOf(context).height;
    final maxExpanded = screenH * 0.78;
    final collapsedTotal = _headerHeight + _collapsedBody + bottomInset;

    return AnimatedBuilder(
      animation: _heightFactor,
      builder: (context, _) {
        final t = _heightFactor.value;
        final height = collapsedTotal + t * (maxExpanded - collapsedTotal);

        return Material(
          elevation: 12,
          shadowColor: Colors.black26,
          color: card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: height,
            child: Column(
              children: [
                Material(
                  color: card,
                  child: InkWell(
                    onTap: _toggle,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 6, 12, 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: MarketplaceColors.textMutedFor(context).withOpacity(0.35),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          Row(
                            children: [
                          const ForemanAvatar(size: 34),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ИИ-прораб',
                                  style: TextStyle(
                                    fontFamily: AppTextStyle.uiFontFamily,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: textPrimary,
                                  ),
                                ),
                                Text(
                                  widget.expanded
                                      ? 'Свернуть — вернуться к заявке'
                                      : 'Развернуть чат — поможет с ТЗ',
                                  style: TextStyle(fontSize: 12, color: textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            widget.expanded
                                ? Icons.keyboard_arrow_down_rounded
                                : Icons.keyboard_arrow_up_rounded,
                            color: MarketplaceColors.aiTurquoise,
                            size: 28,
                          ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRect(
                    child: IgnorePointer(
                      ignoring: !widget.expanded,
                      child: widget.chatChild,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
