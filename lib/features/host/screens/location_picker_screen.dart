import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../../core/services/location_service.dart';
import '../../../../../core/services/geocoding_service.dart';

class LocationPickerScreen extends StatefulWidget {
  final LatLng? initialPosition;
  final bool isSelectingVenue; // If true, emphasizes venues

  const LocationPickerScreen({
    super.key,
    this.initialPosition,
    this.isSelectingVenue = false,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController =
      TextEditingController(); // Add controller
  LatLng _currentCenter = const LatLng(34.0151, 71.5249); // Default to Peshawar
  bool _isLoadingLocation = true;
  String _searchHint = 'Search Location...';

  @override
  void initState() {
    super.initState();
    _searchHint = widget.isSelectingVenue
        ? 'Search Venue (e.g. Shiraz Arena)'
        : 'Search Place (e.g. University of Peshawar)';

    if (widget.initialPosition != null) {
      _currentCenter = widget.initialPosition!;
      _isLoadingLocation = false;
    } else {
      _getCurrentLocation();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final pos = await LocationService.determinePosition();
      setState(() {
        _currentCenter = LatLng(pos.latitude, pos.longitude);
        _isLoadingLocation = false;
      });
    } catch (e) {
      setState(() => _isLoadingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset:
          false, // Prevent map resize/rebuild on keyboard open
      appBar: AppBar(
        title: Text(widget.isSelectingVenue ? 'Pick Venue' : 'Pick Location'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () async {
              setState(() => _isLoadingLocation = true);
              String displayName = 'Pinned Location';
              try {
                final address =
                    await GeocodingService.getAddressFromCoordinates(
                        _currentCenter);
                if (address != null && address.isNotEmpty)
                  displayName = address;
              } catch (e) {}
              if (mounted) {
                Navigator.pop(
                  context,
                  GeocodingResult(
                      displayName: displayName, location: _currentCenter),
                );
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          _isLoadingLocation
              ? const Center(child: CircularProgressIndicator())
              : FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentCenter,
                    initialZoom: 15,
                    onPositionChanged: (pos, hasGesture) {
                      _currentCenter = pos.center!;
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.orginize.app',
                    ),
                  ],
                ),

          // Center Pin
          Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 40.h),
              child: Icon(Icons.location_on, color: Colors.blue, size: 50.w),
            ),
          ),

          // Search Bar (Top)
          Positioned(
            top: 10.h, // Adjusted top margin
            left: 10.w,
            right: 10.w,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(12.r), // Rounded like the image
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Row(
                      children: [
                        Icon(Icons.search,
                            color: Theme.of(context).primaryColor, size: 24.w),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: _searchHint,
                              hintStyle: TextStyle(
                                  color: Colors.grey[400], fontSize: 14.sp),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 14.h), // Better vertical padding
                            ),
                            onChanged: (val) => setState(() {}),
                            onSubmitted: (value) async {
                              if (value.trim().isEmpty) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Searching...'),
                                    duration: Duration(milliseconds: 500)),
                              );

                              final results =
                                  await GeocodingService.searchLocation(value);

                              if (results.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('No results found')),
                                );
                                return;
                              }

                              if (mounted) {
                                showDialog(
                                    context: context,
                                    builder: (context) => SimpleDialog(
                                          title: const Text('Select Location'),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16.r)),
                                          children: results
                                              .map((res) => SimpleDialogOption(
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                      _mapController.move(
                                                          res.location, 16);
                                                      setState(() {
                                                        _currentCenter =
                                                            res.location;
                                                      });
                                                    },
                                                    child: Padding(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                              vertical: 8.h),
                                                      child: Row(
                                                        children: [
                                                          Icon(
                                                              res.isVerifiedVenue
                                                                  ? Icons
                                                                      .verified
                                                                  : Icons.place,
                                                              color: res
                                                                      .isVerifiedVenue
                                                                  ? Colors.blue
                                                                  : Colors.grey
                                                                      .shade600),
                                                          SizedBox(width: 12.w),
                                                          Expanded(
                                                            child: Text(
                                                              res.displayName,
                                                              maxLines: 2,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style: TextStyle(
                                                                fontWeight: res
                                                                        .isVerifiedVenue
                                                                    ? FontWeight
                                                                        .bold
                                                                    : FontWeight
                                                                        .normal,
                                                                fontSize: 14.sp,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ))
                                              .toList(),
                                        ));
                              }
                            },
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              _searchController.clear();
                              setState(() {}); // Rebuild to hide button
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Current Location FAB
          Positioned(
            bottom: 100.h, // FIX: Moved up to avoid overlap with Confirm Button
            right: 20.w,
            child: FloatingActionButton(
              child: const Icon(Icons.my_location),
              onPressed: () async {
                final pos = await LocationService.determinePosition();
                _mapController.move(LatLng(pos.latitude, pos.longitude), 15);
              },
            ),
          ),

          // Confirm Button (Bottom)
          Positioned(
            bottom: 30.h,
            left: 20.w,
            right: 20
                .w, // FIX: Added right constraint to prevent infinite width error
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check_circle),
              label: const Text('Confirm Location'),
              onPressed: () async {
                setState(() => _isLoadingLocation = true);

                String displayName = 'Pinned Location';
                try {
                  final address =
                      await GeocodingService.getAddressFromCoordinates(
                          _currentCenter);
                  if (address != null && address.isNotEmpty) {
                    displayName = address;
                  }
                } catch (e) {
                  // Keep default
                }

                if (mounted) {
                  Navigator.pop(
                    context,
                    GeocodingResult(
                      displayName: displayName,
                      location: _currentCenter,
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
