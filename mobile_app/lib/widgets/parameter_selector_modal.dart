import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/weather_parameter_definition.dart';
import '../providers/weather_provider.dart';
import '../utils/theme.dart';

class ParameterSelectorModal extends StatefulWidget {
  const ParameterSelectorModal({super.key});

  @override
  State<ParameterSelectorModal> createState() => _ParameterSelectorModalState();
}

class _ParameterSelectorModalState extends State<ParameterSelectorModal> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherProvider>(
      builder: (context, provider, _) {
        final selectedIds = provider.activeParameterIds;

        final filteredParams = WeatherParameterDefinition.allParameters.where((p) {
          if (_searchQuery.isEmpty) return true;
          final q = _searchQuery.toLowerCase();
          return p.title.toLowerCase().contains(q) ||
              p.shortTitle.toLowerCase().contains(q) ||
              p.description.toLowerCase().contains(q) ||
              p.category.title.toLowerCase().contains(q);
        }).toList();

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
                  padding: const EdgeInsets.fromLTRB(20, 6, 16, 10),
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
                              'Customize Parameters',
                              style: AppTypography.headlineMd.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Select metrics to display on your dashboard',
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

                // 3. Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.surface.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _searchQuery.isNotEmpty
                            ? AppColors.primary
                            : Colors.white.withOpacity(0.12),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search metrics (e.g. UV, Wind, AQI, Rain, Soil...)',
                        hintStyle: TextStyle(
                          color: AppColors.onSurfaceVariant.withOpacity(0.6),
                          fontSize: 13,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.onSurfaceVariant),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val.trim();
                        });
                      },
                    ),
                  ),
                ),

                // Active Persona Role Indicator
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: provider.activePersona.accentColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: provider.activePersona.accentColor.withOpacity(0.35),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(provider.activePersona.icon, size: 15, color: provider.activePersona.accentColor),
                        const SizedBox(width: 8),
                        Text(
                          'Role: ${provider.activePersona.displayName}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Configuring for this persona',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.65),
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // 4. Scrollable List of Active Tray & Catalog
                Flexible(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                    children: [
                      // Active Selected Parameters Tray
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, size: 15, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text(
                                'ACTIVE SELECTION (${selectedIds.length})',
                                style: AppTypography.labelCaps.copyWith(
                                  color: AppColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () => provider.resetParametersToDefault(),
                            child: const Text(
                              'Reset Defaults',
                              style: TextStyle(
                                color: AppColors.electricCyan,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Selected Chips Wrap
                      if (selectedIds.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: selectedIds.map((id) {
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
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: def.defaultColor.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: def.defaultColor.withOpacity(0.4),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(def.icon, size: 14, color: def.defaultColor),
                                  const SizedBox(width: 6),
                                  Text(
                                    def.shortTitle,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  InkWell(
                                    onTap: () => provider.toggleParameterSelection(def.id),
                                    child: const Padding(
                                      padding: EdgeInsets.all(2.0),
                                      child: Icon(
                                        Icons.close_rounded,
                                        size: 14,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        )
                      else
                        Text(
                          'No parameters selected. Tap below to add metrics.',
                          style: TextStyle(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),

                      const SizedBox(height: 18),
                      const Divider(color: Colors.white10, height: 1),
                      const SizedBox(height: 14),

                      // Section Title
                      Row(
                        children: [
                          const Icon(Icons.apps_rounded, size: 15, color: AppColors.electricCyan),
                          const SizedBox(width: 6),
                          Text(
                            _searchQuery.isNotEmpty ? 'SEARCH RESULTS' : 'AVAILABLE METRICS CATALOG',
                            style: AppTypography.labelCaps.copyWith(
                              color: AppColors.electricCyan,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Catalog Cards
                      if (filteredParams.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32.0),
                          child: Center(
                            child: Text(
                              'No matching metrics found for "$_searchQuery"',
                              style: TextStyle(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        )
                      else
                        ...filteredParams.map((param) {
                          final isSelected = selectedIds.contains(param.id);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Container(
                              padding: const EdgeInsets.all(12.0),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? param.defaultColor.withOpacity(0.12)
                                    : AppColors.surface.withOpacity(0.55),
                                borderRadius: BorderRadius.circular(16.0),
                                border: Border.all(
                                  color: isSelected
                                      ? param.defaultColor.withOpacity(0.45)
                                      : Colors.white.withOpacity(0.08),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Icon Bubble
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: param.defaultColor.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      param.icon,
                                      color: param.defaultColor,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Titles & Category
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              param.title,
                                              style: AppTypography.titleMd.copyWith(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          param.description,
                                          style: AppTypography.bodySm.copyWith(
                                            color: AppColors.onSurfaceVariant,
                                            fontSize: 11,
                                            height: 1.25,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Add / Remove Button
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isSelected
                                          ? AppColors.alertRed.withOpacity(0.2)
                                          : param.defaultColor.withOpacity(0.2),
                                      foregroundColor: isSelected
                                          ? AppColors.alertRed
                                          : param.defaultColor,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        side: BorderSide(
                                          color: isSelected
                                              ? AppColors.alertRed.withOpacity(0.5)
                                              : param.defaultColor.withOpacity(0.5),
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      minimumSize: Size.zero,
                                    ),
                                    onPressed: () => provider.toggleParameterSelection(param.id),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isSelected ? Icons.remove_rounded : Icons.add_rounded,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isSelected ? 'Remove' : 'Add',
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
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
}
