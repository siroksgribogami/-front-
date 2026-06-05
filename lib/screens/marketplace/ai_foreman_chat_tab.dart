import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../config/brand_colors.dart';
import '../../config/text_theme.dart';
import '../../core/theme/brand_ui.dart';
import '../../core/theme/marketplace_colors.dart';
import 'widgets/foreman_scene_workspace.dart';
import '../../data/premise_rooms_catalog.dart';
import '../../models/ai_responses.dart';
import '../../services/ai_foreman_service.dart';
import '../../services/ai_vision_service.dart';
import '../../services/api_service.dart';
import '../../services/local_ai_vision_stub.dart';
import '../../services/survey_service.dart';
import '../../widgets/marketplace_image_attachments.dart';

class AiForemanChatTab extends StatefulWidget {
  final bool showHeader;
  final bool embedded;
  final int? projectId;
  final Map<String, dynamic>? initialObjectCard;

  const AiForemanChatTab({
    super.key,
    this.showHeader = true,
    this.embedded = false,
    this.projectId,
    this.initialObjectCard,
  });

  @override
  State<AiForemanChatTab> createState() => _AiForemanChatTabState();
}

class _AiForemanChatTabState extends State<AiForemanChatTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => widget.embedded;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AiForemanService _foreman = AiForemanService();

  int? _threadId;
  Map<String, dynamic> _objectCard = {};
  final List<String> _pendingPhotoPaths = [];
  String? _selectedRoomChip;

  static const _roomChips = [
    'Кухня',
    'Ванная',
    'Гостиная',
    'Спальня',
    '+ Своя',
  ];

  final List<_ChatMessage> _messages = [
    _ChatMessage(
      text:
          'Привет! Я ИИ-прораб Приделе.\n\nСоберу из вашего описания ТЗ, смету и список материалов. Можно прислать фото комнаты — разберём вместе.\n\nС чего начнём: комната, бюджет или сроки?',
      isUser: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      emotion: 'обычный',
    ),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialObjectCard != null && widget.initialObjectCard!.isNotEmpty) {
      _objectCard = Map<String, dynamic>.from(widget.initialObjectCard!);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool get _canSend =>
      _messageController.text.trim().isNotEmpty || _pendingPhotoPaths.isNotEmpty;

  Future<void> _pickPhotos() async {
    final added = await MarketplaceImageAttachments.pickFromSheet(
      context,
      currentPaths: _pendingPhotoPaths,
    );
    if (added.isEmpty || !mounted) return;
    setState(() => _pendingPhotoPaths.addAll(added));
  }

  Future<String?> _visionSummary(List<String> paths) async {
    if (paths.isEmpty) return null;
    try {
      final bytes = await XFile(paths.first).readAsBytes();
      final result = await AiVisionService().detectFromBytes(
        bytes,
        filename: 'chat_photo.jpg',
      );
      if (result.items.isEmpty) {
        return result.notes.trim().isNotEmpty ? result.notes.trim() : null;
      }
      final labels = result.items
          .take(6)
          .map((e) => e.displayName ?? e.label)
          .where((s) => s.isNotEmpty)
          .join(', ');
      final room = result.roomHint?.trim();
      final buf = StringBuffer('На фото заметил: $labels.');
      if (room != null && room.isNotEmpty) {
        buf.write(' Похоже на: $room.');
      }
      return buf.toString();
    } on ApiException {
      return null;
    } catch (_) {
      return null;
    }
  }

  String _apiMessageText(String text, List<String> paths, String? visionNote) {
    final parts = <String>[];
    if (text.isNotEmpty) parts.add(text);
    if (paths.isNotEmpty) {
      parts.add('Пользователь прикрепил ${paths.length} фото.');
    }
    if (visionNote != null && visionNote.isNotEmpty) {
      parts.add(visionNote);
    }
    return parts.join('\n\n');
  }

  Future<void> _sendMessage() async {
    if (!_canSend) return;

    final text = _messageController.text.trim();
    final paths = List<String>.from(_pendingPhotoPaths);

    setState(() {
      _messages.add(_ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
        imagePaths: paths,
      ));
      _pendingPhotoPaths.clear();
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

    final visionNote = paths.isNotEmpty ? await _visionSummary(paths) : null;
    final apiText = _apiMessageText(text, paths, visionNote);

    try {
      Map<String, dynamic>? survey;
      try {
        survey = await SurveyService().getLatestSurvey();
      } catch (_) {
        survey = null;
      }

      final premiseRooms = await PremiseRoomsCatalog.loadPersistedRooms();

      final result = await _foreman.chat(
        message: apiText.isEmpty ? 'Фото объекта' : apiText,
        threadId: _threadId,
        projectId: widget.projectId,
        objectCard: _objectCard.isEmpty ? null : _objectCard,
        premiseRooms: premiseRooms,
        survey: survey,
      );

      _threadId = result.threadId ?? _threadId;
      if (result.objectCard.isNotEmpty) {
        _objectCard = result.objectCard;
      }

      var replyText = result.text.isNotEmpty ? result.text : '';
      if (replyText.isEmpty) {
        replyText = paths.isNotEmpty
            ? getAiAssistantReply('фото ${paths.length}')
            : getAiAssistantReply(text);
      }
      if (paths.isNotEmpty && visionNote != null) {
        replyText = '$visionNote\n\n$replyText';
      }

      _replaceThinkingWith(_ChatMessage(
        text: replyText,
        isUser: false,
        timestamp: DateTime.now(),
        emotion: result.emotion,
      ));
    } catch (_) {
      final response = paths.isNotEmpty
          ? offlineForemanReplyWithPhotos(photoCount: paths.length, userText: text)
          : getAiAssistantReply(text.isEmpty ? 'фото' : text);
      var reply = response;
      if (visionNote != null && visionNote.isNotEmpty) {
        reply = '$visionNote\n\n$reply';
      }
      _replaceThinkingWith(_ChatMessage(
        text: reply,
        isUser: false,
        timestamp: DateTime.now(),
        emotion: 'обычный',
      ));
    }

    _scrollToEnd();
  }

  void _replaceThinkingWith(_ChatMessage message) {
    if (!mounted) return;
    setState(() {
      if (_messages.isNotEmpty && _messages.last.text == '...') {
        _messages.removeLast();
      }
      _messages.add(message);
    });
  }

  double? get _sceneAreaM2 {
    final rooms = _objectCard['rooms'];
    if (rooms is List) {
      var total = 0.0;
      for (final r in rooms) {
        if (r is Map) {
          final a = r['area_m2'] ?? r['area'];
          if (a is num) total += a.toDouble();
        }
      }
      if (total > 0) return total;
    }
    final passport = _objectCard['passport'];
    if (passport is Map && passport['total_area_m2'] is num) {
      return (passport['total_area_m2'] as num).toDouble();
    }
    return null;
  }

  int? get _sceneRoomsCount {
    final rooms = _objectCard['rooms'];
    if (rooms is List && rooms.isNotEmpty) return rooms.length;
    return null;
  }

  String? get _sceneEstimateLabel {
    final est = _objectCard['estimate'];
    if (est is Map) {
      final min = est['min_rub'] ?? est['min'];
      final max = est['max_rub'] ?? est['max'];
      if (min != null && max != null) {
        return '$min–$max ₽';
      }
    }
    return null;
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
    super.build(context);
    if (widget.embedded) {
      return _buildClassicChat(context);
    }
    return _buildSplitForeman(context);
  }

  Widget _buildSplitForeman(BuildContext context) {
    return ColoredBox(
      color: BrandColors.canvas,
      child: Column(
        children: [
          if (widget.showHeader) const ForemanSplitAppBar(),
          Expanded(
            flex: 58,
            child: ForemanSceneWorkspace(
              areaM2: _sceneAreaM2,
              roomsCount: _sceneRoomsCount,
              estimateLabel: _sceneEstimateLabel,
            ),
          ),
          Expanded(flex: 42, child: _buildChatZone(context, split: true)),
        ],
      ),
    );
  }

  Widget _buildClassicChat(BuildContext context) {
    return ColoredBox(
      color: MarketplaceColors.backgroundFor(context),
      child: Column(
        children: [
          if (widget.showHeader) _ForemanChatHeader(),
          Expanded(child: _buildChatZone(context, split: false)),
        ],
      ),
    );
  }

  Widget _buildMessageList(BuildContext context, {required double horizontal}) {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) =>
          _buildMessageBubble(_messages[index], context),
    );
  }

  Widget _buildChatZone(BuildContext context, {required bool split}) {
    final textPrimary = MarketplaceColors.textPrimaryFor(context);
    final textMuted = MarketplaceColors.textMutedFor(context);
    final pad = split ? BrandColors.screenPadding : 12.0;

    return ColoredBox(
      color: split ? BrandColors.canvas : MarketplaceColors.cardFor(context),
      child: Column(
        children: [
          if (split) _buildSceneCaptionRow(),
          Expanded(child: _buildMessageList(context, horizontal: pad)),
          _buildRoomChips(pad),
          SizedBox(height: split ? 6 : 4),
          if (_pendingPhotoPaths.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(pad, 0, pad, 8),
              child: MarketplaceAttachmentStrip(
                paths: _pendingPhotoPaths,
                showAddTile: false,
                onAdd: _pickPhotos,
                onRemove: (i) => setState(() => _pendingPhotoPaths.removeAt(i)),
              ),
            ),
          _buildInputBar(
            context,
            textPrimary: textPrimary,
            textMuted: textMuted,
            pad: pad,
            compact: !split,
          ),
        ],
      ),
    );
  }

  Widget _buildSceneCaptionRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          Text(
            'СЦЕНА 01 • ЧЕРНОВИК КОМНАТЫ',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              letterSpacing: 0.6,
              color: BrandColors.tar.withOpacity(0.5),
            ),
          ),
          const Spacer(),
          Text(
            'Развернуть',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: BrandColors.needles,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomChips(double pad) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: pad),
        children: _roomChips.map(_buildRoomChip).toList(),
      ),
    );
  }

  Widget _buildRoomChip(String label) {
    final selected = _selectedRoomChip == label;
    final isCustom = label == '+ Своя';
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          if (isCustom) {
            _messageController.text = 'Своя комната: ';
            setState(() {});
            return;
          }
          setState(() => _selectedRoomChip = label);
          _messageController.text = 'Начнём с $label. ';
          setState(() {});
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? BrandColors.needles : BrandColors.milk,
            borderRadius: BorderRadius.circular(BrandColors.radiusChip),
            border: Border.all(
              color: selected ? BrandColors.needles : BrandColors.chipBorder,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? BrandColors.onNeedles : BrandColors.tar,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar(
    BuildContext context, {
    required Color textPrimary,
    required Color textMuted,
    required double pad,
    required bool compact,
  }) {
    return Container(
      padding: EdgeInsets.fromLTRB(pad, 8, pad, compact ? 12 : 16),
      decoration: BoxDecoration(
        color: BrandColors.milk,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            onPressed: _pickPhotos,
            icon: const Icon(
              Icons.attach_file_outlined,
              color: BrandColors.tar,
            ),
            tooltip: 'Фото',
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: BrandColors.milk,
                borderRadius: BorderRadius.circular(BrandColors.radiusButton),
                border: Border.all(color: BrandColors.chipBorder),
              ),
              child: TextField(
                controller: _messageController,
                minLines: 1,
                maxLines: 5,
                onChanged: (_) => setState(() {}),
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: textPrimary,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: BrandColors.milk,
                  hintText: 'Опишите задачу…',
                  hintStyle: TextStyle(
                    fontFamily: 'Inter',
                    color: textMuted,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) {
                  if (_canSend) _sendMessage();
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _canSend ? _sendMessage : null,
            child: AnimatedOpacity(
              opacity: _canSend ? 1 : 0.45,
              duration: const Duration(milliseconds: 150),
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: BrandColors.clay,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send, color: Colors.white, size: 20),
              ),
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
    final textMuted = MarketplaceColors.textMutedFor(context);
    final hasPhotos = message.imagePaths.isNotEmpty;
    final showText = message.text.isNotEmpty && message.text != '...';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.82,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isUser ? BrandColors.needles : BrandColors.milk,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isUser ? 16 : 4),
          bottomRight: Radius.circular(isUser ? 4 : 16),
        ),
        border: isUser
            ? null
            : Border.all(color: BrandColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasPhotos) ...[
            _MessagePhotoGrid(paths: message.imagePaths, isUser: isUser),
            if (showText) const SizedBox(height: 8),
          ],
          if (showText)
            Text(
              message.text,
              style: BrandUi.inter(
                fontSize: 14.5,
                height: 1.45,
                color: isUser ? BrandColors.onNeedles : BrandColors.tar,
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

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class _MessagePhotoGrid extends StatelessWidget {
  final List<String> paths;
  final bool isUser;

  const _MessagePhotoGrid({required this.paths, required this.isUser});

  @override
  Widget build(BuildContext context) {
    if (paths.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220, maxHeight: 220),
          child: MarketplaceAttachmentImage(path: paths.first),
        ),
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: paths.take(6).map((p) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 88,
            height: 88,
            child: MarketplaceAttachmentImage(path: p),
          ),
        );
      }).toList(),
    );
  }
}

