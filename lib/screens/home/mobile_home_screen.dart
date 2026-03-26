import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../core/theme/app_text_style.dart';
import '../tasks/tasks_screen.dart';
import '../map/map_screen.dart';
import '../search/search_screen.dart';
import '../chat/chat_screen.dart';
import '../profile/profile_screen.dart';

/// Мобильная версия главного экрана с нижней навигацией (Android / iOS).
/// Оптимизировано под сенсор: зоны нажатия ≥ 48dp, учёт safe area для жестов.
class MobileHomeScreen extends StatefulWidget {
  const MobileHomeScreen({super.key});

  @override
  State<MobileHomeScreen> createState() => _MobileHomeScreenState();
}

class _MobileHomeScreenState extends State<MobileHomeScreen> {
  int _currentIndex = 2; // Карта по умолчанию (в середине навигации)

  // Порядок: Специалисты, Задачи, Карта, Чат, Профиль (поиск слева, карта в центре)
  final List<Widget> _screens = const [
    SearchScreen(embedded: true),
    TasksScreen(),
    MapScreen(),
    ChatScreen(),
    ProfileScreen(embedded: true),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg =
        isDark ? AppTheme.darkBackground : AppTheme.backgroundColor;
    final navBg = isDark ? AppTheme.darkCard : Colors.white;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: navBg,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: 8,
            right: 8,
            top: 8,
            bottom: bottomPadding + 8,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.search_rounded, Icons.search_rounded, 'Специалисты'),
              _buildNavItem(1, Icons.check_circle_outline, Icons.check_circle, 'Задачи'),
              _buildNavItem(2, Icons.grid_view_outlined, Icons.grid_view, 'Карта'),
              _buildNavItem(3, Icons.chat_bubble_outline, Icons.chat_bubble, 'Чат'),
              _buildNavItem(4, Icons.person_outline, Icons.person, 'Профиль'),
            ],
          ),
        ),
      ),
    );
  }

  /// Зона нажатия не менее 48dp по высоте для удобства на Android.
  Widget _buildNavItem(
      int index, IconData icon, IconData selectedIcon, String label) {
    final isSelected = _currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedColor =
        isDark ? AppTheme.darkTextPrimary : AppTheme.primaryColor;
    final unselectedColor =
        isDark ? AppTheme.darkTextSecondary : AppTheme.textHint;

    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _currentIndex = index),
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark
                                ? Colors.white.withOpacity(0.08)
                                : AppTheme.primaryColor.withOpacity(0.1))
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isSelected ? selectedIcon : icon,
                        color: isSelected ? selectedColor : unselectedColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontFamily: AppTextStyle.fontFamily,
                        height: AppTextStyle.defaultHeight,
                        leadingDistribution: AppTextStyle.defaultLeadingDistribution,
                        color: isSelected ? selectedColor : unselectedColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
