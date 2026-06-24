import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/kpk_optimized_map_service.dart';
import 'optimized_osm_map_widget.dart';
import 'debounced_search_widget.dart';

/// KPK-optimized location picker widget with smart search
class LocationPickerWidget extends StatefulWidget {
  final LatLng? initialPosition;
  final bool showSearchBar;
  final String hintText;
  final Function(LatLng, String) onLocationSelected;
  final double? initialZoom;

  const LocationPickerWidget({
    super.key,
    this.initialPosition,
    this.showSearchBar = true,
    this.hintText = 'Search locations in KPK...',
    required this.onLocationSelected,
    this.initialZoom,
  });

  @override
  State<LocationPickerWidget> createState() => _LocationPickerWidgetState();
}

class _LocationPickerWidgetState extends State<LocationPickerWidget> {
  final MapController _mapController = MapController();

  LatLng? _selectedPosition;
  String _selectedAddress = '';
  bool _isLoadingAddress = false;

  @override
  void initState() {
    super.initState();
    _selectedPosition =
        widget.initialPosition ?? const LatLng(34.0151, 71.5249);
    _reverseGeocodeCurrent();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: OptimizedOsmMapWidget(
              controller: _mapController,
              initialCenter: _selectedPosition!,
              initialZoom: widget.initialZoom ?? 15,
              markers: _selectedPosition != null
                  ? [OptimizedMapMarkers.delivery(_selectedPosition!)]
                  : [],
              onTap: _onMapTap,
              showZoomControls: true,
              showMyLocationButton: true,
            ),
          ),
          if (widget.showSearchBar)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              child: DebouncedSearchWidget(
                hintText: widget.hintText,
                nearLocation: _selectedPosition,
                onLocationSelected: _selectSearchResult,
              ),
            ),
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: _buildAddressCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.location_on, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _isLoadingAddress
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _selectedAddress.isNotEmpty
                              ? _selectedAddress
                              : 'Select a location',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    _selectedPosition != null && _selectedAddress.isNotEmpty
                        ? () => widget.onLocationSelected(
                              _selectedPosition!,
                              _selectedAddress,
                            )
                        : null,
                child: const Text('Confirm Location'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectSearchResult(PlaceSearchResult result) {
    setState(() {
      _selectedPosition = result.position;
      _selectedAddress = result.displayName;
    });

    _mapController.move(result.position, 16);
  }

  void _onMapTap(LatLng position) {
    setState(() => _selectedPosition = position);
    _reverseGeocodeCurrent();
  }

  Future<void> _reverseGeocodeCurrent() async {
    if (_selectedPosition == null) return;

    setState(() => _isLoadingAddress = true);
    try {
      // Use KPK optimized service for reverse geocoding
      final results = await KpkOptimizedMapService.searchPlaces(
        '${_selectedPosition!.latitude},${_selectedPosition!.longitude}',
        limit: 1,
        nearLocation: _selectedPosition,
      );

      if (mounted && results.isNotEmpty) {
        setState(() {
          _selectedAddress = results.first.displayName;
        });
      } else if (mounted) {
        setState(() {
          _selectedAddress = 'Location in KPK, Pakistan';
        });
      }
    } catch (e) {
      debugPrint('Reverse geocoding error: $e');
      if (mounted) {
        setState(() {
          _selectedAddress = 'Selected location';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoadingAddress = false);
    }
  }
}
