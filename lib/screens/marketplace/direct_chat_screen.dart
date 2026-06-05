import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/brand_colors.dart';
import '../../config/text_theme.dart';
import '../../core/theme/brand_ui.dart';
import '../../models/marketplace_project.dart';
import '../../services/marketplace_local_store.dart';
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
        text:
            'Добрый день! Уточните, пожалуйста, по объекту «${widget.thread.projectTitle}».',
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

  MasterProfile? get _masterProfile {
    final id = widget.thread.masterId;
    if (id == null) return null;
    return MarketplaceLocalStore.instance.profileById(id);
  }

  @override
  Widget build(BuildContext context) {
    final timeFmt = DateFormat.Hm('ru');
    final profile = _masterProfile;
    final rating = profile?.rating ?? 5.0;
    final specialty = profile?.specialty ?? 'Мастер';

    final body = Column(
      children: [
        if (!widget.embedded) _buildHeader(context, rating, specialty),
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            itemCount: _lines.length + 1,
            itemBuilder: (_, i) {
              if (i == 0) return _projectContextChip();
              return _bubble(_lines[i - 1], timeFmt);
            },
          ),
        ),
        _buildInputBar(context),
      ],
    );

    if (widget.embedded) {
      return ColoredBox(
        color: BrandColors.canvas,
        child: SafeArea(top: false, child: body),
      );
    }

    return Scaffold(
      backgroundColor: BrandColors.canvas,
      body: SafeArea(child: body),
    );
  }

  Widget _buildHeader(BuildContext context, double rating, String specialty) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: const BoxDecoration(
        color: BrandColors.milk,
        border: Border(bottom: BorderSide(color: BrandColors.borderSubtle)),
      ),
      child: Row(
        children: [
          BrandBackButton(
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 12),
          BrandAvatar(
            name: widget.thread.peerName,
            size: 40,
            radius: 12,
            tone: BrandAvatarTone.clay,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.thread.peerName,
                        style: pochaevsk(
                          fontSize: 17,
                          color: BrandColors.tar,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    BrandStars(value: rating, size: 11),
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  'Мастер · $specialty',
                  style: BrandUi.inter(
                    fontSize: 12,
                    color: BrandColors.clay,
                  ),
                ),
              ],
            ),
          ),
          if (widget.thread.masterId != null)
            BrandIconButton(
              icon: Icon(Icons.phone_outlined, size: 18, color: BrandColors.needles),
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
            ),
        ],
      ),
    );
  }

  Widget _projectContextChip() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: BoxDecoration(
            color: BrandColors.linen.withOpacity(0.55),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: const BrandStripedPlaceholder(
                  label: '',
                  height: 32,
                  radius: 9,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Проект: ${widget.thread.projectTitle}',
                    style: BrandUi.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: BrandColors.needles,
                    ),
                  ),
                  Text(
                    'Отклик · диалог по объекту',
                    style: BrandUi.inter(
                      fontSize: 11.5,
                      color: BrandColors.tar.withOpacity(0.55),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bubble(_Line line, DateFormat timeFmt) {
    final mine = !line.incoming;

    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.82,
          ),
          padding: const EdgeInsets.fromLTRB(14, 11, 14, 9),
          decoration: BoxDecoration(
            color: mine ? BrandColors.needles : BrandColors.milk,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(mine ? 16 : 4),
              bottomRight: Radius.circular(mine ? 4 : 16),
            ),
            border: mine
                ? null
                : Border.all(color: BrandColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                line.text,
                style: BrandUi.inter(
                  fontSize: 14.5,
                  height: 1.45,
                  color: mine ? BrandColors.onNeedles : BrandColors.tar,
                ),
              ),
              const SizedBox(height: 5),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  timeFmt.format(line.at),
                  style: BrandUi.inter(
                    fontSize: 10.5,
                    color: mine
                        ? BrandColors.onNeedles.withOpacity(0.6)
                        : BrandColors.tar.withOpacity(0.4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottom + 16),
      decoration: const BoxDecoration(
        color: BrandColors.canvas,
        border: Border(top: BorderSide(color: BrandColors.borderSubtle)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: BrandColors.chipBorder, width: 1.5),
            ),
            child: Icon(Icons.add, size: 20, color: BrandColors.needles),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _controller,
              style: BrandUi.inter(fontSize: 15),
              decoration: InputDecoration(
                filled: true,
                fillColor: BrandColors.milk,
                hintText: 'Сообщение ${widget.thread.peerName.split(' ').first}…',
                hintStyle: BrandUi.inter(
                  fontSize: 15,
                  color: BrandColors.tar.withOpacity(0.45),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide:
                      const BorderSide(color: BrandColors.chipBorder, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide:
                      const BorderSide(color: BrandColors.chipBorder, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide:
                      const BorderSide(color: BrandColors.needles, width: 1.5),
                ),
                isDense: true,
              ),
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: BrandColors.clay,
            borderRadius: BorderRadius.circular(13),
            elevation: 0,
            shadowColor: BrandColors.clay.withOpacity(0.8),
            child: InkWell(
              onTap: _send,
              borderRadius: BorderRadius.circular(13),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: BrandColors.clay.withOpacity(0.55),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.send_rounded,
                  size: 20,
                  color: BrandColors.onClay,
                ),
              ),
            ),
          ),
        ],
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
