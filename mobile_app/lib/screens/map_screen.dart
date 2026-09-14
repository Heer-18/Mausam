import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../widgets/glass_container.dart';

enum MapWeatherLayer {
  precipitation('Precipitation Radar', 'mm/h', Icons.water_drop_rounded, 'precipitation_new'),
  temperature('Temperature Heatmap', '°C', Icons.thermostat_rounded, 'temp_new'),
  wind('Wind Flow Stream', 'km/h', Icons.air_rounded, 'wind_new'),
  clouds('Cloud & Satellite', '%', Icons.cloud_rounded, 'clouds_new'),
  pressure('Sea-Level Pressure', 'hPa', Icons.speed_rounded, 'pressure_new'),
  radar('Live Doppler Radar', 'dBZ', Icons.radar_rounded, 'rainviewer_radar');

  final String label;
  final String unit;
  final IconData icon;
  final String openWeatherLayer;
  const MapWeatherLayer(this.label, this.unit, this.icon, this.openWeatherLayer);
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final MapController _mapController;
  MapWeatherLayer _selectedLayer = MapWeatherLayer.precipitation;
  String _rainViewerRadarPath = '';
  String _rainViewerHost = 'https://tilecache.rainviewer.com';
  bool _isLoadingTimestamps = false;
  bool _isLayerSelectorOpen = false;
  static const double _overlayOpacity = 0.72;

  String get _openWeatherApiKey {
    final keyFromEnv = dotenv.env['OPENWEATHER_API_KEY']?.trim() ?? '';
    if (keyFromEnv.isNotEmpty) return keyFromEnv;
    return AppConstants.defaultOpenWeatherApiKey;
  }

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
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final host = data['host'] as String? ?? 'https://tilecache.rainviewer.com';
        final radar = data['radar'] as Map<String, dynamic>?;
        final pastRadar = radar?['past'] as List<dynamic>?;

        String rPath = '';

        if (pastRadar != null && pastRadar.isNotEmpty) {
          final last = pastRadar.last as Map<String, dynamic>;
          rPath = last['path'] as String? ?? '';
        }

        if (mounted) {
          setState(() {
            _rainViewerHost = host;
            _rainViewerRadarPath = rPath;
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
    // 1. RainViewer Live Doppler Radar
    if (layer == MapWeatherLayer.radar) {
      if (_rainViewerRadarPath.isNotEmpty) {
        return '$_rainViewerHost$_rainViewerRadarPath/256/{z}/{x}/{y}/2/1_1.png';
      }
      return null;
    }

    // 2. OpenWeatherMap HD Weather Tile Layers
    final apiKey = _openWeatherApiKey;
    if (apiKey.isNotEmpty) {
      return 'https://tile.openweathermap.org/map/${layer.openWeatherLayer}/{z}/{x}/{y}.png?appid=$apiKey';
    }

    // 3. Fallback to RainViewer Doppler
    if (_rainViewerRadarPath.isNotEmpty) {
      return '$_rainViewerHost$_rainViewerRadarPath/256/{z}/{x}/{y}/2/1_1.png';
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
        final currentPoint = LatLng(provider.currentLat, provider.currentLon);
        final overlayUrl = _getLayerTileUrl(_selectedLayer);

        return Scaffold(
          backgroundColor: AppColors.backgroundStart,
          body: Stack(
            children: [
              // 1. Fullscreen Map Canvas
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: currentPoint,
                  initialZoom: 10.0,
                  minZoom: 3.0,
                  maxZoom: 18.0,
                ),
                children: [
                  // Esri World Dark Gray Canvas Basemap (Free, No Watermarks)
                  TileLayer(
                    urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Base/MapServer/tile/{z}/{y}/{x}',
                    userAgentPackageName: 'com.mausam.ai',
                    maxZoom: 16,
                    minZoom: 3,
                    fallbackUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  ),

                  // Active Weather Overlay Layer
                  if (overlayUrl != null)
                    TileLayer(
                      key: ValueKey('${_selectedLayer.name}_$_openWeatherApiKey'),
                      urlTemplate: overlayUrl,
                      userAgentPackageName: 'com.mausam.ai',
                      tileBuilder: (context, tileWidget, tile) => Opacity(
                        opacity: _overlayOpacity,
                        child: tileWidget,
                      ),
                      maxZoom: 18,
                      minZoom: 3,
                    ),

                  // Minimal Stationary Location Beacon Ping
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: currentPoint,
                        width: 32,
                        height: 32,
                        child: Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primaryBlue.withOpacity(0.22),
                                ),
                              ),
                              Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primaryBlue,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryBlue.withOpacity(0.65),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ],
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

              // 2. Top Controls Header Bar (Clean, Unified Single-Row Layout with Zero Overlap)
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Active Layer Badge Pill (Clean: Only Icon & Layer Label)
                      Flexible(
                        child: GlassContainer(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                          borderRadius: 20.0,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _isLoadingTimestamps
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                    )
                                  : Icon(_selectedLayer.icon, color: AppColors.primary, size: 18),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  _selectedLayer.label,
                                  style: AppTypography.titleMd.copyWith(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Right Action Controls (Recenter Button + Layer Selector Button)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Recenter Button
                          GlassContainer(
                            padding: const EdgeInsets.all(8.0),
                            borderRadius: 20.0,
                            onTap: () => _recenterOnLocation(currentPoint),
                            child: const Icon(
                              Icons.my_location_rounded,
                              color: AppColors.primary,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 8),

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
                              mainAxisSize: MainAxisSize.min,
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
                    ],
                  ),
                ),
              ),

              // 3. Layer Switcher Dropdown Modal Menu
              if (_isLayerSelectorOpen)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 58,
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

              // 4. Dynamic Color Scale Legend (Positioned directly above the bottom navigation bar with snug 8px spacing)
              Positioned(
                left: 20,
                right: 20,
                bottom: 88,
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
        minLabel = '-20°C';
        midLabel = '15°C';
        maxLabel = '45°C';
        break;
      case MapWeatherLayer.wind:
        colors = [Colors.cyan, Colors.blue, Colors.indigo, Colors.purple, Colors.pinkAccent];
        minLabel = '0';
        midLabel = '50';
        maxLabel = '100 km/h';
        break;
      case MapWeatherLayer.clouds:
        colors = [Colors.white10, Colors.white38, Colors.white70, Colors.white];
        minLabel = '0%';
        midLabel = '50%';
        maxLabel = '100%';
        break;
      case MapWeatherLayer.pressure:
        colors = [Colors.teal, Colors.green, Colors.yellow, Colors.orange, Colors.deepOrange];
        minLabel = '950';
        midLabel = '1013';
        maxLabel = '1060 hPa';
        break;
      case MapWeatherLayer.precipitation:
      case MapWeatherLayer.radar:
        colors = [Colors.lightBlueAccent, Colors.green, Colors.yellow, Colors.orange, Colors.red, Colors.purple];
        minLabel = '0.1';
        midLabel = '10';
        maxLabel = '50+ mm/h';
        break;
    }

    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      borderRadius: 20.0,
      fillColor: AppColors.surface.withOpacity(0.90),
      borderColor: AppColors.glassBorderBright,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(layer.icon, size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    '${layer.label.toUpperCase()} INTENSITY',
                    style: AppTypography.labelCaps.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Text(
                'Unit: ${layer.unit}',
                style: AppTypography.bodySm.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            height: 8,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: LinearGradient(colors: colors),
              border: Border.all(color: Colors.white24, width: 0.8),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                minLabel,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Text(
                midLabel,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
              Text(
                maxLabel,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
