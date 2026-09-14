import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/theme.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.78),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withOpacity(0.12),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double totalWidth = constraints.maxWidth;
                final double itemWidth = totalWidth / 3.0;

                return Stack(
                  children: [
                    // 1. Sliding Glowing Active Pill Indicator
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeInOutCubic,
                      left: currentIndex * itemWidth + 3,
                      top: 2,
                      bottom: 2,
                      width: itemWidth - 6,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withOpacity(0.24),
                              AppColors.primaryContainer.withOpacity(0.30),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.45),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.25),
                              blurRadius: 14,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 2. Interactive Navigation Items Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildNavItem(
                            index: 0,
                            label: 'Forecast',
                            icon: Icons.wb_sunny_rounded,
                            activeIcon: Icons.wb_sunny_rounded,
                          ),
                        ),
                        Expanded(
                          child: _buildNavItem(
                            index: 1,
                            label: 'Advisor',
                            icon: Icons.auto_awesome_rounded,
                            activeIcon: Icons.auto_awesome_rounded,
                          ),
                        ),
                        Expanded(
                          child: _buildNavItem(
                            index: 2,
                            label: 'Maps',
                            icon: Icons.map_rounded,
                            activeIcon: Icons.map_rounded,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
    required IconData activeIcon,
  }) {
    final isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: AnimatedScale(
          scale: isSelected ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Icon(
                  isSelected ? activeIcon : icon,
                  key: ValueKey('${index}_$isSelected'),
                  size: 20,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant.withOpacity(0.7),
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 6),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isSelected ? 1.0 : 0.0,
                  child: Text(
                    label,
                    style: AppTypography.labelCaps.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
