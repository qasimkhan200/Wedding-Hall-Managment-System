// DEPRECATED: This widget is no longer used
// Mapbox integration was abandoned due to build conflicts with Android Gradle
// The app now uses a simple map placeholder instead
// This file is kept for reference only and can be deleted

// import 'package:flutter/material.dart';
// import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
// import 'package:provider/provider.dart';
// import '../config/env_config.dart';
// import '../providers/location_provider.dart';

// class MapboxMapWidget extends StatefulWidget {
//   final double? initialLatitude;
//   final double? initialLongitude;
//   final bool showUserLocation;
//   final bool allowUserInteraction;
//   final Function(MapboxMap)? onMapCreated;

//   const MapboxMapWidget({
//     super.key,
//     this.initialLatitude,
//     this.initialLongitude,
//     this.showUserLocation = true,
//     this.allowUserInteraction = true,
//     this.onMapCreated,
//   });

//   @override
//   State<MapboxMapWidget> createState() => _MapboxMapWidgetState();
// }

// class _MapboxMapWidgetState extends State<MapboxMapWidget> {
//   @override
//   Widget build(BuildContext context) {
//     if (!EnvConfig.isMapboxConfigured) {
//       return Container(
//         color: Colors.grey[200],
//         child: const Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(Icons.map, size: 60, color: Colors.grey),
//               SizedBox(height: 16),
//               Text(
//                 'Mapbox not configured',
//                 style: TextStyle(
//                   fontSize: 16,
//                   color: Colors.grey,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//               SizedBox(height: 8),
//               Text(
//                 'Add MAPBOX_ACCESS_TOKEN to .env file',
//                 style: TextStyle(
//                   fontSize: 12,
//                   color: Colors.grey,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       );
//     }

//     return Consumer<LocationProvider>(
//       builder: (context, locationProvider, child) {
//         final lat = widget.initialLatitude ?? locationProvider.latitude ?? 0.0;
//         final lng =
//             widget.initialLongitude ?? locationProvider.longitude ?? 0.0;

//         return MapWidget(
//           key: ValueKey('map_${lat}_$lng'),
//           cameraOptions: CameraOptions(
//             center: Point(coordinates: Position(lng, lat)),
//             zoom: 14.0,
//           ),
//           styleUri: MapboxStyles.MAPBOX_STREETS,
//           textureView: true,
//           onMapCreated: _onMapCreated,
//         );
//       },
//     );
//   }

//   void _onMapCreated(MapboxMap mapboxMap) {
//     widget.onMapCreated?.call(mapboxMap);
//   }

//   @override
//   void dispose() {
//     super.dispose();
//   }
// }
