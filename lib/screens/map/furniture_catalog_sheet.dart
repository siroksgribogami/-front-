import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/room_layout.dart';

// ============================================================
//  КАТАЛОГ МЕБЕЛИ (контент для скользящей панели)
// ============================================================

class FurnitureCatalogContent extends StatefulWidget {
  final ValueChanged<FurnitureTemplate> onSelect;

  const FurnitureCatalogContent({super.key, required this.onSelect});

  @override
  State<FurnitureCatalogContent> createState() =>
      _FurnitureCatalogContentState();
}

class _FurnitureCatalogContentState extends State<FurnitureCatalogContent> {
  FurnitureCategory? _activeCategory;

  static const _categoryLabels = {
    FurnitureCategory.seating:   ('🛋️', 'Сиденья'),
    FurnitureCategory.tables:    ('🪑', 'Столы'),
    FurnitureCategory.beds:      ('🛏️', 'Кровати'),
    FurnitureCategory.storage:   ('🚪', 'Хранение'),
    FurnitureCategory.appliances:('📺', 'Техника'),
    FurnitureCategory.decor:     ('🌿', 'Декор'),
    FurnitureCategory.bathroom:  ('🛁', 'Ванная'),
  };

  List<FurnitureTemplate> get _filtered {
    if (_activeCategory == null) return kFurnitureCatalog;
    return kFurnitureCatalog
        .where((t) => t.category == _activeCategory)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Фильтр по категориям ────────────────────────
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _CategoryChip(
                label: 'Все',
                emoji: '✨',
                active: _activeCategory == null,
                onTap: () => setState(() => _activeCategory = null),
              ),
              ...FurnitureCategory.values.map((cat) {
                final (emoji, label) = _categoryLabels[cat]!;
                return _CategoryChip(
                  label: label,
                  emoji: emoji,
                  active: _activeCategory == cat,
                  onTap: () => setState(() => _activeCategory = cat),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // ── Сетка мебели ─────────────────────────────────
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.9,
            ),
            itemCount: _filtered.length,
            itemBuilder: (ctx, i) {
              final item = _filtered[i];
              return _FurnitureCard(
                template: item,
                onSelect: () => widget.onSelect(item),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Чип категории ──────────────────────────────────────────
class _CategoryChip extends StatelessWidget {
  final String label;
  final String emoji;
  final bool active;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.emoji,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? AppTheme.primaryColor
              : AppTheme.primaryColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Карточка мебели ─────────────────────────────────────────
class _FurnitureCard extends StatelessWidget {
  final FurnitureTemplate template;
  final VoidCallback onSelect;

  const _FurnitureCard({required this.template, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelect,
      child: Container(
        decoration: BoxDecoration(
          color: template.baseColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: template.baseColor.withOpacity(0.3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Превью — изометрический мини-блок
            _IsoPreview(color: template.baseColor),
            const SizedBox(height: 4),
            // Эмодзи поверх
            Text(template.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                template.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 2),
            // Размер
            Text(
              '${template.tileWidth}×${template.tileHeight} кл.',
              style: const TextStyle(
                  fontSize: 9, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Мини-изо превью ─────────────────────────────────────────
class _IsoPreview extends StatelessWidget {
  final Color color;
  const _IsoPreview({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 24,
      child: CustomPaint(painter: _IsoBlockPainter(color: color)),
    );
  }
}

class _IsoBlockPainter extends CustomPainter {
  final Color color;
  const _IsoBlockPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final tw = size.width * 0.5;
    final th = size.height * 0.4;
    final bh = size.height * 0.45;

    // Верхняя грань
    final top = [
      Offset(cx, cy - th),
      Offset(cx + tw, cy),
      Offset(cx, cy + th),
      Offset(cx - tw, cy),
    ];
    _fill(canvas, top, Paint()..color = color);

    // Левая грань
    final left = [
      Offset(cx - tw, cy),
      Offset(cx, cy + th),
      Offset(cx, cy + th + bh),
      Offset(cx - tw, cy + bh),
    ];
    _fill(canvas, left, Paint()..color = color.withOpacity(0.65));

    // Правая грань
    final right = [
      Offset(cx + tw, cy),
      Offset(cx, cy + th),
      Offset(cx, cy + th + bh),
      Offset(cx + tw, cy + bh),
    ];
    _fill(canvas, right, Paint()..color = color.withOpacity(0.45));
  }

  void _fill(Canvas c, List<Offset> pts, Paint p) {
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (final pt in pts.skip(1)) {
      path.lineTo(pt.dx, pt.dy);
    }
    path.close();
    c.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_IsoBlockPainter old) => old.color != color;
}