class _ForemanChatHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: BrandColors.milk,
        border: Border(
          bottom: BorderSide(color: BrandColors.borderSubtle),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: [
            if (canPop) ...[
              BrandBackButton(onPressed: () => Navigator.pop(context)),
              const SizedBox(width: 12),
            ],
            const ForemanAvatar(size: 40, radius: 12),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ИИ-прораб',
                    style: pochaevsk(
                      fontSize: 17,
                      color: BrandColors.tar,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: BrandColors.clay,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'составляет смету',
                        style: BrandUi.inter(
                          fontSize: 12,
                          color: BrandColors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            BrandIconButton(
              icon: Icon(
                Icons.view_in_ar_outlined,
                size: 18,
                color: BrandColors.needlesDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ForemanAvatar extends StatelessWidget {
  const ForemanAvatar({
    super.key,
    this.size = 40,
    this.radius,
    this.emotion,
  });

  final double size;
  final double? radius;
  final String? emotion;

  @override
  Widget build(BuildContext context) {
    final r = radius ?? size * 0.3;
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: BrandColors.needles,
          borderRadius: BorderRadius.circular(r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 0,
              spreadRadius: 0,
              offset: Offset.zero,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(r * 0.9),
          child: Padding(
            padding: EdgeInsets.all(size * 0.12),
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
  final List<String> imagePaths;

  _ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.emotion,
    this.imagePaths = const [],
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
