import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/marketplace_colors.dart';
import '../../models/ai_responses.dart';
import '../../services/api_service.dart';
import '../../services/survey_service.dart';

/// Вкладка чата с ИИ-прорабом (сбор ТЗ; офлайн-ответы до API). Вынесено для reuse в [MessagesHubScreen].
class AiForemanChatTab extends StatefulWidget {
  const AiForemanChatTab({super.key});

  @override
  State<AiForemanChatTab> createState() => _AiForemanChatTabState();
}

class _AiForemanChatTabState extends State<AiForemanChatTab> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<_ChatMessage> _messages = [
    _ChatMessage(
      text:
          'Привет! Я ИИ-прораб ARTkhaus.\n\nСоберу из твоего описания ТЗ, смету и список материалов.\n\nС чего начнём: комната, бюджет или сроки?',
      isUser: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
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

    // прокрутка вниз
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    // Показать думалку
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

      final api = ApiService();
      final body = {'message': text, 'survey': survey};
      final resp = await api.post('/ai/foreman/chat', body: body);

      // ожидаем ответ вида { text: '...', emotion: 'рад'|'think'|'обычный', avatar_url?: 'http...'}
      final replyText = resp is Map && resp['text'] != null ? resp['text'].toString() : (getAiAssistantReply(text));
      final emotion = resp is Map && resp['emotion'] != null ? resp['emotion'].toString() : 'обычный';
      final avatar = resp is Map && resp['avatar_url'] != null ? resp['avatar_url'].toString() : null;

      // убираем последнюю думалку (три точки)
      setState(() {
        if (_messages.isNotEmpty && _messages.last.text == '...') _messages.removeLast();
        _messages.add(_ChatMessage(
          text: replyText,
          isUser: false,
          timestamp: DateTime.now(),
          emotion: emotion,
          avatarUrl: avatar,
        ));
      });
    } catch (e) {
      // fallback: локальный оффлайн-ответ
      final response = getAiAssistantReply(text);
      setState(() {
        if (_messages.isNotEmpty && _messages.last.text == '...') _messages.removeLast();
        _messages.add(_ChatMessage(
          text: response,
          isUser: false,
          timestamp: DateTime.now(),
          emotion: 'обычный',
        ));
      });
    }

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
                      style: TextStyle(color: textPrimary, fontSize: 15),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: inputFill,
                        hintText: 'Опишите задачу...',
                        hintStyle: TextStyle(color: textMuted),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
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
                    child:
                        const Icon(Icons.send, color: Colors.white, size: 20),
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
    final card = MarketplaceColors.cardFor(context);
    final textPrimary = MarketplaceColors.textPrimaryFor(context);
    final textMuted = MarketplaceColors.textMutedFor(context);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 6,
          bottom: 6,
          left: isUser ? 50 : 0,
          right: isUser ? 0 : 50,
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
                      color: MarketplaceColors.aiTurquoise, width: 3),
                ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              if (!isUser) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Avatar + emotion
                    Container(
                      width: 28,
                      height: 28,
                      margin: const EdgeInsets.only(right: 8),
                      child: CircleAvatar(
                        backgroundColor:
                            MarketplaceColors.aiTurquoise.withOpacity(0.15),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: SvgPicture.asset(
                            _avatarAssetFor(message.emotion),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Text(
                      'ИИ-прораб',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: MarketplaceColors.aiTurquoise,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ],
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
                  color:
                      isUser ? Colors.white.withOpacity(0.7) : textMuted,
                ),
              ),
            ),
          ],
        ),
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

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? emotion;
  final String? avatarUrl;

  _ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.emotion,
    this.avatarUrl,
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
