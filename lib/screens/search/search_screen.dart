import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../core/theme/app_text_style.dart';
import '../chat/chat_screen.dart';

/// Экран поиска — специалисты, услуги, поиск по городу.
class SearchScreen extends StatefulWidget {
  final bool embedded;
  const SearchScreen({super.key, this.embedded = false});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  String _selectedCategory = 'all';

  final List<Map<String, dynamic>> _categories = [
    {'id': 'all', 'name': 'Все', 'icon': Icons.apps},
    {'id': 'specialists', 'name': 'Специалисты', 'icon': Icons.engineering},
    {'id': 'shops', 'name': 'Магазины', 'icon': Icons.store},
    {'id': 'services', 'name': 'Услуги', 'icon': Icons.home_repair_service},
    {'id': 'furniture', 'name': 'Мебель', 'icon': Icons.chair},
  ];

  final List<Map<String, dynamic>> _popularItems = [
    {
      'type': 'specialist',
      'name': 'Иван Петров',
      'category': 'Сантехник',
      'rating': 4.9,
      'reviews': 127,
      'price': 'от 2000 ₽',
    },
    {
      'type': 'shop',
      'name': 'ДомСтрой',
      'category': 'Стройматериалы',
      'rating': 4.7,
      'reviews': 543,
      'price': '',
    },
    {
      'type': 'specialist',
      'name': 'Алексей Смирнов',
      'category': 'Электрик',
      'rating': 4.8,
      'reviews': 89,
      'price': 'от 1500 ₽',
    },
    {
      'type': 'service',
      'name': 'Клининг Эксперт',
      'category': 'Уборка',
      'rating': 4.6,
      'reviews': 234,
      'price': 'от 3000 ₽',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _openChat() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ChatScreen()),
    );
  }

  void _showSpecialistProfile(BuildContext context, Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.darkCard
                : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppTheme.textHint,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                item['name'] as String,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item['category'] as String,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Чем занимается',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item['type'] == 'specialist'
                    ? 'Профессиональные услуги по своей специализации. Опыт и отзывы ниже.'
                    : 'Услуги и товары в данной категории.',
                style: const TextStyle(fontSize: 15, height: 1.4),
              ),
              const SizedBox(height: 20),
              const Text(
                'Отзывы',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    '${item['rating']} (${item['reviews']} отзывов)',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _openChat();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Связаться'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? AppTheme.darkBackground : AppTheme.backgroundColor;
    final cardBg = isDark ? AppTheme.darkCard : Colors.white;
    final textMain = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: widget.embedded
          ? null
          : AppBar(title: const Text('Поиск')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.embedded)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 36, 20, 0),
              child: Text(
                'Специалисты',
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
          // Город
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: TextField(
              controller: _cityController,
              decoration: InputDecoration(
                hintText: 'Город',
                hintStyle: const TextStyle(color: AppTheme.textHint, fontSize: 14),
                prefixIcon: const Icon(Icons.location_on_outlined, color: AppTheme.textHint, size: 22),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: cardBg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                isDense: true,
              ),
              style: TextStyle(fontSize: 15, color: textMain),
            ),
          ),
          // Поле поиска (специалисты, услуги)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Специалист, услуга, магазин...',
                  hintStyle: const TextStyle(color: AppTheme.textHint, fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: AppTheme.textHint),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppTheme.textHint),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                onChanged: (value) => setState(() {}),
              ),
            ),
          ),
          // Категории
          SizedBox(
            height: 50,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category['id'];
                return FilterChip(
                  selected: isSelected,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        category['icon'] as IconData,
                        size: 18,
                        color: isSelected
                            ? AppTheme.primaryColor
                            : AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(category['name']),
                    ],
                  ),
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = category['id'];
                    });
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Результаты
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Text(
                  'Популярное',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                ..._popularItems
                    .where((item) =>
                        _selectedCategory == 'all' ||
                        _matchesCategory(item, _selectedCategory))
                    .map((item) => _buildItemCard(context, item)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _matchesCategory(Map<String, dynamic> item, String category) {
    switch (category) {
      case 'specialists':
        return item['type'] == 'specialist';
      case 'shops':
        return item['type'] == 'shop';
      case 'services':
        return item['type'] == 'service';
      default:
        return true;
    }
  }

  Widget _buildItemCard(BuildContext context, Map<String, dynamic> item) {
    IconData typeIcon;
    Color typeColor;

    switch (item['type']) {
      case 'specialist':
        typeIcon = Icons.person;
        typeColor = AppTheme.primaryColor;
        break;
      case 'shop':
        typeIcon = Icons.store;
        typeColor = AppTheme.secondaryColor;
        break;
      case 'service':
        typeIcon = Icons.home_repair_service;
        typeColor = AppTheme.accentColor;
        break;
      default:
        typeIcon = Icons.help;
        typeColor = AppTheme.textSecondary;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showSpecialistProfile(context, item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(typeIcon, color: typeColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['category'],
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${item['rating']}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${item['reviews']} отзывов)',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (item['price'].toString().isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    item['price'],
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _openChat,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    child: const Text('Связаться'),
                  ),
                ],
              ),
          ],
        ),
      ),
      ),
    );
  }
}
