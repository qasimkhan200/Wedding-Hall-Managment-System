import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

class VenueModel {
  final String id;
  final String name;
  final LatLng location;
  final LatLng? serviceEntrance; // Specific entrance for riders
  final String? parkingTip; // e.g., "Park at the back gate"
  final Map<String, dynamic> metadata;

  VenueModel({
    required this.id,
    required this.name,
    required this.location,
    this.serviceEntrance,
    this.parkingTip,
    this.metadata = const {},
  });

  factory VenueModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final locGeo = data['location'] as GeoPoint;
    final servGeo = data['serviceEntrance'] as GeoPoint?;

    return VenueModel(
      id: doc.id,
      name: data['name'] ?? '',
      location: LatLng(locGeo.latitude, locGeo.longitude),
      serviceEntrance:
          servGeo != null ? LatLng(servGeo.latitude, servGeo.longitude) : null,
      parkingTip: data['parkingTip'],
      metadata: data['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'location': GeoPoint(location.latitude, location.longitude),
      'serviceEntrance': serviceEntrance != null
          ? GeoPoint(serviceEntrance!.latitude, serviceEntrance!.longitude)
          : null,
      'parkingTip': parkingTip,
      'metadata': metadata,
    };
  }
}

class VenueIntelligenceService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'peshawar_venues';

  // Get all venues (could be optimized with geoquery later)
  static Future<List<VenueModel>> getAllVenues() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      return snapshot.docs.map((doc) => VenueModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error fetching venues: $e');
      return [];
    }
  }

  // Get specific venue details
  static Future<VenueModel?> getVenue(String venueId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(venueId).get();
      if (doc.exists) {
        return VenueModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error fetching venue: $e');
      return null;
    }
  }

  // Seed Data for Peshawar Venues
  static Future<void> seedPeshawarVenues() async {
    final List<VenueModel> venues = [
      VenueModel(
        id: 'venue_shiraz_arena',
        name: 'Shiraz Arena',
        location: const LatLng(34.0044, 71.4827), // University Rd
        serviceEntrance: const LatLng(34.0040, 71.4820), // Back gate
        parkingTip: 'Use service lane on University Rd for quick drop-off.',
        metadata: {'type': 'wedding_hall', 'capacity': 500, 'rating': 4.5},
      ),
      VenueModel(
        id: 'venue_garrison_club',
        name: 'Garrison Club',
        location: const LatLng(34.0175, 71.5583), // Saddar
        serviceEntrance: const LatLng(34.0180, 71.5590), // Side gate
        parkingTip: 'Driver requires ID card for fast entry at Gate 2.',
        metadata: {'type': 'club', 'capacity': 1000, 'rating': 4.8},
      ),
      VenueModel(
        id: 'venue_pc_hotel',
        name: 'Pearl Continental (PC) Peshawar',
        location: const LatLng(34.0182, 71.5414), // Khyber Rd
        serviceEntrance: const LatLng(34.0175, 71.5410), // Delivery dock
        parkingTip: 'Go to backend delivery dock via Khyber Rd service lane.',
        metadata: {'type': 'hotel', 'capacity': 2000, 'rating': 4.9},
      ),
      VenueModel(
        id: 'venue_sheltons_rezidor',
        name: 'Shelton\'s Rezidor',
        location: const LatLng(33.9995, 71.4912), // University Rd
        serviceEntrance: null,
        parkingTip: 'Narrow entrance, park on main road if crowded.',
        metadata: {'type': 'wedding_hall', 'capacity': 400, 'rating': 4.3},
      ),
      VenueModel(
        id: 'venue_royal_grand',
        name: 'The Royal Grand',
        location: const LatLng(33.9850, 71.5200), // Ring Road area approx
        serviceEntrance: const LatLng(33.9855, 71.5205),
        parkingTip: 'Wide parking available at front.',
        metadata: {'type': 'wedding_hall', 'capacity': 800, 'rating': 4.4},
      ),
    ];

    try {
      final batch = _firestore.batch();
      for (var venue in venues) {
        final docRef = _firestore.collection(_collection).doc(venue.id);
        batch.set(docRef, venue.toMap());
      }
      await batch.commit();
      print('Successfully seeded ${venues.length} venues into $_collection');
    } catch (e) {
      print('Error seeding venues: $e');
    }
  }

  // Add a new venue (for admin/host use)
  static Future<void> addVenue(VenueModel venue) async {
    await _firestore.collection(_collection).doc(venue.id).set(venue.toMap());
  }

  // Simple search for venues (Client-side filtering for now as list is small)
  // In production with thousands of venues, use Algolia/Typesense or Firestore combined indexes
  static Future<List<VenueModel>> searchVenues(String query) async {
    final lowerQuery = query.toLowerCase();

    // Fetch all (cached efficiently by Firestore usually if enabled, otherwise expensive)
    // For MVP, fetching all 5-50 venues is fine.
    final allVenues = await getAllVenues();

    return allVenues.where((venue) {
      return venue.name.toLowerCase().contains(lowerQuery);
    }).toList();
  }
}
