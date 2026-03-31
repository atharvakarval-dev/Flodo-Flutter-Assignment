import '../repositories/task_repository.dart';

class DeleteTaskUseCase {
  final TaskRepository repository;

  const DeleteTaskUseCase(this.repository);

  Future<void> call(String id) async {
    await repository.deleteTask(id);
  }
}
