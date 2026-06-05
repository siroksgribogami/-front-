import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/brand_colors.dart';
import '../../config/text_theme.dart';
import '../../core/theme/brand_ui.dart';
import '../../models/app_marketplace_role.dart';
import '../../providers/auth_provider.dart';
import '../../providers/role_provider.dart';
import '../marketplace/messages_hub_screen.dart';
import '../marketplace/customer_find_masters_screen.dart';
import '../marketplace/customer_projects_screen.dart';
import '../marketplace/master_my_bids_screen.dart';
import '../marketplace/master_orders_feed_screen.dart';
import '../marketplace/marketplace_catalog_screen.dart';
import '../marketplace/master_supplies_catalog_screen.dart';
import '../profile/profile_screen.dart';

/// Веб-оболочка: боковое меню зависит от активной роли маркетплейса (заказчик / мастер).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  AppMarketplaceRole? _lastActiveRole;
  /// Два фиксированных режима: только иконки или иконки + подписи (без «растягивания»).
  bool _sidebarExpanded = true;

  static const double _collapsedSidebarWidth = 76;
  static const double _expandedSidebarWidth = 214;

  void _syncRoleTab(AppMarketplaceRole active) {
    if (_lastActiveRole == null) {
      _lastActiveRole = active;
      return;
    }
    if (_lastActiveRole != active) {
      _lastActiveRole = active;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _currentIndex = 0);
      });
    }
  }

  List<_NavItem> _itemsForRole(AppMarketplaceRole role) {
    if (role == AppMarketplaceRole.customer) {
      return const [
        _NavItem(Icons.folder_open_outlined, Icons.folder_open, 'Проекты'),
        _NavItem(Icons.handshake_outlined, Icons.handshake, 'Мастера'),
        _NavItem(Icons.chat_bubble_outline, Icons.chat_bubble, 'Чаты'),
        _NavItem(Icons.storefront_outlined, Icons.storefront, 'Каталог'),
        _NavItem(Icons.person_outline, Icons.person, 'Профиль'),
      ];
    }
    return const [
      _NavItem(Icons.dynamic_feed_outlined, Icons.dynamic_feed, 'Заказы'),
      _NavItem(Icons.send_outlined, Icons.send, 'Отклики'),
      _NavItem(Icons.chat_bubble_outline, Icons.chat_bubble, 'Чаты'),
      _NavItem(Icons.shopping_basket_outlined, Icons.shopping_basket, 'Каталог'),
      _NavItem(Icons.person_outline, Icons.person, 'Профиль'),
    ];
  }

  /// Корневой экран (без обёртки навигатора) для конкретной вкладки.
  Widget _rootScreenFor(int index, AppMarketplaceRole role) {
    final isCustomer = role == AppMarketplaceRole.customer;
    if (isCustomer) {
      switch (index) {
        case 0:
          return CustomerProjectsScreen(
            onPublishedNavigateToMasters: () => setState(() => _currentIndex = 1),
          );
        case 1:
          return const CustomerFindMastersScreen();
        case 2:
          return const MessagesHubScreen();
        case 3:
          return const MarketplaceCatalogScreen();
        case 4:
        default:
          return const ProfileScreen(embedded: true);
      }
    }
    switch (index) {
      case 0:
        return const MasterOrdersFeedScreen();
      case 1:
        return const MasterMyBidsScreen();
      case 2:
        return const MessagesHubScreen();
      case 3:
        return const MasterSuppliesCatalogScreen();
      case 4:
      default:
        return const ProfileScreen(embedded: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final roles = context.watch<RoleProvider>();
    _syncRoleTab(roles.activeRole);
    final navItems = _itemsForRole(roles.activeRole);
    final bg = BrandColors.canvas;

    final sidebarWidth =
        _sidebarExpanded ? _expandedSidebarWidth : _collapsedSidebarWidth;

    /// IndexedStack + Navigator на каждую вкладку. Это даёт два эффекта:
    ///   1) push/pop происходят внутри правой контентной зоны, сайдбар остаётся виден;
    ///   2) состояние каждой вкладки (стек роутов, скролл) сохраняется при переключении.
    final tabStack = IndexedStack(
      index: _currentIndex,
      children: List.generate(navItems.length, (i) {
        return _TabNavigator(
          // ValueKey пересоздаётся при смене роли — старые навигаторы заменяются на новые.
          key: ValueKey('${roles.activeRole.name}_$i'),
          builder: (_) => _rootScreenFor(i, roles.activeRole),
        );
      }),
    );

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Row(
          children: [
            _buildSidebar(
              navItems,
              sidebarWidth: sidebarWidth,
              showLabels: _sidebarExpanded,
            ),
            Expanded(child: tabStack),
          ],
        ),
      ),
    );
  }

  /// Сайдбар: пункты строятся из [_itemsForRole].
  Widget _buildSidebar(
    List<_NavItem> navItems, {
    required double sidebarWidth,
    required bool showLabels,
  }) {
    const sidebarBg = BrandColors.milk;
    const borderC = BrandColors.borderSubtle;
    const textMainC = BrandColors.tar;

    return Container(
      width: sidebarWidth,
      decoration: BoxDecoration(
        color: sidebarBg,
        border: const Border(
          right: BorderSide(color: borderC, width: 1),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          if (showLabels)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Приделе',
                      style: pochaevsk(
                        fontSize: 26,
                        color: BrandColors.needlesDark,
                        height: 1.05,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Свернуть меню',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    onPressed: () => setState(() => _sidebarExpanded = false),
                    icon: Icon(Icons.keyboard_arrow_left_rounded, color: textMainC),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                IconButton(
                  tooltip: 'Развернуть меню',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  onPressed: () => setState(() => _sidebarExpanded = true),
                  icon: Icon(Icons.keyboard_arrow_right_rounded, color: textMainC),
                ),
              ],
            ),
          const SizedBox(height: 12),
          const Divider(color: borderC, height: 1),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: List.generate(navItems.length, (index) {
                  final item = navItems[index];
                  final isSelected = _currentIndex == index;
                  return _buildNavTile(
                    item,
                    isSelected,
                    index,
                    showLabels: showLabels,
                  );
                }),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: showLabels ? 14 : 8,
              vertical: 8,
            ),
            child: Consumer<AuthProvider>(
              builder: (context, auth, _) {
                final username = auth.user?.visibleName ?? '';
                return Column(
                  children: [
                    const Divider(color: borderC, height: 1),
                    const SizedBox(height: 14),
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => setState(
                            () => _currentIndex = navItems.length - 1,
                          ),
                      child: Row(
                        mainAxisAlignment: showLabels
                            ? MainAxisAlignment.start
                            : MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: BrandColors.needles,
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
                          if (showLabels) ...[
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
                        ],
                      ),
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

  Widget _buildNavTile(
    _NavItem item,
    bool isSelected,
    int index, {
    required bool showLabels,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: showLabels ? 12 : 8, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _currentIndex = index),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: showLabels ? 12 : 8,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: isSelected ? BrandColors.linen : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Tooltip(
              message: item.label,
              waitDuration: const Duration(milliseconds: 350),
              child: Row(
                mainAxisAlignment: showLabels
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  Icon(
                    isSelected ? item.selectedIcon : item.icon,
                    color: isSelected
                        ? BrandColors.needles
                        : BrandColors.inkFaint,
                    size: 19,
                  ),
                  if (showLabels) ...[
                    const SizedBox(width: 12),
                    Text(
                      item.label,
                      style: BrandUi.inter(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? BrandColors.needlesDark
                            : BrandColors.inkFaint,
                      ),
                    ),
                  ],
                ],
              ),
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

/// Локальный навигатор для одной вкладки сайдбара. Любые `Navigator.of(context).push(...)`
/// внутри корневого экрана попадают в этот навигатор и не перекрывают левый сайдбар.
class _TabNavigator extends StatelessWidget {
  final WidgetBuilder builder;

  const _TabNavigator({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (settings) => MaterialPageRoute(
        builder: builder,
        settings: settings,
      ),
    );
  }
}
