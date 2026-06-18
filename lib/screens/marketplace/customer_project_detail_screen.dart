import 'package:flutter/material.dart';
import '../../core/theme/brand_runtime.dart';
import 'package:intl/intl.dart';

import '../../config/brand_colors.dart';
import '../../core/theme/brand_ui.dart';
import '../../core/theme/marketplace_colors.dart';
import '../../models/marketplace_project.dart';
import '../../services/marketplace_local_store.dart';
import '../../widgets/marketplace_image_attachments.dart';
import 'create_project_screen.dart';
import 'customer_project_responses_screen.dart';
import 'direct_chat_screen.dart';
import 'master_public_profile_screen.dart';
import 'project_map_editor_screen.dart';

class CustomerProjectDetailScreen extends StatefulWidget {
  final ProjectSummary project;
  final VoidCallback? onPublishedNavigateToMasters;
  final ValueChanged<ProjectSummary>? onProjectUpdated;

  const CustomerProjectDetailScreen({
    super.key,
    required this.project,
    this.onPublishedNavigateToMasters,
    this.onProjectUpdated,
  });

  @override
  State<CustomerProjectDetailScreen> createState() =>
      _CustomerProjectDetailScreenState();
}

class _CustomerProjectDetailScreenState extends State<CustomerProjectDetailScreen> {
  late ProjectSummary _project;
  List<MasterBid> _bids = [];

  @override
  void initState() {
    super.initState();
    _project = widget.project;
    _loadBids();
  }

  Future<void> _loadBids() async {
    await MarketplaceLocalStore.instance.ensureLoaded();
    if (!mounted) return;
    setState(() {
      _bids = MarketplaceLocalStore.instance.bidsForProject(_project.id);
    });
  }

  bool get _isDraft => _project.status.trim().toLowerCase().contains('чернов');
  bool get _inWork => _project.status.trim().toLowerCase().contains('работ');
  bool get _hasMap => _project.mapData.isNotEmpty;

  /// Единый источник числа откликов — реальный список, а не захардкоженное поле.
  int get _responses =>
      _bids.isNotEmpty ? _bids.length : _project.responsesCount;

  List<String> get _photoPaths {
    final raw = _project.mapData['photo_paths'];
    if (raw is List) {
      return raw.map((e) => e.toString()).where((p) => p.isNotEmpty).toList();
    }
    return const [];
  }

  String get _appBarSubtitle {
    final parts = <String>[];
    if (_project.address.isNotEmpty) {
      parts.add(_project.address.split(',').first.trim());
    }
    if (_project.workType.isNotEmpty) {
      parts.add(_project.workType.toLowerCase());
    }
    if (_project.budget.isNotEmpty) {
      parts.add(_project.budget);
    }
    return parts.join(' · ');
  }

  String _statusBannerText(DateFormat dateFmt) {
    if (_inWork) {
      return 'Мастер выбран · старт ${dateFmt.format(_project.updatedAt)}';
    }
    if (_isDraft) {
      return 'Заполните ТЗ и опубликуйте на бирже';
    }
    if (_responses > 0) {
      return '$_responses откликов · обновлено ${dateFmt.format(_project.updatedAt)}';
    }
    return 'На бирже · ожидаем отклики';
  }

  String get _briefSubtitle {
    if (!_project.hasBrief) {
      return 'Добавьте тип работ, бюджет и описание';
    }
    final parts = <String>[];
    if (_project.spec.trim().isNotEmpty) {
      final lines = _project.spec.trim().split('\n').where((l) => l.trim().isNotEmpty);
      parts.add('${lines.length} пунктов');
    }
    if (_project.budget.isNotEmpty) {
      parts.add('смета ${_project.budget}');
    }
    if (parts.isEmpty) {
      return [
        if (_project.workType.isNotEmpty) _project.workType,
        if (_project.budget.isNotEmpty) _project.budget,
        if (_project.address.isNotEmpty) _project.address,
      ].join(' · ');
    }
    return parts.join(' · ');
  }

  Future<void> _editBrief() async {
    final draft = await Navigator.of(context).push<Map<String, String>>(
      MaterialPageRoute(
        builder: (_) => CreateProjectScreen(
          skipPathPicker: true,
          initialTitle: _project.title,
          initialWorkType: _project.workType,
          initialBudget: _project.budget,
          initialAddress: _project.address,
          initialSpec: _project.spec,
          initialPhotoPaths: _photoPaths,
        ),
      ),
    );
    if (draft == null || !mounted) return;
    final photosRaw = draft['photos'] ?? '';
    final photoPaths = photosRaw.isEmpty
        ? _photoPaths
        : photosRaw.split('|').where((p) => p.trim().isNotEmpty).toList();
    final mapData = Map<String, dynamic>.from(_project.mapData);
    if (photoPaths.isNotEmpty) {
      mapData['photo_paths'] = photoPaths;
    } else {
      mapData.remove('photo_paths');
    }
    if ((draft['visibility'] ?? '').isNotEmpty) {
      mapData['visibility'] = draft['visibility'];
    }
    final updated = _project.copyWith(
      title: (draft['title'] ?? '').trim().isEmpty ? _project.title : draft['title']!.trim(),
      workType: draft['workType'] ?? '',
      budget: draft['budget'] ?? '',
      address: draft['address'] ?? '',
      spec: draft['spec'] ?? '',
      mapData: mapData,
      updatedAt: DateTime.now(),
    );
    setState(() => _project = updated);
    widget.onProjectUpdated?.call(updated);
  }

