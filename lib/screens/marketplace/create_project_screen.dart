import 'package:flutter/material.dart';

import '../../core/theme/app_text_style.dart';
import '../../core/theme/marketplace_colors.dart';
import 'ai_foreman_chat_tab.dart';

/// Пошаговое создание проекта / сбор ТЗ. Альтернатива — полноэкранный чат с ИИ.
class CreateProjectScreen extends StatefulWidget {
  /// Черновик: если не null, подставляем в форму.
  final String? initialTitle;
  final String? initialWorkType;

  const CreateProjectScreen({
    super.key,
    this.initialTitle,
    this.initialWorkType,
  });

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _page = PageController();
  int _step = 0;

  late final _titleCtrl = TextEditingController(text: widget.initialTitle ?? '');
  late final _workCtrl = TextEditingController(text: widget.initialWorkType ?? '');
  final _budgetCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _specCtrl = TextEditingController();

  @override
  void dispose() {
    _page.dispose();
    _titleCtrl.dispose();
    _workCtrl.dispose();
    _budgetCtrl.dispose();
    _addressCtrl.dispose();
    _specCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < 2) {
      setState(() => _step++);
      _page.nextPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
    }
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
      _page.previousPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
    }
  }

  void _openAiFullScreen() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (modalContext) => Scaffold(
          backgroundColor: MarketplaceColors.backgroundFor(modalContext),
          appBar: AppBar(
            backgroundColor: MarketplaceColors.cardFor(modalContext),
            foregroundColor: MarketplaceColors.textPrimaryFor(modalContext),
            title: Text(
              'ТЗ с ИИ-прорабом',
              style: TextStyle(fontFamily: AppTextStyle.fontFamily, fontWeight: FontWeight.w700),
            ),
          ),
          body: const SafeArea(child: AiForemanChatTab(showHeader: false)),
        ),
      ),
    );
  }

  void _saveDraft() {
    Navigator.of(context).pop(<String, String>{
      'title': _titleCtrl.text.trim().isEmpty ? 'Новый проект' : _titleCtrl.text.trim(),
      'workType': _workCtrl.text.trim(),
      'budget': _budgetCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
      'spec': _specCtrl.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final bg = MarketplaceColors.backgroundFor(context);
    final card = MarketplaceColors.cardFor(context);
    final textPrimary = MarketplaceColors.textPrimaryFor(context);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: card,
        foregroundColor: textPrimary,
        title: Text(
          'Новый проект',
          style: TextStyle(
            fontFamily: AppTextStyle.fontFamily,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saveDraft,
            child: const Text('Готово'),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: MarketplaceColors.contentMaxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: Row(
                    children: List.generate(3, (i) {
                      final done = i < _step;
                      final cur = i == _step;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: i < 2 ? 8 : 0),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 4,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: done || cur
                                  ? MarketplaceColors.bluePrimary
                                  : MarketplaceColors.textMutedFor(context).withOpacity(0.35),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _openAiFullScreen,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: MarketplaceColors.aiTurquoise.withOpacity(0.55),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.smart_toy_outlined,
                              size: 22,
                              color: MarketplaceColors.aiTurquoise,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Собрать ТЗ в чате с ИИ (альтернатива форме)',
                                style: TextStyle(
                                  fontFamily: AppTextStyle.fontFamily,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: MarketplaceColors.aiTurquoise,
                                  height: 1.25,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: PageView(
                    controller: _page,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _step1(context),
                      _step2(context),
                      _step3(context),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    8,
                    20,
                    MediaQuery.paddingOf(context).bottom + 12,
                  ),
                  child: Row(
                    children: [
                      if (_step > 0)
                        OutlinedButton(
                          onPressed: _back,
                          child: const Text('Назад'),
                        ),
                      const Spacer(),
                      FilledButton(
                        onPressed: _step < 2 ? _next : _saveDraft,
                        style: FilledButton.styleFrom(
                          backgroundColor: MarketplaceColors.bluePrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        ),
                        child: Text(_step < 2 ? 'Далее' : 'Сохранить черновик'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _step1(BuildContext context) {
    final textPrimary = MarketplaceColors.textPrimaryFor(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Название и тип работ',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        _field(
          context: context,
          label: 'Название проекта',
          controller: _titleCtrl,
          hint: 'Например: Ремонт гостиной',
        ),
        const SizedBox(height: 14),
        _field(
          context: context,
          label: 'Тип работ',
          controller: _workCtrl,
          hint: 'Малярные, электрика, сантехника…',
        ),
      ],
    );
  }

  Widget _step2(BuildContext context) {
    final textPrimary = MarketplaceColors.textPrimaryFor(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Бюджет и адрес',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        _field(
          context: context,
          label: 'Бюджет (ориентир)',
          controller: _budgetCtrl,
          hint: 'до 150 000 ₽',
          keyboard: TextInputType.text,
        ),
        const SizedBox(height: 14),
        _field(
          context: context,
          label: 'Адрес / район',
          controller: _addressCtrl,
          hint: 'Москва, САО, р-н Сокол',
        ),
      ],
    );
  }

  Widget _step3(BuildContext context) {
    final textPrimary = MarketplaceColors.textPrimaryFor(context);
    final textSecondary = MarketplaceColors.textSecondaryFor(context);
    final card = MarketplaceColors.cardFor(context);
    final textMuted = MarketplaceColors.textMutedFor(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Техническое задание',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Кратко опишите объём: площадь, материалы, сроки. PDF и фото подключим на шаге интеграции с бэкендом.',
          style: TextStyle(fontSize: 13, color: textSecondary, height: 1.35),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _specCtrl,
          maxLines: 10,
          style: TextStyle(color: textPrimary, height: 1.4),
          decoration: InputDecoration(
            filled: true,
            fillColor: card,
            hintText: 'Текст ТЗ…',
            hintStyle: TextStyle(color: textMuted),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _field({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboard = TextInputType.text,
  }) {
    final textPrimary = MarketplaceColors.textPrimaryFor(context);
    final textSecondary = MarketplaceColors.textSecondaryFor(context);
    final card = MarketplaceColors.cardFor(context);
    final textMuted = MarketplaceColors.textMutedFor(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboard,
          style: TextStyle(color: textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: textMuted),
            filled: true,
            fillColor: card,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
