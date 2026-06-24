import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_colors.dart';

/// Unified OpenStreetMap widget with built-in controls and common features
class OsmMapWidget extends StatefulWidget {
  final LatLng initialCenter;
  final double initialZoom;
  final List<Marker> markers;
  final List<Polyline> polylines;
  final List<CircleMarker> circles;
  final bool showZoomControls;
  final bool showMyLocationButton;
  final bool showLayerSelector;
  final bool showScaleBar;
  final bool interactive;
  final bool autoCenter;
  final Function(LatLng)? onTap;
  final Function(LatLng)? onLongPress;
  final Function()? onMapReady;
  final MapController? controller;

  const OsmMapWidget({
    super.key,
    required this.initialCenter,
    this.initialZoom = 14,
    this.markers = const [],
    this.polylines = const [],
    this.circles = const [],
    this.showZoomControls = true,
    this.showMyLocationButton = true,
    this.showLayerSelector = false,
    this.showScaleBar = false,
    this.interactive = true,
    this.autoCenter = true,
    this.onTap,
    this.onLongPress,
    this.onMapReady,
    this.controller,
  });

  @override
  State<OsmMapWidget> createState() => _OsmMapWidgetState();
}

class _OsmMapWidgetState extends State<OsmMapWidget> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = widget.controller ?? MapController();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: widget.initialCenter,
            initialZoom: widget.initialZoom,
            interactiveFlags: widget.interactive
                ? InteractiveFlag.all & ~InteractiveFlag.rotate
                : InteractiveFlag.none,
            onTap: (tapPos, point) => widget.onTap?.call(point),
            onLongPress: (tapPos, point) => widget.onLongPress?.call(point),
            onMapReady: widget.onMapReady,
          ),
          children: [
            _buildTileLayer(),
            if (widget.polylines.isNotEmpty)
              PolylineLayer(polylines: widget.polylines),
            if (widget.markers.isNotEmpty) MarkerLayer(markers: widget.markers),
            if (widget.circles.isNotEmpty) CircleLayer(circles: widget.circles),
          ],
        ),
        _buildControls(),
      ],
    );
  }

  Widget _buildTileLayer() {
    return TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.orginize.app',
      maxZoom: 19,
      minZoom: 5,
    );
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
        ],
      ),
    );
  }

  Widget _buildZoomControls() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Column(
        children: [
          IconButton(
            icon: const Icon(Icons.add, size: 28),
            onPressed: () => _mapController.move(
              _mapController.camera.center,
              _mapController.camera.zoom + 1,
            ),
          ),
          const Divider(height: 1),
          IconButton(
            icon: const Icon(Icons.remove, size: 28),
            onPressed: () => _mapController.move(
              _mapController.camera.center,
              _mapController.camera.zoom - 1,
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

  void _centerOnUserLocation() {
    _mapController.move(
      _mapController.camera.center,
      16,
    );
  }

  void centerOn(LatLng position, {double zoom = 15}) {
    _mapController.move(position, zoom);
  }

  void fitBounds(List<LatLng> points) {
    if (points.length < 2) {
      if (points.isNotEmpty) centerOn(points.first);
      return;
    }
    centerOn(points.first);
  }
}

/// Marker creation helpers
class MapMarkers {
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
          decoration: BoxDecoration(
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
            boxShadow: [const BoxShadow(color: Colors.black26, blurRadius: 4)],
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

/// Polyline creation helpers
class MapPolylines {
  static Polyline route(List<LatLng> points, {Color? color}) {
    return Polyline(
      points: points,
      strokeWidth: 5,
      color: color ?? Colors.blue,
      strokeJoin: StrokeJoin.round,
      strokeCap: StrokeCap.round,
    );
  }
}

/// Circle creation helpers
class MapCircles {
  static CircleMarker distance(
    LatLng center,
    double radiusMeters, {
    Color? color,
  }) {
    return CircleMarker(
      point: center,
      radius: radiusMeters,
      color: (color ?? Colors.blue).withOpacity(0.2),
      borderColor: (color ?? Colors.blue).withOpacity(0.5),
      borderStrokeWidth: 2,
    );
  }
}
