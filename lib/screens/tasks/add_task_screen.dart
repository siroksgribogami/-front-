import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../core/widgets/ios_picker_sheet.dart';
import '../../core/theme/app_text_style.dart';
import '../../providers/task_provider.dart';

/// Окно добавления задачи поверх экрана (стрелка назад, подтверждение, зоны/комнаты).
/// Для семейного/бизнеса — опционально назначение на пользователя.
class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _titleController = TextEditingController();
  String _selectedZone = 'Гостиная';
  String? _selectedAssignee;
  TimeOfDay? _time;

  static const _zones = [
    'Гостиная',
    'Кухня',
    'Ванная',
    'Спальня',
    'Прихожая',
    'Балкон',
    'Кабинет',
    'Детская',
  ];

  /// Демо-список для назначения (семья/бизнес)
  static const _assignees = ['Я', 'Супруг(а)', 'Дети', 'Коллеги'];

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    final description = 'Зона: $_selectedZone'
        '${_selectedAssignee != null ? ', исполнитель: $_selectedAssignee' : ''}';
    final dueDate = _time == null
        ? null
        : DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
            _time!.hour,
            _time!.minute,
          );
    final ok = await context.read<TaskProvider>().createTask(
          title: title,
          description: description,
          dueDate: dueDate,
        );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      final err = context.read<TaskProvider>().error ?? 'Не удалось создать задачу';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  Future<void> _pickTime() async {
    final picked = await IosPickerSheet.pickTime(
      context,
      initialTime: _time,
      title: 'Выберите время',
    );
    if (picked != null) {
      setState(() => _time = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? AppTheme.darkBackground : AppTheme.backgroundColor;
    final cardBg = isDark ? AppTheme.darkCard : Colors.white;
    final textMain = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final textHint = isDark ? AppTheme.darkTextHint : AppTheme.textHint;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        title: Text(
          'Новая задача',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            fontFamily: AppTextStyle.uiFontFamily,
            color: textMain,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Название',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textHint,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Например: Полить цветы',
                  hintStyle: TextStyle(color: textHint, fontSize: 15),
                  filled: true,
                  fillColor: cardBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                style: TextStyle(fontSize: 15, color: textMain),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 24),
              Text(
                'Зона / комната',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textHint,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _zones.map((z) {
                  final sel = _selectedZone == z;
                  return ChoiceChip(
                    label: Text(z),
                    selected: sel,
                    onSelected: (v) => setState(() => _selectedZone = z),
                    selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Text(
                'Время (необязательно)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textHint,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickTime,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.schedule, color: textHint, size: 22),
                      const SizedBox(width: 12),
                      Text(
                        _time != null
                            ? '${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}'
                            : 'Выбрать время',
                        style: TextStyle(
                          fontSize: 15,
                          color: _time != null ? textMain : textHint,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Назначить (семья / бизнес)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textHint,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _assignees.map((a) {
                  final sel = _selectedAssignee == a;
                  return ChoiceChip(
                    label: Text(a),
                    selected: sel,
                    onSelected: (v) => setState(() => _selectedAssignee = sel ? null : a),
                    selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _titleController.text.trim().isEmpty ? null : _confirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Подтвердить'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
