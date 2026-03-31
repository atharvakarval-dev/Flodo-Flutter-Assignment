import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/task_entity.dart';
import 'highlighted_text_widget.dart';
import 'status_badge.dart';

class TaskCardWidget extends StatelessWidget {
  final TaskEntity task;
  final String searchQuery;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const TaskCardWidget({
    super.key,
    required this.task,
    required this.searchQuery,
    required this.onTap,
    required this.onDelete,
  });

  Color get _leftAccentColor {
    switch (task.status) {
      case TaskStatus.todo:
        return AppColors.statusTodo;
      case TaskStatus.inProgress:
        return AppColors.primary;
      case TaskStatus.done:
        return AppColors.statusDone;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBlocked = task.isBlocked;
    final isDone = task.status == TaskStatus.done;

    return Opacity(
      opacity: isBlocked ? 0.45 : 1.0,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
            border: Border.all(
              color: isBlocked
                  ? AppColors.statusBlocked.withOpacity(0.2)
                  : AppColors.border,
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: _leftAccentColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AppSpacing.radiusLg),
                        bottomLeft: Radius.circular(AppSpacing.radiusLg),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.base),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: HighlightedText(
                                  text: task.title,
                                  query: searchQuery,
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: isBlocked
                                        ? AppColors.textDisabled
                                        : isDone
                                            ? AppColors.textTertiary
                                            : AppColors.textPrimary,
                                    decoration: isDone
                                        ? TextDecoration.lineThrough
                                        : null,
                                    decorationColor: AppColors.textTertiary,
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              if (isBlocked)
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.statusBlockedBackground,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.lock_rounded,
                                    size: 12,
                                    color: AppColors.statusBlocked,
                                  ),
                                ),
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'delete') onDelete();
                                },
                                itemBuilder: (_) => [
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        const Icon(Icons.delete_outline,
                                            size: 16, color: AppColors.error),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Delete',
                                          style: GoogleFonts.inter(
                                              color: AppColors.error,
                                              fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                icon: Icon(
                                  Icons.more_horiz,
                                  color: isBlocked
                                      ? AppColors.textDisabled
                                      : AppColors.textTertiary,
                                  size: 18,
                                ),
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusMd),
                                ),
                              ),
                            ],
                          ),
                          if (task.description.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            HighlightedText(
                              text: task.description,
                              query: searchQuery,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: isBlocked
                                    ? AppColors.textDisabled
                                    : AppColors.textSecondary,
                                height: 1.5,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              StatusBadge(status: task.status, compact: true),
                              const SizedBox(width: AppSpacing.sm),
                              PriorityBadge(priority: task.priority),
                              const Spacer(),
                              if (task.dueDate != null) ...[
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 11,
                                  color: DateFormatter.isOverdue(task.dueDate)
                                      ? AppColors.error
                                      : AppColors.textTertiary,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  DateFormatter.formatDate(task.dueDate!),
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color:
                                        DateFormatter.isOverdue(task.dueDate)
                                            ? AppColors.error
                                            : AppColors.textTertiary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.05, end: 0);
  }
}
