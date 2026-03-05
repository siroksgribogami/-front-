import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../core/theme/app_text_style.dart';

// ── Модель контакта ──
class _Contact {
  final String id;
  final String name;
  final String initials;
  final Color avatarColor;
  final String lastMessage;
  final String lastTime;
  final bool isOnline;
  final int unread;
  final bool isBot;

  const _Contact({
    required this.id,
    required this.name,
    required this.initials,
    required this.avatarColor,
    required this.lastMessage,
    required this.lastTime,
    this.isOnline = false,
    this.unread = 0,
    this.isBot = false,
  });
}

/// Экран мессенджера в стиле Telegram — список контактов + чат
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String? _selectedContactId;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // ── Липовые контакты для демо ──
  final List<_Contact> _contacts = const [
    _Contact(
      id: 'bot',
      name: 'ИИ-ассистент',
      initials: '🤖',
      avatarColor: Color(0xFF6C8671),
      lastMessage: 'Чем я могу вам помочь?',
      lastTime: '10:00',
      isOnline: true,
      unread: 1,
      isBot: true,
    ),
    _Contact(
      id: 'anna',
      name: 'Анна Смирнова',
      initials: 'АС',
      avatarColor: Color(0xFFD4956A),
      lastMessage: 'Привет! Сантехник придёт завтра к 14:00',
      lastTime: '09:42',
      isOnline: true,
      unread: 2,
    ),
    _Contact(
      id: 'dmitry',
      name: 'Дмитрий Козлов',
      initials: 'ДК',
      avatarColor: Color(0xFF5A7360),
      lastMessage: 'Ок, посмотрю фильтр вечером',
      lastTime: 'Вчера',
      isOnline: false,
      unread: 0,
    ),
    _Contact(
      id: 'elena',
      name: 'Елена Петрова',
      initials: 'ЕП',
      avatarColor: Color(0xFF8B6F8E),
      lastMessage: 'Куда кладём плитку? Пришли фото',
      lastTime: 'Вчера',
      isOnline: false,
      unread: 0,
    ),
    _Contact(
      id: 'sergey',
      name: 'Сергей Волков',
      initials: 'СВ',
      avatarColor: Color(0xFF6B8DA6),
      lastMessage: 'Электрика готова, принимайте!',
      lastTime: 'Пн',
      isOnline: true,
      unread: 0,
    ),
    _Contact(
      id: 'maria',
      name: 'Мария Иванова',
      initials: 'МИ',
      avatarColor: Color(0xFFA6866B),
      lastMessage: 'Спасибо за рекомендацию дизайнера 🙏',
      lastTime: 'Пн',
      isOnline: false,
      unread: 0,
    ),
  ];

  // ── Истории чатов по contact id ──
  final Map<String, List<Map<String, dynamic>>> _chats = {};

  @override
  void initState() {
    super.initState();
    // Предзаполняем чаты
    _chats['bot'] = [
      {'isMe': false, 'text': 'Привет! Я AI-ассистент АРТхаус 🏠\n\nЯ помогу вам управлять домом, найти специалистов и ответить на вопросы о ремонте.', 'time': '10:00'},
      {'isMe': false, 'text': 'Чем я могу вам помочь сегодня?', 'time': '10:00'},
    ];
    _chats['anna'] = [
      {'isMe': false, 'text': 'Привет! Как дела с ремонтом?', 'time': '09:30'},
      {'isMe': true, 'text': 'Привет, всё идёт по плану! Осталось только сантехника вызвать', 'time': '09:35'},
      {'isMe': false, 'text': 'Отлично! Сантехник придёт завтра к 14:00', 'time': '09:42'},
      {'isMe': false, 'text': 'Привет! Сантехник придёт завтра к 14:00', 'time': '09:42'},
    ];
    _chats['dmitry'] = [
      {'isMe': true, 'text': 'Дмитрий, можешь посмотреть фильтр в кондиционере?', 'time': '18:20'},
      {'isMe': false, 'text': 'Ок, посмотрю фильтр вечером', 'time': '18:45'},
    ];
    _chats['elena'] = [
      {'isMe': false, 'text': 'Добрый день! Я планирую ремонт в ванной', 'time': '14:10'},
      {'isMe': true, 'text': 'Давайте обсудим. Какой стиль хотите?', 'time': '14:15'},
      {'isMe': false, 'text': 'Куда кладём плитку? Пришли фото', 'time': '14:22'},
    ];
    _chats['sergey'] = [
      {'isMe': false, 'text': 'Здравствуйте! Закончил работу по электрике', 'time': '11:00'},
      {'isMe': false, 'text': 'Электрика готова, принимайте!', 'time': '11:05'},
      {'isMe': true, 'text': 'Супер, приеду вечером проверить', 'time': '11:10'},
    ];
    _chats['maria'] = [
      {'isMe': true, 'text': 'Мария, могу посоветовать хорошего дизайнера интерьеров', 'time': '16:00'},
      {'isMe': false, 'text': 'Спасибо за рекомендацию дизайнера 🙏', 'time': '16:15'},
    ];
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty || _selectedContactId == null) return;
    final cid = _selectedContactId!;

    setState(() {
      _chats.putIfAbsent(cid, () => []);
      _chats[cid]!.add({
        'isMe': true,
        'text': text,
        'time': _formatTime(DateTime.now()),
      });
    });

    _messageController.clear();
    _scrollToBottom();

    // Автоответ
    final contact = _contacts.firstWhere((c) => c.id == cid);
    Future.delayed(Duration(seconds: contact.isBot ? 1 : 2), () {
      if (!mounted) return;
      setState(() {
        _chats[cid]!.add({
          'isMe': false,
          'text': contact.isBot ? _getBotResponse(text) : _getFakeReply(contact.name),
          'time': _formatTime(DateTime.now()),
        });
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
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

  String _getBotResponse(String message) {
    final lm = message.toLowerCase();
    if (lm.contains('сантехник')) {
      return 'Нашёл 3 сантехника рядом:\n\n👨‍🔧 Иван Петров — ⭐ 4.9\n👨‍🔧 Сергей Козлов — ⭐ 4.7\n👨‍🔧 Дмитрий Волков — ⭐ 4.8';
    }
    if (lm.contains('фильтр')) {
      return 'Чтобы заменить фильтр:\n1️⃣ Выключите кондиционер\n2️⃣ Откройте панель\n3️⃣ Извлеките фильтр\n4️⃣ Промойте/замените\n5️⃣ Установите обратно';
    }
    if (lm.contains('задач')) {
      return 'У вас 6 активных задач:\n🔴 Заменить фильтр (сегодня)\n🟡 Вызвать сантехника (завтра)\n🟢 Купить лампочки (на неделе)';
    }
    return 'Понял вас! Попробуйте спросить о:\n• Поиске специалистов\n• Задачах по дому\n• Рекомендациях по уходу';
  }

  String _getFakeReply(String name) {
    final replies = [
      'Хорошо, сделаю!',
      'Отлично, спасибо!',
      'Принято 👍',
      'Договорились!',
      'Сейчас посмотрю и напишу',
      'Ок, перезвоню позже',
    ];
    return replies[(name.hashCode % replies.length).abs()];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppTheme.darkBackground
          : AppTheme.backgroundColor,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 36, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Чат',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                fontFamily: AppTextStyle.fontFamily,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.darkTextPrimary
                    : AppTheme.textPrimary,
                height: AppTextStyle.defaultHeight,
                leadingDistribution: AppTextStyle.defaultLeadingDistribution,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Row(
                children: [
                  // ── Список контактов ──
                  SizedBox(
                    width: 280,
                    child: _buildContactList(),
                  ),
                  const SizedBox(width: 16),
                  // ── «Телефон» с чатом ──
                  Expanded(
                    child: _buildPhoneFrame(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Список контактов (левая панель)
  Widget _buildContactList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Поиск
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Поиск...',
                hintStyle: TextStyle(color: AppTheme.textHint, fontSize: 13),
                prefixIcon: Icon(Icons.search, color: AppTheme.textHint, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppTheme.backgroundColor,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _contacts.length,
              padding: const EdgeInsets.only(bottom: 8),
              itemBuilder: (context, index) {
                final c = _contacts[index];
                final isSelected = _selectedContactId == c.id;
                return _buildContactTile(c, isSelected);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTile(_Contact c, bool isSelected) {
    return InkWell(
      onTap: () {
        setState(() => _selectedContactId = c.id);
        _scrollToBottom();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withOpacity(0.08)
              : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isSelected ? AppTheme.primaryColor : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: c.avatarColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      c.initials,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: c.isBot ? 20 : 14,
                      ),
                    ),
                  ),
                ),
                if (c.isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
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
                          c.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: c.unread > 0 ? FontWeight.w700 : FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        c.lastTime,
                        style: TextStyle(
                          fontSize: 11,
                          color: c.unread > 0 ? AppTheme.primaryColor : AppTheme.textHint,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          c.lastMessage,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textHint,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (c.unread > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            c.unread.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Рамка «телефон» с чатом внутри
  Widget _buildPhoneFrame() {
    if (_selectedContactId == null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppTheme.secondaryColor, width: 1),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_bubble_outline, size: 48, color: AppTheme.textHint),
              const SizedBox(height: 14),
              Text(
                'Выберите контакт',
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.textHint,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'чтобы начать переписку',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textHint.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final contact = _contacts.firstWhere((c) => c.id == _selectedContactId);
    final messages = _chats[_selectedContactId] ?? [];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Column(
          children: [
            // «Динамик» телефона
            Container(
              height: 24,
              color: const Color(0xFF1A1A2E),
              child: Center(
                child: Container(
                  width: 80,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            // Заголовок чата (внутри телефона)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              color: AppTheme.primaryColor,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _selectedContactId = null),
                    child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: contact.avatarColor.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        contact.initials,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: contact.isBot ? 18 : 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contact.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        Row(
                          children: [
                            if (contact.isOnline) ...[
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Colors.greenAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                            ],
                            Text(
                              contact.isOnline ? 'онлайн' : 'был(а) недавно',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.65),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Сообщения
            Expanded(
              child: Container(
                color: AppTheme.backgroundColor,
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    return _buildMessage(messages[index]);
                  },
                ),
              ),
            ),
            // Поле ввода
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Написать...',
                        hintStyle: TextStyle(color: AppTheme.textHint, fontSize: 13),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: AppTheme.backgroundColor,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        isDense: true,
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_upward, color: Colors.white, size: 18),
                      padding: EdgeInsets.zero,
                      onPressed: () => _sendMessage(_messageController.text),
                    ),
                  ),
                ],
              ),
            ),
            // «Полоска» Home indicator
            Container(
              height: 20,
              color: Colors.white,
              child: Center(
                child: Container(
                  width: 100,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(Map<String, dynamic> message) {
    final isMe = message['isMe'] as bool;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 320),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? AppTheme.primaryColor : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                border: isMe
                    ? null
                    : Border.all(color: AppTheme.secondaryColor, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    message['text'],
                    style: TextStyle(
                      color: isMe ? Colors.white : AppTheme.textPrimary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    message['time'],
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe
                          ? Colors.white.withOpacity(0.6)
                          : AppTheme.textHint,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
