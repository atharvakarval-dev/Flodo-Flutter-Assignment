import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../screens/home_screen.dart';
import '../screens/task_list_screen.dart';
import '../screens/task_form_screen.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;

  const CustomBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xFFEEE9FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(
            context,
            icon: Icons.home_rounded,
            index: 0,
            activeColor: AppColors.primary,
            activeBg: Colors.white.withOpacity(0.5),
            onTap: () {
              if (currentIndex != 0) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                );
              }
            },
          ),
          
          // FAB placeholder
          const SizedBox(width: 60),
          
          _buildNavItem(
            context,
            icon: Icons.calendar_today_rounded,
            index: 1,
            activeColor: AppColors.primary,
            activeBg: Colors.white.withOpacity(0.5),
            onTap: () {
              if (currentIndex != 1) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const TaskListScreen()),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, {
    required IconData icon,
    required int index,
    required Color activeColor,
    required Color activeBg,
    required VoidCallback onTap,
  }) {
    final isActive = currentIndex == index;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isActive ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: isActive ? activeColor : AppColors.primary.withOpacity(0.4),
          size: 26,
        ),
      ),
    );
  }
}

class AddProjectFAB extends StatelessWidget {
  const AddProjectFAB({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 18,
            offset: const Offset(2, 10),
          )
        ],
      ),
      child: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const TaskFormScreen(),
              fullscreenDialog: true,
            ),
          );
        },
        backgroundColor: AppColors.primary,
        elevation: 0,
        child: const Icon(Icons.add_rounded, size: 30),
      ),
    );
  }
}
