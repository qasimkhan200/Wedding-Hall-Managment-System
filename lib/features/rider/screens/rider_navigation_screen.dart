import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/kpk_optimized_map_service.dart';
import '../../../core/services/rider_service.dart';
import '../../../core/services/venue_intelligence_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/widgets/optimized_osm_map_widget.dart';

class RiderNavigationScreen extends StatefulWidget {
  final LatLng destination;
  final String destinationAddress;
  final VenueModel? venueModel;

  const RiderNavigationScreen({
    super.key,
    required this.destination,
    required this.destinationAddress,
    this.venueModel,
  });

  @override
  State<RiderNavigationScreen> createState() => _RiderNavigationScreenState();
}

class _RiderNavigationScreenState extends State<RiderNavigationScreen> {
  final MapController _mapController = MapController();
  LatLng? _currentPosition;
  List<LatLng> _routePoints = [];
  double? _routeDuration;
  double? _routeDistance;
  StreamSubscription? _positionStream;
  bool _isRouting = false;
  bool _hasError = false;
  String _errorMessage = '';

  DateTime? _lastLocationUpdate;
  static const Duration _updateInterval = Duration(minutes: 1);

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  void _initLocation() async {
    try {
      final pos = await LocationService.determinePosition();
      setState(() {
        _currentPosition = LatLng(pos.latitude, pos.longitude);
        _hasError = false;
      });
      _getRoute();
      _updateServerLocation(pos.latitude, pos.longitude);

      _positionStream = LocationService.getPositionStream().listen((pos) {
        if (!mounted) return;
        final newPos = LatLng(pos.latitude, pos.longitude);
        setState(() => _currentPosition = newPos);

        _checkNavigationStatus(newPos);

        final now = DateTime.now();
        if (_lastLocationUpdate == null ||
            now.difference(_lastLocationUpdate!) > _updateInterval) {
          _updateServerLocation(pos.latitude, pos.longitude);
          _lastLocationUpdate = now;
        }
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Location error: ${e.toString()}';
      });
    }
  }

  void _checkNavigationStatus(LatLng pos) {
    if (_routePoints.isEmpty || _isRouting) return;

    final distanceToDest = pos.distanceTo(widget.destination);
    if (distanceToDest < 0.05) {
      // 50 meters
      _handleArrival();
    }
  }

  void _handleArrival() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You have arrived at the destination!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _updateServerLocation(double lat, double lng) async {
    final user = context.read<AuthProvider>().user;
    if (user != null && user.role == 'rider') {
      try {
        await RiderService.updateLocation(
          riderId: user.id,
          latitude: lat,
          longitude: lng,
        );
      } catch (e) {
        debugPrint('Failed to update location: $e');
      }
    }
  }

  Future<void> _getRoute() async {
    if (_currentPosition == null) return;

    setState(() {
      _isRouting = true;
      _hasError = false;
    });

    try {
      final target = widget.venueModel?.serviceEntrance ?? widget.destination;

      // Increased timeout for better route fetching
      final routeInfo = await KpkOptimizedMapService.getRouteWithInfo(
        _currentPosition!,
        target,
      ).timeout(const Duration(seconds: 15), onTimeout: () {
        throw TimeoutException('Route request timed out');
      });

      if (!mounted) return;

      if (routeInfo != null && routeInfo.points.isNotEmpty) {
        setState(() {
          _routePoints = routeInfo.points;
          _routeDuration = routeInfo.duration / 60;
          _routeDistance = routeInfo.distance;
          _isRouting = false;
        });

        // Center map on the route
        if (_routePoints.isNotEmpty) {
          _mapController.move(_routePoints[0], 15);
        }
      } else {
        _setError('No route found. Please check your internet connection.');
      }
    } on TimeoutException catch (_) {
      if (!mounted) return;
      _setError('Route request timed out. Please try again.');
    } catch (e) {
      if (!mounted) return;
      _setError('Unable to get route: ${e.toString()}');
    }
  }

  // Removed straight line fallback - only show proper road routes

  void _setError(String message) {
    setState(() {
      _isRouting = false;
      _hasError = true;
      _errorMessage = message;
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigation'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Map using optimized widget
          OptimizedOsmMapWidget(
            controller: _mapController,
            initialCenter:
                widget.venueModel?.serviceEntrance ?? widget.destination,
            initialZoom: 14,
            markers: [
              // Destination marker
              OptimizedMapMarkers.delivery(
                widget.destination,
                onTap: () {},
              ),
              // Rider marker
              if (_currentPosition != null)
                OptimizedMapMarkers.rider(_currentPosition!),
            ],
            polylines: _routePoints.isNotEmpty
                ? [OptimizedMapPolylines.route(_routePoints)]
                : [],
            showZoomControls: true,
            showMyLocationButton: true,
            onTap: (_) {},
          ),

          // Error banner
          if (_hasError)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    TextButton(
                      onPressed: _getRoute,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),

          // Info Panel
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.destinationAddress,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Venue tips
                    if (widget.venueModel != null) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Column(
                          children: [
                            if (widget.venueModel!.serviceEntrance != null)
                              const Row(children: [
                                Icon(Icons.door_back_door,
                                    size: 16, color: Colors.blue),
                                SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Routing to Service Entrance',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ]),
                            if (widget.venueModel!.parkingTip != null) ...[
                              const SizedBox(height: 4),
                              Row(children: [
                                const Icon(Icons.local_parking,
                                    size: 16, color: Colors.orange),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    widget.venueModel!.parkingTip!,
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.black87),
                                  ),
                                ),
                              ]),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Route info or error state
                    if (_routeDuration != null && _routeDistance != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.timer,
                                size: 16, color: Colors.blue),
                            const SizedBox(width: 4),
                            Text(
                              '${_routeDuration!.toStringAsFixed(0)} min',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue),
                            ),
                            const SizedBox(width: 16),
                            const Icon(Icons.speed,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              '${(_routeDistance! / 1000).toStringAsFixed(1)} km',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    else if (_hasError)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.warning,
                                  size: 16, color: Colors.orange),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Route unavailable - using GPS navigation',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Loading or action buttons
                    if (_isRouting)
                      const Column(
                        children: [
                          LinearProgressIndicator(),
                          SizedBox(height: 8),
                          Text('Getting route...',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      )
                    else if (_hasError)
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _getRoute,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry Route'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.my_location),
                              label: const Text('Center'),
                              onPressed: () {
                                if (_currentPosition != null) {
                                  _mapController.move(_currentPosition!, 15);
                                }
                              },
                            ),
                          ),
                        ],
                      )
                    else
                      ElevatedButton.icon(
                        icon: const Icon(Icons.my_location),
                        label: const Text('Recenter'),
                        onPressed: () {
                          if (_currentPosition != null) {
                            _mapController.move(_currentPosition!, 15);
                          }
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
