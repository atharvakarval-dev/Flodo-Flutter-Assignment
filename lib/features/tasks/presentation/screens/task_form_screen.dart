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

class _TaskFormScreenState extends ConsumerState<TaskFormScreen>
    with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  DateTime? _dueDate;
  late TaskStatus _status;
  late TaskPriority _priority;
  late TaskGroup _group;
  String? _blockedById;
  bool _isLoading = false;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descController =
        TextEditingController(text: widget.task?.description ?? '');
    _dueDate = widget.task?.dueDate;
    _status = widget.task?.status ?? TaskStatus.todo;
    _priority = widget.task?.priority ?? TaskPriority.medium;
    _group = widget.task?.group ?? TaskGroup.work;
    _blockedById = widget.task?.blockedById;

    if (!_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadDraft());
    }
  }

  Future<void> _loadDraft() async {
    final draft = await ref.read(tasksNotifierProvider.notifier).getDraft();
    if (draft != null && mounted) {
      setState(() {
        _titleController.text = draft['title'] as String? ?? '';
        _descController.text = draft['description'] as String? ?? '';
        _status = TaskStatus.values.firstWhere(
          (e) => e.name == draft['status'],
          orElse: () => TaskStatus.todo,
        );
        _priority = TaskPriority.values.firstWhere(
          (e) => e.name == draft['priority'],
          orElse: () => TaskPriority.medium,
        );
        _group = TaskGroup.values.firstWhere(
          (e) => e.name == draft['group'],
          orElse: () => TaskGroup.work,
        );
        _blockedById = draft['blockedById'] as String?;
        if (draft['dueDate'] != null) {
          _dueDate = DateTime.tryParse(draft['dueDate'] as String);
        }
      });
    }
  }

  void _saveDraft() {
    if (_isEditing) return;
    ref.read(tasksNotifierProvider.notifier).saveDraft({
      'title': _titleController.text,
      'description': _descController.text,
      'status': _status.name,
      'priority': _priority.name,
      'group': _group.name,
      'blockedById': _blockedById,
      'dueDate': _dueDate?.toIso8601String(),
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _saveDraft();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final now = DateTime.now();
    try {
      if (_isEditing) {
        final updated = widget.task!.copyWith(
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          status: _status,
          priority: _priority,
          group: _group,
          dueDate: _dueDate,
          clearDueDate: _dueDate == null,
          updatedAt: now,
          blockedById: _blockedById,
          clearBlockedBy: _blockedById == null,
        );
        await ref.read(tasksNotifierProvider.notifier).updateTask(updated);
      } else {
        final task = TaskEntity(
          id: const Uuid().v4(),
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          status: _status,
          priority: _priority,
          group: _group,
          dueDate: _dueDate,
          createdAt: now,
          updatedAt: now,
          blockedById: _blockedById,
        );
        await ref.read(tasksNotifierProvider.notifier).createTask(task);
        await ref.read(tasksNotifierProvider.notifier).clearDraft();
      }
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksNotifierProvider);
    final allTasks = tasksAsync.valueOrNull ?? [];
    final blockerOptions =
        allTasks.where((t) => t.id != widget.task?.id).toList();

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && !_isEditing) _saveDraft();
      },
      child: Scaffold(
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
                          _buildTaskGroupCard(),
                          const SizedBox(height: 15),
                          _buildProjectDetailsCard(),
                          const SizedBox(height: 15),
                          _buildDateSelector(
                            label: 'Due Date',
                            dateText: _dueDate != null
                                ? DateFormat('dd MMM, yyyy').format(_dueDate!)
                                : 'Select Date',
                            onTap: _pickDueDate,
                          ),
                          const SizedBox(height: 15),
                          _buildStatusSelector(),
                          const SizedBox(height: 15),
                          _buildPrioritySelector(),
                          const SizedBox(height: 15),
                          _buildBlockedBySelector(blockerOptions),
                        ],
                      ),
                    ),
                  ),
                ),
                _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded,
                color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            _isEditing ? 'Edit Task' : 'Add Task',
            style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  // ── Task Group card — tappable row, opens bottom sheet picker ─────────────
  Widget _buildTaskGroupCard() {
    return _buildPickerRow(
      icon: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: _group.bgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(_group.icon, color: _group.iconColor, size: 16),
      ),
      label: 'Task Group',
      value: _group.label,
      onTap: () => _showGroupPicker(),
    );
  }

  void _showGroupPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Task Group',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              ...TaskGroup.values.map((g) {
                final isSelected = _group == g;
                return GestureDetector(
                  onTap: () {
                    setState(() => _group = g);
                    Navigator.pop(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? g.bgColor : const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? g.iconColor.withValues(alpha: 0.4) : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            color: g.bgColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(g.icon, color: g.iconColor, size: 15),
                        ),
                        const SizedBox(width: 12),
                        Text(g.label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? g.iconColor : AppColors.textPrimary,
                            )),
                        const Spacer(),
                        if (isSelected)
                          Icon(Icons.check_rounded, color: g.iconColor, size: 18),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        ),
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
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 32,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Project Name',
              style:
                  TextStyle(fontSize: 9, color: AppColors.textSecondary)),
          TextFormField(
            controller: _titleController,
            style:
                const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              hintText: 'e.g., Grocery Shopping App',
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Title is required' : null,
          ),
          const Divider(height: 24),
          const Text('Description',
              style:
                  TextStyle(fontSize: 9, color: AppColors.textSecondary)),
          TextFormField(
            controller: _descController,
            style:
                const TextStyle(fontSize: 11, color: AppColors.textPrimary),
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

  Widget _buildDateSelector(
      {required String label,
      required String dateText,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 32,
                offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month_rounded,
                color: AppColors.primary, size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 9, color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(dateText,
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.textPrimary)),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded,
                color: AppColors.textPrimary),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSelector() {
    final options = [
      (TaskStatus.todo, 'To-Do', AppColors.statusTodoBg,
          AppColors.statusTodoText),
      (TaskStatus.inProgress, 'In Progress', AppColors.statusInProgressBg,
          AppColors.statusInProgressText),
      (TaskStatus.done, 'Done', AppColors.statusDoneBg,
          AppColors.statusDoneText),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 32,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Status',
              style:
                  TextStyle(fontSize: 9, color: AppColors.textSecondary)),
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
                        color: isSelected
                            ? fg.withValues(alpha: 0.4)
                            : Colors.transparent,
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
      (TaskPriority.low, 'Low', AppColors.priorityLowBackground,
          AppColors.priorityLow),
      (TaskPriority.medium, 'Medium', AppColors.priorityMediumBackground,
          AppColors.priorityMedium),
      (TaskPriority.high, 'High', AppColors.priorityHighBackground,
          AppColors.priorityHigh),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 32,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Priority',
              style:
                  TextStyle(fontSize: 9, color: AppColors.textSecondary)),
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
                        color: isSelected
                            ? fg.withValues(alpha: 0.4)
                            : Colors.transparent,
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

  // Shared tappable row used by both pickers
  Widget _buildPickerRow({
    required Widget icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 32,
                offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 9, color: AppColors.textSecondary)),
                  const SizedBox(height: 3),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded,
                color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockedBySelector(List<TaskEntity> blockerOptions) {
    final selectedTask = blockerOptions
        .where((t) => t.id == _blockedById)
        .firstOrNull;
    final displayValue = selectedTask?.title ?? 'None';

    return _buildPickerRow(
      icon: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: const Color(0xFFEEE9FF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.link_rounded, color: AppColors.primary, size: 16),
      ),
      label: 'Blocked By (optional)',
      value: displayValue,
      onTap: () => _showBlockedByPicker(blockerOptions),
    );
  }

  void _showBlockedByPicker(List<TaskEntity> blockerOptions) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Blocked By',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              // None option
              _buildBlockerOption(
                title: 'None',
                subtitle: 'No blocker',
                isSelected: _blockedById == null,
                onTap: () {
                  setState(() => _blockedById = null);
                  Navigator.pop(context);
                },
              ),
              ...blockerOptions.map((t) => _buildBlockerOption(
                title: t.title,
                subtitle: t.status.label,
                isSelected: _blockedById == t.id,
                onTap: () {
                  setState(() => _blockedById = t.id);
                  Navigator.pop(context);
                },
              )),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBlockerOption({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEEE9FF) : const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.4) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      )),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_rounded, color: AppColors.primary, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Glow shadow (Ellipse 17 from Figma)
          Container(
            height: 7,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.6),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? () {} : _save,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      _isEditing ? 'Update Task' : 'Add Task',
                      style: const TextStyle(
                          fontSize: 19, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
