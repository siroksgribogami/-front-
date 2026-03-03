import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/apartment.dart';
import '../../providers/apartment_provider.dart';
import '../../config/app_theme.dart';
import 'apartment_form_screen.dart';
import 'apartment_detail_screen.dart';

/// Экран списка квартир
class ApartmentsListScreen extends StatefulWidget {
  const ApartmentsListScreen({super.key});

  @override
  State<ApartmentsListScreen> createState() => _ApartmentsListScreenState();
}

class _ApartmentsListScreenState extends State<ApartmentsListScreen> {
  @override
  void initState() {
    super.initState();
    // Загружаем квартиры при открытии экрана
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ApartmentProvider>().loadApartments();
    });
  }

  Future<void> _refreshApartments() async {
    await context.read<ApartmentProvider>().loadApartments();
  }

  void _openApartmentForm([Apartment? apartment]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ApartmentFormScreen(apartment: apartment),
      ),
    ).then((_) => _refreshApartments());
  }

  void _openApartmentDetail(Apartment apartment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ApartmentDetailScreen(apartment: apartment),
      ),
    ).then((_) => _refreshApartments());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои квартиры'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshApartments,
          ),
        ],
      ),
      body: Consumer<ApartmentProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.apartments.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.apartments.isEmpty) {
            return _buildErrorState(provider.error!);
          }

          if (provider.apartments.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: _refreshApartments,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.apartments.length,
              itemBuilder: (context, index) {
                final apartment = provider.apartments[index];
                return _ApartmentCard(
                  apartment: apartment,
                  onTap: () => _openApartmentDetail(apartment),
                  onEdit: () => _openApartmentForm(apartment),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openApartmentForm(),
        icon: const Icon(Icons.add),
        label: const Text('Добавить'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.apartment_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Нет квартир',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Добавьте первую квартиру',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textHint,
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _openApartmentForm(),
            icon: const Icon(Icons.add),
            label: const Text('Добавить квартиру'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Ошибка загрузки',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshApartments,
              icon: const Icon(Icons.refresh),
              label: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Карточка квартиры
class _ApartmentCard extends StatelessWidget {
  final Apartment apartment;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const _ApartmentCard({
    required this.apartment,
    required this.onTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.home_outlined,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          apartment.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        if (apartment.address != null)
                          Text(
                            apartment.address!,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: onEdit,
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (apartment.squareMeters != null)
                    _InfoChip(
                      icon: Icons.square_foot,
                      label: '${apartment.squareMeters} м²',
                    ),
                  if (apartment.roomsCount != null)
                    _InfoChip(
                      icon: Icons.meeting_room_outlined,
                      label: '${apartment.roomsCount} комн.',
                    ),
                  if (apartment.ceilingHeight != null)
                    _InfoChip(
                      icon: Icons.height,
                      label: '${apartment.ceilingHeight} м',
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Создано: ${DateFormat('dd.MM.yyyy').format(apartment.createdAt)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textHint,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}
