import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Performance monitoring utility for KPK map optimizations
class MapPerformanceMonitor {
  static final Map<String, List<int>> _sessionMetrics = {};
  static const String _metricsKey = 'map_performance_metrics';
  static const int _maxStoredMetrics = 100;

  /// Record a performance metric
  static void recordMetric(String name, int milliseconds) {
    _sessionMetrics[name] ??= [];
    _sessionMetrics[name]!.add(milliseconds);

    developer.log('Performance: $name took ${milliseconds}ms');

    // Store to persistent storage for analytics
    _storeMetric(name, milliseconds);
  }

  /// Record map loading time
  static void recordMapLoad(int milliseconds) {
    recordMetric('map_load', milliseconds);
  }

  /// Record search time
  static void recordSearch(int milliseconds, int resultCount) {
    recordMetric('search', milliseconds);
    recordMetric('search_results', resultCount);
  }

  /// Record route calculation time
  static void recordRoute(int milliseconds, double distanceKm) {
    recordMetric('route_calculation', milliseconds);
    recordMetric('route_distance', distanceKm.round());
  }

  /// Record cache hit
  static void recordCacheHit(String type) {
    recordMetric('${type}_cache_hit', 1);
  }

  /// Record cache miss
  static void recordCacheMiss(String type) {
    recordMetric('${type}_cache_miss', 1);
  }

  /// Get session statistics
  static Map<String, Map<String, double>> getSessionStats() {
    final stats = <String, Map<String, double>>{};

    _sessionMetrics.forEach((name, values) {
      if (values.isNotEmpty) {
        final sum = values.reduce((a, b) => a + b);
        final avg = sum / values.length;
        final min = values.reduce((a, b) => a < b ? a : b);
        final max = values.reduce((a, b) => a > b ? a : b);

        stats[name] = {
          'count': values.length.toDouble(),
          'average': avg,
          'min': min.toDouble(),
          'max': max.toDouble(),
          'total': sum.toDouble(),
        };
      }
    });

    return stats;
  }

  /// Print performance report to console
  static void printReport() {
    developer.log('=== MAP PERFORMANCE REPORT ===');

    final stats = getSessionStats();

    if (stats.isEmpty) {
      developer.log('No performance metrics recorded');
      return;
    }

    stats.forEach((name, metrics) {
      final count = metrics['count']!.toInt();
      final avg = metrics['average']!.toInt();
      final min = metrics['min']!.toInt();
      final max = metrics['max']!.toInt();

      developer
          .log('$name: count=$count, avg=${avg}ms, min=${min}ms, max=${max}ms');
    });

    // Calculate cache hit rates
    _printCacheStats();

    developer.log('=== END REPORT ===');
  }

  /// Print cache statistics
  static void _printCacheStats() {
    final routeHits = _sessionMetrics['route_cache_hit']?.length ?? 0;
    final routeMisses = _sessionMetrics['route_cache_miss']?.length ?? 0;
    final searchHits = _sessionMetrics['search_cache_hit']?.length ?? 0;
    final searchMisses = _sessionMetrics['search_cache_miss']?.length ?? 0;

    if (routeHits + routeMisses > 0) {
      final routeHitRate =
          (routeHits / (routeHits + routeMisses) * 100).toInt();
      developer.log(
          'Route cache hit rate: $routeHitRate% ($routeHits/${routeHits + routeMisses})');
    }

    if (searchHits + searchMisses > 0) {
      final searchHitRate =
          (searchHits / (searchHits + searchMisses) * 100).toInt();
      developer.log(
          'Search cache hit rate: $searchHitRate% ($searchHits/${searchHits + searchMisses})');
    }
  }

  /// Store metric to persistent storage
  static Future<void> _storeMetric(String name, int value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_metricsKey);

      Map<String, List<dynamic>> metrics = {};
      if (stored != null) {
        metrics = Map<String, List<dynamic>>.from(json.decode(stored));
      }

      metrics[name] ??= [];
      metrics[name]!.add({
        'value': value,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      // Keep only recent metrics
      if (metrics[name]!.length > _maxStoredMetrics) {
        metrics[name] =
            metrics[name]!.sublist(metrics[name]!.length - _maxStoredMetrics);
      }

      await prefs.setString(_metricsKey, json.encode(metrics));
    } catch (e) {
      developer.log('Failed to store metric: $e');
    }
  }

