import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/brand_colors.dart';
import '../../config/text_theme.dart';
import '../../core/theme/brand_ui.dart';
import '../../models/marketplace_project.dart';
import '../../providers/auth_provider.dart';
import '../../services/marketplace_local_store.dart';
import '../../services/project_service.dart';
import 'create_project_screen.dart';
import 'customer_project_detail_screen.dart';

class CustomerProjectsScreen extends StatefulWidget {
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
    try {
      final fromApi = await ProjectService().getMyProjects();
      if (fromApi.isNotEmpty) {
        await MarketplaceLocalStore.instance.saveCustomerProjects(fromApi);
      }
    } catch (_) {}
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

  ProjectSummary _fromDraft(Map<String, String> draft, {ProjectSummary? base}) {
    final title = (draft['title'] ?? '').trim();
    final photosRaw = draft['photos'] ?? '';
    final photoPaths = photosRaw.isEmpty
        ? <String>[]
        : photosRaw.split('|').where((p) => p.trim().isNotEmpty).toList();
    final mapData = Map<String, dynamic>.from(base?.mapData ?? const {});
    if (photoPaths.isNotEmpty) {
      mapData['photo_paths'] = photoPaths;
    }
    if ((draft['visibility'] ?? '').isNotEmpty) {
      mapData['visibility'] = draft['visibility'];
    }
    return ProjectSummary(
      id: base?.id ?? 'p_${DateTime.now().millisecondsSinceEpoch}',
      title: title.isEmpty ? (base?.title ?? 'Новый проект') : title,
      status: base?.status ?? 'Черновик',
      updatedAt: DateTime.now(),
      responsesCount: base?.responsesCount ?? 0,
      mapData: mapData,
      workType: draft['workType'] ?? '',
      budget: draft['budget'] ?? '',
      address: draft['address'] ?? '',
      spec: draft['spec'] ?? '',
    );
  }

  Future<void> _createProject() async {
    final draft = await Navigator.of(context).push<Map<String, String>>(
      MaterialPageRoute(builder: (_) => const CreateProjectScreen()),
    );
    if (draft == null || !mounted) return;
    final project = _fromDraft(draft);
    setState(() => _projects.insert(0, project));
    await _persist();
    if (!mounted) return;
    await _openProject(project);
  }

  void _replaceProject(ProjectSummary updated) {
    final idx = _projects.indexWhere((p) => p.id == updated.id);
    if (idx == -1) return;
    setState(() => _projects[idx] = updated);
    _persist();
  }

  Future<void> _openProject(ProjectSummary project) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CustomerProjectDetailScreen(
          project: project,
          onPublishedNavigateToMasters: widget.onPublishedNavigateToMasters,
          onProjectUpdated: _replaceProject,
        ),
      ),
    );
    if (!mounted) return;
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return ColoredBox(
        color: BrandColors.canvas,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final dateFmt = DateFormat('d MMM yyyy', 'ru');
    final auth = context.watch<AuthProvider>();
    final userName = auth.user?.visibleName ?? 'Пользователь';
    final totalResponses =
        _projects.fold<int>(0, (sum, p) => sum + p.responsesCount);
    final onMarket = _projects.where((p) {
      final s = p.status.toLowerCase();
      return s.contains('бирж') || s.contains('market');
    }).length;

    return ColoredBox(
      color: BrandColors.canvas,
      child: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              BrandAppBar(
                kicker: 'Мои проекты',
                title: 'Проекты',
                big: true,
                actions: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BrandIconButton(
                      icon: Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: BrandColors.tar.withOpacity(0.55),
                      ),
                    ),
                    const SizedBox(width: 8),
                    BrandAvatar(name: userName, size: 38, radius: 11),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: BrandStatTile(
                      value: '${_projects.length}',
                      label: 'проекта',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: BrandStatTile(
                      value: '$totalResponses',
                      label: 'откликов',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: BrandStatTile(
                      value: '$onMarket',
                      label: 'на бирже',
                      accent: onMarket > 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              if (_projects.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.folder_open_outlined,
                        size: 48,
                        color: BrandColors.tar.withOpacity(0.35),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Пока нет проектов',
                        style: BrandUi.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Создайте заявку — с ИИ-прорабом или вручную',
                        textAlign: TextAlign.center,
                        style: BrandUi.inter(
                          fontSize: 13,
                          color: BrandColors.tar.withOpacity(0.55),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ..._projects.map(
                  (p) => Padding(
                    padding: const EdgeInsets.only(bottom: 13),
                    child: _ProjectCard(
                      project: p,
                      dateFmt: dateFmt,
                      onTap: () => _openProject(p),
                    ),
                  ),
                ),
            ],
          ),
          Positioned(
            right: 18,
            bottom: 16 + MediaQuery.paddingOf(context).bottom,
            child: BrandAccentFabExtended(onPressed: _createProject),
          ),
        ],
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.project,
    required this.dateFmt,
    required this.onTap,
  });

  final ProjectSummary project;
  final DateFormat dateFmt;
  final VoidCallback onTap;

  String get _statusLabel {
    final s = project.status.trim();
    if (s.isEmpty) return 'Черновик';
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final kind = BrandStatus.fromProjectStatus(project.status);
    final footer = project.responsesCount > 0
        ? '${project.responsesCount} откликов мастеров'
        : 'Ещё не опубликован';

    return Material(
      color: BrandColors.milk,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: BrandColors.borderSubtle),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(13),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 74,
                      height: 74,
                      child: BrandStripedPlaceholder(
                        label: 'план',
                        height: 74,
                        radius: 12,
                      ),
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
                                  project.title,
                                  style: pochaevsk(
                                    fontSize: 19,
                                    color: BrandColors.tar,
                                    height: 1,
                                  ),
                                ),
                              ),
                              BrandStatus(label: _statusLabel, kind: kind),
                            ],
                          ),
                          if (project.address.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.place_outlined,
                                  size: 14,
                                  color: BrandColors.tar.withOpacity(0.35),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    project.address,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: BrandUi.inter(
                                      fontSize: 12.5,
                                      color: BrandColors.tar.withOpacity(0.55),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 9),
                          Text(
                            project.briefLine.isNotEmpty
                                ? project.briefLine
                                : dateFmt.format(project.updatedAt),
                            style: BrandUi.inter(
                              fontSize: 12.5,
                              color: BrandColors.tar.withOpacity(0.55),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                decoration: BoxDecoration(
                  color: BrandColors.canvas,
                  border: Border(
                    top: BorderSide(color: BrandColors.borderSubtle),
                  ),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(18),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        footer,
                        style: BrandUi.inter(
                          fontSize: 12.5,
                          color: BrandColors.tar.withOpacity(0.55),
                        ),
                      ),
                    ),
                    Text(
                      'Открыть →',
                      style: BrandUi.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: BrandColors.clay,
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
