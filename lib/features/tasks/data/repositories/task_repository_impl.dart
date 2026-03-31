import '../../domain/entities/task_entity.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_local_datasource.dart';
import '../models/task_model.dart';

class TaskRepositoryImpl implements TaskRepository {
  final TaskLocalDataSource localDataSource;

  TaskRepositoryImpl(this.localDataSource);

  @override
  Future<List<TaskEntity>> getTasks() async {
    return localDataSource.getTasks();
  }

  @override
  Future<void> createTask(TaskEntity task) async {
    final tasks = await localDataSource.getTasks();
    final model = TaskModel.fromEntity(task);
    tasks.add(model);
    await localDataSource.saveTasks(tasks);
  }

  @override
  Future<void> updateTask(TaskEntity task) async {
    final tasks = await localDataSource.getTasks();
    final index = tasks.indexWhere((t) => t.id == task.id);
    if (index >= 0) {
      tasks[index] = TaskModel.fromEntity(task);
      await localDataSource.saveTasks(tasks);
    }
  }

  @override
  Future<void> deleteTask(String id) async {
    final tasks = await localDataSource.getTasks();
    tasks.removeWhere((t) => t.id == id);
    await localDataSource.saveTasks(tasks);
  }

  @override
  Future<void> saveDraft(Map<String, dynamic> draft) async {
    await localDataSource.saveDraft(draft);
  }

  @override
  Future<Map<String, dynamic>?> getDraft() async {
    return localDataSource.getDraft();
  }

  @override
  Future<void> clearDraft() async {
    await localDataSource.clearDraft();
  }
}
