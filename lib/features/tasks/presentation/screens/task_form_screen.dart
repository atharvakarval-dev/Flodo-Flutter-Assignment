import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/task_entity.dart';
import '../providers/task_providers.dart';
import '../widgets/blurred_background.dart';

class TaskFormScreen extends ConsumerStatefulWidget {
  final TaskEntity? task;

  const TaskFormScreen({super.key, this.task});

  @override
  ConsumerState<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends ConsumerState<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  DateTime? _dueDate;
  late TaskStatus _status;
  late TaskPriority _priority;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descController = TextEditingController(text: widget.task?.description ?? '');
    _dueDate = widget.task?.dueDate;
    _status = widget.task?.status ?? TaskStatus.pending;
    _priority = widget.task?.priority ?? TaskPriority.medium;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    if (_isEditing) {
      final updated = widget.task!.copyWith(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        status: _status,
        priority: _priority,
        dueDate: _dueDate,
        clearDueDate: _dueDate == null,
        updatedAt: now,
      );
      await ref.read(tasksNotifierProvider.notifier).updateTask(updated);
    } else {
      final task = TaskEntity(
        id: const Uuid().v4(),
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        status: _status,
        priority: _priority,
        dueDate: _dueDate,
        createdAt: now,
        updatedAt: now,
      );
      await ref.read(tasksNotifierProvider.notifier).createTask(task);
    }

    if (mounted) Navigator.pop(context);
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlurredBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildTaskGroupDropdown(),
                        const SizedBox(height: 20),
                        _buildProjectDetailsCard(),
                        const SizedBox(height: 20),
                        _buildDateSelector(
                          label: 'Start Date',
                          dateText: DateFormat('dd MMM, yyyy').format(DateTime.now()),
                          onTap: () {},
                        ),
                        const SizedBox(height: 20),
                        _buildDateSelector(
                          label: 'End Date',
                          dateText: _dueDate != null ? DateFormat('dd MMM, yyyy').format(_dueDate!) : 'Select Date',
                          onTap: _pickDueDate,
                        ),
                        const SizedBox(height: 20),
                        _buildStatusSelector(),
                        const SizedBox(height: 20),
                        _buildPrioritySelector(),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                child: ElevatedButton(
                  onPressed: _save,
                  child: Text(_isEditing ? 'Update Project' : 'Add Project'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
             _isEditing ? 'Edit Project' : 'Add Project',
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_rounded, color: AppColors.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildTaskGroupDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 32, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
           Container(
             padding: const EdgeInsets.all(8),
             decoration: BoxDecoration(color: AppColors.catWorkBg, borderRadius: BorderRadius.circular(8)),
             child: const Icon(Icons.work_rounded, color: AppColors.catWorkIcon, size: 16),
           ),
           const SizedBox(width: 16),
           const Expanded(
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text('Task Group', style: TextStyle(fontSize: 9, color: AppColors.textSecondary)),
                 SizedBox(height: 2),
                 Text('Work', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
               ],
             ),
           ),
           const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textPrimary),
        ],
      ),
    );
  }

  Widget _buildProjectDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 32, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Project Name', style: TextStyle(fontSize: 9, color: AppColors.textSecondary)),
          TextFormField(
            controller: _titleController,
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              hintText: 'e.g., Grocery Shopping App',
            ),
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const Divider(height: 24),
          const Text('Description', style: TextStyle(fontSize: 9, color: AppColors.textSecondary)),
          TextFormField(
            controller: _descController,
            style: const TextStyle(fontSize: 11, color: AppColors.textPrimary),
            maxLines: 3,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              hintText: 'Project description here...',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector({required String label, required String dateText, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 32, offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
             const Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 20),
             const SizedBox(width: 16),
             Expanded(
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textSecondary)),
                   const SizedBox(height: 2),
                   Text(dateText, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
                 ],
               ),
             ),
             const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textPrimary),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSelector() {
    final options = [
      (TaskStatus.pending, 'To Do', AppColors.statusTodoBg, AppColors.statusTodoText),
      (TaskStatus.inProgress, 'In Progress', AppColors.statusInProgressBg, AppColors.statusInProgressText),
      (TaskStatus.done, 'Done', AppColors.statusDoneBg, AppColors.statusDoneText),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 32, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Status', style: TextStyle(fontSize: 9, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          Row(
            children: options.map((opt) {
              final (status, label, bg, fg) = opt;
              final isSelected = _status == status;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _status = status),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? bg : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? fg.withOpacity(0.4) : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? fg : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPrioritySelector() {
    final options = [
      (TaskPriority.low, 'Low', const Color(0xFFE8F5E9), const Color(0xFF388E3C)),
      (TaskPriority.medium, 'Medium', const Color(0xFFFFF8E1), const Color(0xFFF9A825)),
      (TaskPriority.high, 'High', const Color(0xFFFFEBEE), const Color(0xFFD32F2F)),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 32, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Priority', style: TextStyle(fontSize: 9, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          Row(
            children: options.map((opt) {
              final (priority, label, bg, fg) = opt;
              final isSelected = _priority == priority;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _priority = priority),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? bg : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? fg.withOpacity(0.4) : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? fg : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
