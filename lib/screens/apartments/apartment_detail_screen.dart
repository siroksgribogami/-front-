import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/apartment.dart';
import '../../providers/apartment_provider.dart';
import '../../config/app_theme.dart';
import 'apartment_form_screen.dart';

/// Экран детальной информации о квартире
class ApartmentDetailScreen extends StatelessWidget {
  final Apartment apartment;

  const ApartmentDetailScreen({
    super.key,
    required this.apartment,
  });

  void _editApartment(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ApartmentFormScreen(apartment: apartment),
      ),
    );
  }

  Future<void> _deleteApartment(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить квартиру?'),
        content: Text('Вы уверены, что хотите удалить "${apartment.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final provider = context.read<ApartmentProvider>();
      final success = await provider.deleteApartment(apartment.id);
      
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Квартира удалена'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context);
      } else if (context.mounted && provider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error!),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Квартира'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _editApartment(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _deleteApartment(context),
            color: AppTheme.errorColor,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Основная информация
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.home_rounded,
                          size: 32,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              apartment.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            if (apartment.address != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: 16,
                                    color: AppTheme.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      apartment.address!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: AppTheme.textSecondary,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Характеристики
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Характеристики',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    context,
                    icon: Icons.square_foot,
                    label: 'Площадь',
                    value: apartment.squareMeters != null
                        ? '${apartment.squareMeters} м²'
                        : '—',
                  ),
                  _buildInfoRow(
                    context,
                    icon: Icons.height,
                    label: 'Высота потолков',
                    value: apartment.ceilingHeight != null
                        ? '${apartment.ceilingHeight} м'
                        : '—',
                  ),
                  _buildInfoRow(
                    context,
                    icon: Icons.meeting_room_outlined,
                    label: 'Комнат',
                    value: apartment.roomsCount?.toString() ?? '—',
                  ),
                  _buildInfoRow(
                    context,
                    icon: Icons.layers_outlined,
                    label: 'Этажей',
                    value: apartment.floors?.toString() ?? '—',
                    showDivider: false,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Даты
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Информация',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    context,
                    icon: Icons.calendar_today_outlined,
                    label: 'Создано',
                    value: DateFormat('dd MMMM yyyy, HH:mm', 'ru')
                        .format(apartment.createdAt),
                  ),
                  _buildInfoRow(
                    context,
                    icon: Icons.update_outlined,
                    label: 'Обновлено',
                    value: apartment.updatedAt != null
                        ? DateFormat('dd MMMM yyyy, HH:mm', 'ru')
                            .format(apartment.updatedAt!)
                        : '—',
                    showDivider: false,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppTheme.textSecondary),
              const SizedBox(width: 12),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
              const Spacer(),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }
}
