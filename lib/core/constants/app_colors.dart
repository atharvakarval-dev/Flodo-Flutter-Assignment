import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF5B6AF8);
  static const Color primaryLight = Color(0xFFEEF0FF);
  static const Color primaryDark = Color(0xFF3A4BD4);

  static const Color background = Color(0xFFF7F8FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F1F5);

  static const Color textPrimary = Color(0xFF0D0E1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFFADB5BD);
  static const Color textDisabled = Color(0xFFCBD5E1);

  static const Color border = Color(0xFFE8ECF0);
  static const Color divider = Color(0xFFF0F2F5);

  static const Color statusTodo = Color(0xFF6B7280);
  static const Color statusTodoBackground = Color(0xFFF3F4F6);
  static const Color statusInProgress = Color(0xFF5B6AF8);
  static const Color statusInProgressBackground = Color(0xFFEEF0FF);
  static const Color statusDone = Color(0xFF10B981);
  static const Color statusDoneBackground = Color(0xFFECFDF5);
  static const Color statusBlocked = Color(0xFFEF4444);
  static const Color statusBlockedBackground = Color(0xFFFEF2F2);

  static const Color priorityLow = Color(0xFF10B981);
  static const Color priorityLowBackground = Color(0xFFECFDF5);
  static const Color priorityMedium = Color(0xFFF59E0B);
  static const Color priorityMediumBackground = Color(0xFFFFFBEB);
  static const Color priorityHigh = Color(0xFFEF4444);
  static const Color priorityHighBackground = Color(0xFFFEF2F2);

  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  static const Color searchHighlight = Color(0xFFFEF9C3);
  static const Color searchHighlightText = Color(0xFF854D0E);

  static const Color shimmer = Color(0xFFE8ECF0);
  static const Color shimmerHighlight = Color(0xFFF7F8FC);

  static Color blockedOverlay = Colors.white.withOpacity(0.5);
}
