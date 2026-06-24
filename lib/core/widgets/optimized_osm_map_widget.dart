import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math';
import '../theme/app_colors.dart';
import '../services/kpk_optimized_map_service.dart';

/// Optimized OpenStreetMap widget for KPK with performance enhancements
class OptimizedOsmMapWidget extends StatefulWidget {
  final LatLng initialCenter;
  final double initialZoom;
  final List<Marker> markers;
  final List<Polyline> polylines;
  final List<CircleMarker> circles;
  final bool showZoomControls;
  final bool showMyLocationButton;
  final bool interactive;
  final Function(LatLng)? onTap;
  final Function(LatLng)? onLongPress;
  final Function()? onMapReady;
  final MapController? controller;

  const OptimizedOsmMapWidget({
    super.key,
    required this.initialCenter,
    this.initialZoom = 12, // Reduced for faster loading
    this.markers = const [],
    this.polylines = const [],
    this.circles = const [],
    this.showZoomControls = true,
    this.showMyLocationButton = true,
    this.interactive = true,
    this.onTap,
    this.onLongPress,
    this.onMapReady,
    this.controller,
  });

  @override
  State<OptimizedOsmMapWidget> createState() => _OptimizedOsmMapWidgetState();
}

class _OptimizedOsmMapWidgetState extends State<OptimizedOsmMapWidget> {
  late final MapController _mapController;
  bool _isLoading = true;

  // CDN tile servers for better performance in Pakistan
  static const List<String> _tileServers = [
    'https://a.tile.openstreetmap.org/{z}/{x}/{y}.png',
    'https://b.tile.openstreetmap.org/{z}/{x}/{y}.png',
    'https://c.tile.openstreetmap.org/{z}/{x}/{y}.png',
  ];

  int _currentTileServer = 0;

