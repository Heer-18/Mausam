import 'package:flutter/material.dart';
import '../models/persona_type.dart';
import '../models/weather_models.dart';
import '../utils/theme.dart';
import 'glass_container.dart';
import 'persona_modal.dart';

class PersonalizedInsightsSection extends StatelessWidget {
  final PersonaType persona;
  final List<PersonaSlotData> slots;
  final String advisorySummary;
  final String actionBullet;
  final VoidCallback? onChangePersona;
  final ScrollController? scrollController;

  const PersonalizedInsightsSection({
    super.key,
    required this.persona,
    required this.slots,
    required this.advisorySummary,
    required this.actionBullet,
    this.onChangePersona,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.psychology_rounded,
                  size: 20,
                  color: persona.accentColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Personalized Insights',
                  style: AppTypography.headlineMd.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onChangePersona ??
                  () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => const PersonaModal(),
                    );
                  },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Row(
                  children: [
                    Text(
                      'Change',
                      style: AppTypography.labelCaps.copyWith(
                        color: AppColors.primary,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Active Persona Badge Card with Animated Fade-In
        TweenAnimationBuilder<double>(
          key: ValueKey(persona.name),
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          builder: (context, val, child) {
            return Opacity(
              opacity: val,
              child: Transform.translate(
                offset: Offset(0, (1.0 - val) * 8),
                child: child,
              ),
            );
          },
          child: GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            borderRadius: 20.0,
            fillColor: persona.accentColor.withOpacity(0.06),
            borderColor: persona.accentColor.withOpacity(0.25),
            child: Row(
              children: [
                // Persona Icon in Glowing Bubble
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: persona.accentColor.withOpacity(0.18),
                    border: Border.all(
                      color: persona.accentColor.withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    persona.icon,
                    color: persona.accentColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),

                // Title and Subtitle Capsule
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        persona.displayName,
                        style: AppTypography.titleMd.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Targeted focus for your day',
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                // Pill Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: persona.accentColor.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: persona.accentColor.withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    persona.subtitle,
                    style: AppTypography.labelCaps.copyWith(
                      fontSize: 10,
                      color: persona.accentColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // 6 Parameter Slots (3 rows of 2 cards each with Staggered Entrance Animations)
        if (slots.isNotEmpty) ...[
          for (int i = 0; i < slots.length; i += 2)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                  Expanded(child: _buildParameterSlotCard(slots[i], i)),
                  const SizedBox(width: 12),
                  if (i + 1 < slots.length)
                    Expanded(child: _buildParameterSlotCard(slots[i + 1], i + 1))
                  else
                    const Expanded(child: SizedBox.shrink()),
                ],
              ),
            ),
        ],
        const SizedBox(height: 2),

        // Actionable Advisory Card
        TweenAnimationBuilder<double>(
          key: ValueKey(advisorySummary),
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeOutCubic,
          builder: (context, val, child) {
            return Opacity(
              opacity: val,
              child: Transform.translate(
                offset: Offset(0, (1.0 - val) * 8),
                child: child,
              ),
            );
          },
          child: GlassContainer(
            padding: const EdgeInsets.all(16.0),
            borderRadius: 20.0,
            fillColor: AppColors.agriEmerald.withOpacity(0.06),
            borderColor: AppColors.agriEmerald.withOpacity(0.3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Check Icon
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.agriEmerald.withOpacity(0.2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.agriEmerald.withOpacity(0.25),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: AppColors.agriEmerald,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),

                // Summary Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Actionable Intelligence',
                        style: AppTypography.labelCaps.copyWith(
                          color: AppColors.agriEmerald,
                          fontSize: 10,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        advisorySummary.isNotEmpty
                            ? advisorySummary
                            : (actionBullet.isNotEmpty
                                ? actionBullet
                                : 'Conditions are favorable for your daily outdoor schedule.'),
                        style: AppTypography.bodyMd.copyWith(
                          fontSize: 13,
                          color: AppColors.onSurface,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildParameterSlotCard(PersonaSlotData slot, int index) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('${slot.title}_${slot.value}'),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 60).clamp(0, 400)),
      curve: Curves.easeOutCubic,
      builder: (context, animVal, child) {
        return Opacity(
          opacity: animVal,
          child: Transform.translate(
            offset: Offset(0, (1.0 - animVal) * 10),
            child: child,
          ),
        );
      },
      child: GlassContainer(
        padding: const EdgeInsets.all(12.0),
        borderRadius: 18.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    slot.title,
                    style: AppTypography.labelCaps.copyWith(
                      fontSize: 10,
                      letterSpacing: 0.6,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(slot.icon, size: 16, color: slot.color),
              ],
            ),

            const SizedBox(height: 6),

            // Value and Subtitle (Constant real data, stable on scroll)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slot.value,
                  style: AppTypography.titleMd.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  slot.subtitle,
                  style: AppTypography.bodySm.copyWith(
                    fontSize: 11,
                    color: AppColors.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Animated Progress Bar (Fills smoothly to exact constant percentage)
            if (slot.progressPercentage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: TweenAnimationBuilder<double>(
                  key: ValueKey('${slot.title}_progress_${slot.progressPercentage}'),
                  tween: Tween<double>(begin: 0.0, end: slot.progressPercentage!.clamp(0.0, 1.0)),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, val, child) {
                    return LinearProgressIndicator(
                      value: val,
                      backgroundColor: Colors.white.withOpacity(0.06),
                      valueColor: AlwaysStoppedAnimation<Color>(slot.color.withOpacity(0.85)),
                      minHeight: 3.0,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
