class TaskItem {
  final int id;
  final int apartmentId;
  final String title;
  final String? description;
  final int priority;
  final String status;
  final DateTime? dueDate;
  final DateTime createdAt;

  const TaskItem({
    required this.id,
    required this.apartmentId,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    required this.dueDate,
    required this.createdAt,
  });

  bool get isDone => status == 'completed';

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      id: json['id'] as int,
      apartmentId: json['apartment_id'] as int,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      priority: (json['priority'] as num?)?.toInt() ?? 1,
      status: json['status'] as String? ?? 'pending',
      dueDate: json['due_date'] != null
          ? DateTime.tryParse(json['due_date'] as String)
          : null,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

