import 'dart:io';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class OfflineMapService {
  final Dio _dio = Dio();
  bool _isDownloading = false;

  // Peshawar Bounds
  // SW: 33.9, 71.3
  // NE: 34.2, 71.8
  static const double minLat = 33.9;
  static const double minLng = 71.3;
  static const double maxLat = 34.2;
  static const double maxLng = 71.8;

  bool get isDownloading => _isDownloading;

  Future<String> _getTileCachePath() async {
    final dir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${dir.path}/map_tiles');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir.path;
  }

  Future<void> downloadPeshawarRegion({
    required Function(double progress) onProgress,
  }) async {
    if (_isDownloading) return;
    _isDownloading = true;

    try {
      final cachePath = await _getTileCachePath();
      int totalTiles = 0;
      int downloadedTiles = 0;

      // Calculate total tiles first for progress
      for (int z = 12; z <= 15; z++) {
        final p1 = _project(minLat, minLng, z);
        final p2 = _project(maxLat, maxLng, z);
        totalTiles += ((p2.x - p1.x).abs() + 1) * ((p2.y - p1.y).abs() + 1);
      }

      print('Total tiles to download for Peshawar: $totalTiles');

      for (int z = 12; z <= 15; z++) {
        final p1 = _project(minLat, minLng, z);
        final p2 = _project(maxLat, maxLng, z);

        final xMin = p1.x < p2.x ? p1.x : p2.x;
        final xMax = p1.x > p2.x ? p1.x : p2.x;
        final yMin = p1.y < p2.y ? p1.y : p2.y;
        final yMax = p1.y > p2.y ? p1.y : p2.y;

        for (int x = xMin; x <= xMax; x++) {
          for (int y = yMin; y <= yMax; y++) {
            if (!_isDownloading) break;

            final url = 'https://tile.openstreetmap.org/$z/$x/$y.png';
            final savePath = '$cachePath/$z/$x/$y.png';
            final file = File(savePath);

            if (!await file.exists()) {
              await file.parent.create(recursive: true);
              try {
                await _dio.download(url, savePath,
                    options:
                        Options(headers: {'User-Agent': 'com.orginize.app'}));
                // Simple throttle
                await Future.delayed(const Duration(milliseconds: 50));
              } catch (e) {
                print('Failed to download tile $z/$x/$y: $e');
              }
            }

            downloadedTiles++;
            onProgress(downloadedTiles / totalTiles);
          }
        }
      }
    } catch (e) {
      print('Error downloading region: $e');
      rethrow;
    } finally {
      _isDownloading = false;
    }
  }

  void cancelDownload() {
    _isDownloading = false;
  }

  // Helper to convert LatLng to Tile Coordinates
  Point<int> _project(double lat, double lng, int zoom) {
    var n = 1 << zoom;
    var x = (n * (lng + 180) / 360).floor();
    var latRad = lat * pi / 180;
    var y = (n * (1 - (log(tan(latRad) + 1 / cos(latRad)) / pi)) / 2).floor();
    return Point(x, y);
  }
}
