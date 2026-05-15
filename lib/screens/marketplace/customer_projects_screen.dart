import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_text_style.dart';
import '../../core/theme/marketplace_colors.dart';
import '../../models/marketplace_project.dart';
import '../../services/marketplace_local_store.dart';
import 'create_project_screen.dart';
import 'customer_project_responses_screen.dart';
import 'project_map_editor_screen.dart';

/// Экран «Мои проекты» (заказчик): список, создание, редактирование, публикация.
class CustomerProjectsScreen extends StatefulWidget {
  /// После публикации — переключить нижнюю вкладку на «Поиск мастеров».
  final VoidCallback? onPublishedNavigateToMasters;

  const CustomerProjectsScreen({super.key, this.onPublishedNavigateToMasters});

  @override
  State<CustomerProjectsScreen> createState() => _CustomerProjectsScreenState();
}

class _CustomerProjectsScreenState extends State<CustomerProjectsScreen> {
  List<ProjectSummary> _projects = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    await MarketplaceLocalStore.instance.ensureLoaded();
    if (!mounted) return;
    setState(() {
      _projects = List.from(MarketplaceLocalStore.instance.customerProjects);
      _loading = false;
    });
  }

  Future<void> _persist() async {
    await MarketplaceLocalStore.instance.saveCustomerProjects(_projects);
  }

  Future<void> _createProject() async {
    final draft = await Navigator.of(context).push<Map<String, String>>(
      MaterialPageRoute(builder: (_) => const CreateProjectScreen()),
    );
    if (draft == null || !mounted) return;
    final title = (draft['title'] ?? '').trim();
    setState(() {
      _projects.insert(
        0,
        ProjectSummary(
          id: 'p_${DateTime.now().millisecondsSinceEpoch}',
          title: title.isEmpty ? 'Новый проект' : title,
          status: 'Черновик',
          updatedAt: DateTime.now(),
          responsesCount: 0,
          mapData: {},
        ),
      );
    });
    await _persist();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Проект создан в черновиках')),
    );
  }

  Future<void> _editProject(ProjectSummary project) async {
    final draft = await Navigator.of(context).push<Map<String, String>>(
      MaterialPageRoute(
        builder: (_) => CreateProjectScreen(initialTitle: project.title),
      ),
    );
    if (draft == null || !mounted) return;
    final title = (draft['title'] ?? '').trim();
    setState(() {
      final idx = _projects.indexWhere((p) => p.id == project.id);
      if (idx == -1) return;
      _projects[idx] = ProjectSummary(
        id: project.id,
        title: title.isEmpty ? project.title : title,
        status: project.status,
        updatedAt: DateTime.now(),
        responsesCount: project.responsesCount,
        mapData: project.mapData,
      );
    });
    await _persist();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Проект обновлён')),
    );
  }

  Future<void> _publishProject(ProjectSummary project) async {
    final idx = _projects.indexWhere((p) => p.id == project.id);
    if (idx == -1) return;
    final updated = ProjectSummary(
      id: project.id,
      title: project.title,
      status: 'Опубликован',
      updatedAt: DateTime.now(),
      responsesCount: project.responsesCount > 0 ? project.responsesCount : 1,
      mapData: project.mapData,
    );
    setState(() => _projects[idx] = updated);
    await _persist();
    await MarketplaceLocalStore.instance.syncPublishedProject(updated);
    widget.onPublishedNavigateToMasters?.call();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Проект опубликован и виден мастерам')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return ColoredBox(
        color: MarketplaceColors.backgroundFor(context),
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    final dateFmt = DateFormat('d MMM yyyy', 'ru');
    final bg = MarketplaceColors.backgroundFor(context);
    final textPrimary = MarketplaceColors.textPrimaryFor(context);
    final textSecondary = MarketplaceColors.textSecondaryFor(context);
    final horizontalPad = MarketplaceColors.horizontalPaddingFor(context);

    return ColoredBox(
      color: bg,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(horizontalPad, 12, horizontalPad, 20),
          children: [
                Text(
                  'Мои проекты',
                  style: TextStyle(
                    fontFamily: AppTextStyle.fontFamily,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                    height: AppTextStyle.defaultHeight,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Черновики, опубликованные заявки и работа в процессе.',
                  style: TextStyle(
                    fontSize: 13,
                    color: textSecondary,
                    height: AppTextStyle.defaultHeight,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _createProject,
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('Создать новый проект'),
                  style: FilledButton.styleFrom(
                    backgroundColor: MarketplaceColors.bluePrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 18),
                ..._projects.map(
                  (p) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ProjectCard(
                      project: p,
                      dateFmt: dateFmt,
                      onPublishedNavigateToMasters: () => _publishProject(p),
                      onEdit: () => _editProject(p),
                      onOpenResponses: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => CustomerProjectResponsesScreen(
                              projectId: p.id,
                              projectTitle: p.title,
                            ),
                          ),
                        );
                      },
                      onOpenMap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ProjectMapEditorScreen(
                              project: p,
                              onMapSaved: _reload,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final ProjectSummary project;
  final DateFormat dateFmt;
  final VoidCallback? onPublishedNavigateToMasters;
  final VoidCallback? onEdit;
  final VoidCallback? onOpenResponses;
  final VoidCallback? onOpenMap;

  const _ProjectCard({
    required this.project,
    required this.dateFmt,
    this.onPublishedNavigateToMasters,
    this.onEdit,
    this.onOpenResponses,
    this.onOpenMap,
  });

  @override
  Widget build(BuildContext context) {
    final card = MarketplaceColors.cardFor(context);
    final textPrimary = MarketplaceColors.textPrimaryFor(context);
    final textSecondary = MarketplaceColors.textSecondaryFor(context);

    return Material(
      color: card,
      borderRadius: BorderRadius.circular(12),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onOpenResponses,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: MarketplaceColors.textMutedFor(context).withOpacity(0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(
                  Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.06,
                ),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      project.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  _StatusChip(label: project.status),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                dateFmt.format(project.updatedAt),
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.how_to_reg_outlined,
                    size: 18,
                    color: project.responsesCount > 0
                        ? MarketplaceColors.aiTurquoise
                        : textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    project.responsesCount > 0
                        ? 'Отклики мастеров (${project.responsesCount}) · открыть'
                        : 'Откликов пока нет — открыть проект',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: project.responsesCount > 0
                          ? MarketplaceColors.aiTurquoise
                          : textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right, color: textSecondary, size: 20),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onOpenMap,
                icon: const Icon(Icons.map_outlined, size: 18),
                label: const Text('Карта проекта'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: MarketplaceColors.bluePrimary,
                  side: BorderSide(
                    color: MarketplaceColors.bluePrimary.withOpacity(0.4),
                  ),
                  minimumSize: const Size.fromHeight(40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton(
                    onPressed: onEdit,
                    style: TextButton.styleFrom(
                      foregroundColor: MarketplaceColors.bluePrimary,
                    ),
                    child: const Text('Изменить'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: project.status == 'В работе'
                        ? null
                        : () {
                            _confirmPublish(context);
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: MarketplaceColors.ctaOrange,
                      foregroundColor: textPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(project.status == 'В работе'
                        ? 'В работе'
                        : 'Опубликовать'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmPublish(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MarketplaceColors.cardFor(ctx),
        title: Text(
          'Опубликовать проект?',
          style: TextStyle(
            color: MarketplaceColors.textPrimaryFor(ctx),
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Заявка появится в ленте мастеров. Дальше вы сможете открыть поиск исполнителей.',
          style: TextStyle(color: MarketplaceColors.textSecondaryFor(ctx), height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Опубликовать'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    onPublishedNavigateToMasters?.call();
  }
}

class _StatusChip extends StatelessWidget {
  final String label;

  const _StatusChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final normalized = label.trim().toLowerCase();
    final bool isDraft = normalized.contains('чернов');
    final bool isInWork = normalized.contains('работ');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    late final Color fg;
    late final Color bg;
    late final Color border;
    if (isDark) {
      fg = isInWork
          ? const Color(0xFFFFCCAA)
          : isDraft
              ? MarketplaceColors.textMutedFor(context)
              : const Color(0xFFFFF0AA);
      bg = isInWork
          ? const Color(0xFF4A3020)
          : isDraft
              ? const Color(0xFF2A3230)
              : const Color(0xFF454018);
      border = isInWork
          ? const Color(0xFF7A5540)
          : isDraft
              ? const Color(0xFF404848)
              : const Color(0xFF6A6538);
    } else {
      fg = isInWork
          ? const Color(0xFF7A4A18)
          : isDraft
              ? MarketplaceColors.textMuted
              : const Color(0xFF5C4A00);
      bg = isInWork
          ? const Color(0xFFFFE2C7)
          : isDraft
              ? const Color(0xFFE8ECE8)
              : const Color(0xFFFFF4C2);
      border = isInWork
          ? const Color(0xFFE4BC96)
          : isDraft
              ? const Color(0xFFD4DBD4)
              : const Color(0xFFE8D681);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}
