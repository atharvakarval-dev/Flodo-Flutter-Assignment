import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';

class CreateTaskUseCase {
  final TaskRepository repository;

  const CreateTaskUseCase(this.repository);

  Future<void> call(TaskEntity task) async {
    await Future.delayed(const Duration(seconds: 2));
    await repository.createTask(task);
  }
}
