import 'package:flutter/foundation.dart';
import '../models/apartment.dart';
import '../services/apartment_service.dart';
import '../services/api_service.dart';

/// Состояние загрузки квартир
enum ApartmentLoadState {
  initial,
  loading,
  loaded,
  error,
}

/// Провайдер для работы с квартирами
class ApartmentProvider with ChangeNotifier {
  final ApartmentService _service = ApartmentService();

  ApartmentLoadState _state = ApartmentLoadState.initial;
  List<Apartment> _apartments = [];
  Apartment? _selectedApartment;
  String? _error;
  bool _isSubmitting = false;

  ApartmentLoadState get state => _state;
  List<Apartment> get apartments => _apartments;
  Apartment? get selectedApartment => _selectedApartment;
  String? get error => _error;
  bool get isLoading => _state == ApartmentLoadState.loading;
  bool get isSubmitting => _isSubmitting;

  /// Загрузить все квартиры пользователя
  Future<void> loadApartments() async {
    _setState(ApartmentLoadState.loading);
    _error = null;

    try {
      _apartments = await _service.getMyApartments();
      _setState(ApartmentLoadState.loaded);
    } on ApiException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError('Не удалось загрузить квартиры');
    }
  }

  /// Загрузить квартиру по ID
  Future<void> loadApartment(int id) async {
    _setState(ApartmentLoadState.loading);
    _error = null;

    try {
      _selectedApartment = await _service.getApartment(id);
      _setState(ApartmentLoadState.loaded);
    } on ApiException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError('Не удалось загрузить квартиру');
    }
  }

  /// Создать квартиру
  Future<Apartment?> createApartment({
    required String name,
    double? ceilingHeight,
    double? squareMeters,
    int? floors,
    int? roomsCount,
    String? address,
  }) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      final data = ApartmentCreate(
        name: name,
        ceilingHeight: ceilingHeight,
        squareMeters: squareMeters,
        floors: floors,
        roomsCount: roomsCount,
        address: address,
      );

      final apartment = await _service.createApartment(data);
      _apartments.insert(0, apartment);
      _isSubmitting = false;
      notifyListeners();
      return apartment;
    } on ApiException catch (e) {
      _error = e.message;
      _isSubmitting = false;
      notifyListeners();
      return null;
    } catch (e) {
      _error = 'Не удалось создать квартиру';
      _isSubmitting = false;
      notifyListeners();
      return null;
    }
  }

  /// Обновить квартиру
  Future<Apartment?> updateApartment({
    required int id,
    String? name,
    double? ceilingHeight,
    double? squareMeters,
    int? floors,
    int? roomsCount,
    String? address,
  }) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      final data = ApartmentUpdate(
        name: name,
        ceilingHeight: ceilingHeight,
        squareMeters: squareMeters,
        floors: floors,
        roomsCount: roomsCount,
        address: address,
      );

      final apartment = await _service.updateApartment(id, data);
      
      // Обновляем в списке
      final index = _apartments.indexWhere((a) => a.id == id);
      if (index != -1) {
        _apartments[index] = apartment;
      }
      
      // Обновляем выбранную квартиру
      if (_selectedApartment?.id == id) {
        _selectedApartment = apartment;
      }

      _isSubmitting = false;
      notifyListeners();
      return apartment;
    } on ApiException catch (e) {
      _error = e.message;
      _isSubmitting = false;
      notifyListeners();
      return null;
    } catch (e) {
      _error = 'Не удалось обновить квартиру';
      _isSubmitting = false;
      notifyListeners();
      return null;
    }
  }

  /// Удалить квартиру
  Future<bool> deleteApartment(int id) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      await _service.deleteApartment(id);
      _apartments.removeWhere((a) => a.id == id);
      
      if (_selectedApartment?.id == id) {
        _selectedApartment = null;
      }

      _isSubmitting = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isSubmitting = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Не удалось удалить квартиру';
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  /// Выбрать квартиру
  void selectApartment(Apartment apartment) {
    _selectedApartment = apartment;
    notifyListeners();
  }

  /// Очистить выбор
  void clearSelection() {
    _selectedApartment = null;
    notifyListeners();
  }

  /// Очистить ошибку
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Сбросить состояние (при выходе)
  void reset() {
    _apartments = [];
    _selectedApartment = null;
    _error = null;
    _state = ApartmentLoadState.initial;
    notifyListeners();
  }

  void _setState(ApartmentLoadState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setError(String message) {
    _error = message;
    _state = ApartmentLoadState.error;
    notifyListeners();
  }
}
