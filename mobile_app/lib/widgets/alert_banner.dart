import 'package:flutter/material.dart';
import '../models/weather_models.dart';
import '../utils/theme.dart';
import 'glass_container.dart';

class AlertBanner extends StatelessWidget {
  final WeatherAlert alert;
  final VoidCallback? onTap;

  const AlertBanner({
    super.key,
    required this.alert,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCritical = alert.severity == 'critical';
    final Color alertColor = isCritical ? AppColors.alertRed : AppColors.warningAmber;

    return GlassContainer(
      padding: const EdgeInsets.all(14.0),
      borderRadius: 18.0,
      fillColor: alertColor.withOpacity(0.08),
      borderColor: alertColor.withOpacity(0.35),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Alert Icon Badge with soft glow
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: alertColor.withOpacity(0.18),
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              color: alertColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),

          // Title & Description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        alert.title,
                        style: AppTypography.titleMd.copyWith(
                          fontSize: 15,
                          color: alertColor,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: alertColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  alert.description,
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.onSurface.withOpacity(0.85),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 6),
          Icon(
            Icons.chevron_right_rounded,
            color: alertColor.withOpacity(0.7),
            size: 20,
          ),
        ],
      ),
    );
  }
}
