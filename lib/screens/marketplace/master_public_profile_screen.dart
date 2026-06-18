import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/theme/brand_runtime.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/brand_colors.dart';
import '../../config/text_theme.dart';
import '../../core/theme/brand_ui.dart';
import '../../models/marketplace_project.dart';
import '../../services/marketplace_local_store.dart';
import '../../services/master_profile_local_store.dart';
import '../profile/master_portfolio_screen.dart';
import 'contract_confirm_screen.dart';
import 'direct_chat_screen.dart';

class MasterPublicProfileScreen extends StatefulWidget {
  final String masterId;
  final String? projectTitleForContract;

  /// Проект, по которому идёт выбор / переписка (если открыт из проекта).
  final String? projectId;

  /// Без AppBar/Scaffold — для встраивания в сплит-панель (поиск мастеров).
  final bool embedded;

  /// Можно ли редактировать профиль (фото, сертификаты, отзывы).
  /// По умолчанию ВЫКЛ: заказчик видит чужой профиль только для чтения и
  /// не может прикреплять фото / менять данные мастера.
  final bool editable;

  const MasterPublicProfileScreen({
    super.key,
    required this.masterId,
    this.projectTitleForContract,
    this.projectId,
    this.embedded = false,
    this.editable = false,
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

  Future<void> _openChat(BuildContext context, MasterProfile p) async {
    final navigator = Navigator.of(context);
    final title = widget.projectTitleForContract?.trim().isNotEmpty == true
        ? widget.projectTitleForContract!
        : 'Обсуждение работ';
    final thread = await MarketplaceLocalStore.instance.ensureChatThread(
      masterId: widget.masterId,
      peerName: p.name,
      projectTitle: title,
      projectId: widget.projectId,
    );
    if (!mounted) return;
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => DirectChatScreen(thread: thread),
      ),
    );
  }

