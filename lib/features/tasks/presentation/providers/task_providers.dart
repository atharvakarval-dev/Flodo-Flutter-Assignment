import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/datasources/task_local_datasource.dart';
import '../../data/repositories/task_repository_impl.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/usecases/create_task_usecase.dart';
import '../../domain/usecases/delete_task_usecase.dart';
import '../../domain/usecases/get_tasks_usecase.dart';
import '../../domain/usecases/update_task_usecase.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences not initialized');
});

final taskLocalDataSourceProvider = Provider<TaskLocalDataSource>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return TaskLocalDataSourceImpl(prefs);
});

final taskRepositoryProvider = Provider((ref) {
  final dataSource = ref.watch(taskLocalDataSourceProvider);
  return TaskRepositoryImpl(dataSource);
});

final getTasksUseCaseProvider = Provider((ref) {
  return GetTasksUseCase(ref.watch(taskRepositoryProvider));
});

final createTaskUseCaseProvider = Provider((ref) {
  return CreateTaskUseCase(ref.watch(taskRepositoryProvider));
});

final updateTaskUseCaseProvider = Provider((ref) {
  return UpdateTaskUseCase(ref.watch(taskRepositoryProvider));
});

final deleteTaskUseCaseProvider = Provider((ref) {
  return DeleteTaskUseCase(ref.watch(taskRepositoryProvider));
});

class TasksNotifier extends AsyncNotifier<List<TaskEntity>> {
  @override
  Future<List<TaskEntity>> build() async {
    return ref.read(getTasksUseCaseProvider).call();
  }

  Future<void> createTask(TaskEntity task) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(createTaskUseCaseProvider).call(task);
      return ref.read(getTasksUseCaseProvider).call();
    });
  }

  Future<void> updateTask(TaskEntity task) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(updateTaskUseCaseProvider).call(task);
      return ref.read(getTasksUseCaseProvider).call();
    });
  }

  Future<void> deleteTask(String id) async {
    state = await AsyncValue.guard(() async {
      await ref.read(deleteTaskUseCaseProvider).call(id);
      return ref.read(getTasksUseCaseProvider).call();
    });
  }

  Future<void> saveDraft(Map<String, dynamic> draft) async {
    await ref.read(taskRepositoryProvider).saveDraft(draft);
  }

  Future<Map<String, dynamic>?> getDraft() async {
    return ref.read(taskRepositoryProvider).getDraft();
  }

  Future<void> clearDraft() async {
    await ref.read(taskRepositoryProvider).clearDraft();
  }
}

final tasksNotifierProvider =
    AsyncNotifierProvider<TasksNotifier, List<TaskEntity>>(TasksNotifier.new);

final searchQueryProvider = StateProvider<String>((ref) => '');

final debouncedSearchQueryProvider = StateProvider<String>((ref) => '');

final statusFilterProvider = StateProvider<TaskStatus?>((ref) => null);

// Set of task IDs that are actively blocking another task (blocker is not done)
final blockedTaskIdsProvider = Provider<Set<String>>((ref) {
  final tasksAsync = ref.watch(tasksNotifierProvider);
  return tasksAsync.when(
    data: (tasks) {
      final doneIds = tasks.where((t) => t.status == TaskStatus.done).map((t) => t.id).toSet();
      return tasks
          .where((t) => t.blockedById != null && !doneIds.contains(t.blockedById))
          .map((t) => t.id)
          .toSet();
    },
    loading: () => {},
    error: (_, __) => {},
  );
});

final filteredTasksProvider = Provider<List<TaskEntity>>((ref) {
  final tasksAsync = ref.watch(tasksNotifierProvider);
  final query = ref.watch(debouncedSearchQueryProvider).toLowerCase().trim();
  final statusFilter = ref.watch(statusFilterProvider);

  return tasksAsync.when(
    data: (tasks) {
      var filtered = tasks;
      if (statusFilter != null) {
        filtered = filtered.where((t) => t.status == statusFilter).toList();
      }
      if (query.isNotEmpty) {
        filtered = filtered
            .where((t) => t.title.toLowerCase().contains(query))
            .toList();
      }
      return filtered;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});