  Future<void> _openMap() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProjectMapEditorScreen(
          project: _project,
          onMapSaved: () async {
            await MarketplaceLocalStore.instance.ensureLoaded();
            final list = MarketplaceLocalStore.instance.customerProjects;
            final fresh = list.where((p) => p.id == _project.id).firstOrNull;
            if (fresh != null && mounted) {
              setState(() => _project = fresh);
              widget.onProjectUpdated?.call(fresh);
            }
          },
        ),
      ),
    );
  }

  Future<void> _openResponses() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CustomerProjectResponsesScreen(
          projectId: _project.id,
          projectTitle: _project.title,
        ),
      ),
    );
    if (!mounted) return;
    // Заказчик мог выбрать мастера — подтянем свежий статус проекта и откликов.
    await MarketplaceLocalStore.instance.ensureLoaded();
    final fresh = MarketplaceLocalStore.instance.customerProjects
        .where((p) => p.id == _project.id)
        .firstOrNull;
    if (fresh != null && mounted) {
      setState(() => _project = fresh);
      widget.onProjectUpdated?.call(fresh);
    }
    await _loadBids();
  }

  Future<void> _openProjectChat() async {
    final thread = MarketplaceLocalStore.instance.chatForProject(_project.id);
    if (thread != null) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => DirectChatScreen(thread: thread)),
      );
      return;
    }
    // Чата ещё нет — ведём к откликам, где можно написать мастеру.
    await _openResponses();
  }

  void _openSelectedMaster() {
    final id = _project.selectedMasterId;
    if (id == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MasterPublicProfileScreen(
          masterId: id,
          projectId: _project.id,
          projectTitleForContract: _project.title,
        ),
      ),
    );
  }

  /// Чего не хватает для публикации (масторам нужны тип работ и описание).
  String? _publishBlocker() {
    final missing = <String>[];
    if (_project.workType.trim().isEmpty) missing.add('тип работ');
    if (_project.spec.trim().isEmpty) missing.add('описание');
    if (missing.isEmpty) return null;
    return 'Заполните ${missing.join(' и ')} — без этого мастера не поймут заказ.';
  }

  String get _districtLine {
    final a = _project.address.trim();
    return a.isEmpty ? 'Регион уточняется у заказчика' : a;
  }

  Future<void> _confirmPublish() async {
    // #7 — реальная валидация перед публикацией.
    final blocker = _publishBlocker();
    if (blocker != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(blocker),
          action: SnackBarAction(label: 'Заполнить', onPressed: _editBrief),
        ),
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BrandRuntime.card,
        title: Text(
          'Опубликовать?',
          style: BrandUi.inter(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Заявка появится в ленте мастеров. Убедитесь, что заполнены описание и при необходимости карта объекта.',
          style: BrandUi.inter(
            fontSize: 14,
            color: BrandRuntime.ink.withOpacity(0.65),
            height: 1.35,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: BrandColors.clay),
            child: const Text('Опубликовать'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final updated = _project.copyWith(
      status: 'Опубликован',
      updatedAt: DateTime.now(),
      responsesCount: _project.responsesCount > 0 ? _project.responsesCount : 0,
    );
    setState(() => _project = updated);
    widget.onProjectUpdated?.call(updated);
    await MarketplaceLocalStore.instance
        .syncPublishedProject(updated, districtLine: _districtLine);
    widget.onPublishedNavigateToMasters?.call();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Проект опубликован')),
    );
  }

  /// Нижняя панель действий — видна всегда (в т.ч. для «В работе»).
  Widget _buildBottomBar(double bottom) {
    final hasChat =
        MarketplaceLocalStore.instance.chatForProject(_project.id) != null;

    final Widget secondary;
    final Widget primary;

    if (_inWork) {
      secondary = BrandGhostButton(
        label: 'Мастер',
        onPressed:
            _project.selectedMasterId != null ? _openSelectedMaster : null,
      );
      primary = BrandAccentButton(
        label: 'Открыть чат',
        onPressed: _openProjectChat,
      );
    } else if (_isDraft) {
      secondary = const BrandGhostButton(label: 'Чат', onPressed: null);
      primary = BrandAccentButton(
        label: 'Опубликовать на биржу',
        onPressed: _confirmPublish,
      );
    } else {
      secondary = BrandGhostButton(
        label: 'Чат',
        onPressed: hasChat ? _openProjectChat : null,
      );
      primary = BrandAccentButton(
        label: _responses > 0 ? 'Отклики · $_responses' : 'Проект опубликован',
        onPressed: _responses > 0 ? _openResponses : null,
      );
    }

    return Container(
      padding: EdgeInsets.fromLTRB(16, 14, 16, bottom + 14),
      decoration: BoxDecoration(
        color: BrandRuntime.canvas,
        border: Border(top: BorderSide(color: BrandRuntime.border)),
      ),
      child: Row(
        children: [
          secondary,
          const SizedBox(width: 10),
          Expanded(child: primary),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('d MMMM', 'ru');
    final bottom = MediaQuery.paddingOf(context).bottom;
    final statusKind = BrandStatus.fromProjectStatus(_project.status);

    return Scaffold(
      backgroundColor: BrandRuntime.canvas,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: MarketplaceColors.contentMaxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BrandAppBar(
                  title: _project.title,
                  subtitle: _appBarSubtitle.isEmpty ? null : _appBarSubtitle,
                  onBack: () => Navigator.of(context).pop(),
                  actions: BrandIconButton(
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: BrandRuntime.needles,
                    ),
                    onPressed: _editBrief,
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: BrandRuntime.surface.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            BrandStatus(
                              label: _project.status.isEmpty ? 'Черновик' : _project.status,
                              kind: statusKind,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _statusBannerText(dateFmt),
                                style: BrandUi.inter(
                                  fontSize: 13,
                                  color: BrandRuntime.needles,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _DetailSection(
                        icon: Icon(
                          Icons.description_outlined,
                          size: 18,
                          color: BrandRuntime.needles,
                        ),
                        title: 'Техническое задание',
                        subtitle: _briefSubtitle,
                        onTap: _editBrief,
                      ),
                      _DetailSection(
                        icon: Icon(
                          Icons.view_in_ar_outlined,
                          size: 18,
                          color: BrandRuntime.needles,
                        ),
                        title: 'Карта объекта',
                        subtitle: _hasMap
                            ? 'План готов · 3D-визуализация'
                            : 'Нарисуйте план или загрузите фото',
                        onTap: _openMap,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: _hasMap
                              ? const BrandStripedPlaceholder(
                                  label: 'карта объекта · до / после',
                                  height: 130,
                                  radius: 12,
                                )
                              : const BrandStripedPlaceholder(
                                  label: 'карта объекта',
                                  height: 130,
                                  radius: 12,
                                ),
                        ),
                      ),
                      _DetailSection(
                        icon: Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 18,
                          color: BrandRuntime.needles,
                        ),
                        title: 'Отклики мастеров',
                        subtitle: _responses > 0
                            ? '$_responses предложений'
                            : 'Пока никто не откликнулся',
                        trailing: _responses > 0
                            ? BrandStatus(
                                label: '$_responses откл.',
                                kind: BrandStatusKind.market,
                              )
                            : null,
                        onTap: _openResponses,
                        child: _bids.isNotEmpty
                            ? Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Row(
                                  children: [
                                    for (var i = 0;
                                        i < _bids.length && i < 3;
                                        i++)
                                      Transform.translate(
                                        offset: Offset(i > 0 ? -10.0 * i : 0, 0),
                                        child: BrandAvatar(
                                          name: _bids[i].masterName,
                                          size: 34,
                                          radius: 10,
                                          tone: i.isOdd
                                              ? BrandAvatarTone.clay
                                              : BrandAvatarTone.green,
                                        ),
                                      ),
                                    const SizedBox(width: 12),
                                    if (_project.budget.isNotEmpty)
                                      Text(
                                        'от ${_project.budget}',
                                        style: BrandUi.inter(
                                          fontSize: 13,
                                          color: BrandRuntime.ink.withOpacity(0.55),
                                        ),
                                      ),
                                  ],
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          for (var i = 0; i < 3; i++)
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(left: i > 0 ? 8 : 0),
                                child: _photoPaths.length > i
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: SizedBox(
                                          height: 70,
                                          child: MarketplaceAttachmentImage(
                                            path: _photoPaths[i],
                                          ),
                                        ),
                                      )
                                    : BrandStripedPlaceholder(
                                        label: i < 2 ? 'фото до' : 'фото',
                                        height: 70,
                                        radius: 12,
                                      ),
                              ),
                            ),
                        ],
                      ),
                      if (_project.spec.trim().isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const BrandKicker('Описание'),
                        const SizedBox(height: 10),
                        BrandCard(
                          padding: const EdgeInsets.all(14),
                          child: Text(
                            _project.spec.trim(),
                            style: BrandUi.inter(fontSize: 14, height: 1.4),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                _buildBottomBar(bottom),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
    this.child,
  });

  final Widget icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: BrandRuntime.card,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: BrandRuntime.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: BrandRuntime.surface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(child: icon),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: BrandUi.inter(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            subtitle,
                            style: BrandUi.inter(
                              fontSize: 12,
                              color: BrandRuntime.ink.withOpacity(0.55),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (trailing != null)
                      trailing!
                    else
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: BrandRuntime.ink.withOpacity(0.35),
                      ),
                  ],
                ),
                if (child != null) child!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
