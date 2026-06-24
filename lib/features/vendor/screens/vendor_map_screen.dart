import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../core/models/order_model.dart';
import '../../../core/providers/order_provider.dart';
import '../../../core/widgets/optimized_osm_map_widget.dart';

class VendorMapScreen extends StatefulWidget {
  const VendorMapScreen({super.key});

  @override
  State<VendorMapScreen> createState() => _VendorMapScreenState();
}

class _VendorMapScreenState extends State<VendorMapScreen> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Active Deliveries Map')),
      body: Consumer<OrderProvider>(
        builder: (context, provider, child) {
          final orders = provider.activeOrders;
          if (orders.isEmpty) {
            return const Center(child: Text('No active deliveries to show'));
          }

          final validOrders = orders
              .where((o) => o.deliveryLatitude != 0 && o.deliveryLongitude != 0)
              .toList();

          if (validOrders.isEmpty) {
            return const Center(
                child: Text('No deliveries with location data'));
          }

          final center = LatLng(
            validOrders.first.deliveryLatitude,
            validOrders.first.deliveryLongitude,
          );

          return Stack(
            children: [
              OptimizedOsmMapWidget(
                controller: _mapController,
                initialCenter: center,
                initialZoom: 12,
                markers: validOrders.map((order) {
                  return OptimizedMapMarkers.delivery(
                    LatLng(order.deliveryLatitude, order.deliveryLongitude),
                    isEmergency: order.isEmergency,
                    onTap: () => _showOrderDetails(context, order),
                  );
                }).toList(),
                showZoomControls: true,
                showMyLocationButton: true,
                onTap: (_) {},
              ),
              // Order count badge
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 4)
                    ],
                  ),
                  child: Text(
                    '${validOrders.length} Active Deliveries',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showOrderDetails(BuildContext context, OrderModel order) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order #${order.id}',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text('Host: ${order.hostName}'),
            Text('Address: ${order.deliveryAddress}'),
            Text('Status: ${order.status}'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('View Details'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
