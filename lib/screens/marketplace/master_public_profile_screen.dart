import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_text_style.dart';
import '../../core/theme/marketplace_colors.dart';
import '../../services/marketplace_local_store.dart';
import '../../models/marketplace_project.dart';
import '../../services/master_profile_local_store.dart';
import 'contract_confirm_screen.dart';

class MasterPublicProfileScreen extends StatefulWidget {
  final String masterId;
  final String? projectTitleForContract;
  /// Без AppBar/Scaffold — для встраивания в сплит-панель (поиск мастеров).
  final bool embedded;

  const MasterPublicProfileScreen({
    super.key,
    required this.masterId,
    this.projectTitleForContract,
    this.embedded = false,
  });

  @override
  State<MasterPublicProfileScreen> createState() => _MasterPublicProfileScreenState();
}

class _MasterPublicProfileScreenState extends State<MasterPublicProfileScreen> {
  final _store = MasterProfileLocalStore();
  final _picker = ImagePicker();
  List<String> _portfolioPhotos = [];
  List<String> _certPhotos = [];
  List<MasterReview> _reviews = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadLocalData();
  }

  Future<void> _loadLocalData() async {
    await MarketplaceLocalStore.instance.ensureLoaded();
    final profile = MarketplaceLocalStore.instance.profileById(widget.masterId);
    final photos = await _store.loadPortfolioPhotos(widget.masterId);
    final certs = await _store.loadCertificates(widget.masterId);
    final reviews = await _store.loadReviews(widget.masterId, profile.reviews);
    if (!mounted) return;
    setState(() {
      _portfolioPhotos = photos;
      _certPhotos = certs;
      _reviews = reviews;
      _loaded = true;
    });
  }

  Future<void> _addPortfolioPhoto() async {
    final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image == null) return;
    final next = [..._portfolioPhotos, image.path];
    setState(() => _portfolioPhotos = next);
    await _store.savePortfolioPhotos(widget.masterId, next);
  }

  Future<void> _addCertificatePhoto() async {
    final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image == null) return;
    final next = [..._certPhotos, image.path];
    setState(() => _certPhotos = next);
    await _store.saveCertificates(widget.masterId, next);
  }

  Future<void> _addOrEditReview({int? index}) async {
    final initial = index != null ? _reviews[index] : null;
    final authorCtrl = TextEditingController(text: initial?.author ?? '');
    final textCtrl = TextEditingController(text: initial?.text ?? '');
    double rating = initial?.rating ?? 5.0;

    final result = await showDialog<MasterReview>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            title: Text(index == null ? 'Добавить отзыв' : 'Редактировать отзыв'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: authorCtrl,
                  decoration: const InputDecoration(labelText: 'Имя'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Оценка'),
                    Expanded(
                      child: Slider(
                        value: rating,
                        min: 1,
                        max: 5,
                        divisions: 8,
                        onChanged: (v) => setLocal(() => rating = v),
                      ),
                    ),
                    Text(rating.toStringAsFixed(1)),
                  ],
                ),
                TextField(
                  controller: textCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Отзыв'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Отмена'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(
                    ctx,
                    MasterReview(
                      author: authorCtrl.text.trim().isEmpty ? 'Пользователь' : authorCtrl.text.trim(),
                      rating: rating,
                      text: textCtrl.text.trim(),
                    ),
                  );
                },
                child: const Text('Сохранить'),
              ),
            ],
          ),
        );
      },
    );
    if (result == null) return;

    final next = [..._reviews];
    if (index == null) {
      next.insert(0, result);
    } else {
      next[index] = result;
    }
    setState(() => _reviews = next);
    await _store.saveReviews(widget.masterId, next);
  }

  Future<void> _deleteReview(int index) async {
    final next = [..._reviews]..removeAt(index);
    setState(() => _reviews = next);
    await _store.saveReviews(widget.masterId, next);
  }

  @override
  Widget build(BuildContext context) {
    final p = MarketplaceLocalStore.instance.profileById(widget.masterId);
    if (!_loaded) {
      if (widget.embedded) {
        return ColoredBox(
          color: MarketplaceColors.backgroundFor(context),
          child: const Center(child: CircularProgressIndicator()),
        );
      }
      return Scaffold(
        backgroundColor: MarketplaceColors.backgroundFor(context),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final card = MarketplaceColors.cardFor(context);
    final textPrimary = MarketplaceColors.textPrimaryFor(context);
    final textSecondary = MarketplaceColors.textSecondaryFor(context);
    final textMuted = MarketplaceColors.textMutedFor(context);
    final horizontalPad = MarketplaceColors.horizontalPaddingFor(context);

    final scroll = ListView(
          padding: EdgeInsets.fromLTRB(horizontalPad, 12, horizontalPad, 28),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: MarketplaceColors.bluePrimary.withOpacity(0.3),
                  child: Text(
                    p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: TextStyle(
                          fontFamily: AppTextStyle.fontFamily,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        p.specialty,
                        style: TextStyle(
                          fontSize: 14,
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: MarketplaceColors.gold, size: 22),
                          const SizedBox(width: 4),
                          Text(
                            p.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: MarketplaceColors.gold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${_reviews.length} отзывов)',
                            style: TextStyle(fontSize: 13, color: textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              p.about,
              style: TextStyle(
                fontSize: 14,
                height: 1.35,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _smallStat(card, textPrimary, textMuted, 'Заказов', '${p.completedJobs}'),
                const SizedBox(width: 12),
                _smallStat(card, textPrimary, textMuted, 'Отзывов', '${_reviews.length}'),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              'Портфолио',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: textPrimary),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: _portfolioPhotos.length + 1,
              itemBuilder: (_, i) {
                if (i == 0) {
                  return InkWell(
                    onTap: _addPortfolioPhoto,
                    child: Container(
                      decoration: BoxDecoration(
                        color: card,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.add_a_photo_outlined, color: MarketplaceColors.bluePrimary),
                    ),
                  );
                }
                final path = _portfolioPhotos[i - 1];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _imageByPath(path),
                );
              },
            ),
            const SizedBox(height: 22),
            Text(
              'Сертификаты',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: textPrimary),
            ),
            const SizedBox(height: 8),
            ...p.certificates.map(
              (c) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_outlined, color: MarketplaceColors.bluePrimary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        c,
                        style: TextStyle(
                          color: textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 96,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  InkWell(
                    onTap: _addCertificatePhoto,
                    child: Container(
                      width: 96,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: card,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.add_photo_alternate_outlined, color: MarketplaceColors.bluePrimary),
                    ),
                  ),
                  ..._certPhotos.map(
                    (path) => Container(
                      width: 96,
                      margin: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: _imageByPath(path),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Text(
                  'Отзывы',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: textPrimary),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _addOrEditReview(),
                  icon: const Icon(Icons.add_comment_outlined, size: 18),
                  label: const Text('Добавить'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._reviews.asMap().entries.map((entry) {
              final idx = entry.key;
              final r = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          r.author,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.star_rounded, size: 16, color: MarketplaceColors.gold),
                        const SizedBox(width: 2),
                        Text(
                          r.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: MarketplaceColors.gold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      r.text,
                      style: TextStyle(color: textSecondary, height: 1.35),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => _addOrEditReview(index: idx),
                          child: const Text('Редактировать'),
                        ),
                        TextButton(
                          onPressed: () => _deleteReview(idx),
                          child: const Text('Удалить'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
            if (widget.projectTitleForContract != null) ...[
              const SizedBox(height: 28),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ContractConfirmScreen(
                        masterName: p.name,
                        projectTitle: widget.projectTitleForContract!,
                      ),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: MarketplaceColors.ctaOrange,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Выбрать для проекта'),
              ),
            ],
          ],
        );

    if (widget.embedded) {
      return ColoredBox(
        color: MarketplaceColors.backgroundFor(context),
        child: SafeArea(top: false, child: scroll),
      );
    }

    return Scaffold(
      backgroundColor: MarketplaceColors.backgroundFor(context),
      appBar: AppBar(
        backgroundColor: card,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: textPrimary),
        title: Text(
          'Профиль мастера',
          style: TextStyle(
            fontFamily: AppTextStyle.fontFamily,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
      ),
      body: ColoredBox(
        color: MarketplaceColors.backgroundFor(context),
        child: SafeArea(child: scroll),
      ),
    );
  }

  Widget _imageByPath(String path) {
    if (kIsWeb || path.startsWith('http') || path.startsWith('blob:')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const ColoredBox(
          color: MarketplaceColors.lightSurface,
          child: Center(child: Icon(Icons.broken_image_outlined)),
        ),
      );
    }
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const ColoredBox(
        color: MarketplaceColors.lightSurface,
        child: Center(child: Icon(Icons.broken_image_outlined)),
      ),
    );
  }

  Widget _smallStat(
    Color card,
    Color textPrimary,
    Color textMuted,
    String label,
    String value,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: textPrimary,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
