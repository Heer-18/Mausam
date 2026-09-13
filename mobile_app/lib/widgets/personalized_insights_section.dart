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

  const PersonalizedInsightsSection({
    super.key,
    required this.persona,
    required this.slots,
    required this.advisorySummary,
    required this.actionBullet,
    this.onChangePersona,
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

        // Active Persona Badge Card
        GlassContainer(
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
        const SizedBox(height: 14),

        // 6 Parameter Slots Grid (2x3)
        if (slots.isNotEmpty)
          GridView.builder(
            itemCount: slots.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.65,
            ),
            itemBuilder: (context, index) {
              final slot = slots[index];
              return _buildParameterSlotCard(slot);
            },
          ),
        const SizedBox(height: 14),

        // Actionable Advisory Card
        GlassContainer(
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
                          : 'Conditions are favorable for your daily outdoor schedule.',
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
      ],
    );
  }

  Widget _buildParameterSlotCard(PersonaSlotData slot) {
    return GlassContainer(
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

          // Value and Subtitle
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

          // Progress Bar if applicable
          if (slot.progressPercentage != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: slot.progressPercentage,
                backgroundColor: Colors.white.withOpacity(0.06),
                valueColor: AlwaysStoppedAnimation<Color>(slot.color.withOpacity(0.85)),
                minHeight: 3.0,
              ),
            ),
        ],
      ),
    );
  }
}
