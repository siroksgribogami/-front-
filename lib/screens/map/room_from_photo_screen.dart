import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/brand_runtime.dart';
import '../../core/theme/brand_ui.dart';
import '../../core/theme/marketplace_colors.dart';
import '../../services/ai_vision_service.dart';
import '../../services/api_service.dart';
import '../../services/project_service.dart';
import '../../widgets/marketplace_image_attachments.dart';

/// «Комната по фото»: снимок → ИИ строит комнату (размеры + мебель в реальных
/// позициях) → сохранение в карту проекта (`map_data.before`).
///
/// Бэкенд: `POST /ai-vision/geometry-from-photo` (YOLO + глубина + маскировка
/// окон + снап коллизий). Анализ ~5–20 с — показываем прогресс.
class RoomFromPhotoScreen extends StatefulWidget {
  const RoomFromPhotoScreen({
    super.key,
    this.projectId,
    this.roomId,
    this.roomName,
    this.initialMapData,
  });

  /// Если задан — появится кнопка «Сохранить в карту проекта».
  final String? projectId;

  /// roomId в карте (по умолчанию генерируется из названия/`room_photo`).
  final String? roomId;

  /// Человеческое название комнаты («Кухня») — для подписи и roomId.
  final String? roomName;

  /// Текущее `map_data` проекта — чтобы дополнить, а не затереть.
  final Map<String, dynamic>? initialMapData;

  @override
  State<RoomFromPhotoScreen> createState() => _RoomFromPhotoScreenState();
}

class _RoomFromPhotoScreenState extends State<RoomFromPhotoScreen> {
  final List<String> _photoPaths = [];
  bool _analyzing = false;
  bool _saving = false;
  AiGeometryResult? _result;
  String? _error;

  String get _roomId {
    final explicit = widget.roomId?.trim();
    if (explicit != null && explicit.isNotEmpty) return explicit;
    final name = widget.roomName?.trim().toLowerCase();
    if (name != null && name.isNotEmpty) {
      return 'room_${name.replaceAll(RegExp(r'\s+'), '_')}';
    }
    return 'room_photo';
  }

  Future<void> _pickPhotos() async {
    final added = await MarketplaceImageAttachments.pickFromSheet(
      context,
      currentPaths: _photoPaths,
    );
    if (added.isEmpty || !mounted) return;
    setState(() {
      _photoPaths.addAll(added);
      _result = null;
      _error = null;
    });
  }

