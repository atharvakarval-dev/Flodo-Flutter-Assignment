import '../entities/task_entity.dart';

abstract class TaskRepository {
  Future<List<TaskEntity>> getTasks();
  Future<void> createTask(TaskEntity task);
  Future<void> updateTask(TaskEntity task);
  Future<void> deleteTask(String id);
  Future<void> saveDraft(Map<String, dynamic> draft);
  Future<Map<String, dynamic>?> getDraft();
  Future<void> clearDraft();
}
