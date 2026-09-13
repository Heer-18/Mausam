import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../utils/theme.dart';
import '../utils/weather_icons.dart';
import '../widgets/glass_container.dart';

enum MapWeatherLayer {
  radar('Precipitation Radar', 'mm/h', Icons.water_drop_rounded),
  temperature('Temperature', '°C', Icons.thermostat_rounded),
  wind('Wind Flow', 'km/h', Icons.air_rounded),
  clouds('Cloud / Satellite', '%', Icons.cloud_rounded);

  final String label;
  final String unit;
  final IconData icon;
  const MapWeatherLayer(this.label, this.unit, this.icon);
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final MapController _mapController;
  MapWeatherLayer _selectedLayer = MapWeatherLayer.radar;
  int _radarTimestamp = 0;
  int _satelliteTimestamp = 0;
  bool _isLoadingTimestamps = false;
  bool _isLayerSelectorOpen = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _fetchTimestamps();
  }

  Future<void> _fetchTimestamps() async {
    try {
      setState(() => _isLoadingTimestamps = true);
      final res = await http
          .get(Uri.parse('https://api.rainviewer.com/public/weather-maps.json'))
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final radar = data['radar'] as Map<String, dynamic>?;
        final pastRadar = radar?['past'] as List<dynamic>?;
        final satellite = data['satellite'] as Map<String, dynamic>?;
        final pastSat = satellite?['infrared'] as List<dynamic>?;

        int rTs = 0;
        int sTs = 0;

        if (pastRadar != null && pastRadar.isNotEmpty) {
          final last = pastRadar.last as Map<String, dynamic>;
          rTs = last['time'] as int? ?? 0;
        }

        if (pastSat != null && pastSat.isNotEmpty) {
          final lastSat = pastSat.last as Map<String, dynamic>;
          sTs = lastSat['time'] as int? ?? 0;
        }

        if (mounted) {
          setState(() {
            _radarTimestamp = rTs > 0 ? rTs : (DateTime.now().millisecondsSinceEpoch ~/ 1000) - 600;
            _satelliteTimestamp = sTs > 0 ? sTs : (DateTime.now().millisecondsSinceEpoch ~/ 1000) - 600;
            _isLoadingTimestamps = false;
          });
          return;
        }
      }
    } catch (_) {}

    if (mounted) {
      final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      setState(() {
        _radarTimestamp = nowSec - 600;
        _satelliteTimestamp = nowSec - 600;
        _isLoadingTimestamps = false;
      });
    }
  }

  String _getLayerTileUrl(MapWeatherLayer layer) {
    switch (layer) {
      case MapWeatherLayer.radar:
        return 'https://tilecache.rainviewer.com/v2/radar/$_radarTimestamp/256/{z}/{x}/{y}/2/1_1.png';
      case MapWeatherLayer.clouds:
        return 'https://tilecache.rainviewer.com/v2/satellite/$_satelliteTimestamp/256/{z}/{x}/{y}/0/0_0.png';
      case MapWeatherLayer.temperature:
        // RainViewer Color Scheme 4 (Thermal / Temperature Spectrum) - 100% Free & Keyless
        return 'https://tilecache.rainviewer.com/v2/radar/$_radarTimestamp/256/{z}/{x}/{y}/4/1_1.png';
      case MapWeatherLayer.wind:
        // RainViewer Color Scheme 6 (Velocity & Motion Flow) - 100% Free & Keyless
        return 'https://tilecache.rainviewer.com/v2/radar/$_radarTimestamp/256/{z}/{x}/{y}/6/1_1.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherProvider>(
      builder: (context, provider, _) {
        final currentPoint = LatLng(provider.mapLat, provider.mapLon);
        final preview = provider.mapPreviewTelemetry ?? provider.telemetry;

        return Scaffold(
          backgroundColor: AppColors.backgroundStart,
          body: Stack(
            children: [
              // Free Keyless Dark Base Map + Weather Overlays
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: currentPoint,
                  initialZoom: 10.0,
                  minZoom: 3.0,
                  maxZoom: 18.0,
                  onTap: (tapPosition, point) {
                    provider.updateMapSelectedCoordinates(point.latitude, point.longitude);
                  },
                ),
                children: [
                  // 1. Official Free Public OpenStreetMap with Inverted/Dark Color Filter
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.mausam.ai',
                    maxZoom: 18,
                    minZoom: 3,
                    tileBuilder: (context, tileWidget, tile) {
                      return ColorFiltered(
                        colorFilter: const ColorFilter.matrix(<double>[
                          -0.2, -0.2, -0.2, 0, 255,
                          -0.2, -0.2, -0.2, 0, 255,
                          -0.2, -0.2, -0.2, 0, 255,
                          0,    0,    0,    1, 0,
                        ]),
                        child: tileWidget,
                      );
                    },
                  ),

                  // 2. Active Weather Layer Overlay (Free Public Keyless)
                  TileLayer(
                    key: ValueKey(_selectedLayer.name + _radarTimestamp.toString()),
                    urlTemplate: _getLayerTileUrl(_selectedLayer),
                    userAgentPackageName: 'com.mausam.ai',
                    tileBuilder: (context, tileWidget, tile) => Opacity(
                      opacity: 0.68,
                      child: tileWidget,
                    ),
                    maxZoom: 18,
                    minZoom: 3,
                  ),

                  // 3. Interactive Position Marker
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: currentPoint,
                        width: 56,
                        height: 56,
                        child: GestureDetector(
                          onPanUpdate: (details) {
                            final newLat = (provider.mapLat - details.delta.dy * 0.005).clamp(-85.0, 85.0);
                            final newLon = (provider.mapLon + details.delta.dx * 0.005).clamp(-180.0, 180.0);
                            provider.updateMapSelectedCoordinates(newLat, newLon);
                          },
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primaryBlue.withOpacity(0.25),
                                ),
                              ),
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primaryBlue,
                                  border: Border.all(color: Colors.white, width: 2.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryBlue.withOpacity(0.6),
                                      blurRadius: 14,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.location_on_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Top Bar Controls Header
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Map Layer Badge Pill
                      GlassContainer(
                        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                        borderRadius: 20.0,
                        child: Row(
                          children: [
                            _isLoadingTimestamps
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                  )
                                : Icon(_selectedLayer.icon, color: AppColors.primary, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              _selectedLayer.label,
                              style: AppTypography.titleMd.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Layer Picker Trigger Button
                      GlassContainer(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                        borderRadius: 20.0,
                        fillColor: _isLayerSelectorOpen
                            ? AppColors.primary.withOpacity(0.25)
                            : AppColors.glassFill,
                        borderColor: _isLayerSelectorOpen
                            ? AppColors.primary
                            : AppColors.glassBorder,
                        onTap: () {
                          setState(() => _isLayerSelectorOpen = !_isLayerSelectorOpen);
                        },
                        child: Row(
                          children: [
                            const Icon(Icons.layers_rounded, color: AppColors.primary, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'Layers',
                              style: AppTypography.labelCaps.copyWith(
                                fontSize: 11,
                                color: AppColors.primary,
                              ),
                            ),
                            Icon(
                              _isLayerSelectorOpen ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
                              color: AppColors.primary,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Layer Switcher Dropdown Modal Menu
              if (_isLayerSelectorOpen)
                Positioned(
                  top: 76,
                  right: 16,
                  child: GlassContainer(
                    width: 220,
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    borderRadius: 20.0,
                    fillColor: AppColors.surface.withOpacity(0.95),
                    borderColor: AppColors.glassBorderBright,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: MapWeatherLayer.values.map((layer) {
                        final isSelected = _selectedLayer == layer;
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedLayer = layer;
                              _isLayerSelectorOpen = false;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                            color: isSelected ? AppColors.primary.withOpacity(0.15) : Colors.transparent,
                            child: Row(
                              children: [
                                Icon(
                                  layer.icon,
                                  size: 18,
                                  color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    layer.label,
                                    style: AppTypography.bodySm.copyWith(
                                      color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 16),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

              // Dynamic Color Scale Legend (Bottom Right)
              Positioned(
                bottom: 240,
                right: 16,
                child: _buildDynamicLegend(_selectedLayer),
              ),

              // Bottom Coordinate & Weather Preview Card
              Positioned(
                bottom: 88,
                left: 16,
                right: 16,
                child: GlassContainer(
                  padding: const EdgeInsets.all(16.0),
                  borderRadius: 24.0,
                  fillColor: AppColors.surface.withOpacity(0.92),
                  borderColor: AppColors.glassBorderBright,
                  child: provider.isMapPreviewLoading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(12.0),
                            child: CircularProgressIndicator(color: AppColors.primary),
                          ),
                        )
                      : preview != null
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Selected Location',
                                            style: AppTypography.labelCaps.copyWith(
                                              fontSize: 10,
                                              color: AppColors.onSurfaceVariant,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            preview.cityName,
                                            style: AppTypography.titleMd.copyWith(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Condition and Temp
                                    Row(
                                      children: [
                                        Icon(
                                          WeatherIcons.getIconForWmoCode(preview.weatherCode),
                                          color: WeatherIcons.getIconColorForWmoCode(preview.weatherCode),
                                          size: 24,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${preview.currentTemperature.round()}°C',
                                          style: AppTypography.headlineMd.copyWith(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                // Metrics Snippet
                                Text(
                                  '${preview.weatherCondition} • Humidity ${preview.humidity}% • Wind ${preview.windSpeed.round()} km/h',
                                  style: AppTypography.bodySm.copyWith(
                                    fontSize: 12,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Action: Set as active dashboard location
                                SizedBox(
                                  width: double.infinity,
                                  height: 42,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryContainer,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    onPressed: () {
                                      provider.updateLocation(
                                        lat: provider.mapLat,
                                        lon: provider.mapLon,
                                        cityName: preview.cityName,
                                      );
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          backgroundColor: AppColors.surfaceContainerHigh,
                                          behavior: SnackBarBehavior.floating,
                                          content: Text(
                                            'Dashboard location set to ${preview.cityName}!',
                                            style: AppTypography.bodyMd,
                                          ),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'Set as Dashboard Location',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDynamicLegend(MapWeatherLayer layer) {
    List<Color> colors;
    String minLabel;
    String midLabel;
    String maxLabel;

    switch (layer) {
      case MapWeatherLayer.temperature:
        colors = [Colors.blue, Colors.cyan, Colors.green, Colors.yellow, Colors.orange, Colors.red];
        minLabel = '-10°C';
        midLabel = '20°C';
        maxLabel = '45°C';
        break;
      case MapWeatherLayer.wind:
        colors = [Colors.cyan, Colors.blue, Colors.indigo, Colors.purple, Colors.pinkAccent];
        minLabel = '0';
        midLabel = '50';
        maxLabel = '100 km/h';
        break;
      case MapWeatherLayer.clouds:
        colors = [Colors.transparent, Colors.white24, Colors.white60, Colors.white];
        minLabel = '0%';
        midLabel = '50%';
        maxLabel = '100%';
        break;
      case MapWeatherLayer.radar:
        colors = [Colors.lightBlueAccent, Colors.green, Colors.yellow, Colors.orange, Colors.red, Colors.purple];
        minLabel = '0.1';
        midLabel = '10';
        maxLabel = '50+ mm/h';
        break;
    }

    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
      borderRadius: 16.0,
      fillColor: AppColors.surface.withOpacity(0.85),
      borderColor: AppColors.glassBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            layer.unit,
            style: AppTypography.labelCaps.copyWith(fontSize: 9, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Container(
            width: 100,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: LinearGradient(colors: colors),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(minLabel, style: const TextStyle(fontSize: 8, color: AppColors.onSurfaceVariant)),
                Text(midLabel, style: const TextStyle(fontSize: 8, color: AppColors.onSurfaceVariant)),
                Text(maxLabel, style: const TextStyle(fontSize: 8, color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
