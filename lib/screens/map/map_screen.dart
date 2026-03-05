import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../core/theme/app_text_style.dart';
import 'room_editor_screen.dart';

/// Экран карты квартиры - визуальное представление помещения
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  String? _selectedRoom;
  bool _isEditMode = false;

  final List<Map<String, dynamic>> _rooms = [
    {'name': 'Гостиная', 'icon': Icons.weekend, 'tasks': 2, 'taskList': ['Пропылесосить', 'Протереть пыль']},
    {'name': 'Спальня', 'icon': Icons.bed, 'tasks': 0, 'taskList': <String>[]},
    {'name': 'Кухня', 'icon': Icons.kitchen, 'tasks': 1, 'taskList': ['Помыть посуду']},
    {'name': 'Ванная', 'icon': Icons.bathtub, 'tasks': 3, 'taskList': ['Помыть унитаз', 'Протереть раковину', 'Вымыть кафель']},
    {'name': 'Кабинет', 'icon': Icons.computer, 'tasks': 0, 'taskList': <String>[]},
    {'name': 'Детская', 'icon': Icons.child_care, 'tasks': 1, 'taskList': ['Убрать игрушки']},
  ];

  final List<Map<String, dynamic>> _availableRooms = [
    {'name': 'Прихожая', 'icon': Icons.door_front_door},
    {'name': 'Балкон', 'icon': Icons.balcony},
    {'name': 'Гардероб', 'icon': Icons.checkroom},
    {'name': 'Столовая', 'icon': Icons.dining},
    {'name': 'Терраса', 'icon': Icons.deck},
    {'name': 'Коридор', 'icon': Icons.sensor_door},
    {'name': 'Кладовая', 'icon': Icons.inventory_2},
    {'name': 'Лоджия', 'icon': Icons.window},
    {'name': 'Гостевая', 'icon': Icons.hotel},
    {'name': 'Игровая', 'icon': Icons.sports_esports},
  ];

  void _deleteRoom(String name) {
    setState(() {
      _rooms.removeWhere((r) => r['name'] == name);
      if (_selectedRoom == name) {
        _selectedRoom = null;
      }
    });
  }

  void _addRoom(Map<String, dynamic> room) {
    setState(() {
      _rooms.add({
        ...room,
        'tasks': 0,
        'taskList': <String>[],
      });
    });
    Navigator.pop(context);
  }

  void _showAddRoomDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final availableToAdd = _availableRooms
            .where((r) => !_rooms.any((existing) => existing['name'] == r['name']))
            .toList();

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Добавить комнату',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  fontFamily: AppTextStyle.fontFamily,
                  height: AppTextStyle.defaultHeight,
                  leadingDistribution: AppTextStyle.defaultLeadingDistribution,
                ),
              ),
              const SizedBox(height: 20),
              if (availableToAdd.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text('Все комнаты уже добавлены'),
                  ),
                )
              else
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: availableToAdd.map((room) {
                    return GestureDetector(
                      onTap: () => _addRoom(room),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              room['icon'] as IconData,
                              color: AppTheme.primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              room['name'],
                              style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.darkBackground
          : AppTheme.backgroundColor,
      body: Column(
        children: [
          // Заголовок
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 36, 20, 12),
            child: Row(
              children: [
                Text(
                  'Карта',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    fontFamily: AppTextStyle.fontFamily,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.textPrimary,
                    height: AppTextStyle.defaultHeight,
                    leadingDistribution: AppTextStyle.defaultLeadingDistribution,
                  ),
                ),
                const Spacer(),
                // Кнопка редактирования
                GestureDetector(
                  onTap: () => setState(() => _isEditMode = !_isEditMode),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _isEditMode ? AppTheme.primaryColor : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isEditMode ? Icons.done : Icons.edit_outlined,
                          size: 18,
                          color: _isEditMode ? Colors.white : AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isEditMode ? 'Готово' : 'Редактировать',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _isEditMode ? Colors.white : AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Основная область: сетка + боковая панель
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Левая часть: прокручиваемая сетка комнат
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurface : AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.warmGrey.withOpacity(0.3)),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: [
                          ..._rooms.map((room) {
                            final isSelected = _selectedRoom == room['name'];
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedRoom = isSelected ? null : room['name'];
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: isSelected ? 195 : 180,
                                height: isSelected ? 195 : 180,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.primaryColor.withOpacity(0.12)
                                      : (isDark
                                          ? AppTheme.getRoomColorDark(room['name'])
                                          : AppTheme.getRoomColor(room['name'])),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppTheme.primaryColor
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: AppTheme.primaryColor.withOpacity(0.2),
                                            blurRadius: 12,
                                            spreadRadius: 2,
                                          ),
                                        ]
                                      : [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.06),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                ),
                                child: Stack(
                                  children: [
                                    SizedBox(
                                      width: double.infinity,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            room['icon'] as IconData,
                                            size: isSelected ? 40 : 36,
                                            color: isSelected
                                                ? AppTheme.primaryColor
                                                : (isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            room['name'],
                                            style: TextStyle(
                                              fontSize: isSelected ? 15 : 13,
                                              fontWeight: isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                              color: isSelected
                                                  ? AppTheme.primaryColor
                                                  : (isDark ? AppTheme.darkTextSecondary : AppTheme.textPrimary),
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          if (room['tasks'] > 0 && !_isEditMode)
                                            Container(
                                              margin: const EdgeInsets.only(top: 6),
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: AppTheme.accentColor,
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                '${room['tasks']} задач',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (_isEditMode)
                                      Positioned(
                                        top: 6,
                                        right: 6,
                                        child: GestureDetector(
                                          onTap: () => _deleteRoom(room['name']),
                                          child: Container(
                                            width: 26,
                                            height: 26,
                                            decoration: BoxDecoration(
                                              color: Colors.red.withOpacity(0.9),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              size: 14,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }),
                          if (_isEditMode) _buildAddRoomButton(),
                        ],
                      ),
                    ),
                  ),
                ),
                // Правая панель (анимированная)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: (_selectedRoom != null && !_isEditMode) ? 260.0 : 0.0,
                  curve: Curves.easeInOut,
                  child: (_selectedRoom != null && !_isEditMode)
                      ? Container(
                          margin: const EdgeInsets.fromLTRB(0, 16, 16, 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 12,
                                offset: const Offset(-2, 0),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: _buildSidePanel(),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddRoomButton() {
    return GestureDetector(
      onTap: _showAddRoomDialog,
      child: Container(
        width: 180,
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.primaryColor,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, size: 28, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 10),
            const Text(
              'Добавить',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidePanel() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final room = _rooms.firstWhere((r) => r['name'] == _selectedRoom);
    final taskList = (room['taskList'] as List?)?.cast<String>() ?? <String>[];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок комнаты
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.getRoomColorDark(room['name'])
                      : AppTheme.getRoomColor(room['name']),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(room['icon'] as IconData,
                    color: AppTheme.primaryColor, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  room['name'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _selectedRoom = null),
                child: const Icon(Icons.close, size: 20, color: AppTheme.textHint),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Заголовок задач
          Row(
            children: [
              const Icon(Icons.task_alt, size: 16, color: AppTheme.primaryColor),
              const SizedBox(width: 6),
              Text(
                taskList.isEmpty
                    ? 'Нет задач'
                    : '${room['tasks']} задач',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Список задач
          Expanded(
            child: taskList.isEmpty
                ? const Center(
                    child: Text(
                      'Всё чисто ✓',
                      style: TextStyle(color: AppTheme.textHint, fontSize: 13),
                    ),
                  )
                : ListView.separated(
                    itemCount: taskList.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: Color(0xFFEEEEEE)),
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: AppTheme.accentColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                taskList[index],
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          // Кнопка 3D редактора
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RoomEditorScreen(roomName: _selectedRoom!),
              ),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.view_in_ar_rounded, size: 16, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    '3D редактор',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
