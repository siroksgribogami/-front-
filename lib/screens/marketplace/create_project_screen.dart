import 'package:flutter/material.dart';

import '../../config/brand_colors.dart';
import '../../config/text_theme.dart';
import '../../core/theme/brand_ui.dart';
import '../../core/theme/marketplace_colors.dart';
import '../../widgets/marketplace_image_attachments.dart';
import 'ai_foreman_chat_tab.dart';
import 'create_project_foreman_panel.dart';

class CreateProjectScreen extends StatefulWidget {
  final String? initialTitle;
  final String? initialWorkType;
  final String? initialBudget;
  final String? initialAddress;
  final String? initialSpec;
  final List<String>? initialPhotoPaths;
  final bool skipPathPicker;

  const CreateProjectScreen({
    super.key,
    this.initialTitle,
    this.initialWorkType,
    this.initialBudget,
    this.initialAddress,
    this.initialSpec,
    this.initialPhotoPaths,
    this.skipPathPicker = false,
  });

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  static const _workTypes = [
    'Ремонт',
    'Дизайн',
    'Электрика',
    'Сантехника',
    'Малярные работы',
    'Плитка',
    'Мебель',
    'Другое',
  ];

  bool _showForm = false;
  bool _foremanExpanded = false;
  String? _selectedWorkType;
  bool _publicOrder = true;
  final List<String> _photoPaths = [];
  static const _specMaxLen = 4000;

  late final Widget _foremanChat = const AiForemanChatTab(
    key: ValueKey('create_project_foreman_chat'),
    showHeader: false,
    embedded: true,
  );

  bool get _showForemanPanel => !widget.skipPathPicker;

