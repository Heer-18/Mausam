import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../models/city_search_result.dart';
import '../providers/weather_provider.dart';
import '../services/location_service.dart';
import '../services/weather_api_service.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';

class LocationSearchModal extends StatefulWidget {
  const LocationSearchModal({super.key});

  @override
  State<LocationSearchModal> createState() => _LocationSearchModalState();
}

class _LocationSearchModalState extends State<LocationSearchModal> {
  final TextEditingController _searchController = TextEditingController();
  final WeatherApiService _apiService = WeatherApiService();

  List<CitySearchResult> _searchResults = [];
  bool _isSearching = false;
  bool _isGpsLocating = false;

  void _onSearchChanged(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await _apiService.searchCities(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _useGpsLocation() async {
    setState(() {
      _isGpsLocating = true;
    });

    final Position? pos = await LocationService.getCurrentPosition();
    if (pos != null && mounted) {
      context.read<WeatherProvider>().updateLocation(
        lat: pos.latitude,
        lon: pos.longitude,
        cityName: 'My Location',
      );
      Navigator.of(context).pop();
    } else {
      if (mounted) {
        setState(() {
          _isGpsLocating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.surfaceContainerHigh,
            content: Text(
              'Location permission not granted or GPS unavailable. Please choose a city below.',
              style: AppTypography.bodyMd,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
        ),
        child: Column(
          children: [
            // Drag Handle & Header
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

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Select Location',
                  style: AppTypography.headlineMd.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Search Bar Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  autofocus: true,
                  style: AppTypography.bodyMd,
                  decoration: InputDecoration(
                    hintText: 'Search city (e.g. Mumbai, Delhi, London)...',
                    hintStyle: AppTypography.bodySm.copyWith(
                      color: AppColors.onSurfaceVariant.withOpacity(0.6),
                    ),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: AppColors.onSurfaceVariant),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Current GPS Location Tile
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _useGpsLocation,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      _isGpsLocating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                            )
                          : const Icon(Icons.my_location_rounded, color: AppColors.primary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _isGpsLocating ? 'Detecting current GPS location...' : 'Use Current GPS Location',
                          style: AppTypography.bodyMd.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.primary, size: 20),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Results or Popular Cities
            Expanded(
              child: _isSearching
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : _searchResults.isNotEmpty
                      ? ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          itemCount: _searchResults.length,
                          separatorBuilder: (context, index) => Divider(
                            color: Colors.white.withOpacity(0.06),
                            height: 1,
                          ),
                          itemBuilder: (context, index) {
                            final city = _searchResults[index];
                            return ListTile(
                              leading: const Icon(Icons.location_city_rounded, color: AppColors.electricCyan),
                              title: Text(
                                city.name,
                                style: AppTypography.bodyMd.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                [
                                  if (city.admin1 != null && city.admin1!.isNotEmpty) city.admin1!,
                                  city.country
                                ].join(', '),
                                style: AppTypography.bodySm,
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.onSurfaceVariant),
                              onTap: () {
                                context.read<WeatherProvider>().updateLocation(
                                  lat: city.latitude,
                                  lon: city.longitude,
                                  cityName: '${city.name}${city.country.isNotEmpty ? ', ${city.country}' : ''}',
                                );
                                Navigator.of(context).pop();
                              },
                            );
                          },
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
                              child: Text(
                                'POPULAR CITIES',
                                style: AppTypography.labelCaps.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            Expanded(
                              child: GridView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                itemCount: AppConstants.popularCities.length,
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  childAspectRatio: 2.8,
                                ),
                                itemBuilder: (context, index) {
                                  final c = AppConstants.popularCities[index];
                                  final name = c['name'] as String;
                                  final state = c['state'] as String;
                                  final lat = c['lat'] as double;
                                  final lon = c['lon'] as double;

                                  return InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: () {
                                      context.read<WeatherProvider>().updateLocation(
                                        lat: lat,
                                        lon: lon,
                                        cityName: '$name, $state',
                                      );
                                      Navigator.of(context).pop();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.04),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.place_outlined, size: 16, color: AppColors.primary),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  name,
                                                  style: AppTypography.bodyMd.copyWith(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                Text(
                                                  state,
                                                  style: AppTypography.bodySm.copyWith(
                                                    fontSize: 10,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
