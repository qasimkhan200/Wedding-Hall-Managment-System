import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/commercial_rates_model.dart';

class FeeBreakdown {
  final double subtotal;
  final double deliveryFee;
  final double totalAmount;
  final double platformCommission;
  final double riderFee;
  final double platformDeliveryCut;
  final double vendorPayout;
  final double emergencySurcharge;
  final List<String> appliedMultipliers;

  FeeBreakdown({
    required this.subtotal,
    required this.deliveryFee,
    required this.totalAmount,
    required this.platformCommission,
    required this.riderFee,
    required this.platformDeliveryCut,
    required this.vendorPayout,
    required this.emergencySurcharge,
    required this.appliedMultipliers,
  });

  Map<String, dynamic> toMap() {
    return {
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'totalAmount': totalAmount,
      'platformCommission': platformCommission,
      'riderFee': riderFee,
      'platformDeliveryCut': platformDeliveryCut,
      'vendorPayout': vendorPayout,
      'emergencySurcharge': emergencySurcharge,
      'appliedMultipliers': appliedMultipliers,
    };
  }
}

class CommercialRatesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'platform_config';
  static const String _doc = 'commercial_rates';

  // Cache the rates to avoid fetching on every calculation if not needed
  CommercialRatesModel? _cachedRates;

  Future<CommercialRatesModel> getRates({bool forceRefresh = false}) async {
    if (_cachedRates != null && !forceRefresh) {
      return _cachedRates!;
    }

    try {
      final doc = await _firestore.collection(_collection).doc(_doc).get();
      if (doc.exists && doc.data() != null) {
        _cachedRates = CommercialRatesModel.fromMap(doc.data()!);
      } else {
        // Initialize with defaults if not found
        _cachedRates = CommercialRatesModel.defaults();
        await updateRates(_cachedRates!);
      }
      return _cachedRates!;
    } catch (e) {
      print('Error fetching rates: $e');
      return CommercialRatesModel.defaults();
    }
  }

  Future<void> updateRates(CommercialRatesModel rates) async {
    await _firestore.collection(_collection).doc(_doc).set(rates.toMap());
    _cachedRates = rates;
  }

  FeeBreakdown calculateOrderFees({
    required double subtotal,
    required double baseDeliveryFee,
    required bool isEmergency,
    required String vendorTier, // 'free', 'pro', 'enterprise'
    String? areaName,
    String vehicleType = 'bike',
    double distanceKm = 0.0,
  }) {
    final rates = _cachedRates ?? CommercialRatesModel.defaults();
    final List<String> multipliers = [];

    // 0. Calculate Base Fee from Vehicle Rates (if applicable)
    double calculatedBase = baseDeliveryFee;

    // Use fetched rates, but fallback to defaults if specific vehicle key is missing
    Map<String, dynamic> effectiveVehicleRate;
    if (rates.vehicleRates.containsKey(vehicleType)) {
      effectiveVehicleRate = rates.vehicleRates[vehicleType]!;
    } else {
      // Fallback to default values for this vehicle type
      print(
          'WARNING: Vehicle type $vehicleType not found in config, using defaults.');
      effectiveVehicleRate =
          CommercialRatesModel.defaults().vehicleRates[vehicleType] ??
              {'base': 200.0, 'perKm': 25.0};
    }

    double vBase = (effectiveVehicleRate['base'] ?? 200.0).toDouble();
    double vPerKm = (effectiveVehicleRate['perKm'] ?? 25.0).toDouble();

    // Only apply formula if distance is provided, otherwise fall back to base or vehicle base
    if (distanceKm > 0) {
      calculatedBase = vBase + (distanceKm * vPerKm);
    } else {
      calculatedBase = vBase; // Use vehicle base minimum if no distance
    }

    // 1. Calculate Delivery Fee with Multipliers
    double finalDeliveryFee = calculatedBase;

    // Area Multiplier
    if (areaName != null && rates.areaMultipliers.containsKey(areaName)) {
      final multiplier = rates.areaMultipliers[areaName]!;
      finalDeliveryFee *= multiplier;
      multipliers.add('Area: $areaName (${multiplier}x)');
    }

    // Seasonal Multiplier
    final now = DateTime.now();
    rates.seasonalMultipliers.forEach((key, data) {
      // Simple logic: check if current month is within range (handling year wrap)
      int start = data['startMonth'];
      int end = data['endMonth'];
      int current = now.month;

      bool isActive = false;
      if (start <= end) {
        isActive = current >= start && current <= end;
      } else {
        // e.g., Nov (11) to Mar (3)
        isActive = current >= start || current <= end;
      }

      if (isActive) {
        double seasonalMult = (data['multiplier'] as num).toDouble();
        finalDeliveryFee *= seasonalMult;
        multipliers.add('$key (${seasonalMult}x)');
      }
    });

    // Time Multiplier (Rush Hour)
    if (rates.timeMultipliers.isNotEmpty) {
      double startHour = rates.timeMultipliers['rushHourStart'] ?? -1;
      double endHour = rates.timeMultipliers['rushHourEnd'] ?? -1;

      // Convert current time to double hour (e.g. 14.5 for 2:30 PM)
      double currentHour = now.hour + (now.minute / 60.0);

      if (startHour != -1 &&
          endHour != -1 &&
          currentHour >= startHour &&
          currentHour <= endHour) {
        double timeMult = rates.timeMultipliers['multiplier'] ?? 1.0;
        finalDeliveryFee *= timeMult;
        multipliers.add('Rush Hour (${timeMult}x)');
      }
    }

    // Emergency Premium (on Delivery Fee or Total? Usually surcharge on service)
    double emergencySurcharge = 0.0;
    if (isEmergency) {
      emergencySurcharge = subtotal * rates.emergencyPremiumPercentage;
      multipliers.add(
          'Emergency Premium (${(rates.emergencyPremiumPercentage * 100).toStringAsFixed(0)}%)');
    }

    // 2. Rider Split
    // Rider gets percentage of final delivery fee
    double riderFee = finalDeliveryFee * rates.riderSplitPercentage;
    double platformDeliveryCut = finalDeliveryFee - riderFee;

    // 3. Vendor Commission
    double commissionRate = rates.commissionTiers[vendorTier.toLowerCase()] ??
        rates.commissionTiers['free']!;
    double platformCommission = subtotal * commissionRate;
    double vendorPayout = subtotal - platformCommission;

    return FeeBreakdown(
      subtotal: subtotal,
      deliveryFee: finalDeliveryFee, // To be charged to customer
      totalAmount: subtotal + finalDeliveryFee + emergencySurcharge,
      platformCommission: platformCommission,
      riderFee: riderFee,
      platformDeliveryCut: platformDeliveryCut,
      vendorPayout: vendorPayout,
      emergencySurcharge: emergencySurcharge,
      appliedMultipliers: multipliers,
    );
  }
}
