import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_text_style.dart';
import '../../core/theme/marketplace_colors.dart';
import '../../models/marketplace_project.dart';
import 'master_public_profile_screen.dart';

/// Переписка заказчик ↔ мастер.
class DirectChatScreen extends StatefulWidget {
  final DirectChatThread thread;
  final bool embedded;

  const DirectChatScreen({
    super.key,
    required this.thread,
    this.embedded = false,
  });

  @override
  State<DirectChatScreen> createState() => _DirectChatScreenState();
}

class _DirectChatScreenState extends State<DirectChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final List<_Line> _lines = [];

  @override
  void initState() {
    super.initState();
    _lines.addAll([
      _Line(
        text: 'Добрый день! Уточните, пожалуйста, по объекту «${widget.thread.projectTitle}».',
        incoming: true,
        at: DateTime(2026, 4, 20, 10, 0),
      ),
      _Line(
        text: widget.thread.lastMessagePreview,
        incoming: false,
        at: widget.thread.updatedAt,
      ),
    ]);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final t = _controller.text.trim();
    if (t.isEmpty) return;
    setState(() {
      _lines.add(_Line(text: t, incoming: false, at: DateTime.now()));
    });
    _controller.clear();
    Future.delayed(const Duration(milliseconds: 50), () {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final timeFmt = DateFormat.Hm('ru');
    final bg = MarketplaceColors.backgroundFor(context);
    final card = MarketplaceColors.cardFor(context);
    final textPrimary = MarketplaceColors.textPrimaryFor(context);
    final textMuted = MarketplaceColors.textMutedFor(context);
    final inputFill = MarketplaceColors.surfaceFor(context);

    final body = Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: _lines.length,
            itemBuilder: (_, i) => _bubble(_lines[i], timeFmt, context),
          ),
        ),
        Container(
          padding: EdgeInsets.only(
            left: 12,
            right: 12,
            top: 8,
            bottom: MediaQuery.paddingOf(context).bottom + 10,
          ),
          color: card,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: TextStyle(color: textPrimary),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: inputFill,
                    hintText: 'Сообщение…',
                    hintStyle: TextStyle(color: textMuted),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: MarketplaceColors.textMutedFor(context)
                            .withOpacity(0.18),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: MarketplaceColors.textMutedFor(context)
                            .withOpacity(0.18),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: MarketplaceColors.bluePrimary, width: 1.4),
                    ),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _send,
                style: FilledButton.styleFrom(
                  backgroundColor: MarketplaceColors.bluePrimary,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
                child: const Icon(Icons.send, size: 20),
              ),
            ],
          ),
        ),
      ],
    );

    if (widget.embedded) {
      return ColoredBox(
        color: bg,
        child: SafeArea(top: false, child: body),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: card,
        foregroundColor: textPrimary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.thread.peerName,
              style: TextStyle(
                fontFamily: AppTextStyle.fontFamily,
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: textPrimary,
              ),
            ),
            Text(
              widget.thread.projectTitle,
              style: TextStyle(
                fontSize: 12,
                color: textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          if (widget.thread.masterId != null)
            IconButton(
              tooltip: 'Карточка мастера',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => MasterPublicProfileScreen(
                      masterId: widget.thread.masterId!,
                      projectTitleForContract: widget.thread.projectTitle,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.badge_outlined),
            ),
        ],
      ),
      body: body,
    );
  }

  Widget _bubble(_Line line, DateFormat timeFmt, BuildContext context) {
    final incoming = line.incoming;
    final card = MarketplaceColors.cardFor(context);
    final textPrimary = MarketplaceColors.textPrimaryFor(context);
    final textMuted = MarketplaceColors.textMutedFor(context);

    return Align(
      alignment: incoming ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.82),
        decoration: BoxDecoration(
          color: incoming ? card : MarketplaceColors.bluePrimary,
          borderRadius: BorderRadius.circular(14),
          border: incoming
              ? Border.all(
                  color: MarketplaceColors.textMutedFor(context).withOpacity(0.12),
                )
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              line.text,
              style: TextStyle(
                color: incoming ? textPrimary : Colors.white,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              timeFmt.format(line.at),
              style: TextStyle(
                fontSize: 11,
                color: incoming ? textMuted : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Line {
  final String text;
  final bool incoming;
  final DateTime at;

  _Line({required this.text, required this.incoming, required this.at});
}
