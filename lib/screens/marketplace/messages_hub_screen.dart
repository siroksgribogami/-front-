import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_text_style.dart';
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
              title: const Text('ИИ-прораб'),
            ),
            body: const SafeArea(child: AiForemanChatTab()),
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
            padding: EdgeInsets.fromLTRB(horizontalPad, 16, horizontalPad, 8),
            child: Text(
              'Чаты',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                fontFamily: AppTextStyle.fontFamily,
                color: textPrimary,
                height: AppTextStyle.defaultHeight,
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 720;
                final dateFmt = DateFormat('d MMM, HH:mm', 'ru');

                final list = ListView.separated(
                  padding: EdgeInsets.fromLTRB(horizontalPad, 4, horizontalPad, 16),
                  itemCount: _threads.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      return _PinnedAiTile(
                        selected: _selectedId == _aiPinnedId,
                        onTap: () => _openAi(context, isWide: isWide),
                      );
                    }
                    final t = _threads[i - 1];
                    return _ThreadTile(
                      thread: t,
                      dateFmt: dateFmt,
                      selected: _selectedId == t.id,
                      onTap: () => _openThread(context, t, isWide: isWide),
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
                                fontFamily: AppTextStyle.fontFamily,
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
    final card = MarketplaceColors.cardFor(context);
    final textPrimary = MarketplaceColors.textPrimaryFor(context);
    final textMuted = MarketplaceColors.textMutedFor(context);

    return Material(
      color: selected
          ? MarketplaceColors.aiTurquoise.withOpacity(0.18)
          : card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: MarketplaceColors.aiTurquoise.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: MarketplaceColors.aiTurquoise.withOpacity(0.45),
                  ),
                ),
                padding: const EdgeInsets.all(6),
                child: SvgPicture.asset(
                  'picture/обычный.svg',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'ИИ-прораб',
                            style: TextStyle(
                              fontFamily: AppTextStyle.fontFamily,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: textPrimary,
                            ),
                          ),
                        ),
                        Icon(Icons.push_pin, size: 14, color: textMuted),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Соберёт ТЗ, смету и список материалов',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: MarketplaceColors.aiTurquoise,
                        fontWeight: FontWeight.w600,
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
  final bool selected;
  final VoidCallback onTap;

  const _ThreadTile({
    required this.thread,
    required this.dateFmt,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = MarketplaceColors.cardFor(context);
    final textPrimary = MarketplaceColors.textPrimaryFor(context);
    final textSecondary = MarketplaceColors.textSecondaryFor(context);
    final textMuted = MarketplaceColors.textMutedFor(context);

    return Material(
      color: selected
          ? MarketplaceColors.bluePrimary.withOpacity(0.12)
          : card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    MarketplaceColors.bluePrimary.withOpacity(0.25),
                child: Text(
                  thread.peerName.isNotEmpty
                      ? thread.peerName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            thread.peerName,
                            style: TextStyle(
                              fontFamily: AppTextStyle.fontFamily,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          dateFmt.format(thread.updatedAt),
                          style: TextStyle(fontSize: 11, color: textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      thread.projectTitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: MarketplaceColors.aiTurquoise,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      thread.lastMessagePreview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                        height: 1.3,
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
