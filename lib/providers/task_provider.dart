import 'package:flutter/foundation.dart';

import '../models/task.dart';
import '../services/apartment_service.dart';
import '../services/task_service.dart';
import '../services/api_service.dart';

class TaskProvider with ChangeNotifier {
  final TaskService _taskService = TaskService();
  final ApartmentService _apartmentService = ApartmentService();

  List<TaskItem> _tasks = [];
  bool _offlineMode = false;
  bool _isLoading = false;
  String? _error;

  List<TaskItem> get tasks => _tasks;
  bool get isLoading => _isLoading;
  bool get offlineMode => _offlineMode;
  String? get error => _error;

  int get completedCount => _tasks.where((t) => t.isDone).length;
  int get remainingCount => _tasks.where((t) => !t.isDone).length;

  Future<void> loadTasks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final rawTasks = await _taskService.getTasks();
      _tasks = rawTasks.map((json) => TaskItem.fromJson(json)).toList();
      _offlineMode = false;
    } on ApiException catch (e) {
      // Backend tasks могут быть временно недоступны — работаем локально.
      _offlineMode = true;
      _error = 'Задачи backend временно недоступны, включен локальный режим';
      if (_tasks.isEmpty) {
        _tasks = _localSeedTasks();
      }
    } catch (_) {
      _offlineMode = true;
      _error = 'Не удалось загрузить задачи, включен локальный режим';
      if (_tasks.isEmpty) {
        _tasks = _localSeedTasks();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createTask({
    required String title,
    String? description,
    DateTime? dueDate,
  }) async {
    if (_offlineMode) {
      final newId = DateTime.now().millisecondsSinceEpoch;
      final local = TaskItem(
        id: newId,
        apartmentId: 0,
        title: title,
        description: description,
        priority: 1,
        status: 'pending',
        dueDate: dueDate,
        createdAt: DateTime.now(),
      );
      _tasks = [local, ..._tasks];
      notifyListeners();
      return true;
    }

    try {
      final apartments = await _apartmentService.getMyApartments();
      if (apartments.isEmpty) {
        _error = 'Сначала создайте помещение, затем добавьте задачу';
        notifyListeners();
        return false;
      }

      final taskData = {
        'apartment_id': apartments.first.id,
        'title': title,
        'description': description,
        'due_date': dueDate?.toIso8601String(),
      };

      final taskJson = await _taskService.createTask(taskData);
      final task = TaskItem.fromJson(taskJson);
      _tasks = [task, ..._tasks];
      _error = null;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Не удалось создать задачу';
      notifyListeners();
      return false;
    }
  }

  Future<void> toggleTask(TaskItem task) async {
    if (_offlineMode) {
      final idx = _tasks.indexWhere((t) => t.id == task.id);
      if (idx != -1) {
        final current = _tasks[idx];
        final toggled = TaskItem(
          id: current.id,
          apartmentId: current.apartmentId,
          title: current.title,
          description: current.description,
          priority: current.priority,
          status: current.isDone ? 'pending' : 'completed',
          dueDate: current.dueDate,
          createdAt: current.createdAt,
        );
        _tasks[idx] = toggled;
        notifyListeners();
      }
      return;
    }

    final nextStatus = task.isDone ? 'pending' : 'completed';
    try {
      final updatedJson = await _taskService.updateTaskStatus(
        task.id,
        nextStatus,
      );
      final updated = TaskItem.fromJson(updatedJson);
      final idx = _tasks.indexWhere((t) => t.id == task.id);
      if (idx != -1) {
        _tasks[idx] = updated;
        notifyListeners();
      }
    } catch (_) {
      // Silent fail for now; UI stays at previous state
    }
  }

  List<TaskItem> _localSeedTasks() {
    return [
      TaskItem(
        id: 1,
        apartmentId: 0,
        title: 'Убрать кухню',
        description: 'Зона: Кухня',
        priority: 1,
        status: 'pending',
        dueDate: DateTime.now().copyWith(hour: 14, minute: 0),
        createdAt: DateTime.now(),
      ),
      TaskItem(
        id: 2,
        apartmentId: 0,
        title: 'Полить цветы',
        description: 'Зона: Гостиная',
        priority: 1,
        status: 'completed',
        dueDate: null,
        createdAt: DateTime.now(),
      ),
    ];
  }
}

