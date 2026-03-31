import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';

class UpdateTaskUseCase {
  final TaskRepository repository;

  const UpdateTaskUseCase(this.repository);

  Future<void> call(TaskEntity task) async {
    await Future.delayed(const Duration(seconds: 2));
    await repository.updateTask(task);
  }
}
