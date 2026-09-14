import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../utils/theme.dart';
import 'location_search_modal.dart';
import 'notifications_modal.dart';
import 'persona_modal.dart';

class MausamTopAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MausamTopAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(64.0);

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherProvider>(
      builder: (context, provider, _) {
        final alertCount = provider.alerts.length;
        final cityName = provider.cityName;

        return ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.85),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withOpacity(0.08),
                    width: 1,
                  ),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: SizedBox(
                  height: preferredSize.height,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        // Location Trigger Pill
                        InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => const LocationSearchModal(),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.location_on_rounded,
                                  color: AppColors.primary,
                                  size: 22,
                                ),
                                const SizedBox(width: 6),
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: MediaQuery.of(context).size.width * 0.42,
                                  ),
                                  child: Text(
                                    cityName,
                                    style: AppTypography.titleMd.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: AppColors.onSurfaceVariant,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),

                        // Search Button
                        IconButton(
                          icon: const Icon(Icons.search_rounded, color: AppColors.onSurfaceVariant, size: 22),
                          tooltip: 'Search City',
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => const LocationSearchModal(),
                            );
                          },
                        ),

                        // Notification Bell with Alert Dot
                        Stack(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.notifications_outlined,
                                color: AppColors.onSurfaceVariant,
                                size: 22,
                              ),
                              tooltip: 'Notification Center & Alerts',
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => const NotificationsModal(),
                                );
                              },
                            ),
                            if (alertCount > 0)
                              Positioned(
                                right: 10,
                                top: 10,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.alertRed,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(width: 4),

                        // Persona / Profile Avatar Button
                        GestureDetector(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => const PersonaModal(),
                            );
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: provider.activePersona.accentColor.withOpacity(0.6),
                                width: 1.5,
                              ),
                              gradient: LinearGradient(
                                colors: [
                                  provider.activePersona.accentColor.withOpacity(0.3),
                                  AppColors.surfaceContainer,
                                ],
                              ),
                            ),
                            child: Icon(
                              provider.activePersona.icon,
                              size: 18,
                              color: provider.activePersona.accentColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
