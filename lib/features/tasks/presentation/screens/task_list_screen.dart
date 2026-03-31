import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/debouncer.dart';
import '../../domain/entities/task_entity.dart';
import '../providers/task_providers.dart';
import '../widgets/blurred_background.dart';
import '../widgets/custom_bottom_nav.dart';
import '../widgets/highlighted_text_widget.dart';
import 'task_form_screen.dart';

class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  final _searchController = TextEditingController();
  final _debouncer = Debouncer();

  @override
  void dispose() {
    _searchController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksNotifierProvider);
    final filteredTasks = ref.watch(filteredTasksProvider);
    final statusFilter = ref.watch(statusFilterProvider);
    final searchQuery = ref.watch(debouncedSearchQueryProvider);
    final blockedIds = ref.watch(blockedTaskIdsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: BlurredBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              _buildSearchBar(),
              const SizedBox(height: 12),
              _buildFilterChips(statusFilter),
              const SizedBox(height: 20),
              Expanded(
                child: tasksAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text(err.toString())),
                  data: (_) => filteredTasks.isEmpty
                      ? const Center(
                          child: Text('No tasks found',
                              style: TextStyle(color: AppColors.textSecondary)),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                          itemCount: filteredTasks.length,
                          itemBuilder: (context, index) {
                            final task = filteredTasks[index];
                            final isBlocked = blockedIds.contains(task.id);
                            return _buildTaskTimelineItem(
                              context: context,
                              task: task,
                              isBlocked: isBlocked,
                              searchQuery: searchQuery,
                              isLast: index == filteredTasks.length - 1,
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: const AddProjectFAB(),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 1),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            'Today\'s Tasks',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          ref.read(searchQueryProvider.notifier).state = value;
          _debouncer.run(() {
            ref.read(debouncedSearchQueryProvider.notifier).state = value;
          });
          setState(() {}); // refresh suffix icon
        },
        decoration: InputDecoration(
          hintText: 'Search tasks...',
          hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, color: AppColors.textSecondary, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(searchQueryProvider.notifier).state = '';
                    ref.read(debouncedSearchQueryProvider.notifier).state = '';
                    setState(() {});
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(TaskStatus? selectedStatus) {
    final filters = [
      (null, 'All'),
      (TaskStatus.todo, 'To-Do'),
      (TaskStatus.inProgress, 'In Progress'),
      (TaskStatus.done, 'Done'),
    ];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, index) {
          final (status, label) = filters[index];
          final isSelected = status == selectedStatus;
          return GestureDetector(
            onTap: () => ref.read(statusFilterProvider.notifier).state = status,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : const Color(0xFFEDE8FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.primary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTaskTimelineItem({
    required BuildContext context,
    required TaskEntity task,
    required bool isBlocked,
    required String searchQuery,
    required bool isLast,
  }) {
    Color statusBgColor;
    Color statusTextColor;
    String statusLabel;

    switch (task.status) {
      case TaskStatus.todo:
        statusBgColor = AppColors.statusTodoBg;
        statusTextColor = AppColors.statusTodoText;
        statusLabel = 'To-Do';
        break;
      case TaskStatus.inProgress:
        statusBgColor = AppColors.statusInProgressBg;
        statusTextColor = AppColors.statusInProgressText;
        statusLabel = 'In Progress';
        break;
      case TaskStatus.done:
        statusBgColor = AppColors.statusDoneBg;
        statusTextColor = AppColors.statusDoneText;
        statusLabel = 'Done';
        break;
    }

    final timeString = DateFormat('hh:mm a').format(task.dueDate ?? task.createdAt);

    return Opacity(
      opacity: isBlocked ? 0.45 : 1.0,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Time column
            SizedBox(
              width: 60,
              child: Column(
                children: [
                  const SizedBox(height: 36),
                  Text(
                    timeString,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, color: AppColors.timelinePurple),
                  ),
                ],
              ),
            ),
            // Timeline dot + line
            SizedBox(
              width: 30,
              child: Column(
                children: [
                  const SizedBox(height: 36),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.timelinePurple,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: AppColors.timelinePurple.withValues(alpha: 0.3),
                      ),
                    ),
                  if (isLast) const Expanded(child: SizedBox()),
                ],
              ),
            ),
            // Card
            Expanded(
              child: GestureDetector(
                onTap: isBlocked
                    ? null
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => TaskFormScreen(task: task)),
                        ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: isBlocked
                        ? Border.all(color: AppColors.statusBlocked.withValues(alpha: 0.3))
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task.description.isNotEmpty
                                      ? task.description
                                      : task.group.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 11, color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 4),
                                HighlightedText(
                                  text: task.title,
                                  query: searchQuery,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isBlocked
                                        ? AppColors.textDisabled
                                        : AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Group icon badge (matches Figma Rectangle 1053)
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: task.group.bgColor,
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Icon(task.group.icon,
                                color: task.group.iconColor, size: 13),
                          ),
                          if (isBlocked) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.lock_rounded,
                                size: 14, color: AppColors.statusBlocked),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusBgColor,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                  fontSize: 9, color: statusTextColor),
                            ),
                          ),
                          if (isBlocked) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.statusBlockedBackground,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: const Text('Blocked',
                                  style: TextStyle(
                                      fontSize: 9,
                                      color: AppColors.statusBlocked)),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
