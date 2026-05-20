import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_text_style.dart';
import '../../core/theme/marketplace_colors.dart';
import '../../data/premise_rooms_catalog.dart';
import '../../models/ai_responses.dart';
import '../../services/api_service.dart';
import '../../services/survey_service.dart';

/// Чат с ИИ-прорабом. Аватар — в шапке (как Telegram), не в каждом сообщении.
class AiForemanChatTab extends StatefulWidget {
  /// `false`, если аватар уже в AppBar родительского экрана.
  final bool showHeader;

  const AiForemanChatTab({super.key, this.showHeader = true});

  @override
  State<AiForemanChatTab> createState() => _AiForemanChatTabState();
}

class _AiForemanChatTabState extends State<AiForemanChatTab> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<_ChatMessage> _messages = [
    _ChatMessage(
      text:
          'Привет! Я ИИ-прораб ARTkhaus.\n\nСоберу из вашего описания ТЗ, смету и список материалов.\n\nС чего начнём: комната, бюджет или сроки?',
      isUser: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      emotion: 'обычный',
    ),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
    });
    _messageController.clear();
    _scrollToEnd();

    setState(() {
      _messages.add(_ChatMessage(
        text: '...',
        isUser: false,
        timestamp: DateTime.now(),
        emotion: 'think',
      ));
    });

    try {
      Map<String, dynamic>? survey;
      try {
        survey = await SurveyService().getLatestSurvey();
      } catch (_) {
        survey = null;
      }

      final premiseRooms = await PremiseRoomsCatalog.loadPersistedRooms();

      final api = ApiService();
      final body = <String, dynamic>{
        'message': text,
        if (survey != null) 'survey': survey,
        if (premiseRooms != null && premiseRooms.isNotEmpty)
          'premise_rooms': premiseRooms,
      };
      final resp = await api.post('/ai/foreman/chat', body: body);

      final replyText = resp is Map && resp['text'] != null
          ? resp['text'].toString()
          : getAiAssistantReply(text);
      final emotion = resp is Map && resp['emotion'] != null
          ? resp['emotion'].toString()
          : 'обычный';

      setState(() {
        if (_messages.isNotEmpty && _messages.last.text == '...') {
          _messages.removeLast();
        }
        _messages.add(_ChatMessage(
          text: replyText,
          isUser: false,
          timestamp: DateTime.now(),
          emotion: emotion,
        ));
      });
    } catch (_) {
      final response = getAiAssistantReply(text);
      setState(() {
        if (_messages.isNotEmpty && _messages.last.text == '...') {
          _messages.removeLast();
        }
        _messages.add(_ChatMessage(
          text: response,
          isUser: false,
          timestamp: DateTime.now(),
          emotion: 'обычный',
        ));
      });
    }

    _scrollToEnd();
  }

  void _scrollToEnd() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bg = MarketplaceColors.backgroundFor(context);
    final card = MarketplaceColors.cardFor(context);
    final textPrimary = MarketplaceColors.textPrimaryFor(context);
    final textMuted = MarketplaceColors.textMutedFor(context);
    final inputFill = MarketplaceColors.surfaceFor(context);

    return ColoredBox(
      color: bg,
      child: Column(
        children: [
          if (widget.showHeader) _ForemanChatHeader(),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) =>
                  _buildMessageBubble(_messages[index], context),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildQuickReply('Формат комнаты и метраж'),
                _buildQuickReply('Бюджет до 150 тыс.'),
                _buildQuickReply('Нужен дизайн-проект'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              color: card,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: inputFill,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: MarketplaceColors.aiTurquoise.withOpacity(0.35),
                      ),
                    ),
                    child: TextField(
                      controller: _messageController,
                      textAlign: TextAlign.start,
                      style: TextStyle(color: textPrimary, fontSize: 15),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: inputFill,
                        hintText: 'Опишите задачу...',
                        hintStyle: TextStyle(color: textMuted),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: MarketplaceColors.aiTurquoise,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage message, BuildContext context) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: _buildBubbleBody(message, context, isUser: isUser),
    );
  }

  Widget _buildBubbleBody(
    _ChatMessage message,
    BuildContext context, {
    required bool isUser,
  }) {
    final card = MarketplaceColors.cardFor(context);
    final textPrimary = MarketplaceColors.textPrimaryFor(context);
    final textMuted = MarketplaceColors.textMutedFor(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.82,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isUser ? MarketplaceColors.bluePrimary : card,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isUser ? 18 : 4),
          bottomRight: Radius.circular(isUser ? 4 : 18),
        ),
        border: isUser
            ? null
            : const Border(
                left: BorderSide(
                  color: MarketplaceColors.aiTurquoise,
                  width: 3,
                ),
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.text,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: isUser ? Colors.white : textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                fontSize: 10,
                color: isUser ? Colors.white.withOpacity(0.7) : textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickReply(String text) {
    return GestureDetector(
      onTap: () {
        _messageController.text = text;
        _sendMessage();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: MarketplaceColors.aiTurquoise.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: MarketplaceColors.aiTurquoise.withOpacity(0.4)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: MarketplaceColors.aiTurquoise,
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

/// Шапка чата: аватар + имя (как в Telegram).
class _ForemanChatHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final card = MarketplaceColors.cardFor(context);
    final textPrimary = MarketplaceColors.textPrimaryFor(context);
    final textMuted = MarketplaceColors.textMutedFor(context);

    return Material(
      color: card,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          children: [
            const ForemanAvatar(size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ИИ-прораб',
                    style: TextStyle(
                      fontFamily: AppTextStyle.fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                  Text(
                    'Соберёт ТЗ, смету и материалы',
                    style: TextStyle(fontSize: 12, color: textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Компактный аватар для AppBar / списка чатов.
class ForemanAvatar extends StatelessWidget {
  const ForemanAvatar({
    super.key,
    this.size = 40,
    this.emotion,
  });

  final double size;
  final String? emotion;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF4EDE4),
          borderRadius: BorderRadius.circular(size * 0.28),
          border: Border.all(
            color: MarketplaceColors.aiTurquoise.withOpacity(0.4),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.24),
          child: Padding(
            padding: EdgeInsets.all(size * 0.04),
            child: SvgPicture.asset(
              _avatarAssetFor(emotion),
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? emotion;

  _ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.emotion,
  });
}

String _avatarAssetFor(String? emotion) {
  switch (emotion) {
    case 'think':
      return 'picture/думает.svg';
    case 'рад':
    case 'happy':
      return 'picture/веселый.svg';
    default:
      return 'picture/обычный.svg';
  }
}
