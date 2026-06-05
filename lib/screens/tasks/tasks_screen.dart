import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../core/theme/app_text_style.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';
import 'add_task_screen.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final int _streakDays = 2;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().loadTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? AppTheme.darkBackground : AppTheme.backgroundColor;
    final textMain = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;

    return Consumer<TaskProvider>(
      builder: (context, taskProv, _) => Scaffold(
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
                  fontFamily: AppTextStyle.uiFontFamily,
                  color: textMain,
                  height: AppTextStyle.defaultHeight,
                  leadingDistribution: AppTextStyle.defaultLeadingDistribution,
                ),
              ),
            ),
          ),
          // Мобильная раскладка: сверху страйк (крупнее), снизу выполнено и осталось (мельче)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Страйк — выше и крупнее
                  SizedBox(
                    height: 100,
                    child: _buildStreakCard(days: _streakDays),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatSquare(
                          value: taskProv.completedCount.toString(),
                          label: 'выполнено',
                          color: Colors.white,
                          background: AppTheme.primaryColor,
                          compact: true,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildStatSquare(
                          value: taskProv.remainingCount.toString(),
                          label: 'осталось',
                          color: Colors.white,
                          background: AppTheme.primaryColor,
                          compact: true,
                        ),
                      ),
                    ],
                  ),
                ],
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
                  final task = taskProv.tasks[index];
                  return _buildTaskCard(task);
                },
                childCount: taskProv.tasks.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final added = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const AddTaskScreen()),
          );
          if (added == true && mounted) {
            await context.read<TaskProvider>().loadTasks();
          }
        },
        backgroundColor: AppTheme.accentColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    ),
    );
  }

  Widget _buildStatSquare({
    required String value,
    required String label,
    required Color color,
    required Color background,
    bool compact = false,
  }) {
    final valueFontSize = compact ? 22.0 : 28.0;
    final labelFontSize = compact ? 9.0 : 10.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.maxWidth < constraints.maxHeight
            ? constraints.maxWidth
            : constraints.maxHeight;
        return SizedBox(
          width: side,
          height: compact ? 72 : side,
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
                    fontSize: valueFontSize,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Roboto',
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: labelFontSize,
                    color: color.withOpacity(0.65),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: AppTheme.accentColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🔥', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 2),
              Text(
                days.toString(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Roboto',
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  'до $nextMilestone дн.',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.white.withOpacity(0.65),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
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

  Widget _buildTaskCard(TaskItem task) {
    final isDone = task.isDone;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayZone = task.description?.contains('Зона:') == true
        ? task.description!.split(',').first.replaceFirst('Зона:', '').trim()
        : null;
    return GestureDetector(
      onTap: () => context.read<TaskProvider>().toggleTask(task),
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
            const Text('🧩', style: TextStyle(fontSize: 22)),
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
                      if (task.dueDate != null)
                        _buildChip(
                          icon: Icons.schedule,
                          label:
                              '${task.dueDate!.hour.toString().padLeft(2, '0')}:${task.dueDate!.minute.toString().padLeft(2, '0')}',
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                          background: isDark
                              ? AppTheme.darkBorder.withOpacity(0.7)
                              : AppTheme.secondaryColor.withOpacity(0.45),
                        ),
                      if (task.dueDate != null && displayZone != null)
                        const SizedBox(width: 8),
                      if (displayZone != null)
                        _buildChip(
                          icon: Icons.home_outlined,
                          label: displayZone,
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
