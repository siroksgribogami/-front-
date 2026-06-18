import 'package:flutter/material.dart';
import '../../core/theme/brand_runtime.dart';
import 'package:provider/provider.dart';

import '../../config/brand_colors.dart';
import '../../core/arthouse_scroll_behavior.dart';
import '../../core/theme/brand_ui.dart';
import '../../models/app_marketplace_role.dart';
import '../../providers/role_provider.dart';
import '../marketplace/messages_hub_screen.dart';
import '../marketplace/customer_find_masters_screen.dart';
import '../marketplace/customer_projects_screen.dart';
import '../marketplace/master_my_bids_screen.dart';
import '../marketplace/master_orders_feed_screen.dart';
import '../marketplace/marketplace_catalog_screen.dart';
import '../marketplace/master_supplies_catalog_screen.dart';
import '../profile/profile_screen.dart';

/// Мобильный таб-бар маркетплейса ARTхаус: набор вкладок зависит от активной роли (заказчик / мастер).
class MobileHomeScreen extends StatefulWidget {
  const MobileHomeScreen({super.key});

  @override
  State<MobileHomeScreen> createState() => _MobileHomeScreenState();
}

class _MobileHomeScreenState extends State<MobileHomeScreen> {
  int _currentIndex = 0;
  AppMarketplaceRole? _lastActiveRole;

  /// Сбрасываем вкладку на первую при смене активной роли в профиле.
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

  @override
  Widget build(BuildContext context) {
    final roles = context.watch<RoleProvider>();
    _syncRoleTab(roles.activeRole);

    final isCustomer = roles.activeRole == AppMarketplaceRole.customer;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    final builders = isCustomer
        ? <WidgetBuilder>[
            (_) => CustomerProjectsScreen(
                  onPublishedNavigateToMasters: () => setState(() => _currentIndex = 1),
                ),
            (_) => const CustomerFindMastersScreen(),
            (_) => const MessagesHubScreen(),
            (_) => const MarketplaceCatalogScreen(),
            (_) => const ProfileScreen(embedded: true),
          ]
        : <WidgetBuilder>[
            (_) => const MasterOrdersFeedScreen(),
            (_) => const MasterMyBidsScreen(),
            (_) => const MessagesHubScreen(),
            (_) => const MasterSuppliesCatalogScreen(),
            (_) => const ProfileScreen(embedded: true),
          ];

    final labels = isCustomer
        ? ['Проекты', 'Мастера', 'Чаты', 'Каталог', 'Профиль']
        : ['Заказы', 'Отклики', 'Чаты', 'Каталог', 'Профиль'];

    final iconsOutlined = isCustomer
        ? [
            Icons.folder_open_outlined,
            Icons.handshake_outlined,
            Icons.chat_bubble_outline,
            Icons.storefront_outlined,
            Icons.person_outline,
          ]
        : [
            Icons.dynamic_feed_outlined,
            Icons.send_outlined,
            Icons.chat_bubble_outline,
            Icons.shopping_basket_outlined,
            Icons.person_outline,
          ];
    final iconsFilled = isCustomer
        ? [
            Icons.folder_open,
            Icons.handshake,
            Icons.chat_bubble,
            Icons.storefront,
            Icons.person,
          ]
        : [
            Icons.dynamic_feed,
            Icons.send,
            Icons.chat_bubble,
            Icons.shopping_basket,
            Icons.person,
          ];

    return Scaffold(
      backgroundColor: BrandRuntime.canvas,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _currentIndex,
          children: List.generate(
            labels.length,
            (index) => _LazyTab(
              active: _currentIndex == index,
              builder: builders[index],
            ),
          ),
        ),
      ),
      bottomNavigationBar: RepaintBoundary(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: BrandRuntime.card,
            border: Border(
              top: BorderSide(color: BrandRuntime.border),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: 8,
              right: 8,
              top: 9,
              bottom: bottomPadding + 9,
            ),
            child: Row(
              children: List.generate(labels.length, (i) {
                return _buildNavItem(
                  i,
                  iconsOutlined[i],
                  iconsFilled[i],
                  labels[i],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  /// Нижняя кнопка: иконка + подпись, зона ≥ 48dp по высоте.
  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData selectedIcon,
    String label,
  ) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (_currentIndex == index) return;
              ArthouseHaptics.select();
              setState(() => _currentIndex = index);
            },
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isSelected ? selectedIcon : icon,
                    color: isSelected
                        ? BrandRuntime.needles
                        : BrandRuntime.inkFaint,
                    size: 23,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: BrandUi.inter(
                      fontSize: 10.5,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? BrandColors.needlesDark
                          : BrandRuntime.inkFaint,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LazyTab extends StatefulWidget {
  final bool active;
  final WidgetBuilder builder;

  const _LazyTab({
    required this.active,
    required this.builder,
  });

  @override
  State<_LazyTab> createState() => _LazyTabState();
}

class _LazyTabState extends State<_LazyTab> {
  Widget? _child;

  @override
  void didUpdateWidget(covariant _LazyTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && _child == null) {
      _child = widget.builder(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.active && _child == null) {
      _child = widget.builder(context);
    }
    return _child ?? const SizedBox.shrink();
  }
}
