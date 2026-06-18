import 'dart:io';

import 'package:flutter/material.dart';
import '../../core/theme/brand_runtime.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/unity_webgl_config.dart';
import '../../config/brand_colors.dart';
import '../../core/theme/brand_ui.dart';
import '../../core/theme/marketplace_colors.dart';
import '../../data/premise_rooms_catalog.dart';
import '../../models/map_floor_plan.dart';
import '../../models/marketplace_project.dart';
import '../../providers/auth_provider.dart';
import '../../services/ai_map_service.dart';
import '../../services/ai_vision_service.dart';
import '../../services/api_service.dart';
import '../../services/marketplace_local_store.dart';
import '../../services/project_service.dart';
import '../map/sketch/sketch_plan_wizard.dart';
import '../map/unity/hosted_unity_webgl_screen.dart';

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
  bool _aiMapLoading = false;
  bool _aiMapApproved = false;
  bool _aiVisionLoading = false;
  AiVisionDetectResult? _lastDetection;
  final _aiMapCtrl = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  /// 0 = смотрим До, 1 = смотрим После, 2 = редактируем До, 3 = редактируем После
  int _viewMode = 0;
  int _segIndex = 0;

  @override
  void initState() {
    super.initState();
    _project = widget.project;
  }

  @override
  void dispose() {
    _aiMapCtrl.dispose();
    super.dispose();
  }

  void _setViewMode(int mode) {
    setState(() => _viewMode = mode);
  }

  void _startEditingBefore() => _setViewMode(2);
  void _startEditingAfter() => _setViewMode(3);

  Future<void> _openSketchWizard() async {
    final auth = context.read<AuthProvider>();
    final navigator = Navigator.of(context);
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final houseFloors = prefs.getString('arthouse_house_floors');
    final existingAfter = MapFloorPlanHelper.floorsFromBlock(
      (_project.mapData['after'] as Map?)?.cast<String, dynamic>(),
    );
    final floorCount = MapFloorPlanHelper.suggestedFloorCount(
      premiseType: auth.premiseType,
      houseFloors: houseFloors,
      floorsCount: existingAfter.isNotEmpty
          ? existingAfter.length
          : (auth.user?.floorsCount),
    );

    final result = await navigator.push<SketchPlanResult>(
      MaterialPageRoute(
        builder: (_) => SketchPlanWizard(
          initialAreaSqM: MapFloorPlanHelper.totalAreaSqm(existingAfter).clamp(18, 500) > 0
              ? MapFloorPlanHelper.totalAreaSqm(existingAfter)
              : 60,
          initialFloorCount: existingAfter.isNotEmpty ? existingAfter.length : floorCount,
          existingFloors: existingAfter.isNotEmpty ? existingAfter : null,
        ),
      ),
    );
    if (!mounted || result == null) return;

    final newAfter = MapFloorPlanHelper.blockPayload(floors: result.floors);

    setState(() {
      _project = ProjectSummary(
        id: _project.id,
        title: _project.title,
        status: _project.status,
        updatedAt: DateTime.now(),
        responsesCount: _project.responsesCount,
        mapData: {
          ..._project.mapData,
          'after': newAfter,
          'rooms': result.rooms,
        },
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'План сохранён: ${result.floors.length} этаж., '
          '${result.rooms.length} комн., ${result.totalAreaSqM} м²',
        ),
      ),
    );
  }

  void _back() {
    if (_isEditing) {
      setState(() => _isEditing = false);
    } else if (_viewMode > 0) {
      _setViewMode(0);
    } else {
      Navigator.of(context).pop();
    }
  }

  Map<String, dynamic> _currentUnityMapSeed() {
    final after = (_project.mapData['after'] as Map?)?.cast<String, dynamic>();
    final floors = MapFloorPlanHelper.floorsFromBlock(after);
    if (floors.isNotEmpty) {
      return {
        'apartmentId': _project.id,
        'apartmentName': _project.title,
        'floors': floors.map((f) => f.toJson()).toList(),
        'floors_count': floors.length,
        'rooms': MapFloorPlanHelper.flattenRooms(floors),
        'tasks': (_project.mapData['tasks'] as List?) ?? [],
      };
    }
    final rooms = _project.mapData['rooms'];
    if (rooms is List && rooms.isNotEmpty) {
      return {
        'apartmentId': _project.id,
        'apartmentName': _project.title,
        'rooms': rooms,
        'tasks': (_project.mapData['tasks'] as List?) ?? [],
      };
    }
    return {};
  }

  Future<void> _runAiVision({required ImageSource source}) async {
    if (_aiVisionLoading) return;
    XFile? picked;
    try {
      picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось открыть фото: $e')),
      );
      return;
    }
    if (picked == null) return;

    setState(() => _aiVisionLoading = true);
    try {
      final smartVision = await AiMapService().placeFromPhoto(
        imageFile: File(picked.path),
        currentMap: _currentUnityMapSeed(),
        premiseRooms: await PremiseRoomsCatalog.loadPersistedRooms(),
        apartmentId: _project.id.isNotEmpty ? _project.id : 'arthouse_project',
        apartmentName: _project.title,
        roomId: _project.mapData['ai_focus_room_id']?.toString(),
        roomHint: _project.mapData['ai_focus_room_id']?.toString(),
      );
      final detection = smartVision.detection;
      final placement = smartVision.placement;
      if (!mounted) return;
      setState(() => _lastDetection = detection);

      if (!mounted) return;
      setState(() {
        _project = ProjectSummary(
          id: _project.id,
          title: _project.title,
          status: _project.status,
          updatedAt: DateTime.now(),
          responsesCount: _project.responsesCount,
          mapData: {
            ..._project.mapData,
            'after': placement.unityMap,
            'rooms': placement.unityMap['rooms'],
            'ai_map_source': placement.source,
            'last_vision_source': detection.source,
            'last_detection_items':
                detection.items.map((e) => e.toJson()).toList(),
            if (placement.unityMapPatch != null)
              'last_unity_patch': placement.unityMapPatch,
            if (placement.focusRoomId != null)
              'ai_focus_room_id': placement.focusRoomId,
          },
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(placement.replyText)),
      );

      if (placement.unityMapPatch != null) {
        _openHostedUnityWithCurrentMap(mapPatch: placement.unityMapPatch);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ИИ-зрение: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ИИ-зрение: $e')),
      );
    } finally {
      if (mounted) setState(() => _aiVisionLoading = false);
    }
  }

  Future<void> _pickAiVisionSource() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Сделать фото'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Выбрать из галереи'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source != null) {
      await _runAiVision(source: source);
    }
  }

  Future<void> _applyAiMap({required bool approved}) async {
    final message = _aiMapCtrl.text.trim();
    if (message.isEmpty || _aiMapLoading) return;

    setState(() {
      _aiMapLoading = true;
      _aiMapApproved = approved;
    });
    try {
      final premiseRooms = await PremiseRoomsCatalog.loadPersistedRooms();
      final result = await AiMapService().apply(
        message: message,
        currentMap: _currentUnityMapSeed(),
        premiseRooms: premiseRooms,
        apartmentId: _project.id.isNotEmpty ? _project.id : 'arthouse_project',
        apartmentName: _project.title,
        approved: approved,
      );

      if (!mounted) return;
      if (result.patchApplied) {
        setState(() {
          _project = ProjectSummary(
            id: _project.id,
            title: _project.title,
            status: _project.status,
            updatedAt: DateTime.now(),
            responsesCount: _project.responsesCount,
            mapData: {
              ..._project.mapData,
              'after': result.unityMap,
              'rooms': result.unityMap['rooms'],
              'ai_map_source': result.source,
              if (result.unityMapPatch != null)
                'last_unity_patch': result.unityMapPatch,
              if (result.focusRoomId != null) 'ai_focus_room_id': result.focusRoomId,
            },
          );
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.replyText)),
      );

      if (result.patchApplied && result.unityMapPatch != null) {
        _openHostedUnityWithCurrentMap(mapPatch: result.unityMapPatch);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ИИ-карта: $e')),
      );
    } finally {
      if (mounted) setState(() => _aiMapLoading = false);
    }
  }

  void _openHostedUnityWithCurrentMap({Map<String, dynamic>? mapPatch}) {
    final raw = UnityWebGlConfig.buildUrl.trim();
    final uri = Uri.tryParse(raw);
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Некорректный URL Unity WebGL.')),
      );
      return;
    }
    final seed = _currentUnityMapSeed();
    final focusId = _project.mapData['ai_focus_room_id']?.toString();
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => HostedUnityWebGlScreen(
          uri: uri,
          initialMap: seed.isNotEmpty ? seed : null,
          mapPatch: mapPatch,
          focusRoomId: focusId,
        ),
      ),
    );
  }

  List<MapFloorData> _floorsForMode({required bool isAfter}) {
    final sourceKey = isAfter ? 'after' : 'before';
    final source = (_project.mapData[sourceKey] as Map?)?.cast<String, dynamic>();
    final floors = MapFloorPlanHelper.floorsFromBlock(source);
    if (floors.isNotEmpty) return floors;

    final legacy = (_project.mapData['rooms'] as List?) ?? const [];
    if (legacy.isNotEmpty && isAfter) {
      return [
        MapFloorData(
          index: 0,
          label: MapFloorPlanHelper.labelForIndex(0),
          rooms: legacy
              .whereType<Map>()
              .map((e) => e.cast<String, dynamic>())
              .toList(),
        ),
      ];
    }
    return [];
  }

  Widget _buildRoomsEditor({required bool isAfter}) {
    return Column(
      children: [
        _buildAiDimsBar(),
        Expanded(child: _buildRoomsEditorBody(isAfter: isAfter)),
      ],
    );
  }

  // Кнопка-мост: переносит размеры комнат из диалога с ИИ-прорабом в план.
  Widget _buildAiDimsBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Material(
        color: BrandColors.needlesLight.withOpacity(0.18),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: _applyDialogDimensions,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded,
                    size: 19, color: BrandColors.needlesDark),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Подтянуть размеры из диалога с ИИ-прорабом',
                    style: BrandUi.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: BrandColors.needlesDark,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right,
                    size: 20, color: BrandColors.needlesDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoomsEditorBody({required bool isAfter}) {
    final floors = _floorsForMode(isAfter: isAfter);
    final textPrimary = MarketplaceColors.textPrimaryFor(context);
    final textSecondary = MarketplaceColors.textSecondaryFor(context);
    final card = MarketplaceColors.cardFor(context);
    final accent = isAfter ? Colors.green.shade600 : Colors.orange.shade700;

    if (floors.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.layers_outlined, size: 56, color: textSecondary),
              const SizedBox(height: 12),
              Text(
                'Планировка ещё не заполнена.\n'
                'Нарисуйте от руки (можно несколько этажей) или уточните через ИИ.',
                textAlign: TextAlign.center,
                style: TextStyle(color: textSecondary, height: 1.4),
              ),
            ],
          ),
        ),
      );
    }

    if (floors.length == 1) {
      return _buildRoomsList(
        floors.first.rooms,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        card: card,
        accent: accent,
        floorLabel: floors.first.label,
      );
    }

    return DefaultTabController(
      length: floors.length,
      child: Column(
        children: [
          TabBar(
            isScrollable: floors.length > 3,
            labelColor: accent,
            unselectedLabelColor: textSecondary,
            indicatorColor: accent,
            tabs: [
              for (final f in floors)
                Tab(
                  child: Text(
                    f.label,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                for (final f in floors)
                  _buildRoomsList(
                    f.rooms,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    card: card,
                    accent: accent,
                    floorLabel: f.label,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // #3: размеры из диалога с ИИ (PremiseRoomsCatalog) → mapData['rooms'].
  Future<void> _applyDialogDimensions() async {
    final aiRooms = await PremiseRoomsCatalog.loadPersistedRooms() ??
        const <Map<String, dynamic>>[];
    final withDims = aiRooms.where((r) =>
        r['width_m'] != null || r['length_m'] != null || r['area_sqm'] != null);
    if (withDims.isEmpty) {
      _toast('В диалоге с ИИ-прорабом пока нет размеров комнат');
      return;
    }

    String keyOf(Map r) =>
        (r['name'] ?? r['displayName'] ?? '').toString().toLowerCase().trim();

    final current = (_project.mapData['rooms'] as List?)
            ?.whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList() ??
        <Map<String, dynamic>>[];
    final currentByName = {for (final r in current) keyOf(r): r};

    void applyDims(Map<String, dynamic> target, Map<String, dynamic> ai) {
      if (ai['width_m'] != null) target['width_m'] = ai['width_m'];
      if (ai['length_m'] != null) target['length_m'] = ai['length_m'];
      final a = ai['area_sqm'] ?? ai['area_m2'];
      if (a != null) target['area_sqm'] = a;
    }

    var updated = 0;
    var added = 0;
    for (final ai in aiRooms) {
      final key = keyOf(ai);
      if (key.isEmpty) continue;
      final existing = currentByName[key];
      if (existing != null) {
        applyDims(existing, ai.cast<String, dynamic>());
        updated++;
      } else {
        final name = (ai['name'] ?? ai['displayName'] ?? 'Комната').toString();
        final room = <String, dynamic>{
          'id': ai['id']?.toString() ?? key,
          'name': name,
          'displayName': name,
          'source': 'ai_foreman',
        };
        applyDims(room, ai.cast<String, dynamic>());
        current.add(room);
        currentByName[key] = room;
        added++;
      }
    }

    setState(() {
      _project = _project.copyWith(
        mapData: {..._project.mapData, 'rooms': current},
      );
    });
    await _saveMap();
    _toast('Размеры из ИИ применены — обновлено: $updated, добавлено: $added');
  }

  Widget _buildRoomsList(
    List<Map<String, dynamic>> rooms, {
    required Color textPrimary,
    required Color textSecondary,
    required Color card,
    required Color accent,
    required String floorLabel,
  }) {
    if (rooms.isEmpty) {
      return Center(
        child: Text(
          'На $floorLabel комнат нет',
          style: TextStyle(color: textSecondary),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: rooms.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final room = rooms[index];
        final name = (room['displayName'] ?? room['name'] ?? 'Комната').toString();
        final area = room['area_sqm'] ?? room['area'];
        final w = room['width_m'];
        final l = room['length_m'];
        final dimText = (w != null && l != null) ? '$w × $l м' : null;
        final areaText = area != null ? '$area м²' : null;
        final subtitle = [dimText, areaText].whereType<String>().join(' · ');
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accent.withOpacity(0.25)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.meeting_room_outlined, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: textSecondary),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveMap() async {
    _project = await ProjectService().updateMapData(
      _project.id,
      _project.mapData,
      project: _project,
    );

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
    if (_viewMode > 1) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _back();
        },
        child: Scaffold(
          backgroundColor: BrandRuntime.canvas,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BrandAppBar(
                  title: _viewMode == 2 ? 'Карта: Сейчас' : 'Карта: Должно стать',
                  subtitle: _project.title,
                  onBack: _back,
                ),
                Expanded(child: _buildRoomsEditor(isAfter: _viewMode == 3)),
              ],
            ),
          ),
        ),
      );
    }

    final hasAfter = (_project.mapData['after'] as Map?)?.isNotEmpty ?? false;
    final previewAfter = _segIndex == 1;

    return Scaffold(
      backgroundColor: BrandRuntime.canvas,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ColoredBox(
            color: BrandColors.needlesDeep,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 6, 16, 14),
                child: Row(
                  children: [
                    BrandBackButton(
                      onPressed: () => Navigator.of(context).pop(),
                      onDark: true,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Карта объекта',
                            style: BrandUi.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: BrandColors.onNeedles,
                            ),
                          ),
                          Text(
                            '${_project.title} · проект',
                            style: BrandUi.inter(
                              fontSize: 12.5,
                              color: BrandColors.onNeedles.withOpacity(0.55),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Material(
                      color: BrandColors.clay,
                      borderRadius: BorderRadius.circular(999),
                      child: InkWell(
                        onTap: _openHostedUnityWithCurrentMap,
                        borderRadius: BorderRadius.circular(999),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.view_in_ar_outlined,
                                size: 16,
                                color: BrandColors.onClay,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '3D',
                                style: BrandUi.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: BrandColors.onClay,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          BrandFloorStage(
            height: 300,
            afterMode: previewAfter && hasAfter,
            label: previewAfter ? 'ПЛАН · ПОСЛЕ' : 'UNITY · ЧЕРНОВИК',
            status: hasAfter ? 'ДАННЫЕ ЕСТЬ' : 'СБОР ДАННЫХ',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  BrandBeforeAfterSegment(
                    selectedIndex: _segIndex,
                    onChanged: (i) {
                      setState(() => _segIndex = i);
                      if (i == 0) {
                        _startEditingBefore();
                      } else {
                        _startEditingAfter();
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  const BrandKicker('Как заполнить карту'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      BrandMapActionCard(
                        accent: true,
                        icon: Icons.draw_outlined,
                        title: 'Нарисовать',
                        subtitle: 'Эскиз плана пальцем',
                        onTap: _openSketchWizard,
                      ),
                      const SizedBox(width: 10),
                      BrandMapActionCard(
                        icon: Icons.photo_camera_outlined,
                        title: 'Сфотографировать',
                        subtitle: 'Распознаем по фото',
                        onTap: _pickAiVisionSource,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      BrandMapActionCard(
                        icon: Icons.notes_outlined,
                        title: 'Описать ИИ',
                        subtitle: 'Текстом — соберём план',
                        onTap: () {},
                      ),
                      const SizedBox(width: 10),
                      BrandMapActionCard(
                        icon: Icons.view_in_ar_outlined,
                        title: 'Открыть 3D',
                        subtitle: 'Unity-визуализация',
                        onTap: _openHostedUnityWithCurrentMap,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildComparisonPreview(),
                  const SizedBox(height: 16),
                  _buildAiMapCard(),
                  const SizedBox(height: 16),
                  _buildAiVisionCard(),
                  const SizedBox(height: 16),
                  BrandGhostButton(
                    label: 'Сохранить карту',
                    onPressed: _saveMap,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: BrandPrimaryButton(
                label: 'Начать с эскиза',
                icon: Icons.draw_outlined,
                onPressed: _openSketchWizard,
              ),
            ),
          ),
        ],
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

  Widget _buildAiVisionCard() {
    final card = MarketplaceColors.cardFor(context);
    final textPrimary = MarketplaceColors.textPrimaryFor(context);
    final textSecondary = MarketplaceColors.textSecondaryFor(context);
    final detection = _lastDetection;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: MarketplaceColors.aiTurquoise.withOpacity(0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'ИИ-зрение по фото',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Сфотографируйте комнату — ИИ распознаёт мебель и расставит её на 3D-карте.',
            style: TextStyle(fontSize: 12, color: textSecondary, height: 1.4),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _aiVisionLoading ? null : _pickAiVisionSource,
            style: FilledButton.styleFrom(
              backgroundColor: MarketplaceColors.aiTurquoise,
              minimumSize: const Size.fromHeight(46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: _aiVisionLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.camera_alt_outlined, color: Colors.white),
            label: const Text(
              'Распознать мебель по фото',
              style: TextStyle(color: Colors.white),
            ),
          ),
          if (detection != null && detection.items.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Найдено (${detection.source}):',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final item in detection.items)
                  Chip(
                    label: Text(
                      '${item.displayName ?? item.label}'
                      ' · ${(item.confidence * 100).round()}%',
                      style: const TextStyle(fontSize: 11),
                    ),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: item.isMapped
                        ? MarketplaceColors.aiTurquoise.withOpacity(0.12)
                        : Colors.grey.withOpacity(0.18),
                    side: BorderSide(
                      color: item.isMapped
                          ? MarketplaceColors.aiTurquoise.withOpacity(0.4)
                          : Colors.grey.withOpacity(0.4),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAiMapCard() {
    final card = MarketplaceColors.cardFor(context);
    final textPrimary = MarketplaceColors.textPrimaryFor(context);
    final textSecondary = MarketplaceColors.textSecondaryFor(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: MarketplaceColors.aiTurquoise.withOpacity(0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'ИИ-карта (прораб)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Опишите изменения — ИИ обновит карту.',
            style: TextStyle(fontSize: 12, color: textSecondary, height: 1.4),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _aiMapCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Например: в кухне остров, плитка на полу',
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton(
                onPressed: _aiMapLoading ? null : () => _applyAiMap(approved: true),
                style: FilledButton.styleFrom(
                  backgroundColor: MarketplaceColors.aiTurquoise,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _aiMapLoading && _aiMapApproved
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Согласовать',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                      ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _aiMapLoading ? null : () => _applyAiMap(approved: false),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(42),
                      ),
                      child: const Text(
                        'Уточнить',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _openHostedUnityWithCurrentMap(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(42),
                      ),
                      child: const Text(
                        'Открыть 3D',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
