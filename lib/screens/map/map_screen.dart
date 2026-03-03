import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
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
    {'name': 'Гостиная', 'icon': Icons.weekend, 'devices': 5, 'tasks': 2},
    {'name': 'Спальня', 'icon': Icons.bed, 'devices': 3, 'tasks': 0},
    {'name': 'Кухня', 'icon': Icons.kitchen, 'devices': 8, 'tasks': 1},
    {'name': 'Ванная', 'icon': Icons.bathtub, 'devices': 4, 'tasks': 3},
    {'name': 'Кабинет', 'icon': Icons.computer, 'devices': 6, 'tasks': 0},
    {'name': 'Детская', 'icon': Icons.child_care, 'devices': 2, 'tasks': 1},
  ];

  final List<Map<String, dynamic>> _availableRooms = [
    {'name': 'Прихожая', 'icon': Icons.door_front_door},
    {'name': 'Балкон', 'icon': Icons.balcony},
    {'name': 'Гардероб', 'icon': Icons.checkroom},
    {'name': 'Столовая', 'icon': Icons.dining},
    {'name': 'Терраса', 'icon': Icons.deck},
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
        'devices': 0,
        'tasks': 0,
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
                  fontFamily: 'Gropled',
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
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          // Заголовок
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 36, 20, 12),
            child: Row(
              children: [
                Text(
                  'Карта',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Gropled',
                    color: AppTheme.textPrimary,
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
          // Визуализация плана квартиры
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.warmGrey.withOpacity(0.3)),
              ),
              child: Center(
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
                          _selectedRoom = room['name'];
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: isSelected ? 120 : 100,
                        height: isSelected ? 120 : 100,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryColor.withOpacity(0.1)
                              : AppTheme.getRoomColor(room['name']),
                          borderRadius: BorderRadius.circular(16),
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
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: Stack(
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  room['icon'] as IconData,
                                  size: isSelected ? 32 : 28,
                                  color: isSelected
                                      ? AppTheme.primaryColor
                                      : AppTheme.textSecondary,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  room['name'],
                                  style: TextStyle(
                                    fontSize: isSelected ? 14 : 12,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? AppTheme.primaryColor
                                        : AppTheme.textPrimary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                if (room['tasks'] > 0 && !_isEditMode)
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentColor,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${room['tasks']} задач',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            // Delete button in edit mode
                            if (_isEditMode)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _deleteRoom(room['name']),
                                  child: Container(
                                    width: 24,
                                    height: 24,
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
          // Детали выбранной комнаты
          if (_selectedRoom != null && !_isEditMode)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: _buildRoomDetails(),
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
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add,
                size: 24,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Добавить',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomDetails() {
    final room = _rooms.firstWhere((r) => r['name'] == _selectedRoom);
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(room['icon'] as IconData, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                room['name'],
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              // Кнопка «Редактор» → 3D изометрия
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RoomEditorScreen(
                      roomName: _selectedRoom!,
                    ),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.view_in_ar_rounded,
                          size: 16, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        '3D редактор',
                        style: TextStyle(
                          fontSize: 12,
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
          const SizedBox(height: 16),
          Row(
            children: [
              _buildInfoChip(
                icon: Icons.devices,
                label: '${room['devices']} устройств',
              ),
              const SizedBox(width: 12),
              _buildInfoChip(
                icon: Icons.task_alt,
                label: '${room['tasks']} задач',
                highlight: room['tasks'] > 0,
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.devices),
                  label: const Text('Устройства'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add_task),
                  label: const Text('Добавить'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: highlight
            ? AppTheme.accentColor.withOpacity(0.1)
            : AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: highlight ? AppTheme.accentColor : AppTheme.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: highlight ? AppTheme.accentColor : AppTheme.textSecondary,
              fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
