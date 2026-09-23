import 'package:flutter/material.dart';

import '../../config/brand_assets.dart';
import '../../config/brand_colors.dart';
import '../../config/text_theme.dart';
import '../../core/theme/brand_ui.dart';
import '../profile/profile_screen.dart';
import 'marketplace_catalog_screen.dart';

class PridelMarketplaceShell extends StatefulWidget {
  const PridelMarketplaceShell({super.key});

  @override
  State<PridelMarketplaceShell> createState() => _PridelMarketplaceShellState();
}

class _PridelMarketplaceShellState extends State<PridelMarketplaceShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const _HomeTab(),
      const MarketplaceCatalogScreen(),
      const _ArTab(),
      const _CartTab(),
      const ProfileScreen(embedded: true),
    ];
    return Scaffold(
      backgroundColor: BrandColors.canvas,
      body: SafeArea(bottom: false, child: IndexedStack(index: _index, children: pages)),
      bottomNavigationBar: _BottomNavigation(index: _index, onChanged: (value) => setState(() => _index = value)),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
          sliver: SliverToBoxAdapter(
            child: Row(children: [
              Image.asset(BrandAssets.frameVertical, width: 38, height: 38, fit: BoxFit.cover),
              const SizedBox(width: 10),
              Text('Приялье', style: pochaevsk(fontSize: 26, color: BrandColors.tar)),
              const Spacer(),
              IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded)),
            ]),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Найти вещь для дома',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: BrandColors.milk,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          sliver: SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(colors: [BrandColors.needlesDeep, BrandColors.needles]),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Примерьте до покупки', style: pochaevsk(fontSize: 30, color: BrandColors.onNeedles)),
                const SizedBox(height: 8),
                Text('Поставьте мебель в свою комнату через AR и проверьте масштаб.', style: BrandUi.inter(fontSize: 14, color: BrandColors.onNeedles.withOpacity(.82))),
                const SizedBox(height: 18),
                FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.view_in_ar_rounded), label: const Text('Открыть AR')),
              ]),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          sliver: SliverList(delegate: SliverChildListDelegate([
            Text('Выбор для дома', style: pochaevsk(fontSize: 28, color: BrandColors.tar)),
            const SizedBox(height: 12),
            const _ProductPreview(title: 'Кресло «Таёжное»', price: '24 900 ₽', image: BrandAssets.frameVertical),
            const SizedBox(height: 12),
            const _ProductPreview(title: 'Лампа «Сибирь»', price: '8 400 ₽', image: BrandAssets.logoPriDele),
          ])),
        ),
      ],
    );
  }
}

class _ProductPreview extends StatelessWidget {
  const _ProductPreview({required this.title, required this.price, required this.image});
  final String title;
  final String price;
  final String image;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: BrandColors.milk, borderRadius: BorderRadius.circular(20)),
      child: Row(children: [
        ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.asset(image, width: 82, height: 82, fit: BoxFit.cover)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: pochaevsk(fontSize: 19, color: BrandColors.tar)),
          const SizedBox(height: 8),
          Text(price, style: BrandUi.inter(fontSize: 15, fontWeight: FontWeight.w700, color: BrandColors.surik)),
        ])),
        const Icon(Icons.chevron_right_rounded),
      ]),
    );
  }
}

class _ArTab extends StatelessWidget {
  const _ArTab();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [BrandColors.needlesDeep, BrandColors.needles])),
      padding: const EdgeInsets.fromLTRB(24, 42, 24, 30),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Spacer(),
        const Icon(Icons.view_in_ar_rounded, size: 58, color: BrandColors.dawn),
        const SizedBox(height: 22),
        Text('Вещь должна подходить вашему дому.', style: pochaevsk(fontSize: 40, color: BrandColors.onNeedles, height: 1)),
        const SizedBox(height: 14),
        Text('Наведите камеру на пол, выберите товар и разместите его в реальном масштабе.', style: BrandUi.inter(fontSize: 16, color: BrandColors.onNeedles.withOpacity(.82), height: 1.45)),
        const SizedBox(height: 28),
        SizedBox(width: double.infinity, child: FilledButton(onPressed: () {}, child: const Text('Запустить AR'))),
        const Spacer(),
      ]),
    );
  }
}

class _CartTab extends StatelessWidget {
  const _CartTab();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 100),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Корзина', style: pochaevsk(fontSize: 38, color: BrandColors.tar)),
        const SizedBox(height: 18),
        Container(width: double.infinity, padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: BrandColors.milk, borderRadius: BorderRadius.circular(22)), child: Column(children: [
          const Icon(Icons.shopping_bag_outlined, size: 46, color: BrandColors.clay),
          const SizedBox(height: 12),
          Text('Здесь пока пусто', style: pochaevsk(fontSize: 24, color: BrandColors.tar)),
          const SizedBox(height: 8),
          Text('Добавляйте понравившиеся товары после примерки в AR.', textAlign: TextAlign.center, style: BrandUi.inter(fontSize: 14, color: BrandColors.inkSoft)),
        ])),
      ]),
    );
  }
}

class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation({required this.index, required this.onChanged});
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const labels = ['Главная', 'Каталог', 'AR', 'Корзина', 'Профиль'];
    const icons = <IconData>[Icons.home_outlined, Icons.grid_view_rounded, Icons.view_in_ar_rounded, Icons.shopping_bag_outlined, Icons.person_outline_rounded];
    return DecoratedBox(
      decoration: BoxDecoration(color: BrandColors.milk, border: Border(top: BorderSide(color: BrandColors.borderSubtle))),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + 8, top: 8),
        child: Row(
          children: List.generate(
            labels.length,
            (i) => Expanded(
              child: Semantics(
                button: true,
                label: labels[i],
                selected: index == i,
                child: InkWell(
                  onTap: () => onChanged(i),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icons[i], color: index == i ? BrandColors.surik : BrandColors.inkFaint),
                      const SizedBox(height: 4),
                      Text(
                        labels[i],
                        style: BrandUi.inter(
                          fontSize: 11,
                          fontWeight: index == i ? FontWeight.w700 : FontWeight.w400,
                          color: index == i ? BrandColors.surik : BrandColors.inkFaint,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
