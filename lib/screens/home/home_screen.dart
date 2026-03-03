import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../tasks/tasks_screen.dart';
import '../map/map_screen.dart';
import '../search/search_screen.dart';
import '../chat/chat_screen.dart';
import '../profile/profile_screen.dart';

/// Главный экран АРТхаус с боковой навигацией (sidebar)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<_NavItem> _navItems = const [
    _NavItem(Icons.check_circle_outline, Icons.check_circle, 'Задачи'),
    _NavItem(Icons.grid_view_outlined, Icons.grid_view, 'Карта'),
    _NavItem(Icons.search_rounded, Icons.search_rounded, 'Поиск'),
    _NavItem(Icons.chat_bubble_outline, Icons.chat_bubble, 'Чат'),
    _NavItem(Icons.person_outline, Icons.person, 'Профиль'),
  ];

  Widget _getScreen(int index) {
    switch (index) {
      case 0:
        return const TasksScreen();
      case 1:
        return const MapScreen();
      case 2:
        return const SearchScreen(embedded: true);
      case 3:
        return const ChatScreen();
      case 4:
        return const ProfileScreen(embedded: true);
      default:
        return const TasksScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Row(
          children: [
            // ── Сайдбар ──
            _buildSidebar(),
            // ── Контент ──
            Expanded(child: _getScreen(_currentIndex)),
          ],
        ),
      ),
    );
  }

  /// Боковая навигация в стиле АРТхаус
  Widget _buildSidebar() {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(
            color: AppTheme.secondaryColor,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Логотип
          const SizedBox(height: 28),
          Text(
            'АРТхаус',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              fontFamily: 'Gropled',
              color: AppTheme.primaryColor,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'твой дом в порядке',
            style: TextStyle(
              fontSize: 9,
              letterSpacing: 2,
              color: AppTheme.textHint,
              fontFamily: 'Gropled',
            ),
          ),
          const SizedBox(height: 32),
          Divider(color: AppTheme.secondaryColor, height: 1),
          const SizedBox(height: 12),

          // Навигационные элементы
          ...List.generate(_navItems.length, (index) {
            final item = _navItems[index];
            final isSelected = _currentIndex == index;
            return _buildNavTile(item, isSelected, index);
          }),

          const Spacer(),

          // Выход
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Consumer<AuthProvider>(
              builder: (context, auth, _) {
                final username = auth.user?.username ?? '';
                return Column(
                  children: [
                    Divider(color: AppTheme.secondaryColor, height: 1),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              username.isNotEmpty ? username[0].toUpperCase() : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            username,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavTile(_NavItem item, bool isSelected, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _currentIndex = index),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryColor.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? item.selectedIcon : item.icon,
                  color: isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.textHint,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _NavItem(this.icon, this.selectedIcon, this.label);
}