  late final _titleCtrl = TextEditingController(text: widget.initialTitle ?? '');
  late final _budgetCtrl = TextEditingController(text: widget.initialBudget ?? '');
  late final _addressCtrl = TextEditingController(text: widget.initialAddress ?? '');
  final _specCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final wt = widget.initialWorkType?.trim();
    if (wt != null && wt.isNotEmpty) {
      _selectedWorkType = _workTypes.contains(wt) ? wt : 'Другое';
      if (_selectedWorkType == 'Другое' && !_workTypes.contains(wt)) {
        _customWorkCtrl.text = wt;
      }
    }
    _specCtrl.text = widget.initialSpec ?? '';
    _showForm = widget.skipPathPicker;
    if (widget.initialPhotoPaths != null) {
      _photoPaths.addAll(widget.initialPhotoPaths!);
    }
    _specCtrl.addListener(() => setState(() {}));
  }

  final _customWorkCtrl = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _budgetCtrl.dispose();
    _addressCtrl.dispose();
    _specCtrl.dispose();
    _customWorkCtrl.dispose();
    super.dispose();
  }

  String get _resolvedWorkType {
    if (_selectedWorkType == null) return '';
    if (_selectedWorkType == 'Другое') {
      return _customWorkCtrl.text.trim();
    }
    return _selectedWorkType!;
  }

  Map<String, String> _buildResult() {
    final title = _titleCtrl.text.trim();
    return {
      'title': title.isEmpty ? 'Новый проект' : title,
      'workType': _resolvedWorkType,
      'budget': _budgetCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
      'spec': _specCtrl.text.trim(),
      'visibility': _publicOrder ? 'public' : 'private',
      if (_photoPaths.isNotEmpty) 'photos': _photoPaths.join('|'),
    };
  }

  Future<void> _addPhotos() async {
    final added = await MarketplaceImageAttachments.pickFromSheet(
      context,
      currentPaths: _photoPaths,
    );
    if (added.isEmpty || !mounted) return;
    setState(() => _photoPaths.addAll(added));
  }

  void _saveAndPop() {
    Navigator.of(context).pop(_buildResult());
  }

  void _startWithForeman() {
    setState(() {
      _showForm = true;
      _foremanExpanded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: BrandColors.canvas,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: MarketplaceColors.contentMaxWidth),
            child: Column(
              children: [
                BrandAppBar(
                  title: widget.skipPathPicker ? 'Заявка' : 'Новый проект',
                  subtitle: widget.skipPathPicker
                      ? null
                      : 'Опишите ремонт — или доверьте ИИ',
                  onBack: () => Navigator.of(context).pop(),
                  actions: _showForm
                      ? TextButton(
                          onPressed: _saveAndPop,
                          child: Text(
                            widget.skipPathPicker ? 'Сохранить' : 'Готово',
                            style: BrandUi.inter(
                              fontWeight: FontWeight.w700,
                              color: BrandColors.clay,
                            ),
                          ),
                        )
                      : null,
                ),
                Expanded(
                  child: _showForm ? _buildForm(context) : _buildPathPicker(context),
                ),
                if (_showForemanPanel)
                  CreateProjectForemanPanel(
                    expanded: _foremanExpanded,
                    onExpandedChanged: (v) => setState(() => _foremanExpanded = v),
                    chatChild: _foremanChat,
                  ),
                if (_showForm && !_foremanExpanded) _buildBottomBar(bottom),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(double bottomInset) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 14, 16, bottomInset + 14),
      decoration: const BoxDecoration(
        color: BrandColors.canvas,
        border: Border(top: BorderSide(color: BrandColors.borderSubtle)),
      ),
      child: Row(
        children: [
          BrandGhostButton(label: 'Фото', onPressed: _addPhotos),
          const SizedBox(width: 10),
          Expanded(
            child: BrandPrimaryButton(
              label: widget.skipPathPicker ? 'Сохранить' : 'Создать проект',
              onPressed: _saveAndPop,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPathPicker(BuildContext context) {
    final panelPad = _showForemanPanel ? 72.0 : 24.0;

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 0, 16, panelPad),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _AiPathCard(onTap: _startWithForeman)),
            const SizedBox(width: 11),
            Expanded(
              child: _ManualPathCard(
                onTap: () => setState(() => _showForm = true),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    final specLen = _specCtrl.text.length;
    final panelPad = _showForemanPanel && _foremanExpanded ? 0.0 : 0.0;

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + panelPad),
      children: [
        if (!widget.skipPathPicker) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _AiPathCard(
                  onTap: _startWithForeman,
                  selected: _foremanExpanded,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: _ManualPathCard(
                  onTap: () => setState(() {
                    _showForm = true;
                    _foremanExpanded = false;
                  }),
                  selected: !_foremanExpanded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
        ],
        const BrandKicker('Бриф проекта'),
        const SizedBox(height: 14),
        _brandField('Название', _titleCtrl, hint: 'Кухня-гостиная'),
        const SizedBox(height: 13),
        Text(
          'Тип работ',
          style: BrandUi.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: BrandColors.tar.withOpacity(0.55),
          ),
        ),
        const SizedBox(height: 9),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _workTypes.map((label) {
            return BrandChip(
              label: label,
              selected: _selectedWorkType == label,
              onTap: () => setState(() => _selectedWorkType = label),
            );
          }).toList(),
        ),
        if (_selectedWorkType == 'Другое') ...[
          const SizedBox(height: 10),
          _brandField('Уточните тип', _customWorkCtrl, hint: 'Тип работ'),
        ],
        const SizedBox(height: 13),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _brandField(
                'Бюджет, ₽',
                _budgetCtrl,
                hint: '1 200 000',
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: _brandField(
                'Адрес объекта',
                _addressCtrl,
                hint: 'Район, улица',
                prefix: Icon(
                  Icons.place_outlined,
                  color: BrandColors.clay,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 13),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Описание',
                  style: BrandUi.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: BrandColors.tar.withOpacity(0.55),
                  ),
                ),
                const Spacer(),
                Text(
                  '$specLen / $_specMaxLen',
                  style: BrandUi.inter(
                    fontSize: 12,
                    color: BrandColors.tar.withOpacity(0.45),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            TextField(
              controller: _specCtrl,
              maxLines: 6,
              maxLength: _specMaxLen,
              buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                  const SizedBox.shrink(),
              style: BrandUi.inter(fontSize: 15, height: 1.4),
              decoration: BrandUi.inputDecoration(
                hint: 'Опишите пожелания и детали для исполнителей',
              ),
            ),
          ],
        ),
        const SizedBox(height: 13),
        Text(
          'Фото (не обязательно)',
          style: BrandUi.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: BrandColors.tar.withOpacity(0.55),
          ),
        ),
        const SizedBox(height: 9),
        MarketplaceAttachmentStrip(
          paths: _photoPaths,
          onAdd: _addPhotos,
          onRemove: (i) => setState(() => _photoPaths.removeAt(i)),
        ),
        const SizedBox(height: 20),
        Text(
          'Кто увидит заказ',
          style: BrandUi.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: BrandColors.tar.withOpacity(0.55),
          ),
        ),
        const SizedBox(height: 10),
        _VisibilityCard(
          selected: _publicOrder,
          title: 'Публичный заказ',
          subtitle: 'Заявка в общей ленте — все мастера смогут откликнуться',
          onTap: () => setState(() => _publicOrder = true),
        ),
        const SizedBox(height: 10),
        _VisibilityCard(
          selected: !_publicOrder,
          title: 'Приватный заказ',
          subtitle: 'Только мастера, которым вы сами отправите приглашение',
          onTap: () => setState(() => _publicOrder = false),
        ),
      ],
    );
  }

  Widget _brandField(
    String label,
    TextEditingController controller, {
    String? hint,
    Widget? prefix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: BrandUi.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: BrandColors.tar.withOpacity(0.55),
          ),
        ),
        const SizedBox(height: 9),
        TextField(
          controller: controller,
          style: BrandUi.inter(fontSize: 15),
          decoration: BrandUi.inputDecoration(hint: hint, prefix: prefix),
        ),
      ],
    );
  }
}

