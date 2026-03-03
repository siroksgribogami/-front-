import 'package:flutter/material.dart';
import '../../config/app_theme.dart';

/// Экран задач с акцентом на streak и зелёной палитрой
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  int _completedCount = 4;
  int _remainingCount = 3;
  int _streakDays = 2;

  final List<_Task> _tasks = [
    const _Task(
      id: '1',
      title: 'Убрать кухню',
      time: '14:00',
      room: 'Кухня',
      icon: '🧽',
      isDone: false,
    ),
    const _Task(
      id: '2',
      title: 'Полить цветы утром',
      time: null,
      room: 'Гостиная',
      icon: '🌿',
      isDone: true,
    ),
    const _Task(
      id: '3',
      title: 'Помыть ванную',
      time: '16:00',
      room: 'Ванная',
      icon: '🛁',
      isDone: false,
    ),
  ];

  void _toggleTask(String id) {
    setState(() {
      final idx = _tasks.indexWhere((t) => t.id == id);
      if (idx != -1) {
        final updated = _tasks[idx].copyWith(isDone: !_tasks[idx].isDone);
        _tasks[idx] = updated;
        if (updated.isDone) {
          _completedCount++;
          _remainingCount--;
        } else {
          _completedCount--;
          _remainingCount++;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 36, 20, 20),
              child: Text(
                'Задачи',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Gropled',
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildStatCard(
                    value: _completedCount.toString(),
                    label: 'выполнено',
                    color: Colors.white,
                    background: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    value: _remainingCount.toString(),
                    label: 'осталось',
                    color: Colors.white,
                    background: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 12),
                  _buildStreakCard(days: _streakDays),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 28)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'СЕГОДНЯ',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final task = _tasks[index];
                  return _buildTaskCard(task);
                },
                childCount: _tasks.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppTheme.accentColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStatCard({
    required String value,
    required String label,
    required Color color,
    required Color background,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: background.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                fontFamily: 'Gropled',
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color.withOpacity(0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCard({required int days}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: AppTheme.accentColor.withOpacity(0.9),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentColor.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 4),
                Text(
                  days.toString(),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Gropled',
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'подряд',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(_Task task) {
    final isDone = task.isDone;
    return GestureDetector(
      onTap: () => _toggleTask(task.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDone ? AppTheme.primaryPale.withOpacity(0.18) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDone
                ? AppTheme.primaryColor.withOpacity(0.2)
                : AppTheme.primaryColor.withOpacity(0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isDone ? AppTheme.primaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDone
                      ? AppTheme.primaryColor
                      : AppTheme.warmGrey.withOpacity(0.4),
                  width: 2,
                ),
              ),
              child: isDone
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : null,
            ),
            const SizedBox(width: 14),
            Text(task.icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDone ? AppTheme.textSecondary : AppTheme.textPrimary,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                      decorationColor: AppTheme.warmGrey,
                    ),
                  ),
                  if (task.time != null || task.room != null) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (task.time != null)
                          _buildChip(
                            icon: Icons.schedule,
                            label: task.time!,
                            color: AppTheme.textSecondary,
                            background: AppTheme.backgroundColor,
                          ),
                        if (task.room != null)
                          _buildChip(
                            icon: Icons.room_preferences_outlined,
                            label: task.room!,
                            color: AppTheme.primaryColor,
                            background: AppTheme.primaryColor.withOpacity(0.12),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 8,
              height: 48,
              decoration: BoxDecoration(
                color: isDone ? AppTheme.primaryColor : AppTheme.accentColor,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String label,
    required Color color,
    required Color background,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Task {
  final String id;
  final String title;
  final String? time;
  final String? room;
  final String icon;
  final bool isDone;

  const _Task({
    required this.id,
    required this.title,
    this.time,
    this.room,
    required this.icon,
    required this.isDone,
  });

  _Task copyWith({
    String? id,
    String? title,
    String? time,
    String? room,
    String? icon,
    bool? isDone,
  }) {
    return _Task(
      id: id ?? this.id,
      title: title ?? this.title,
      time: time ?? this.time,
      room: room ?? this.room,
      icon: icon ?? this.icon,
      isDone: isDone ?? this.isDone,
    );
  }
}