  @override
  void initState() {
    super.initState();
    _mapController = widget.controller ?? MapController();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Loading background
        if (_isLoading)
          Container(
            color: Colors.grey[200],
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading map...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),

        // Map
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: widget.initialCenter,
            initialZoom: widget.initialZoom,
            minZoom: 8, // Limit zoom range for performance
            maxZoom: 18,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
            onTap: (tapPos, point) => widget.onTap?.call(point),
            onLongPress: (tapPos, point) => widget.onLongPress?.call(point),
            onMapReady: () {
              setState(() => _isLoading = false);
              widget.onMapReady?.call();
            },
            // KPK bounds for better performance
            cameraConstraint: CameraConstraint.contain(
              bounds: LatLngBounds(
                const LatLng(31.0, 69.0), // SW
                const LatLng(37.0, 75.0), // NE
              ),
            ),
            backgroundColor: Colors.grey[200] ?? Colors.grey,
          ),
          children: [
            _buildOptimizedTileLayer(),
            if (widget.polylines.isNotEmpty)
              PolylineLayer(polylines: widget.polylines),
            if (widget.markers.isNotEmpty) _buildOptimizedMarkerLayer(),
            if (widget.circles.isNotEmpty) CircleLayer(circles: widget.circles),
          ],
        ),

        // Controls
        if (!_isLoading) _buildControls(),
      ],
    );
  }

  Widget _buildOptimizedTileLayer() {
    return TileLayer(
      urlTemplate: _tileServers[_currentTileServer],
      userAgentPackageName: 'com.orginize.app.kpk',
      maxZoom: 18,
      minZoom: 8,
      // Performance optimizations
      keepBuffer: 2,
      panBuffer: 1,
      // Error handling - switch to next server
      errorTileCallback: (tile, error, stackTrace) {
        _currentTileServer = (_currentTileServer + 1) % _tileServers.length;
      },
    );
  }

  Widget _buildOptimizedMarkerLayer() {
    // Implement marker clustering if too many markers
    if (widget.markers.length > 50) {
      return _buildClusteredMarkers();
    }
    return MarkerLayer(markers: widget.markers);
  }

  Widget _buildClusteredMarkers() {
    // Simple clustering implementation
    final clusteredMarkers = <Marker>[];
    final processed = <bool>[];

    for (int i = 0; i < widget.markers.length; i++) {
      processed.add(false);
    }

    for (int i = 0; i < widget.markers.length; i++) {
      if (processed[i]) continue;

      final cluster = <Marker>[widget.markers[i]];
      processed[i] = true;

      // Find nearby markers (within 100m at zoom 15)
      for (int j = i + 1; j < widget.markers.length; j++) {
        if (processed[j]) continue;

        final distance = KpkOptimizedMapService.calculateDistance(
          widget.markers[i].point,
          widget.markers[j].point,
        );

        if (distance < 0.1) {
          // 100m
          cluster.add(widget.markers[j]);
          processed[j] = true;
        }
      }

      if (cluster.length > 1) {
        // Create cluster marker
        clusteredMarkers.add(Marker(
          point: cluster.first.point,
          width: 50,
          height: 50,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Center(
              child: Text(
                cluster.length.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ));
      } else {
        clusteredMarkers.add(cluster.first);
      }
    }

    return MarkerLayer(markers: clusteredMarkers);
  }

  Widget _buildControls() {
    return Positioned(
      right: 16,
      bottom: 100,
      child: Column(
        spacing: 8,
        children: [
          if (widget.showZoomControls) _buildZoomControls(),
          if (widget.showMyLocationButton) _buildMyLocationButton(),
          _buildCacheButton(),
        ],
      ),
    );
  }

  Widget _buildZoomControls() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Column(
        children: [
          IconButton(
            icon: const Icon(Icons.add, size: 28),
            onPressed: () => _mapController.move(
              _mapController.camera.center,
              (_mapController.camera.zoom + 1).clamp(8, 18),
            ),
          ),
          const Divider(height: 1),
          IconButton(
            icon: const Icon(Icons.remove, size: 28),
            onPressed: () => _mapController.move(
              _mapController.camera.center,
              (_mapController.camera.zoom - 1).clamp(8, 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyLocationButton() {
    return FloatingActionButton.small(
      backgroundColor: Colors.white,
      onPressed: _centerOnUserLocation,
      child: const Icon(Icons.my_location, color: AppColors.primary),
    );
  }

  Widget _buildCacheButton() {
    return FloatingActionButton.small(
      backgroundColor: Colors.white,
      onPressed: _showCacheOptions,
      child: const Icon(Icons.download, color: AppColors.primary),
    );
  }

  void _centerOnUserLocation() {
    // Will be connected to location provider
    _mapController.move(_mapController.camera.center, 16);
  }

  void _showCacheOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Map Cache Options',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Preload KPK Data'),
              subtitle: const Text('Download routes for major cities'),
              onTap: () {
                Navigator.pop(context);
                _preloadKpkData();
              },
            ),
            ListTile(
              leading: const Icon(Icons.clear),
              title: const Text('Clear Cache'),
              subtitle: const Text('Free up storage space'),
              onTap: () {
                Navigator.pop(context);
                _clearCache();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _preloadKpkData() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preloading KPK map data...')),
    );

    await KpkOptimizedMapService.preloadKpkData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('KPK data preloaded successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _clearCache() async {
    await KpkOptimizedMapService.clearCaches();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cache cleared successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // Public methods
  void centerOn(LatLng position, {double zoom = 15}) {
    _mapController.move(position, zoom.clamp(8, 18));
  }

  void fitBounds(List<LatLng> points) {
    if (points.length < 2) {
      if (points.isNotEmpty) centerOn(points.first);
      return;
    }
    centerOn(points.first);
  }
}

/// Optimized marker creation helpers
class OptimizedMapMarkers {
  static Marker venue(LatLng position, {VoidCallback? onTap}) {
    return Marker(
      point: position,
      width: 40,
      height: 40,
      alignment: Alignment.topCenter,
      child: GestureDetector(
        onTap: onTap,
        child: const Icon(Icons.location_on, color: Colors.red, size: 40),
      ),
    );
  }

  static Marker rider(LatLng position, {VoidCallback? onTap}) {
    return Marker(
      point: position,
      width: 44,
      height: 44,
      alignment: Alignment.center,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(blurRadius: 6, color: Colors.black26)],
          ),
          child:
              const Icon(Icons.directions_bike, color: Colors.blue, size: 28),
        ),
      ),
    );
  }

  static Marker delivery(
    LatLng position, {
    bool isEmergency = false,
    VoidCallback? onTap,
  }) {
    return Marker(
      point: position,
      width: 50,
      height: 50,
      alignment: Alignment.center,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: Icon(
            isEmergency ? Icons.flash_on : Icons.local_shipping,
            color: isEmergency ? Colors.yellow : Colors.white,
            size: 30,
          ),
        ),
      ),
    );
  }
}

/// Optimized polyline creation helpers
class OptimizedMapPolylines {
  static Polyline route(List<LatLng> points, {Color? color}) {
    return Polyline(
      points: points,
      strokeWidth: 4, // Slightly thinner for performance
      color: color ?? Colors.blue,
      strokeJoin: StrokeJoin.round,
      strokeCap: StrokeCap.round,
    );
  }
}

// Extension for distance calculation
extension LatLngDistance on LatLng {
  double distanceTo(LatLng other) {
    const earthRadius = 6371.0;
    final dLat = (other.latitude - latitude) * (pi / 180);
    final dLon = (other.longitude - longitude) * (pi / 180);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(latitude * (pi / 180)) *
            cos(other.latitude * (pi / 180)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }
}
