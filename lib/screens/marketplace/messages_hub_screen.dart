import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/brand_colors.dart';
import '../../config/text_theme.dart';
import '../../core/theme/app_text_style.dart';
import '../../core/theme/brand_ui.dart';
import '../../core/theme/marketplace_colors.dart';
import '../../models/marketplace_project.dart';
import '../../services/marketplace_local_store.dart';
import 'ai_foreman_chat_tab.dart';
import 'direct_chat_screen.dart';

/// Хаб сообщений в стиле Telegram: список чатов с закреплённым ИИ-прорабом сверху.
class MessagesHubScreen extends StatefulWidget {
  const MessagesHubScreen({super.key});

  @override
  State<MessagesHubScreen> createState() => _MessagesHubScreenState();
}

class _MessagesHubScreenState extends State<MessagesHubScreen> {
  static const String _aiPinnedId = '__ai_foreman__';

  String _selectedId = _aiPinnedId;
  List<DirectChatThread> _threads = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await MarketplaceLocalStore.instance.ensureLoaded();
    if (!mounted) return;
    setState(() {
      _threads = List.from(MarketplaceLocalStore.instance.directChats);
      _loading = false;
    });
  }

  void _openThread(BuildContext context, DirectChatThread t, {required bool isWide}) {
    if (isWide) {
      setState(() => _selectedId = t.id);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => DirectChatScreen(thread: t),
        ),
      );
    }
  }

  void _openAi(BuildContext context, {required bool isWide}) {
    if (isWide) {
      setState(() => _selectedId = _aiPinnedId);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            backgroundColor: MarketplaceColors.backgroundFor(context),
            appBar: AppBar(
              backgroundColor: MarketplaceColors.cardFor(context),
              foregroundColor: MarketplaceColors.textPrimaryFor(context),
              titleSpacing: 0,
              title: Row(
                children: [
                  const ForemanAvatar(size: 36),
                  const SizedBox(width: 10),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontFamily: AppTextStyle.uiFontFamily,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: MarketplaceColors.textPrimaryFor(context),
                      ),
                      children: const [
                        TextSpan(text: 'ИИ-'),
                        TextSpan(
                          text: 'прораб',
                          style: TextStyle(color: BrandColors.clay),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            body: const SafeArea(child: AiForemanChatTab(showHeader: false)),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = MarketplaceColors.backgroundFor(context);
    final card = MarketplaceColors.cardFor(context);
    final textPrimary = MarketplaceColors.textPrimaryFor(context);
    final textMuted = MarketplaceColors.textMutedFor(context);

    if (_loading) {
      return ColoredBox(
        color: bg,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final horizontalPad = MarketplaceColors.horizontalPaddingFor(context);

    return ColoredBox(
      color: bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(horizontalPad, 8, horizontalPad, 8),
            child: BrandAppBar(
              title: 'Сообщения',
              big: true,
              actions: BrandIconButton(
                icon: Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: BrandColors.tar.withOpacity(0.55),
                ),
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 720;
                final dateFmt = DateFormat('d MMM, HH:mm', 'ru');

                final list = ListView.builder(
                  padding: EdgeInsets.fromLTRB(horizontalPad, 4, horizontalPad, 16),
                  itemCount: _threads.length + 2,
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _PinnedAiTile(
                          selected: _selectedId == _aiPinnedId,
                          onTap: () => _openAi(context, isWide: isWide),
                        ),
                      );
                    }
                    if (i == 1) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
                        child: Text(
                          'МАСТЕРА И БРИГАДЫ',
                          style: BrandUi.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: BrandColors.tar.withOpacity(0.4),
                          ).copyWith(letterSpacing: 0.5),
                        ),
                      );
                    }
                    final t = _threads[i - 2];
                    return _ThreadTile(
                      thread: t,
                      dateFmt: dateFmt,
                      index: i - 2,
                      selected: _selectedId == t.id,
                      onTap: () => _openThread(context, t, isWide: isWide),
                      isLast: i == _threads.length + 1,
                    );
                  },
                );

                if (!isWide) return list;

                Widget detail;
                if (_selectedId == _aiPinnedId) {
                  detail = const AiForemanChatTab();
                } else {
                  final selected = _threads.firstWhere(
                    (t) => t.id == _selectedId,
                    orElse: () => _threads.first,
                  );
                  detail = DirectChatScreen(
                    key: ValueKey(selected.id),
                    thread: selected,
                    embedded: true,
                  );
                }

                final headerLabel = _selectedId == _aiPinnedId
                    ? 'ИИ-прораб'
                    : 'Диалог: ${_threads.firstWhere(
                        (t) => t.id == _selectedId,
                        orElse: () => _threads.first,
                      ).peerName}';

                return Row(
                  children: [
                    Expanded(flex: 1, child: list),
                    Container(
                        width: 1, color: Theme.of(context).dividerColor),
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          Container(
                            height: 46,
                            width: double.infinity,
                            color: card,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            alignment: Alignment.centerLeft,
                            child: Text(
                              headerLabel,
                              style: TextStyle(
                                fontFamily: AppTextStyle.uiFontFamily,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Divider(height: 1),
                          Expanded(child: detail),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          if (_threads.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPad, vertical: 8),
              child: Text(
                'Прямых чатов пока нет — они появятся, когда заказчик и мастер договорятся.',
                style: TextStyle(color: textMuted, fontSize: 12, height: 1.35),
              ),
            ),
        ],
      ),
    );
  }
}

class _PinnedAiTile extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;

  const _PinnedAiTile({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: BrandColors.needles,
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: BrandColors.needles.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: RadialGradient(
                      center: const Alignment(0.9, -0.2),
                      radius: 1.2,
                      colors: [
                        BrandColors.needlesLight.withOpacity(0.45),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const ForemanAvatar(size: 46, radius: 13),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'ИИ-прораб',
                                style: pochaevsk(
                                  fontSize: 17,
                                  color: BrandColors.onNeedles,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.auto_awesome_rounded,
                                size: 13,
                                color: BrandColors.dawn,
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Смета по кухне готова — посмотрим?',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: BrandUi.inter(
                              fontSize: 13,
                              color: BrandColors.onNeedles.withOpacity(0.82),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '10:05',
                      style: BrandUi.inter(
                        fontSize: 11.5,
                        color: BrandColors.onNeedles.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThreadTile extends StatelessWidget {
  final DirectChatThread thread;
  final DateFormat dateFmt;
  final int index;
  final bool selected;
  final bool isLast;
  final VoidCallback onTap;

  const _ThreadTile({
    required this.thread,
    required this.dateFmt,
    required this.index,
    required this.selected,
    required this.isLast,
    required this.onTap,
  });

  static BrandAvatarTone _toneFor(int index) {
    switch (index % 3) {
      case 0:
        return BrandAvatarTone.clay;
      case 1:
        return BrandAvatarTone.green;
      default:
        return BrandAvatarTone.sand;
    }
  }

  static int _unreadCount(DirectChatThread thread) {
    final preview = thread.lastMessagePreview.trim();
    if (preview.startsWith('Вы:') || preview.startsWith('Вы ')) return 0;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final profile = thread.masterId != null
        ? MarketplaceLocalStore.instance.profileById(thread.masterId!)
        : null;
    final role = profile?.specialty.isNotEmpty == true
        ? 'Мастер · ${profile!.specialty}'
        : thread.projectTitle;
    final unread = _unreadCount(thread);
    final timeLabel = _formatTime(thread.updatedAt, dateFmt);

    return Material(
      color: selected ? BrandColors.linen.withOpacity(0.45) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: isLast
                ? null
                : const Border(
                    bottom: BorderSide(color: BrandColors.borderSubtle),
                  ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    BrandAvatar(
                      name: thread.peerName,
                      size: 48,
                      radius: 14,
                      tone: _toneFor(index),
                    ),
                    if (index == 0)
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: BrandColors.gilded,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: BrandColors.canvas,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.star_rounded,
                            size: 9,
                            color: BrandColors.onClay,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              thread.peerName,
                              style: BrandUi.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: BrandColors.tar,
                              ),
                            ),
                          ),
                          Text(
                            timeLabel,
                            style: BrandUi.inter(
                              fontSize: 11.5,
                              color: BrandColors.tar.withOpacity(0.4),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        role,
                        style: BrandUi.inter(
                          fontSize: 11.5,
                          color: BrandColors.clay,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              thread.lastMessagePreview,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: BrandUi.inter(
                                fontSize: 13,
                                color: BrandColors.tar.withOpacity(0.65),
                              ),
                            ),
                          ),
                          if (unread > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              constraints: const BoxConstraints(minWidth: 19),
                              height: 19,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              decoration: BoxDecoration(
                                color: BrandColors.clay,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '$unread',
                                style: BrandUi.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: BrandColors.onClay,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _formatTime(DateTime at, DateFormat dateFmt) {
    final now = DateTime.now();
    final diff = now.difference(at);
    if (diff.inDays == 0) {
      return DateFormat.Hm('ru').format(at);
    }
    if (diff.inDays == 1) return 'Вчера';
    if (diff.inDays < 7) {
      const days = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
      return days[at.weekday - 1];
    }
    return dateFmt.format(at);
  }
}
