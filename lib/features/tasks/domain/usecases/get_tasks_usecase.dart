import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';

class GetTasksUseCase {
  final TaskRepository repository;

  const GetTasksUseCase(this.repository);

  Future<List<TaskEntity>> call() async {
    return repository.getTasks();
  }
}