class _AiPathCard extends StatelessWidget {
  const _AiPathCard({
    required this.onTap,
    this.selected = false,
  });

  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BrandColors.needles,
      borderRadius: BorderRadius.circular(16),
      elevation: selected ? 2 : 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: RadialGradient(
                    center: Alignment.topRight,
                    radius: 1.2,
                    colors: [
                      BrandColors.needlesLight.withOpacity(0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: BrandColors.needlesLight.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.engineering_rounded,
                      color: BrandColors.dawn,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'ИИ-прораб',
                    style: pochaevsk(
                      fontSize: 19,
                      color: BrandColors.milk,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Соберёт ТЗ и смету в диалоге',
                    style: BrandUi.inter(
                      fontSize: 12,
                      color: BrandColors.dawn.withOpacity(0.78),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Рекомендуем',
                      style: BrandUi.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: BrandColors.milk,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManualPathCard extends StatelessWidget {
  const _ManualPathCard({
    required this.onTap,
    this.selected = false,
  });

  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BrandColors.milk,
      borderRadius: BorderRadius.circular(16),
      elevation: selected ? 1 : 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? BrandColors.needles : BrandColors.borderSubtle,
              width: selected ? 2 : 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: BrandColors.linen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.edit_outlined,
                  color: BrandColors.needles,
                  size: 20,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Вручную',
                style: pochaevsk(
                  fontSize: 19,
                  color: BrandColors.tar,
                  height: 1,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Заполнить поля самостоятельно',
                style: BrandUi.inter(
                  fontSize: 12,
                  color: BrandColors.tar.withOpacity(0.55),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VisibilityCard extends StatelessWidget {
  final bool selected;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _VisibilityCard({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? BrandColors.sandstone.withOpacity(0.35) : BrandColors.milk,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? BrandColors.clay : BrandColors.borderSubtle,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? BrandColors.clay : BrandColors.tar.withOpacity(0.45),
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: BrandUi.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: BrandUi.inter(
                        fontSize: 13,
                        color: BrandColors.tar.withOpacity(0.55),
                        height: 1.35,
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
