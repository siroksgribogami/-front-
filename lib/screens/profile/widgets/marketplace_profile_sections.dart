import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_text_style.dart';
import '../../../core/theme/marketplace_colors.dart';
import '../../../models/app_marketplace_role.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/role_provider.dart';
import '../master_portfolio_screen.dart';

/// Карточка текущей роли маркетплейса (только отображение).
/// Роль выбирается один раз на регистрации и больше не меняется.
class MarketplaceRoleCard extends StatelessWidget {
  const MarketplaceRoleCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RoleProvider>(
      builder: (context, roles, _) {
        final card = MarketplaceColors.cardFor(context);
        final textPrimary = MarketplaceColors.textPrimaryFor(context);
        final textSecondary = MarketplaceColors.textSecondaryFor(context);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: MarketplaceColors.textMutedFor(context).withOpacity(0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.35 : 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ваша роль',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              _CurrentRoleBadge(role: roles.activeRole),
            ],
          ),
        );
      },
    );
  }
}

class _CurrentRoleBadge extends StatelessWidget {
  final AppMarketplaceRole role;

  const _CurrentRoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final isCustomer = role == AppMarketplaceRole.customer;
    final textPrimary = MarketplaceColors.textPrimaryFor(context);
    final surface = MarketplaceColors.surfaceFor(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          MarketplaceColors.bluePrimary.withOpacity(0.16),
          surface,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: MarketplaceColors.bluePrimary.withOpacity(0.45),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isCustomer ? Icons.person_outline : Icons.handyman_outlined,
            color: MarketplaceColors.bluePrimary,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isCustomer ? 'Вы заказчик' : 'Вы мастер',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Блок личного кабинета заказчика.
class MarketplaceCustomerSection extends StatefulWidget {
  const MarketplaceCustomerSection({super.key});

  @override
  State<MarketplaceCustomerSection> createState() =>
      _MarketplaceCustomerSectionState();
}

class _MarketplaceCustomerSectionState
    extends State<MarketplaceCustomerSection> {
  // Кэшируем Future один раз — иначе FutureBuilder заново дёргает
  // SharedPreferences на каждый rebuild (что ощутимо на A54 и подобных).
  late final Future<String> _cityFuture = _cityFromPrefs();

  static Future<String> _cityFromPrefs() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('arthouse_city') ?? '';
  }

  static String _premiseRu(String? code) {
    switch (code) {
      case 'apartment':
        return 'Квартира';
      case 'house':
        return 'Дом';
      case 'office':
        return 'Офис';
      case 'commerce':
        return 'Склад / коммерция';
      case 'hotel':
        return 'Апартаменты';
      default:
        return 'Тип объекта не указан';
    }
  }

  @override
  Widget build(BuildContext context) {
    const rooms = ['Гостиная', 'Кухня', 'Санузел'];
    const history = ['Косметика гостиной — завершён', 'Электрика — в работе'];

    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final userName = auth.user?.visibleName ?? 'Профиль';
        final premise = _premiseRu(auth.premiseType);
        final cityFuture = _cityFuture;
        final card = MarketplaceColors.cardFor(context);
        final textPrimary = MarketplaceColors.textPrimaryFor(context);
        final textSecondary = MarketplaceColors.textSecondaryFor(context);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: MarketplaceColors.textMutedFor(context).withOpacity(0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.35 : 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Заказчик',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _line(context, Icons.badge_outlined, 'Имя в объявлениях', userName),
              _line(context, Icons.apartment_outlined, 'Тип объекта', premise),
              FutureBuilder<String>(
                future: cityFuture,
                builder: (context, snap) {
                  final city = snap.data;
                  final line = (city != null && city.isNotEmpty)
                      ? city
                      : 'Город не указан — будет использован при поиске мастеров';
                  return _line(context, Icons.place_outlined, 'Город / регион', line);
                },
              ),
              const SizedBox(height: 12),
              Text(
                'Помещения',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: rooms
                    .map(
                      (r) => Chip(
                        label: Text(r),
                        backgroundColor: MarketplaceColors.surfaceFor(context).withOpacity(0.65),
                        side: BorderSide(
                          color: MarketplaceColors.textMutedFor(context).withOpacity(0.22),
                        ),
                        labelStyle: TextStyle(color: textPrimary, fontSize: 12),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              Text(
                'История проектов',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              ...history.map(
                (h) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        h.contains('заверш')
                            ? Icons.check_circle_outline
                            : Icons.more_horiz,
                        size: 18,
                        color: h.contains('заверш')
                            ? MarketplaceColors.successService
                            : MarketplaceColors.bluePrimary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          h,
                          style: TextStyle(color: textPrimary, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _line(BuildContext context, IconData icon, String label, String value) {
    final textPrimary = MarketplaceColors.textPrimaryFor(context);
    final textSecondary = MarketplaceColors.textSecondaryFor(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Блок личного кабинета мастера.
class MarketplaceMasterSection extends StatelessWidget {
  const MarketplaceMasterSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final name = auth.user?.visibleName ?? 'Профиль';
        final mode = auth.accountMode ?? '';
        final statusLine = mode == 'master'
            ? 'Мастер · данные из опроса регистрации'
            : 'Исполнитель';

        final card = MarketplaceColors.cardFor(context);
        final textPrimary = MarketplaceColors.textPrimaryFor(context);
        final textSecondary = MarketplaceColors.textSecondaryFor(context);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: MarketplaceColors.textMutedFor(context).withOpacity(0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.35 : 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Мастер',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              _line(context, Icons.person_outline, 'Отображаемое имя', name),
              _line(context, Icons.workspace_premium_outlined, 'Рейтинг', 'Появится после подключения отзывов'),
              _line(context, Icons.business_center_outlined, 'Статус', statusLine),
              const SizedBox(height: 4),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => const MasterPortfolioScreen(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.photo_library_outlined,
                          size: 20,
                          color: textSecondary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Портфолио',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Открыть галерею работ',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: textSecondary,
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _line(BuildContext context, IconData icon, String label, String value) {
    final textPrimary = MarketplaceColors.textPrimaryFor(context);
    final textSecondary = MarketplaceColors.textSecondaryFor(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
