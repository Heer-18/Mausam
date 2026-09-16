import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/weather_parameter_definition.dart';
import '../providers/weather_provider.dart';
import '../services/dynamic_icon_service.dart';
import '../utils/theme.dart';
import 'parameter_selector_modal.dart';
import 'persona_modal.dart';

class SettingsModal extends StatelessWidget {
  const SettingsModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherProvider>(
      builder: (context, provider, _) {
        final activeParamIds = provider.activeParameterIds;

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.90,
          ),
          decoration: BoxDecoration(
            color: const Color(0xF80F172A),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.55),
                blurRadius: 30,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Drag Handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 6),
                    width: 42,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),

                // 2. Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 16, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.electricCyan],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.tune_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Customize & Settings',
                              style: AppTypography.headlineMd.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Personalize parameters, layout & dynamic icons',
                              style: AppTypography.bodySm.copyWith(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.onSurfaceVariant),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                const Divider(color: Colors.white10, height: 1),

                // 3. Scrollable Settings Content
                Flexible(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    children: [
                      // SECTION 1: CUSTOM WEATHER PARAMETERS (METRICS CATALOG & SEARCH)
                      _buildSectionHeader(
                        'WEATHER PARAMETERS & METRICS',
                        Icons.dashboard_customize_rounded,
                        AppColors.electricCyan,
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(14.0),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(20.0),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.08),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Dashboard Metrics (${activeParamIds.length} Active)',
                                      style: AppTypography.titleMd.copyWith(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Text(
                                          'Active Role: ',
                                          style: AppTypography.bodySm.copyWith(
                                            color: AppColors.onSurfaceVariant,
                                            fontSize: 11.5,
                                          ),
                                        ),
                                        Text(
                                          provider.activePersona.displayName,
                                          style: AppTypography.bodySm.copyWith(
                                            color: provider.activePersona.accentColor,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Active Chips Tray
                            if (activeParamIds.isNotEmpty)
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: activeParamIds.take(8).map((id) {
                                  final def = WeatherParameterDefinition.allParameters.firstWhere(
                                    (p) => p.id == id,
                                    orElse: () => WeatherParameterDefinition(
                                      id: id,
                                      title: id,
                                      shortTitle: id,
                                      description: '',
                                      category: ParameterCategory.lifestyle,
                                      icon: Icons.insights_rounded,
                                      defaultColor: AppColors.primary,
                                    ),
                                  );

                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: def.defaultColor.withOpacity(0.18),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: def.defaultColor.withOpacity(0.35),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(def.icon, size: 12, color: def.defaultColor),
                                        const SizedBox(width: 4),
                                        Text(
                                          def.shortTitle,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),

                            if (activeParamIds.length > 8) ...[
                              const SizedBox(height: 6),
                              Text(
                                '+ ${activeParamIds.length - 8} more parameters active',
                                style: const TextStyle(
                                  color: AppColors.onSurfaceVariant,
                                  fontSize: 10.5,
                                ),
                              ),
                            ],

                            const SizedBox(height: 14),

                            // Manage & Search Parameters Action Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.electricCyan.withOpacity(0.18),
                                  foregroundColor: AppColors.electricCyan,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    side: BorderSide(
                                      color: AppColors.electricCyan.withOpacity(0.5),
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                icon: const Icon(Icons.search_rounded, size: 18),
                                label: const Text(
                                  'Manage & Search All Parameters',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) => const ParameterSelectorModal(),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),

                      // SECTION 2: HOMESCREEN LAYOUT
                      _buildSectionHeader('HOMESCREEN SECTIONS', Icons.view_quilt_rounded, AppColors.primary),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(20.0),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.08),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            _SmoothToggleTile(
                              icon: Icons.grid_view_rounded,
                              iconColor: AppColors.electricCyan,
                              title: 'Mini Metrics Grid',
                              subtitle: '4-card atmospheric grid (AQI, UV, Humidity, Wind)',
                              initialValue: provider.showMiniMetrics,
                              onChanged: (val) => provider.setShowMiniMetrics(val),
                            ),
                            const Divider(color: Colors.white10, height: 1),
                            _SmoothToggleTile(
                              icon: Icons.psychology_rounded,
                              iconColor: provider.activePersona.accentColor,
                              title: 'Personalized Insights',
                              subtitle: 'Persona parameter cards & actionable advisory',
                              initialValue: provider.showPersonalizedInsights,
                              onChanged: (val) => provider.setShowPersonalizedInsights(val),
                            ),
                            const Divider(color: Colors.white10, height: 1),
                            _SmoothToggleTile(
                              icon: Icons.schedule_rounded,
                              iconColor: AppColors.warningAmber,
                              title: '24-Hour Forecast',
                              subtitle: 'Hourly timeline with temp & precipitation chance',
                              initialValue: provider.showHourlyForecast,
                              onChanged: (val) => provider.setShowHourlyForecast(val),
                            ),
                            const Divider(color: Colors.white10, height: 1),
                            _SmoothToggleTile(
                              icon: Icons.calendar_today_rounded,
                              iconColor: AppColors.primary,
                              title: '7-Day Daily Outlook',
                              subtitle: 'Weekly temperature range bars & conditions',
                              initialValue: provider.showDailyForecast,
                              onChanged: (val) => provider.setShowDailyForecast(val),
                            ),
                            const Divider(color: Colors.white10, height: 1),
                            _SmoothToggleTile(
                              icon: Icons.nightlight_round,
                              iconColor: const Color(0xFFBAE6FD),
                              title: 'Celestial Almanac & Moon',
                              subtitle: 'Moon phase tracker, illumination & twilight info',
                              initialValue: provider.showCelestialAlmanac,
                              onChanged: (val) => provider.setShowCelestialAlmanac(val),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),

                      // SECTION 3: UNITS & METRICS
                      _buildSectionHeader('UNITS & STANDARDS', Icons.straighten_rounded, AppColors.electricCyan),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(14.0),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(20.0),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.08),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Temperature Unit Selector
                            Text(
                              'Temperature Scale',
                              style: AppTypography.titleMd.copyWith(fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildUnitPill(
                                    title: 'Celsius (°C)',
                                    isSelected: provider.tempUnit == 'C',
                                    onTap: () => provider.setTempUnit('C'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildUnitPill(
                                    title: 'Fahrenheit (°F)',
                                    isSelected: provider.tempUnit == 'F',
                                    onTap: () => provider.setTempUnit('F'),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),
                            const Divider(color: Colors.white10, height: 1),
                            const SizedBox(height: 14),

                            // Wind Speed Unit Selector
                            Text(
                              'Wind Speed Unit',
                              style: AppTypography.titleMd.copyWith(fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildUnitPill(
                                    title: 'km/h',
                                    isSelected: provider.windUnit == 'km/h',
                                    onTap: () => provider.setWindUnit('km/h'),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: _buildUnitPill(
                                    title: 'mph',
                                    isSelected: provider.windUnit == 'mph',
                                    onTap: () => provider.setWindUnit('mph'),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: _buildUnitPill(
                                    title: 'm/s',
                                    isSelected: provider.windUnit == 'm/s',
                                    onTap: () => provider.setWindUnit('m/s'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),

                      // SECTION 4: AUTOMATED NOTIFICATIONS
                      _buildSectionHeader('AUTOMATED WEATHER ALERTS', Icons.notifications_active_rounded, AppColors.agriEmerald),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(20.0),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.08),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            _SmoothToggleTile(
                              icon: Icons.bolt_rounded,
                              iconColor: AppColors.agriEmerald,
                              title: 'Automated Weather Dispatcher',
                              subtitle: 'Automatically triggers notifications as conditions change',
                              initialValue: provider.isAutoNotificationsActive,
                              onChanged: (val) => provider.setAutoNotifications(val),
                            ),
                            const Divider(color: Colors.white10, height: 1),
                            _SmoothToggleTile(
                              icon: Icons.coffee_rounded,
                              iconColor: const Color(0xFFF59E0B),
                              title: 'Contextual Witty Alerts (Zomato-Style)',
                              subtitle: 'Chai-pakoda tips, heat hydration, SPF sunglasses alerts',
                              initialValue: provider.isWittyAlertsActive,
                              onChanged: (val) => provider.setWittyAlerts(val),
                            ),
                            const Divider(color: Colors.white10, height: 1),
                            _SmoothToggleTile(
                              icon: Icons.wb_sunny_rounded,
                              iconColor: AppColors.warningAmber,
                              title: 'Good Morning Daily Briefing',
                              subtitle: 'Morning temperature & personalized activity forecast',
                              initialValue: provider.isMorningBriefingActive,
                              onChanged: (val) => provider.setMorningBriefing(val),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),

                      // SECTION 5: DYNAMIC WEATHER-ADAPTIVE APP ICON
                      _buildSectionHeader('WEATHER-ADAPTIVE APP ICON', Icons.auto_awesome_rounded, const Color(0xFF8B5CF6)),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(14.0),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(20.0),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.08),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'App Icon Preset',
                              style: AppTypography.titleMd.copyWith(fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Choose whether the home screen icon changes dynamically with live weather conditions or remains fixed.',
                              style: AppTypography.bodySm.copyWith(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 11.5,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildIconChip(
                                  label: '⚡ Auto (Weather-Adaptive)',
                                  value: DynamicIconService.themeAuto,
                                  currentValue: provider.dynamicIconTheme,
                                  onTap: () => provider.setDynamicIconTheme(DynamicIconService.themeAuto),
                                ),
                                _buildIconChip(
                                  label: '☀️ Sunny / Radiant',
                                  value: DynamicIconService.themeSunny,
                                  currentValue: provider.dynamicIconTheme,
                                  onTap: () => provider.setDynamicIconTheme(DynamicIconService.themeSunny),
                                ),
                                _buildIconChip(
                                  label: '🌧️ Rainy / Drizzle',
                                  value: DynamicIconService.themeRainy,
                                  currentValue: provider.dynamicIconTheme,
                                  onTap: () => provider.setDynamicIconTheme(DynamicIconService.themeRainy),
                                ),
                                _buildIconChip(
                                  label: '☁️ Overcast / Cloudy',
                                  value: DynamicIconService.themeCloudy,
                                  currentValue: provider.dynamicIconTheme,
                                  onTap: () => provider.setDynamicIconTheme(DynamicIconService.themeCloudy),
                                ),
                                _buildIconChip(
                                  label: '🌙 Crescent Night',
                                  value: DynamicIconService.themeNight,
                                  currentValue: provider.dynamicIconTheme,
                                  onTap: () => provider.setDynamicIconTheme(DynamicIconService.themeNight),
                                ),
                                _buildIconChip(
                                  label: '✨ Classic Brand',
                                  value: DynamicIconService.themeDefault,
                                  currentValue: provider.dynamicIconTheme,
                                  onTap: () => provider.setDynamicIconTheme(DynamicIconService.themeDefault),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),

                      // SECTION 6: ACTIVE PERSONA
                      _buildSectionHeader('ACTIVE PERSONA INTELLIGENCE', Icons.psychology_rounded, provider.activePersona.accentColor),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(14.0),
                          decoration: BoxDecoration(
                            color: provider.activePersona.accentColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20.0),
                            border: Border.all(
                              color: provider.activePersona.accentColor.withOpacity(0.35),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: provider.activePersona.accentColor.withOpacity(0.2),
                                  border: Border.all(
                                    color: provider.activePersona.accentColor.withOpacity(0.5),
                                    width: 1.5,
                                  ),
                                ),
                                child: Icon(
                                  provider.activePersona.icon,
                                  color: provider.activePersona.accentColor,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      provider.activePersona.displayName,
                                      style: AppTypography.titleMd.copyWith(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Targeted daily focus for ${provider.activePersona.shortTitle}',
                                      style: AppTypography.bodySm.copyWith(
                                        color: AppColors.onSurfaceVariant,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: provider.activePersona.accentColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) => const PersonaModal(),
                                  );
                                },
                                child: const Text('Change', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTypography.labelCaps.copyWith(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildUnitPill({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.25) : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.white10,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildIconChip({
    required String label,
    required String value,
    required String currentValue,
    required VoidCallback onTap,
  }) {
    final bool isSelected = (value == currentValue);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8B5CF6).withOpacity(0.25) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF8B5CF6) : Colors.white12,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _SmoothToggleTile extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool initialValue;
  final ValueChanged<bool> onChanged;

  const _SmoothToggleTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<_SmoothToggleTile> createState() => _SmoothToggleTileState();
}

class _SmoothToggleTileState extends State<_SmoothToggleTile> {
  late bool _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue;
  }

  @override
  void didUpdateWidget(covariant _SmoothToggleTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _currentValue = widget.initialValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: widget.iconColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(widget.icon, size: 18, color: widget.iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: AppTypography.titleMd.copyWith(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.subtitle,
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _currentValue,
            activeColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withOpacity(0.4),
            inactiveThumbColor: Colors.white70,
            inactiveTrackColor: Colors.white12,
            onChanged: (val) {
              setState(() => _currentValue = val);
              widget.onChanged(val);
            },
          ),
        ],
      ),
    );
  }
}