  /// Get historical metrics from storage
  static Future<Map<String, List<Map<String, dynamic>>>>
      getHistoricalMetrics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_metricsKey);

      if (stored != null) {
        final data = Map<String, List<dynamic>>.from(json.decode(stored));
        return data.map((key, value) => MapEntry(
              key,
              value.map((item) => Map<String, dynamic>.from(item)).toList(),
            ));
      }
    } catch (e) {
      developer.log('Failed to load historical metrics: $e');
    }

    return {};
  }

  /// Clear all stored metrics
  static Future<void> clearMetrics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_metricsKey);
      _sessionMetrics.clear();
      developer.log('Performance metrics cleared');
    } catch (e) {
      developer.log('Failed to clear metrics: $e');
    }
  }

  /// Get performance summary for UI display
  static Map<String, String> getPerformanceSummary() {
    final stats = getSessionStats();
    final summary = <String, String>{};

    // Map load performance
    if (stats.containsKey('map_load')) {
      final avg = stats['map_load']!['average']!.toInt();
      summary['Map Load'] = '${avg}ms avg';
    }

    // Search performance
    if (stats.containsKey('search')) {
      final avg = stats['search']!['average']!.toInt();
      summary['Search'] = '${avg}ms avg';
    }

    // Route performance
    if (stats.containsKey('route_calculation')) {
      final avg = stats['route_calculation']!['average']!.toInt();
      summary['Routes'] = '${avg}ms avg';
    }

    // Cache hit rates
    final routeHits = _sessionMetrics['route_cache_hit']?.length ?? 0;
    final routeMisses = _sessionMetrics['route_cache_miss']?.length ?? 0;
    if (routeHits + routeMisses > 0) {
      final hitRate = (routeHits / (routeHits + routeMisses) * 100).toInt();
      summary['Cache Hit Rate'] = '$hitRate%';
    }

    return summary;
  }

  /// Check if performance is within acceptable limits
  static Map<String, bool> getPerformanceHealth() {
    final stats = getSessionStats();
    final health = <String, bool>{};

    // Map load should be < 5000ms
    if (stats.containsKey('map_load')) {
      health['map_load'] = stats['map_load']!['average']! < 5000;
    }

    // Search should be < 1000ms
    if (stats.containsKey('search')) {
      health['search'] = stats['search']!['average']! < 1000;
    }

    // Route calculation should be < 10000ms
    if (stats.containsKey('route_calculation')) {
      health['route_calculation'] =
          stats['route_calculation']!['average']! < 10000;
    }

    // Cache hit rate should be > 60%
    final routeHits = _sessionMetrics['route_cache_hit']?.length ?? 0;
    final routeMisses = _sessionMetrics['route_cache_miss']?.length ?? 0;
    if (routeHits + routeMisses > 0) {
      final hitRate = routeHits / (routeHits + routeMisses);
      health['cache_performance'] = hitRate > 0.6;
    }

    return health;
  }

  /// Start performance monitoring for a specific operation
  static PerformanceTimer startTimer(String operation) {
    return PerformanceTimer(operation);
  }
}

/// Timer utility for measuring performance
class PerformanceTimer {
  final String _operation;
  final Stopwatch _stopwatch;

  PerformanceTimer(this._operation) : _stopwatch = Stopwatch()..start();

  /// Stop the timer and record the metric
  void stop() {
    _stopwatch.stop();
    MapPerformanceMonitor.recordMetric(
        _operation, _stopwatch.elapsedMilliseconds);
  }

  /// Get elapsed time without stopping
  int get elapsedMilliseconds => _stopwatch.elapsedMilliseconds;
}

/// Extension for easy performance monitoring
extension PerformanceMonitoring on Future<T> Function<T>() {
  Future<T> withPerformanceMonitoring<T>(String operation) async {
    final timer = MapPerformanceMonitor.startTimer(operation);
    try {
      final result = await this();
      timer.stop();
      return result;
    } catch (e) {
      timer.stop();
      rethrow;
    }
  }
}
