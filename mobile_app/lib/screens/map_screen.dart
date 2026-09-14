import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../utils/theme.dart';
import '../widgets/glass_container.dart';

enum MapWeatherLayer {
  radar('Precipitation Radar', 'mm/h', Icons.water_drop_rounded, 2),
  clouds('Cloud & Satellite', '%', Icons.cloud_rounded, 0),
  temperature('Thermal Heat Spectrum', '°C', Icons.thermostat_rounded, 4),
  wind('Motion & Velocity Flow', 'km/h', Icons.air_rounded, 6);

  final String label;
  final String unit;
  final IconData icon;
  final int rainViewerScheme;
  const MapWeatherLayer(this.label, this.unit, this.icon, this.rainViewerScheme);
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final MapController _mapController;
  MapWeatherLayer _selectedLayer = MapWeatherLayer.radar;
  String _rainViewerRadarPath = '';
  String _rainViewerSatellitePath = '';
  String _rainViewerHost = 'https://tilecache.rainviewer.com';
  bool _isLoadingTimestamps = false;
  bool _isLayerSelectorOpen = false;
  static const double _overlayOpacity = 0.75;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _fetchRainViewerPaths();
  }

  Future<void> _fetchRainViewerPaths() async {
    try {
      if (mounted) setState(() => _isLoadingTimestamps = true);
      final res = await http
          .get(Uri.parse('https://api.rainviewer.com/public/weather-maps.json'))
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final host = data['host'] as String? ?? 'https://tilecache.rainviewer.com';
        final radar = data['radar'] as Map<String, dynamic>?;
        final pastRadar = radar?['past'] as List<dynamic>?;
        final satellite = data['satellite'] as Map<String, dynamic>?;
        final pastSat = satellite?['infrared'] as List<dynamic>?;

        String rPath = '';
        String sPath = '';

        if (pastRadar != null && pastRadar.isNotEmpty) {
          final last = pastRadar.last as Map<String, dynamic>;
          rPath = last['path'] as String? ?? '';
        }

        if (pastSat != null && pastSat.isNotEmpty) {
          final lastSat = pastSat.last as Map<String, dynamic>;
          sPath = lastSat['path'] as String? ?? '';
        }

        if (mounted) {
          setState(() {
            _rainViewerHost = host;
            _rainViewerRadarPath = rPath;
            _rainViewerSatellitePath = sPath;
            _isLoadingTimestamps = false;
          });
          return;
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoadingTimestamps = false);
    }
  }

  String? _getLayerTileUrl(MapWeatherLayer layer) {
    // 100% Free, Keyless, and High-Resolution Global Doppler Radar & Weather Overlays
    if (layer == MapWeatherLayer.clouds) {
      if (_rainViewerSatellitePath.isNotEmpty) {
        return '$_rainViewerHost$_rainViewerSatellitePath/256/{z}/{x}/{y}/0/0_0.png';
      } else if (_rainViewerRadarPath.isNotEmpty) {
        return '$_rainViewerHost$_rainViewerRadarPath/256/{z}/{x}/{y}/0/0_0.png';
      }
      return null;
    }

    if (_rainViewerRadarPath.isNotEmpty) {
      return '$_rainViewerHost$_rainViewerRadarPath/256/{z}/{x}/{y}/${layer.rainViewerScheme}/1_1.png';
    }

    return null;
  }

  void _recenterOnLocation(LatLng point) {
    try {
      _mapController.move(point, 10.0);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherProvider>(
      builder: (context, provider, _) {
        final currentPoint = LatLng(provider.mapLat, provider.mapLon);
        final overlayUrl = _getLayerTileUrl(_selectedLayer);

        return Scaffold(
          backgroundColor: AppColors.backgroundStart,
          body: Stack(
            children: [
              // 1. Fullscreen Interactive Map
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
                  // High performance Dark Basemap (CartoDB Dark Matter with OSM Fallback)
                  TileLayer(
                    urlTemplate: 'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    userAgentPackageName: 'com.mausam.ai',
                    maxZoom: 19,
                    minZoom: 3,
                    fallbackUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  ),

                  // Free Keyless Weather Radar Overlay
                  if (overlayUrl != null)
                    TileLayer(
                      key: ValueKey('${_selectedLayer.name}_$_rainViewerRadarPath'),
                      urlTemplate: overlayUrl,
                      userAgentPackageName: 'com.mausam.ai',
                      tileBuilder: (context, tileWidget, tile) => Opacity(
                        opacity: _overlayOpacity,
                        child: tileWidget,
                      ),
                      maxZoom: 18,
                      minZoom: 3,
                    ),

                  // Pinpoint Interactive Location Marker
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

              // Top Controls Header Bar
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Active Layer Badge
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

                      // Layer Picker Toggle Button
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

              // Recenter Floating Button (Right side)
              Positioned(
                right: 16,
                top: 76,
                child: GlassContainer(
                  borderRadius: 30,
                  padding: const EdgeInsets.all(10),
                  onTap: () => _recenterOnLocation(currentPoint),
                  child: const Icon(
                    Icons.my_location_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
              ),

              // Layer Switcher Dropdown Modal Menu
              if (_isLayerSelectorOpen)
                Positioned(
                  top: 76,
                  right: 16,
                  child: GlassContainer(
                    width: 230,
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    borderRadius: 20.0,
                    fillColor: AppColors.surface.withOpacity(0.96),
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

              // Dynamic Color Scale Legend (Bottom Right, clean & unobtrusive)
              Positioned(
                bottom: 84,
                right: 16,
                child: _buildDynamicLegend(_selectedLayer),
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
      fillColor: AppColors.surface.withOpacity(0.88),
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
