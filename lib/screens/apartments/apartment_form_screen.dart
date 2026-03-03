import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/apartment.dart';
import '../../providers/apartment_provider.dart';
import '../../config/app_theme.dart';

/// Экран создания/редактирования квартиры
class ApartmentFormScreen extends StatefulWidget {
  final Apartment? apartment;

  const ApartmentFormScreen({
    super.key,
    this.apartment,
  });

  @override
  State<ApartmentFormScreen> createState() => _ApartmentFormScreenState();
}

class _ApartmentFormScreenState extends State<ApartmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _squareMetersController;
  late final TextEditingController _ceilingHeightController;
  late final TextEditingController _floorsController;
  late final TextEditingController _roomsCountController;

  bool get _isEditing => widget.apartment != null;

  @override
  void initState() {
    super.initState();
    final a = widget.apartment;
    _nameController = TextEditingController(text: a?.name ?? '');
    _addressController = TextEditingController(text: a?.address ?? '');
    _squareMetersController = TextEditingController(
      text: a?.squareMeters?.toString() ?? '',
    );
    _ceilingHeightController = TextEditingController(
      text: a?.ceilingHeight?.toString() ?? '',
    );
    _floorsController = TextEditingController(
      text: a?.floors?.toString() ?? '',
    );
    _roomsCountController = TextEditingController(
      text: a?.roomsCount?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _squareMetersController.dispose();
    _ceilingHeightController.dispose();
    _floorsController.dispose();
    _roomsCountController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<ApartmentProvider>();

    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    final squareMeters = double.tryParse(_squareMetersController.text);
    final ceilingHeight = double.tryParse(_ceilingHeightController.text);
    final floors = int.tryParse(_floorsController.text);
    final roomsCount = int.tryParse(_roomsCountController.text);

    dynamic result;

    if (_isEditing) {
      result = await provider.updateApartment(
        id: widget.apartment!.id,
        name: name,
        address: address.isNotEmpty ? address : null,
        squareMeters: squareMeters,
        ceilingHeight: ceilingHeight,
        floors: floors,
        roomsCount: roomsCount,
      );
    } else {
      result = await provider.createApartment(
        name: name,
        address: address.isNotEmpty ? address : null,
        squareMeters: squareMeters,
        ceilingHeight: ceilingHeight,
        floors: floors,
        roomsCount: roomsCount,
      );
    }

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? 'Квартира обновлена' : 'Квартира создана',
          ),
          backgroundColor: AppTheme.successColor,
        ),
      );
      Navigator.pop(context);
    } else if (mounted && provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error!),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Редактирование' : 'Новая квартира'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Название
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Название *',
                hintText: 'Например: Квартира на Ленина',
                prefixIcon: Icon(Icons.home_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Введите название';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Адрес
            TextFormField(
              controller: _addressController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Адрес',
                hintText: 'Город, улица, дом, квартира',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 24),

            // Разделитель
            Text(
              'Характеристики',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: 16),

            // Площадь и Высота потолков в ряд
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _squareMetersController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Площадь (м²)',
                      prefixIcon: Icon(Icons.square_foot),
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final num = double.tryParse(value);
                        if (num == null || num < 1 || num > 1000) {
                          return '1-1000';
                        }
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _ceilingHeightController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Потолки (м)',
                      prefixIcon: Icon(Icons.height),
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final num = double.tryParse(value);
                        if (num == null || num < 1 || num > 10) {
                          return '1-10';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Комнаты и Этажи в ряд
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _roomsCountController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Комнат',
                      prefixIcon: Icon(Icons.meeting_room_outlined),
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final num = int.tryParse(value);
                        if (num == null || num < 1 || num > 20) {
                          return '1-20';
                        }
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _floorsController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Этажей',
                      prefixIcon: Icon(Icons.layers_outlined),
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final num = int.tryParse(value);
                        if (num == null || num < 1 || num > 3) {
                          return '1-3';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Кнопка сохранения
            Consumer<ApartmentProvider>(
              builder: (context, provider, _) {
                return ElevatedButton(
                  onPressed: provider.isSubmitting ? null : _handleSubmit,
                  child: provider.isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_isEditing ? 'Сохранить' : 'Создать'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
