import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_text_style.dart';
import '../../core/theme/marketplace_colors.dart';
import '../../data/marketplace_mock_data.dart';
import 'direct_chat_screen.dart';

/// Список прямых чатов с мастерами / заказчиками.
class DirectChatsListScreen extends StatelessWidget {
  const DirectChatsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final threads = MarketplaceMockData.directChats;
    final dateFmt = DateFormat('d MMM, HH:mm', 'ru');

    if (threads.isEmpty) {
      return const Center(
        child: Text(
          'Пока нет переписок',
          style: TextStyle(color: MarketplaceColors.textMuted),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: threads.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final t = threads[i];
        return Material(
          color: MarketplaceColors.card,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => DirectChatScreen(thread: t),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: MarketplaceColors.bluePrimary.withOpacity(0.25),
                    child: Text(
                      t.peerName.isNotEmpty ? t.peerName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: MarketplaceColors.textPrimary,
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
                                t.peerName,
                                style: TextStyle(
                                  fontFamily: AppTextStyle.fontFamily,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: MarketplaceColors.textPrimary,
                                ),
                              ),
                            ),
                            Text(
                              dateFmt.format(t.updatedAt),
                              style: const TextStyle(
                                fontSize: 11,
                                color: MarketplaceColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          t.projectTitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: MarketplaceColors.aiTurquoise,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          t.lastMessagePreview,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: MarketplaceColors.textSecondary,
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
      },
    );
  }
}
