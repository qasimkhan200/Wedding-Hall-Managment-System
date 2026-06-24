// DEPRECATED: This file is no longer used
// Mapbox integration was abandoned due to build conflicts with Android Gradle
// The app now uses a simple map placeholder instead
// This file is kept for reference only and can be deleted

// import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
// import '../config/env_config.dart';

// class MapboxService {
//   static String get accessToken => EnvConfig.mapboxAccessToken;

//   static void initialize() {
//     // Initialize Mapbox with access token
//     MapboxOptions.setAccessToken(EnvConfig.mapboxAccessToken);
//   }

//   static CameraOptions getInitialCameraOptions({
//     double? latitude,
//     double? longitude,
//   }) {
//     return CameraOptions(
//       center: Point(
//           coordinates: Position(
//         longitude ?? 77.2090,
//         latitude ?? 28.6139,
//       )),
//       zoom: 14.0,
//     );
//   }

//   static Position createPosition({
//     required double latitude,
//     required double longitude,
//   }) {
//     return Position(longitude, latitude);
//   }
// }
