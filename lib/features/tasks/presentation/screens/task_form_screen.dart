import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/entities/task_entity.dart';
import '../providers/task_providers.dart';
import '../widgets/status_badge.dart';

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

  TaskStatus _status = TaskStatus.pending;
  TaskPriority _priority = TaskPriority.medium;
  DateTime? _dueDate;
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descController =
        TextEditingController(text: widget.task?.description ?? '');
    _status = widget.task?.status ?? TaskStatus.pending;
    _priority = widget.task?.priority ?? TaskPriority.medium;
    _dueDate = widget.task?.dueDate;

    _titleController.addListener(_onChanged);
    _descController.addListener(_onChanged);

    if (!_isEditing) {
      _loadDraft();
    }
  }

  void _onChanged() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
    _autoSaveDraft();
  }

  Future<void> _loadDraft() async {
    final draft =
        await ref.read(tasksNotifierProvider.notifier).getDraft();
    if (draft == null || !mounted) return;

    setState(() {
      _titleController.text = draft['title'] as String? ?? '';
      _descController.text = draft['description'] as String? ?? '';
      _status = TaskStatus.values.firstWhere(
        (e) => e.name == draft['status'],
        orElse: () => TaskStatus.pending,
      );
      _priority = TaskPriority.values.firstWhere(
        (e) => e.name == draft['priority'],
        orElse: () => TaskPriority.medium,
      );
      _dueDate = draft['dueDate'] != null
          ? DateTime.parse(draft['dueDate'] as String)
          : null;
      _hasUnsavedChanges = draft['title']?.toString().isNotEmpty ?? false;
    });

    if (_titleController.text.isNotEmpty || _descController.text.isNotEmpty) {
      _showDraftRestoredBanner();
    }
  }

  void _showDraftRestoredBanner() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Draft restored',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        backgroundColor: AppColors.info,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  Future<void> _autoSaveDraft() async {
    if (_isEditing) return;
    await ref.read(tasksNotifierProvider.notifier).saveDraft({
      'title': _titleController.text,
      'description': _descController.text,
      'status': _status.name,
      'priority': _priority.name,
      'dueDate': _dueDate?.toIso8601String(),
    });
  }

  @override
  void dispose() {
    _titleController.removeListener(_onChanged);
    _descController.removeListener(_onChanged);
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges || _isEditing) return true;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        title: Text(
          'Save as Draft?',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Your changes will be saved as a draft for next time.',
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'discard'),
            child: Text(
              'Discard',
              style: GoogleFonts.inter(color: AppColors.error),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'draft'),
            child: Text(
              'Save Draft',
              style: GoogleFonts.inter(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );

    if (result == 'discard') {
      await ref.read(tasksNotifierProvider.notifier).clearDraft();
      return true;
    }
    if (result == 'draft') {
      await _autoSaveDraft();
      return true;
    }
    return false;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
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
        await ref.read(tasksNotifierProvider.notifier).clearDraft();
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing ? 'Task updated!' : 'Task created!',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
        _hasUnsavedChanges = true;
      });
      _autoSaveDraft();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final canPop = await _onWillPop();
        if (canPop && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(),
        body: _isSaving ? _buildSavingOverlay() : _buildForm(),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
        onPressed: () async {
          final canPop = await _onWillPop();
          if (canPop && mounted) Navigator.pop(context);
        },
      ),
      title: Text(
        _isEditing ? 'Edit Task' : 'New Task',
        style: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.3,
        ),
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.base),
          child: TextButton(
            onPressed: _isSaving ? null : _save,
            style: TextButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base,
                vertical: AppSpacing.xs,
              ),
            ),
            child: Text(
              _isEditing ? 'Update' : 'Create',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSavingOverlay() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _isEditing ? 'Updating task…' : 'Creating task…',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This may take a moment',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              child: Column(
                children: [
                  _buildTextField(
                    controller: _titleController,
                    label: 'Task Title',
                    hint: 'What needs to be done?',
                    maxLines: 2,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Title is required';
                      }
                      return null;
                    },
                    prefixIcon: Icons.title_rounded,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildTextField(
                    controller: _descController,
                    label: 'Description',
                    hint: 'Add details (optional)',
                    maxLines: 4,
                    prefixIcon: Icons.notes_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.base),
            _buildSectionLabel('Status'),
            _buildStatusPicker(),
            const SizedBox(height: AppSpacing.base),
            _buildSectionLabel('Priority'),
            _buildPriorityPicker(),
            const SizedBox(height: AppSpacing.base),
            _buildSectionLabel('Due Date'),
            _buildDueDatePicker(),
            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
    required IconData prefixIcon,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: GoogleFonts.inter(
        fontSize: 15,
        color: AppColors.textPrimary,
        height: 1.5,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.textTertiary,
        ),
        prefixIcon: Icon(prefixIcon, size: 18, color: AppColors.textTertiary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        filled: true,
        fillColor: AppColors.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.base,
        ),
      ),
    );
  }

  Widget _buildStatusPicker() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: TaskStatus.values.asMap().entries.map((entry) {
          final i = entry.key;
          final status = entry.value;
          final isSelected = _status == status;
          final isLast = i == TaskStatus.values.length - 1;
          return GestureDetector(
            onTap: () {
              setState(() {
                _status = status;
                _hasUnsavedChanges = true;
              });
              _autoSaveDraft();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryLight
                    : Colors.transparent,
                borderRadius: BorderRadius.vertical(
                  top: i == 0
                      ? const Radius.circular(AppSpacing.radiusLg)
                      : Radius.zero,
                  bottom: isLast
                      ? const Radius.circular(AppSpacing.radiusLg)
                      : Radius.zero,
                ),
                border: isLast
                    ? null
                    : const Border(
                        bottom:
                            BorderSide(color: AppColors.divider, width: 1)),
              ),
              child: Row(
                children: [
                  StatusBadge(status: status),
                  const Spacer(),
                  if (isSelected)
                    const Icon(Icons.check_rounded,
                        color: AppColors.primary, size: 18),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPriorityPicker() {
    final priorities = [
      (TaskPriority.low, Icons.arrow_downward_rounded, AppColors.priorityLow),
      (TaskPriority.medium, Icons.remove_rounded, AppColors.priorityMedium),
      (TaskPriority.high, Icons.arrow_upward_rounded, AppColors.priorityHigh),
    ];

    return Row(
      children: priorities.map((entry) {
        final (priority, icon, color) = entry;
        final isSelected = _priority == priority;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _priority = priority;
                _hasUnsavedChanges = true;
              });
              _autoSaveDraft();
            },
            child: AnimatedContainer(
              duration: 200.ms,
              margin: EdgeInsets.only(
                right: priority != TaskPriority.high ? AppSpacing.sm : 0,
              ),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withOpacity(0.12)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: isSelected ? color : AppColors.border,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(icon, size: 18, color: isSelected ? color : AppColors.textTertiary),
                  const SizedBox(height: 4),
                  Text(
                    priority.label,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? color : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDueDatePicker() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _pickDueDate,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.base),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: const Icon(Icons.calendar_month_rounded,
                      size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    _dueDate != null
                        ? _formatDate(_dueDate!)
                        : 'Set due date (optional)',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight:
                          _dueDate != null ? FontWeight.w600 : FontWeight.w400,
                      color: _dueDate != null
                          ? AppColors.textPrimary
                          : AppColors.textTertiary,
                    ),
                  ),
                ),
                if (_dueDate != null)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _dueDate = null;
                        _hasUnsavedChanges = true;
                      });
                      _autoSaveDraft();
                    },
                    child: const Icon(Icons.close_rounded,
                        size: 18, color: AppColors.textTertiary),
                  )
                else
                  const Icon(Icons.chevron_right_rounded,
                      size: 18, color: AppColors.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
