import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/persona_type.dart';
import '../providers/weather_provider.dart';
import '../utils/theme.dart';

class PersonaModal extends StatefulWidget {
  const PersonaModal({super.key});

  @override
  State<PersonaModal> createState() => _PersonaModalState();
}

class _PersonaModalState extends State<PersonaModal> {
  late PersonaType _tempSelected;

  @override
  void initState() {
    super.initState();
    _tempSelected = context.read<WeatherProvider>().activePersona;
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.88,
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.92),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
        ),
        child: Column(
          children: [
            // Top Drag Handle & Close Row
            Padding(
              padding: const EdgeInsets.only(top: 12.0, left: 20.0, right: 16.0, bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.onSurfaceVariant),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Header Title & Subtitle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Settings — Change Persona',
                      style: AppTypography.headlineMd.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Select a new category for your personalized weather',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // 3x3 Card Grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: GridView.builder(
                  itemCount: PersonaType.values.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.92,
                  ),
                  itemBuilder: (context, index) {
                    final p = PersonaType.values[index];
                    final isSelected = p == _tempSelected;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _tempSelected = p;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.electricCyan.withOpacity(0.14)
                              : Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.electricCyan
                                : Colors.white.withOpacity(0.08),
                            width: isSelected ? 2.0 : 1.0,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.electricCyan.withOpacity(0.3),
                                    blurRadius: 16,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Icon
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? AppColors.electricCyan.withOpacity(0.25)
                                    : p.accentColor.withOpacity(0.15),
                              ),
                              child: Icon(
                                p.icon,
                                color: isSelected ? AppColors.electricCyan : p.accentColor,
                                size: 22,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Short Title
                            Text(
                              p.shortTitle,
                              style: AppTypography.titleMd.copyWith(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                color: isSelected ? Colors.white : AppColors.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),

                            // Subtitle
                            Text(
                              p.subtitle,
                              style: AppTypography.bodySm.copyWith(
                                fontSize: 9.5,
                                color: isSelected
                                    ? AppColors.electricCyan
                                    : AppColors.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Bottom Action Area
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.electricCyan,
                      foregroundColor: AppColors.backgroundStart,
                      elevation: 4,
                      shadowColor: AppColors.electricCyan.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    onPressed: () {
                      context.read<WeatherProvider>().switchPersona(_tempSelected);
                      Navigator.of(context).pop();
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Save & Continue',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'Selected: ${_tempSelected.displayName}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.backgroundStart.withOpacity(0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
