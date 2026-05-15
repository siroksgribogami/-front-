import 'package:flutter/material.dart';
import '../../core/theme/app_text_style.dart';
import '../../core/theme/marketplace_colors.dart';
import '../../models/marketplace_project.dart';
import '../../services/marketplace_local_store.dart';
import '../../services/project_service.dart';
import '../map/editor/apartment_editor_screen.dart';

/// Экран для редактирования карты проекта (До/После).
/// Оптимизирован для мобильного телефона.
class ProjectMapEditorScreen extends StatefulWidget {
  final ProjectSummary project;
  final VoidCallback? onMapSaved;

  const ProjectMapEditorScreen({
    super.key,
    required this.project,
    this.onMapSaved,
  });

  @override
  State<ProjectMapEditorScreen> createState() => _ProjectMapEditorScreenState();
}

class _ProjectMapEditorScreenState extends State<ProjectMapEditorScreen> {
  late ProjectSummary _project;
  bool _isEditing = false;

  /// 0 = смотрим До, 1 = смотрим После, 2 = редактируем До, 3 = редактируем После
  int _viewMode = 0;

  @override
  void initState() {
    super.initState();
    _project = widget.project;
  }

  void _setViewMode(int mode) {
    setState(() => _viewMode = mode);
  }

  void _startEditingBefore() => _setViewMode(2);
  void _startEditingAfter() => _setViewMode(3);

  void _back() {
    if (_isEditing) {
      setState(() => _isEditing = false);
    } else if (_viewMode > 0) {
      _setViewMode(0);
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _saveMap() async {
    // Сохраняем проект с обновлённой картой и синхронизируем с бэком.
    try {
      final updated = await ProjectService().updateMapData(
        _project.id,
        _project.mapData,
      );
      _project = updated;
    } catch (_) {
      // Если сервер недоступен, сохраняем хотя бы локальный кэш.
    }

    await MarketplaceLocalStore.instance.ensureLoaded();
    final currentProjects = List<ProjectSummary>.from(
      MarketplaceLocalStore.instance.customerProjects,
    );
    final index = currentProjects.indexWhere((item) => item.id == _project.id);
    if (index == -1) {
      currentProjects.insert(0, _project);
    } else {
      currentProjects[index] = _project;
    }
    await MarketplaceLocalStore.instance.saveCustomerProjects(currentProjects);

    widget.onMapSaved?.call();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Карта проекта сохранена')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = MarketplaceColors.backgroundFor(context);
    final textPrimary = MarketplaceColors.textPrimaryFor(context);
    final textSecondary = MarketplaceColors.textSecondaryFor(context);

    if (_viewMode > 1) {
      // Редактирование карты - показываем полный редактор
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _back();
        },
        child: Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            title: Text(
              _viewMode == 2 ? 'Карта: СЕЙЧАС' : 'Карта: ДОЛЖНО СТАТЬ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _back,
            ),
            backgroundColor: bg,
            elevation: 0,
          ),
          body: const ApartmentEditorScreen(),
        ),
      );
    }

    // Просмотр режима - выбор что смотреть и редактировать
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Карта проекта'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: bg,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Визуализация квартиры',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                  height: AppTextStyle.defaultHeight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Создайте планировку "сейчас" (текущее состояние) и "должно стать" '
                '(ваша мечта). Мастера смогут оценить объём работ.',
                style: TextStyle(
                  fontSize: 13,
                  color: textSecondary,
                  height: AppTextStyle.defaultHeight,
                ),
              ),
              const SizedBox(height: 24),
              _buildModeCard(
                label: 'СЕЙЧАС',
                subtitle: 'Текущее состояние квартиры',
                icon: Icons.home_outlined,
                onTap: _startEditingBefore,
                hasData: (_project.mapData['before'] as Map?)?.isNotEmpty ?? false,
                accentColor: Colors.orange.shade600,
              ),
              const SizedBox(height: 12),
              _buildModeCard(
                label: 'ДОЛЖНО СТАТЬ',
                subtitle: 'Ваша мечта и пожелания',
                icon: Icons.lightbulb_outlined,
                onTap: _startEditingAfter,
                hasData: (_project.mapData['after'] as Map?)?.isNotEmpty ?? false,
                accentColor: Colors.green.shade600,
              ),
              const SizedBox(height: 24),
              _buildComparisonPreview(),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saveMap,
                style: FilledButton.styleFrom(
                  backgroundColor: MarketplaceColors.bluePrimary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Сохранить карту'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeCard({
    required String label,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    required bool hasData,
    required Color accentColor,
  }) {
    final card = MarketplaceColors.cardFor(context);
    final textSecondary = MarketplaceColors.textSecondaryFor(context);

    return Material(
      color: card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasData
                  ? accentColor.withOpacity(0.3)
                  : MarketplaceColors.textMutedFor(context).withOpacity(0.1),
              width: hasData ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: accentColor,
                          ),
                        ),
                        const Spacer(),
                        if (hasData)
                          Icon(
                            Icons.check_circle,
                            color: accentColor,
                            size: 18,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComparisonPreview() {
    final card = MarketplaceColors.cardFor(context);
    final textPrimary = MarketplaceColors.textPrimaryFor(context);
    final textSecondary = MarketplaceColors.textSecondaryFor(context);

    final hasBefore = (_project.mapData['before'] as Map?)?.isNotEmpty ?? false;
    final hasAfter = (_project.mapData['after'] as Map?)?.isNotEmpty ?? false;

    if (!hasBefore && !hasAfter) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: MarketplaceColors.textMutedFor(context).withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Превью',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (hasBefore)
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.home_outlined,
                            color: Colors.orange.shade600,
                            size: 40,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Сейчас',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              if (hasBefore && hasAfter) const SizedBox(width: 8),
              if (hasAfter)
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.green.shade100.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.lightbulb_outlined,
                            color: Colors.green.shade600,
                            size: 40,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Должно стать',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
