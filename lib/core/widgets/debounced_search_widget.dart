import 'package:flutter/material.dart';
import 'dart:async';
import '../services/kpk_optimized_map_service.dart';
import 'package:latlong2/latlong.dart';

/// Debounced search widget optimized for KPK locations
class DebouncedSearchWidget extends StatefulWidget {
  final String hintText;
  final Function(PlaceSearchResult) onLocationSelected;
  final LatLng? nearLocation;
  final bool showRecentSearches;

  const DebouncedSearchWidget({
    super.key,
    this.hintText = 'Search locations in KPK...',
    required this.onLocationSelected,
    this.nearLocation,
    this.showRecentSearches = true,
  });

  @override
  State<DebouncedSearchWidget> createState() => _DebouncedSearchWidgetState();
}

class _DebouncedSearchWidgetState extends State<DebouncedSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  List<PlaceSearchResult> _searchResults = [];
  List<String> _recentSearches = [];
  bool _isSearching = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchField(),
        if (_searchResults.isNotEmpty || _recentSearches.isNotEmpty)
          _buildResultsList(),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      focusNode: _searchFocus,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _isSearching
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _clearSearch,
                  )
                : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      onChanged: _onSearchChanged,
      onSubmitted: (_) => _performSearch(),
    );
  }

  Widget _buildResultsList() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Column(
        children: [
          // Search results
          if (_searchResults.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.search, size: 16, color: Colors.grey),
                  SizedBox(width: 8),
                  Text(
                    'Search Results',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            ...(_searchResults
                .take(5)
                .map((result) => _buildResultTile(result))),
          ],

          // Recent searches (only when no search results)
          if (_searchResults.isEmpty &&
              _recentSearches.isNotEmpty &&
              widget.showRecentSearches &&
              _searchController.text.isEmpty) ...[
            const Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.history, size: 16, color: Colors.grey),
                  SizedBox(width: 8),
                  Text(
                    'Recent Searches',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            ...(_recentSearches
                .take(3)
                .map((search) => _buildRecentSearchTile(search))),
          ],

          // KPK cities quick access
          if (_searchResults.isEmpty && _searchController.text.isEmpty) ...[
            const Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.location_city, size: 16, color: Colors.grey),
                  SizedBox(width: 8),
                  Text(
                    'Popular Cities in KPK',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            ..._buildKpkCityTiles(),
          ],
        ],
      ),
    );
  }

  Widget _buildResultTile(PlaceSearchResult result) {
    return ListTile(
      leading: const Icon(Icons.location_on_outlined),
      title: Text(
        _getShortName(result.displayName),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        result.displayName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12),
      ),
      onTap: () => _selectResult(result),
    );
  }

  Widget _buildRecentSearchTile(String search) {
    return ListTile(
      leading: const Icon(Icons.history, color: Colors.grey),
      title: Text(search),
      trailing: IconButton(
        icon: const Icon(Icons.close, size: 16),
        onPressed: () => _removeRecentSearch(search),
      ),
      onTap: () {
        _searchController.text = search;
        _performSearch();
      },
    );
  }

  List<Widget> _buildKpkCityTiles() {
    final cities = [
      'Peshawar',
      'Islamabad',
      'Rawalpindi',
      'Mardan',
      'Abbottabad'
    ];

    return cities
        .map((city) => ListTile(
              leading: const Icon(Icons.location_city, color: Colors.blue),
              title: Text(city),
              subtitle: const Text('Major city in KPK'),
              onTap: () {
                _searchController.text = city;
                _performSearch();
              },
            ))
        .toList();
  }

  void _onSearchChanged(String value) {
    if (value.length >= 2) {
      _debounceSearch();
    } else {
      setState(() {
        _searchResults = [];
      });
    }
  }

  void _debounceSearch() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) _performSearch();
    });
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isSearching = true);

    try {
      final results = await KpkOptimizedMapService.searchPlaces(
        query,
        nearLocation: widget.nearLocation,
      );

      if (mounted) {
        setState(() {
          _searchResults = results;
        });
      }
    } catch (e) {
      debugPrint('Search error: $e');
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  void _selectResult(PlaceSearchResult result) {
    _searchController.clear();
    _searchResults = [];
    _searchFocus.unfocus();

    _addToRecentSearches(result.displayName);
    widget.onLocationSelected(result);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = [];
    });
  }

  String _getShortName(String fullName) {
    final parts = fullName.split(',');
    return parts.first.trim();
  }

  Future<void> _loadRecentSearches() async {
    // Load from SharedPreferences
    // Implementation would load recent searches
    setState(() {
      _recentSearches = []; // Placeholder
    });
  }

  Future<void> _addToRecentSearches(String search) async {
    final shortName = _getShortName(search);
    _recentSearches.remove(shortName);
    _recentSearches.insert(0, shortName);

    if (_recentSearches.length > 10) {
      _recentSearches.removeRange(10, _recentSearches.length);
    }

    // Save to SharedPreferences
    // Implementation would save recent searches
  }

  Future<void> _removeRecentSearch(String search) async {
    setState(() {
      _recentSearches.remove(search);
    });
    // Save to SharedPreferences
  }
}