  Future<void> _analyze() async {
    if (_photoPaths.isEmpty || _analyzing) return;
    setState(() {
      _analyzing = true;
      _error = null;
      _result = null;
    });
    try {
      // MVP: позиции строятся по первому снимку; остальные снимки этой комнаты
      // бэкенд использует для merge размеров (этап 2a) в следующей итерации API.
      final bytes = await XFile(_photoPaths.first).readAsBytes();
      final result = await AiVisionService().geometryFromPhoto(
        bytes,
        roomId: _roomId,
      );
      if (!mounted) return;
      setState(() => _result = result);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Не удалось проанализировать фото.');
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  /// Комнату из результата — в `map_data.before.rooms` (upsert по roomId).
  Map<String, dynamic> _mergedMapData(AiGeometryResult result) {
    final mapData = Map<String, dynamic>.from(widget.initialMapData ?? const {});
    final before = Map<String, dynamic>.from(
      (mapData['before'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
    final rooms = ((before['rooms'] as List?) ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e.cast<String, dynamic>()))
        .toList();

    final room = Map<String, dynamic>.from(result.room ?? const {});
    if (widget.roomName != null && widget.roomName!.trim().isNotEmpty) {
      room['displayName'] = widget.roomName!.trim();
    }
    room['source'] = 'geometry_from_photo';

    final idx = rooms.indexWhere((r) => r['roomId'] == room['roomId']);
    if (idx >= 0) {
      rooms[idx] = room;
    } else {
      rooms.add(room);
    }
    before['rooms'] = rooms;
    mapData['before'] = before;
    return mapData;
  }

  Future<void> _saveToProject() async {
    final result = _result;
    final projectId = widget.projectId;
    if (result == null || projectId == null || _saving) return;
    setState(() => _saving = true);
    try {
      final updated = await ProjectService().updateMapData(
        projectId,
        _mergedMapData(result),
      );
      if (!mounted) return;
      Navigator.of(context).pop(updated);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Не удалось сохранить карту.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomLabel = widget.roomName?.trim().isNotEmpty == true
        ? widget.roomName!.trim()
        : 'Комната';
    return Scaffold(
      backgroundColor: BrandRuntime.canvas,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BrandAppBar(
              title: 'Комната по фото',
              subtitle: roomLabel,
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  _hintCard(),
                  const SizedBox(height: 16),
                  _photosSection(),
                  const SizedBox(height: 16),
                  if (_analyzing) _progressCard(),
                  if (_error != null) _errorCard(_error!),
                  if (_result != null) _resultSection(_result!),
                ],
              ),
            ),
            _bottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _hintCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MarketplaceColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Text(
        'Снимите комнату с разных углов (3–5 фото). ИИ определит мебель, '
        'прикинет размеры по снимку и расставит всё на карте — '
        'без рулетки и лидара.',
        style: TextStyle(fontSize: 14, height: 1.35),
      ),
    );
  }

  Widget _photosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Фото (${_photoPaths.length})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _analyzing ? null : _pickPhotos,
              icon: const Icon(Icons.add_a_photo_outlined, size: 20),
              label: const Text('Добавить'),
            ),
          ],
        ),
        if (_photoPaths.isNotEmpty)
          SizedBox(
            height: 84,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _photoPaths.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) => _photoThumb(_photoPaths[i], i),
            ),
          ),
      ],
    );
  }

  Widget _photoThumb(String path, int index) {
    final image = kIsWeb
        ? Image.network(path, width: 84, height: 84, fit: BoxFit.cover)
        : Image.file(File(path), width: 84, height: 84, fit: BoxFit.cover);
    return Stack(
      children: [
        ClipRRect(borderRadius: BorderRadius.circular(10), child: image),
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: _analyzing
                ? null
                : () => setState(() {
                      _photoPaths.removeAt(index);
                      _result = null;
                    }),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(2),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _progressCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MarketplaceColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(),
          SizedBox(height: 10),
          Text(
            'Считаю глубину и мебель по фото — обычно 5–20 секунд…',
            style: TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _errorCard(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MarketplaceColors.accentWarmBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(message, style: const TextStyle(fontSize: 14)),
    );
  }

  Widget _resultSection(AiGeometryResult result) {
    final furniture = result.furniture;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Что получилось',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: MarketplaceColors.card,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.straighten,
                      size: 18, color: MarketplaceColors.bluePrimary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Размер комнаты ${result.sizeLabel}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Мебель: найдено ${result.detected}, размещено ${result.placed}'
                '${result.snapped > 0 ? ' (уточнено позиций: ${result.snapped})' : ''}',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final f in furniture)
                    Chip(
                      backgroundColor: MarketplaceColors.paleSurface,
                      label: Text(
                        '${f['displayName'] ?? f['templateId']} '
                        '· ${(((f['confidence'] as num?) ?? 0) * 100).round()}%',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Размеры — «не меньше чем» (одно фото видит часть комнаты). '
                'Позиции можно поправить в 3D-редакторе.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bottomBar() {
    final canAnalyze = _photoPaths.isNotEmpty && !_analyzing && !_saving;
    final canSave = _result != null && widget.projectId != null && !_saving;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: canAnalyze ? _analyze : null,
              child: Text(_result == null ? 'Проанализировать' : 'Ещё раз'),
            ),
          ),
          if (widget.projectId != null) ...[
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: MarketplaceColors.bluePrimary,
                  foregroundColor: Colors.white,
                ),
                onPressed: canSave ? _saveToProject : null,
                child: Text(_saving ? 'Сохраняю…' : 'В карту проекта'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
