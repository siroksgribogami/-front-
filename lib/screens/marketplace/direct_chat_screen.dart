import 'package:flutter/material.dart';
import '../../core/theme/brand_runtime.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/brand_colors.dart';
import '../../config/text_theme.dart';
import '../../core/theme/brand_ui.dart';
import '../../models/marketplace_project.dart';
import '../../services/marketplace_local_store.dart';
import '../../widgets/marketplace_image_attachments.dart';
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
  final _picker = ImagePicker();
  List<ChatMessage> _messages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final store = MarketplaceLocalStore.instance;
    await store.ensureLoaded();
    var msgs = store.messagesForThread(widget.thread.id);
    if (msgs.isEmpty) {
      // Демо-диалог без истории — засеваем первые реплики (один раз) и сохраняем.
      msgs = [
        ChatMessage(
          id: 'seed_in_${widget.thread.id}',
          text:
              'Добрый день! Уточните, пожалуйста, по объекту «${widget.thread.projectTitle}».',
          mine: false,
          at: DateTime(2026, 4, 20, 10, 0),
        ),
        if (widget.thread.lastMessagePreview.trim().isNotEmpty)
          ChatMessage(
            id: 'seed_out_${widget.thread.id}',
            text: widget.thread.lastMessagePreview,
            mine: true,
            at: widget.thread.updatedAt,
          ),
      ];
      await store.seedThreadMessages(widget.thread.id, msgs);
    }
    if (!mounted) return;
    setState(() {
      _messages = msgs;
      _loading = false;
    });
    _scrollToBottom();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 50), () {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  Future<void> _send() async {
    final t = _controller.text.trim();
    if (t.isEmpty) return;
    final msg = ChatMessage(
      id: 'm_${DateTime.now().millisecondsSinceEpoch}',
      text: t,
      mine: true,
      at: DateTime.now(),
    );
    setState(() => _messages = [..._messages, msg]);
    _controller.clear();
    await MarketplaceLocalStore.instance.appendMessage(widget.thread.id, msg);
    _scrollToBottom();
  }

  Future<void> _attachPhoto() async {
    final image =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image == null) return;
    final msg = ChatMessage(
      id: 'm_${DateTime.now().millisecondsSinceEpoch}',
      text: '',
      mine: true,
      at: DateTime.now(),
      imagePath: image.path,
    );
    setState(() => _messages = [..._messages, msg]);
    await MarketplaceLocalStore.instance.appendMessage(widget.thread.id, msg);
    _scrollToBottom();
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
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  itemCount: _messages.length + 1,
                  itemBuilder: (_, i) {
                    if (i == 0) return _projectContextChip();
                    return _bubble(_messages[i - 1], timeFmt);
                  },
                ),
        ),
        _buildInputBar(context),
      ],
    );

    if (widget.embedded) {
      return ColoredBox(
        color: BrandRuntime.canvas,
        child: SafeArea(top: false, child: body),
      );
    }

    return Scaffold(
      backgroundColor: BrandRuntime.canvas,
      body: SafeArea(child: body),
    );
  }

  Widget _buildHeader(BuildContext context, double rating, String specialty) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: BrandRuntime.card,
        border: Border(bottom: BorderSide(color: BrandRuntime.border)),
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
                          color: BrandRuntime.ink,
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
              icon: Icon(Icons.phone_outlined, size: 18, color: BrandRuntime.needles),
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
            color: BrandRuntime.surface.withOpacity(0.55),
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
                      color: BrandRuntime.needles,
                    ),
                  ),
                  Text(
                    'Отклик · диалог по объекту',
                    style: BrandUi.inter(
                      fontSize: 11.5,
                      color: BrandRuntime.ink.withOpacity(0.55),
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

  Widget _bubble(ChatMessage line, DateFormat timeFmt) {
    final mine = line.mine;
    final hasImage = line.imagePath != null && line.imagePath!.isNotEmpty;
    final hasText = line.text.trim().isNotEmpty;

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
            color: mine ? BrandRuntime.needles : BrandRuntime.card,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(mine ? 16 : 4),
              bottomRight: Radius.circular(mine ? 4 : 16),
            ),
            border: mine
                ? null
                : Border.all(color: BrandRuntime.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasImage) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 220,
                      maxHeight: 220,
                    ),
                    child: MarketplaceAttachmentImage(path: line.imagePath!),
                  ),
                ),
                if (hasText) const SizedBox(height: 7),
              ],
              if (hasText)
                Text(
                  line.text,
                  style: BrandUi.inter(
                    fontSize: 14.5,
                    height: 1.45,
                    color: mine ? BrandColors.onNeedles : BrandRuntime.ink,
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
                        : BrandRuntime.ink.withOpacity(0.4),
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
      decoration: BoxDecoration(
        color: BrandRuntime.canvas,
        border: Border(top: BorderSide(color: BrandRuntime.border)),
      ),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: _attachPhoto,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: BrandRuntime.borderStrong, width: 1.5),
                ),
                child: Icon(Icons.add, size: 20, color: BrandRuntime.needles),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _controller,
              style: BrandUi.inter(fontSize: 15),
              decoration: InputDecoration(
                filled: true,
                fillColor: BrandRuntime.card,
                hintText: 'Сообщение ${widget.thread.peerName.split(' ').first}…',
                hintStyle: BrandUi.inter(
                  fontSize: 15,
                  color: BrandRuntime.ink.withOpacity(0.45),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide:
                      BorderSide(color: BrandRuntime.borderStrong, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide:
                      BorderSide(color: BrandRuntime.borderStrong, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide:
                      BorderSide(color: BrandRuntime.needles, width: 1.5),
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

