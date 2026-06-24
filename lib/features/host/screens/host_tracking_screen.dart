import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../../core/models/order_model.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/delivery_calculation_service.dart';
import '../../../core/providers/order_provider.dart';
import '../../../core/widgets/optimized_osm_map_widget.dart';

class HostTrackingScreen extends StatefulWidget {
  final OrderModel order;

  const HostTrackingScreen({super.key, required this.order});

  @override
  State<HostTrackingScreen> createState() => _HostTrackingScreenState();
}

class _HostTrackingScreenState extends State<HostTrackingScreen> {
  LatLng? _riderPosition;
  late final LatLng _venuePosition;
  StreamSubscription? _riderStream;
  final MapController _mapController = MapController();
  bool _shouldAutoCenter = true;

  @override
  void initState() {
    super.initState();
    _venuePosition = LatLng(
      widget.order.deliveryLatitude,
      widget.order.deliveryLongitude,
    );
    _initRiderTracking();
  }

  void _initRiderTracking() {
    if (widget.order.riderId == null) return;

    _riderStream = FirebaseService.users
        .doc(widget.order.riderId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        if (data['latitude'] != null && data['longitude'] != null) {
          final newPos = LatLng(data['latitude'], data['longitude']);
          setState(() => _riderPosition = newPos);
          if (_shouldAutoCenter) _centerOnBothPoints();
        }
      }
    });
  }

  void _centerOnBothPoints() {
    if (_riderPosition != null) {
      _mapController.move(_riderPosition!, 14);
    }
  }

  @override
  void dispose() {
    _riderStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Order'),
        actions: [
          IconButton(
            icon: const Icon(Icons.center_focus_strong),
            onPressed: () {
              setState(() => _shouldAutoCenter = true);
              _centerOnBothPoints();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          OptimizedOsmMapWidget(
            controller: _mapController,
            initialCenter: _venuePosition,
            initialZoom: 13,
            markers: [
              OptimizedMapMarkers.venue(_venuePosition),
              if (_riderPosition != null)
                OptimizedMapMarkers.rider(_riderPosition!),
            ],
            showZoomControls: true,
            showMyLocationButton: true,
            onTap: (_) {},
          ),
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: _buildStatusCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: const Icon(Icons.person, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.order.riderName ?? 'Rider',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const Text(
                        'On the way to venue',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('In Transit',
                      style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Consumer<OrderProvider>(
              builder: (context, orderProvider, child) {
                String estimatedArrival = 'Calculating...';
                if (orderProvider.currentOrder != null) {
                  final order = orderProvider.currentOrder!;
                  if (order.estimatedDeliveryTime != null) {
                    estimatedArrival =
                        'Estimated Arrival: ${DeliveryCalculationService.formatEstimatedArrival(order.estimatedDeliveryTime!)}';
                  } else if (order.riderLatitude != null &&
                      order.riderLongitude != null) {
                    final distanceKm =
                        DeliveryCalculationService.calculateDistance(
                      lat1: order.riderLatitude!,
                      lon1: order.riderLongitude!,
                      lat2: order.deliveryLatitude,
                      lon2: order.deliveryLongitude,
                    );
                    final estimatedMinutes =
                        DeliveryCalculationService.calculateDeliveryTime(
                      distanceKm: distanceKm,
                      vehicleType: 'bike',
                      preparationTime: 0,
                    );
                    estimatedArrival =
                        'Estimated Arrival: ${DeliveryCalculationService.formatDeliveryTime(estimatedMinutes)}';
                  }
                }
                return Text(estimatedArrival,
                    style: const TextStyle(fontWeight: FontWeight.bold));
              },
            ),
          ],
        ),
      ),
    );
  }
}
