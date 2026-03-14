import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../core/theme/app_text_style.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  int _completedCount = 4;
  int _remainingCount = 3;
  final int _streakDays = 2;

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? AppTheme.darkBackground : AppTheme.backgroundColor;
    final textMain = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 36, 20, 20),
              child: Text(
                'Задачи',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  fontFamily: AppTextStyle.fontFamily,
                  color: textMain,
                  height: AppTextStyle.defaultHeight,
                  leadingDistribution: AppTextStyle.defaultLeadingDistribution,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                height: 95,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStatSquare(
                      value: _completedCount.toString(),
                      label: 'выполнено',
                      color: Colors.white,
                      background: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 10),
                    _buildStatSquare(
                      value: _remainingCount.toString(),
                      label: 'осталось',
                      color: Colors.white,
                      background: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 10),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 200),
                      child: _buildStreakCard(days: _streakDays),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 28)),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
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

  Widget _buildStatSquare({
    required String value,
    required String label,
    required Color color,
    required Color background,
  }) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                fontFamily: 'Roboto',
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color.withOpacity(0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCard({required int days}) {
    const milestones = [3, 7, 14, 30, 60, 100];
    final nextMilestone = milestones.firstWhere(
      (m) => m > days,
      orElse: () => milestones.last,
    );
    final prevMilestone = milestones.lastWhere(
      (m) => m <= days,
      orElse: () => 0,
    );
    final double progress = nextMilestone == prevMilestone
        ? 1.0
        : (days - prevMilestone) / (nextMilestone - prevMilestone);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
      decoration: BoxDecoration(
        color: AppTheme.accentColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('🔥', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 4),
              Text(
                days.toString(),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Roboto',
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Text(
                'до $nextMilestone дн.',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withOpacity(0.65),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'подряд',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.white.withOpacity(0.6),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(_Task task) {
    final isDone = task.isDone;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => _toggleTask(task.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? (isDone
                  ? AppTheme.primaryColor.withOpacity(0.12)
                  : AppTheme.darkCard)
              : (isDone
                  ? AppTheme.primaryPale.withOpacity(0.18)
                  : Colors.white),
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
                      : AppTheme.primaryColor.withOpacity(0.35),
                  width: 2,
                ),
              ),
              child: isDone
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
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
                      color: isDone
                          ? (isDark ? AppTheme.darkTextHint : AppTheme.textHint)
                          : (isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary),
                      decoration: isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (task.time != null)
                        _buildChip(
                          icon: Icons.schedule,
                          label: task.time!,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                          background: isDark
                              ? AppTheme.darkBorder.withOpacity(0.7)
                              : AppTheme.secondaryColor.withOpacity(0.45),
                        ),
                      if (task.time != null && task.room != null)
                        const SizedBox(width: 8),
                      if (task.room != null)
                        _buildChip(
                          icon: Icons.home_outlined,
                          label: task.room!,
                          color: AppTheme.primaryColor,
                          background: AppTheme.primaryColor.withOpacity(0.12),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 8,
              height: 48,
              decoration: BoxDecoration(
                color: isDone
                    ? AppTheme.primaryColor.withOpacity(0.55)
                    : AppTheme.accentColor.withOpacity(0.65),
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
              color: color,
              fontSize: 11,
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
