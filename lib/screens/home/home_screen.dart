import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../core/theme/app_text_style.dart';
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
  int _currentIndex = 2; // Карта по умолчанию (в середине)

  // Порядок: Специалисты, Задачи, Карта, Чат, Профиль (поиск слева, карта в центре)
  final List<_NavItem> _navItems = const [
    _NavItem(Icons.search_rounded, Icons.search_rounded, 'Специалисты'),
    _NavItem(Icons.check_circle_outline, Icons.check_circle, 'Задачи'),
    _NavItem(Icons.grid_view_outlined, Icons.grid_view, 'Карта'),
    _NavItem(Icons.chat_bubble_outline, Icons.chat_bubble, 'Чат'),
    _NavItem(Icons.person_outline, Icons.person, 'Профиль'),
  ];

  Widget _getScreen(int index) {
    switch (index) {
      case 0:
        return const SearchScreen(embedded: true);
      case 1:
        return const TasksScreen();
      case 2:
        return const MapScreen();
      case 3:
        return const ChatScreen();
      case 4:
        return const ProfileScreen(embedded: true);
      default:
        return const SearchScreen(embedded: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? AppTheme.darkBackground : AppTheme.backgroundColor;

    return Scaffold(
      backgroundColor: scaffoldBg,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sidebarBg = isDark ? AppTheme.darkCard : Colors.white;
    final borderC = isDark ? AppTheme.darkBorder : AppTheme.secondaryColor;
    final textHintC = isDark ? AppTheme.darkTextHint : AppTheme.textHint;
    final textMainC = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: sidebarBg,
        border: Border(
          right: BorderSide(
            color: borderC,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.03),
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
              fontFamily: AppTextStyle.fontFamily,
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.primaryColor,
              letterSpacing: -1,
              height: AppTextStyle.defaultHeight,
            ),
          ),
          const SizedBox(height: 6),
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              final premise = auth.premiseType;
              final subtitle = _premiseSubtitle(
                premise,
                accountMode: auth.accountMode,
              );
              return Text(
                subtitle,
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 2,
                  color: textHintC,
                  fontFamily: AppTextStyle.fontFamily,
                  height: AppTextStyle.defaultHeight,
                  leadingDistribution: AppTextStyle.defaultLeadingDistribution,
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          Divider(color: borderC, height: 1),
          const SizedBox(height: 12),

          // Навигационные элементы
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: List.generate(_navItems.length, (index) {
                  final item = _navItems[index];
                  final isSelected = _currentIndex == index;
                  return _buildNavTile(item, isSelected, index);
                }),
              ),
            ),
          ),

          // Пользователь
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Consumer<AuthProvider>(
              builder: (context, auth, _) {
                final username = auth.user?.username ?? '';
                return Column(
                  children: [
                    Divider(color: borderC, height: 1),
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
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textMainC,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                  ? (isDark
                      ? Colors.white.withOpacity(0.08)
                      : AppTheme.primaryColor.withOpacity(0.1))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? item.selectedIcon : item.icon,
                  color: isSelected
                      ? (isDark ? AppTheme.darkTextPrimary : AppTheme.primaryColor)
                      : (isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.textHint),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontFamily: AppTextStyle.fontFamily,
                    height: AppTextStyle.defaultHeight,
                    leadingDistribution: AppTextStyle.defaultLeadingDistribution,
                    color: isSelected
                        ? (isDark ? AppTheme.darkTextPrimary : AppTheme.primaryColor)
                        : (isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.textSecondary),
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

String _premiseSubtitle(String? premiseType, {String? accountMode}) {
  if (accountMode == 'service') return 'доступ к картам клиентов';
  if (accountMode == 'p2p') return 'карта на заказ и вручную';
  switch (premiseType) {
    case 'apartment': return 'твоя квартира в порядке';
    case 'house': return 'твой дом в порядке';
    case 'office': return 'твой офис в порядке';
    case 'commerce': return 'твой склад в порядке';
    case 'hotel': return 'твои апартаменты в порядке';
    case 'service_access': return 'временный доступ к объектам';
    default: return 'твой дом в порядке';
  }
}
