import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/task_entity.dart';
import '../providers/task_providers.dart';
import '../widgets/blurred_background.dart';
import '../widgets/custom_bottom_nav.dart';
import 'task_form_screen.dart';
import 'task_list_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlurredBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              Expanded(
                child: tasksAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(child: Text('Error: $error')),
                  data: (tasks) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProgressCard(context, tasks),
                          const SizedBox(height: 30),
                          _buildSectionHeader('In Progress', _getInProgressCount(tasks)),
                          const SizedBox(height: 16),
                          _buildInProgressList(context, tasks),
                          const SizedBox(height: 30),
                          _buildSectionHeader('All Tasks', tasks.length.toString()),
                          const SizedBox(height: 16),
                          _buildAllTasksList(context, tasks),
                          const SizedBox(height: 30),
                          _buildSectionHeader('Priority Groups', '3'),
                          const SizedBox(height: 16),
                          _buildTaskGroupsList(tasks),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: const AddProjectFAB(),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 0),
    );
  }

  String _getInProgressCount(List<TaskEntity> tasks) {
    final count = tasks.where((t) => t.status == TaskStatus.inProgress).length;
    return count.toString();
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning ☀️';
    if (hour < 17) return 'Good Afternoon 🌤️';
    if (hour < 21) return 'Good Evening 🌆';
    return 'Good Night 🌙';
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting,
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(BuildContext context, List<TaskEntity> tasks) {
    int totalTasks = tasks.length;
    int completedTasks = tasks.where((t) => t.status == TaskStatus.done).length;
    double progress = totalTasks == 0 ? 0.0 : completedTasks / totalTasks;
    int percentage = (progress * 100).toInt();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your today\'s task\nalmost done!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context, 
                      MaterialPageRoute(builder: (_) => const TaskListScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('View Task', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 90,
            height: 90,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 7,
                    backgroundColor: Colors.white.withOpacity(0.25),
                    color: Colors.white,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Text(
                  '$percentage%',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String count) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFEEE9FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            count,
            style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildInProgressList(BuildContext context, List<TaskEntity> tasks) {
    final activeTasks = tasks.where((t) => t.status == TaskStatus.inProgress).toList();
    
    if (activeTasks.isEmpty) {
      return Container(
        height: 126,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text('No tasks currently in progress 🎉', style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    return SizedBox(
      height: 126,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: activeTasks.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (_, index) {
          final task = activeTasks[index];
          double progress = 0.5;
          final bgColors = [AppColors.cardBlue, AppColors.cardPeach, AppColors.cardPurple];
          final progressColors = [const Color(0xFF0087FF), const Color(0xFFFF7D53), AppColors.primary];
          
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TaskFormScreen(task: task)),
            ),
            child: _buildInProgressCard(
              category: task.priority.label + ' Priority', 
              title: task.title, 
              bgColor: bgColors[index % bgColors.length],
              progressColor: progressColors[index % progressColors.length], 
              progress: progress,
            ),
          );
        },
      ),
    );
  }

  Widget _buildInProgressCard({
    required String category,
    required String title,
    required Color bgColor,
    required Color progressColor,
    required double progress,
  }) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              const Icon(Icons.shopping_bag_rounded, size: 14, color: AppColors.textSecondary),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
            ),
          ),
          const Spacer(),
          Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: progressColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAllTasksList(BuildContext context, List<TaskEntity> tasks) {
    if (tasks.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text('No tasks yet. Tap + to create one!', style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return Column(
      children: tasks.map((task) {
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
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TaskFormScreen(task: task)),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(task.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      if (task.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(task.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: statusBgColor, borderRadius: BorderRadius.circular(5)),
                  child: Text(statusLabel, style: TextStyle(fontSize: 9, color: statusTextColor)),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTaskGroupsList(List<TaskEntity> tasks) {
    return Column(
      children: [
        _buildPriorityGroup(
          tasks: tasks,
          priority: TaskPriority.high,
          icon: Icons.priority_high_rounded,
          iconBg: AppColors.catWorkBg,
          iconColor: AppColors.catWorkIcon,
          title: 'High Priority',
        ),
        const SizedBox(height: 16),
        _buildPriorityGroup(
          tasks: tasks,
          priority: TaskPriority.medium,
          icon: Icons.remove_rounded,
          iconBg: AppColors.catPersonalBg,
          iconColor: AppColors.catPersonalIcon,
          title: 'Medium Priority',
        ),
        const SizedBox(height: 16),
        _buildPriorityGroup(
          tasks: tasks,
          priority: TaskPriority.low,
          icon: Icons.arrow_downward_rounded,
          iconBg: AppColors.catStudyBg,
          iconColor: AppColors.catStudyIcon,
          title: 'Low Priority',
        ),
      ],
    );
  }

  Widget _buildPriorityGroup({
    required List<TaskEntity> tasks,
    required TaskPriority priority,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
  }) {
    final groupTasks = tasks.where((t) => t.priority == priority).toList();
    final total = groupTasks.length;
    final doneCount = groupTasks.where((t) => t.status == TaskStatus.done).length;
    
    double progress = total == 0 ? 0.0 : doneCount / total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 0),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('$total Tasks', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          SizedBox(
            width: 42,
            height: 42,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: total == 0 ? 1 : progress, // display full grey circle if empty, or actual progress
                  strokeWidth: 4,
                  backgroundColor: iconBg,
                  color: total == 0 ? iconBg : iconColor,
                  strokeCap: StrokeCap.round,
                ),
                Center(
                  child: Text(
                    total == 0 ? '-' : '${(progress * 100).toInt()}%',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
