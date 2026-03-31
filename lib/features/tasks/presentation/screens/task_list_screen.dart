import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/task_entity.dart';
import '../providers/task_providers.dart';
import '../widgets/blurred_background.dart';
import '../widgets/custom_bottom_nav.dart';
import 'task_form_screen.dart';

class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksNotifierProvider);
    final filteredTasks = ref.watch(filteredTasksProvider);
    final statusFilter = ref.watch(statusFilterProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: BlurredBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              _buildCalendarSlider(),
              _buildFilterChips(statusFilter),
              const SizedBox(height: 20),
              Expanded(
                child: tasksAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text(err.toString())),
                  data: (_) => filteredTasks.isEmpty
                      ? const Center(child: Text('No tasks for today', style: TextStyle(color: AppColors.textSecondary)))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                          itemCount: filteredTasks.length,
                          itemBuilder: (context, index) {
                            return _buildTaskTimelineItem(
                              context: context,
                              task: filteredTasks[index],
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
            onPressed: () {},
          ),
          const Text(
            'Today\'s Tasks',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_rounded, color: AppColors.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarSlider() {
    return Container(
      height: 90,
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 7,
        itemBuilder: (context, index) {
          final date = DateTime.now().subtract(const Duration(days: 2)).add(Duration(days: index));
          final isSelected = date.day == _selectedDate.day && date.month == _selectedDate.month;

          return GestureDetector(
            onTap: () => setState(() => _selectedDate = date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 64,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: isSelected
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('MMM').format(date),
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('E').format(date),
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChips(TaskStatus? selectedStatus) {
    final filters = [
      (null, 'All'),
      (TaskStatus.pending, 'To do'),
      (TaskStatus.inProgress, 'In Progress'),
      (TaskStatus.done, 'Completed'),
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

  Widget _buildTaskTimelineItem({required BuildContext context, required TaskEntity task, required bool isLast}) {
    Color statusBgColor;
    Color statusTextColor;
    String statusLabel;

    switch (task.status) {
      case TaskStatus.pending:
      case TaskStatus.blocked:
        statusBgColor = AppColors.statusTodoBg;
        statusTextColor = AppColors.statusTodoText;
        statusLabel = 'To-do';
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

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                      color: AppColors.timelinePurple.withOpacity(0.3),
                    ),
                  ),
                if (isLast) const Expanded(child: SizedBox()),
              ],
            ),
          ),
          Expanded(
            child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TaskFormScreen(task: task)),
            ),
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          task.description.isNotEmpty ? task.description.split('\n')[0] : 'No description',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: AppColors.catWorkBg, borderRadius: BorderRadius.circular(5)),
                        child: const Icon(Icons.work_rounded, color: AppColors.catWorkIcon, size: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    task.title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: statusBgColor, borderRadius: BorderRadius.circular(5)),
                    child: Text(
                      statusLabel,
                      style: TextStyle(fontSize: 9, color: statusTextColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ),
        ],
      ),
    );
  }
}
