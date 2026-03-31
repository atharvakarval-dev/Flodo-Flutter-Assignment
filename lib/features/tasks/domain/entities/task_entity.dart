import 'package:flutter/material.dart';

enum TaskGroup {
  work,
  personal,
  study,
  other;

  String get label {
    switch (this) {
      case TaskGroup.work: return 'Work';
      case TaskGroup.personal: return 'Personal';
      case TaskGroup.study: return 'Study';
      case TaskGroup.other: return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case TaskGroup.work: return Icons.work_rounded;
      case TaskGroup.personal: return Icons.person_rounded;
      case TaskGroup.study: return Icons.menu_book_rounded;
      case TaskGroup.other: return Icons.category_rounded;
    }
  }

  Color get iconColor {
    switch (this) {
      case TaskGroup.work: return const Color(0xFFF478B8);
      case TaskGroup.personal: return const Color(0xFF9260F4);
      case TaskGroup.study: return const Color(0xFFFF9142);
      case TaskGroup.other: return const Color(0xFFFFD12E);
    }
  }

  Color get bgColor {
    switch (this) {
      case TaskGroup.work: return const Color(0xFFFFE4F2);
      case TaskGroup.personal: return const Color(0xFFEDE4FF);
      case TaskGroup.study: return const Color(0xFFFFE6D5);
      case TaskGroup.other: return const Color(0xFFFFF6D5);
    }
  }
}

enum TaskStatus {
  todo,
  inProgress,
  done;

  String get label {
    switch (this) {
      case TaskStatus.todo: return 'To-Do';
      case TaskStatus.inProgress: return 'In Progress';
      case TaskStatus.done: return 'Done';
    }
  }
}

enum TaskPriority {
  low,
  medium,
  high;

  String get label {
    switch (this) {
      case TaskPriority.low: return 'Low';
      case TaskPriority.medium: return 'Medium';
      case TaskPriority.high: return 'High';
    }
  }
}

class TaskEntity {
  final String id;
  final String title;
  final String description;
  final TaskStatus status;
  final TaskPriority priority;
  final TaskGroup group;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? blockedById;

  const TaskEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    this.group = TaskGroup.work,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
    this.blockedById,
  });

  bool get isBlocked => blockedById != null;

  TaskEntity copyWith({
    String? id,
    String? title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    TaskGroup? group,
    DateTime? dueDate,
    bool clearDueDate = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? blockedById,
    bool clearBlockedBy = false,
  }) {
    return TaskEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      group: group ?? this.group,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      blockedById: clearBlockedBy ? null : (blockedById ?? this.blockedById),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskEntity && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