  void _openPortfolio(MasterProfile p) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MasterPortfolioScreen(
          masterName: p.name,
          worksCount: p.portfolioPlaceholders.length + _portfolioPhotos.length,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = MarketplaceLocalStore.instance.profileById(widget.masterId);
    if (!_loaded) {
      if (widget.embedded) {
        return ColoredBox(
          color: BrandRuntime.canvas,
          child: const Center(child: CircularProgressIndicator()),
        );
      }
      return Scaffold(
        backgroundColor: BrandRuntime.canvas,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final portfolioCount = p.portfolioPlaceholders.length + _portfolioPhotos.length;
    final topReview = _reviews.isNotEmpty ? _reviews.first : null;

    final body = Column(
      children: [
        _HeroHeader(
          profile: p,
          reviewsCount: _reviews.isNotEmpty ? _reviews.length : p.reviewsCount,
          embedded: widget.embedded,
          onBack: widget.embedded ? null : () => Navigator.of(context).pop(),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(BrandUi.pad, 16, BrandUi.pad, 16),
            children: [
              Row(
                children: [
                  BrandKicker('Портфолио · $portfolioCount работ'),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _openPortfolio(p),
                    child: Text(
                      'Все →',
                      style: BrandUi.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: BrandColors.clay,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 11),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemCount: portfolioCount + (widget.editable ? 1 : 0),
                itemBuilder: (_, i) {
                  if (widget.editable && i == 0) {
                    return InkWell(
                      onTap: _addPortfolioPhoto,
                      borderRadius: BorderRadius.circular(12),
                      child: BrandStripedPlaceholder(
                        label: 'добавить',
                        height: 88,
                        radius: 12,
                      ),
                    );
                  }
                  final photoIndex = i - (widget.editable ? 1 : 0);
                  if (photoIndex < _portfolioPhotos.length) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _imageByPath(_portfolioPhotos[photoIndex]),
                    );
                  }
                  final placeholderIndex = photoIndex - _portfolioPhotos.length;
                  final label = placeholderIndex < p.portfolioPlaceholders.length
                      ? p.portfolioPlaceholders[placeholderIndex]
                      : 'работа';
                  return BrandStripedPlaceholder(
                    label: label,
                    height: 88,
                    radius: 12,
                  );
                },
              ),
              if (p.about.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  p.about,
                  style: BrandUi.inter(
                    fontSize: 13.5,
                    color: BrandRuntime.ink.withOpacity(0.65),
                    height: 1.5,
                  ),
                ),
              ],
              if (p.certificates.isNotEmpty) ...[
                const SizedBox(height: 18),
                const BrandKicker('Сертификаты'),
                const SizedBox(height: 8),
                ...p.certificates.map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: BrandCard(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.verified_outlined,
                            size: 20,
                            color: BrandRuntime.needles,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              c,
                              style: BrandUi.inter(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              if (widget.editable || _certPhotos.isNotEmpty) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 96,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      if (widget.editable)
                        InkWell(
                          onTap: _addCertificatePhoto,
                          child: SizedBox(
                            width: 96,
                            child: BrandStripedPlaceholder(
                              label: 'серт',
                              height: 96,
                              radius: 12,
                            ),
                          ),
                        ),
                      ..._certPhotos.map(
                        (path) => Container(
                          width: 96,
                          margin: const EdgeInsets.only(left: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: _imageByPath(path),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  const BrandKicker('Отзывы'),
                  const Spacer(),
                  if (widget.editable)
                    TextButton(
                      onPressed: () => _addOrEditReview(),
                      child: const Text('Добавить'),
                    ),
                ],
              ),
              if (topReview != null)
                _ReviewCard(
                  review: topReview,
                  onEdit: widget.editable && _reviews.length == 1
                      ? () => _addOrEditReview(index: 0)
                      : null,
                ),
              ..._reviews.asMap().entries.skip(topReview != null ? 1 : 0).map((entry) {
                final idx = entry.key;
                final r = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: _ReviewCard(
                    review: r,
                    onEdit: widget.editable ? () => _addOrEditReview(index: idx) : null,
                    onDelete: widget.editable ? () => _deleteReview(idx) : null,
                  ),
                );
              }),
            ],
          ),
        ),
        if (widget.projectTitleForContract != null || !widget.embedded)
          DecoratedBox(
            decoration: BoxDecoration(
              color: BrandRuntime.canvas,
              border: Border(top: BorderSide(color: BrandRuntime.border)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 36),
              child: Row(
                children: [
                  BrandGhostButton(
                    label: 'Написать',
                    onPressed: () => _openChat(context, p),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: widget.projectTitleForContract != null
                          ? () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => ContractConfirmScreen(
                                    masterName: p.name,
                                    projectId: widget.projectId,
                                    masterId: widget.masterId,
                                    projectTitle: widget.projectTitleForContract!,
                                  ),
                                ),
                              );
                            }
                          : () => _openChat(context, p),
                      style: FilledButton.styleFrom(
                        backgroundColor: BrandColors.clay,
                        foregroundColor: BrandColors.onClay,
                        minimumSize: const Size(double.infinity, 48),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BrandUi.buttonRadius,
                        ),
                        textStyle: BrandUi.inter(fontWeight: FontWeight.w600),
                      ),
                      child: Text(
                        widget.projectTitleForContract != null
                            ? 'Выбрать для проекта'
                            : 'Написать мастеру',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
      body: SafeArea(bottom: false, child: body),
    );
  }

  Widget _imageByPath(String path) {
    if (kIsWeb || path.startsWith('http') || path.startsWith('blob:')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => ColoredBox(
          color: BrandRuntime.surface,
          child: const Center(child: Icon(Icons.broken_image_outlined)),
        ),
      );
    }
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => ColoredBox(
        color: BrandRuntime.surface,
        child: const Center(child: Icon(Icons.broken_image_outlined)),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.profile,
    required this.reviewsCount,
    required this.embedded,
    required this.onBack,
  });

  final MasterProfile profile;
  final int reviewsCount;
  final bool embedded;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: BrandColors.needlesDeep,
        gradient: RadialGradient(
          center: const Alignment(0.8, -0.2),
          radius: 1.2,
          colors: [
            BrandColors.needlesLight.withOpacity(0.5),
            Colors.transparent,
          ],
          stops: const [0.0, 0.6],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(18, embedded ? 16 : 8, 18, 20),
        child: Column(
          children: [
            if (onBack != null)
              Row(
                children: [
                  BrandBackButton(onPressed: onBack!, onDark: true),
                  const Spacer(),
                  BrandIconButton(
                    onDark: true,
                    icon: Icon(
                      Icons.ios_share_rounded,
                      size: 18,
                      color: BrandColors.onNeedles,
                    ),
                  ),
                ],
              ),
            if (onBack != null) const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BrandAvatar(
                  name: profile.name,
                  size: 72,
                  radius: 20,
                  tone: BrandAvatarTone.clay,
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              profile.name,
                              style: pochaevsk(
                                fontSize: 24,
                                color: BrandColors.onNeedles,
                                height: 1.05,
                              ),
                            ),
                          ),
                          const SizedBox(width: 7),
                          Icon(
                            Icons.verified_rounded,
                            size: 17,
                            color: BrandColors.dawn,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile.specialty,
                        style: BrandUi.inter(
                          fontSize: 13.5,
                          color: BrandColors.dawn,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          BrandStars(value: profile.rating, size: 13),
                          const SizedBox(width: 6),
                          Text(
                            profile.rating.toStringAsFixed(1),
                            style: BrandUi.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: BrandColors.onNeedles,
                            ),
                          ),
                          Text(
                            ' · $reviewsCount отзывов',
                            style: BrandUi.inter(
                              fontSize: 12.5,
                              color: BrandColors.onNeedles.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            DecoratedBox(
              decoration: BoxDecoration(
                color: BrandColors.onNeedles.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    _HeroStat(value: '${profile.completedJobs}', label: 'заказа'),
                    _HeroStat(
                      value: profile.statusLabel,
                      label: 'на сервисе',
                      showBorder: true,
                    ),
                    _HeroStat(
                      value: '2 года',
                      label: 'гарантия',
                      showBorder: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.value,
    required this.label,
    this.showBorder = false,
  });

  final String value;
  final String label;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: showBorder
              ? Border(
                  left: BorderSide(
                    color: BrandColors.onNeedles.withOpacity(0.14),
                  ),
                )
              : null,
        ),
        child: Column(
          children: [
            Text(
              value,
              style: pochaevsk(
                fontSize: 22,
                color: BrandColors.onNeedles,
                height: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: BrandUi.inter(
                fontSize: 11.5,
                color: BrandColors.onNeedles.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.review,
    this.onEdit,
    this.onDelete,
  });

  final MasterReview review;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return BrandCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              BrandAvatar(name: review.author, size: 36, radius: 11),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.author,
                      style: BrandUi.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    BrandStars(value: review.rating, size: 10),
                  ],
                ),
              ),
              Text(
                'НЕДАВНО',
                style: BrandUi.monoLabel(
                  fontSize: 10,
                  color: BrandRuntime.ink.withOpacity(0.35),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            '«${review.text}»',
            style: BrandUi.inter(
              fontSize: 13.5,
              color: BrandRuntime.ink.withOpacity(0.65),
              height: 1.5,
            ),
          ),
          if (onEdit != null || onDelete != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (onEdit != null)
                  TextButton(onPressed: onEdit, child: const Text('Редактировать')),
                if (onDelete != null)
                  TextButton(onPressed: onDelete, child: const Text('Удалить')),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
