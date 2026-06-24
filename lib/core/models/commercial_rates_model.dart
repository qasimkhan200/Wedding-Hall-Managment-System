class CommercialRatesModel {
  final Map<String, double>
      commissionTiers; // 'free', 'pro', 'enterprise' -> percentage (0.15, 0.20, etc.)
  final double riderSplitPercentage; // 0.70 for rider
  final double emergencyPremiumPercentage; // 0.30 extra
  final Map<String, double>
      areaMultipliers; // 'university_road', 'old_city' -> 1.x
  final Map<String, Map<String, dynamic>>
      seasonalMultipliers; // 'wedding_season' -> {start, end, multiplier}
  final Map<String, double>
      timeMultipliers; // 'rush_hour_start', 'rush_hour_end', 'multiplier' - simplified for now
  final Map<String, dynamic>
      vehicleRates; // 'bike' -> {base: 200, perKm: 25}, 'van' -> {base: 800, perKm: 60}

  // Default values
  static const double defaultRiderSplit = 0.70;
  static const double defaultEmergencyPremium = 0.30;

  CommercialRatesModel({
    required this.commissionTiers,
    required this.riderSplitPercentage,
    required this.emergencyPremiumPercentage,
    this.areaMultipliers = const {},
    this.seasonalMultipliers = const {},
    this.timeMultipliers = const {},
    this.vehicleRates = const {},
  });

  factory CommercialRatesModel.defaults() {
    return CommercialRatesModel(
      commissionTiers: {
        'free': 0.25,
        'pro': 0.20,
        'enterprise': 0.15,
      },
      riderSplitPercentage: defaultRiderSplit,
      emergencyPremiumPercentage: defaultEmergencyPremium,
      areaMultipliers: {
        'University Road': 1.2,
        'Old City': 1.1,
        'Hayatabad': 1.15,
      },
      seasonalMultipliers: {
        'Wedding Season (Nov-Mar)': {
          'startMonth': 11,
          'endMonth': 3,
          'multiplier': 1.25,
        }
      },
      timeMultipliers: {
        'rushHourStart': 16.0, // 4 PM
        'rushHourEnd': 20.0, // 8 PM
        'multiplier': 1.15,
      },
      vehicleRates: {
        'bike': {'base': 200.0, 'perKm': 25.0},
        'car': {'base': 400.0, 'perKm': 40.0},
        'van': {'base': 800.0, 'perKm': 60.0},
      },
    );
  }

  factory CommercialRatesModel.fromMap(Map<String, dynamic> map) {
    return CommercialRatesModel(
      commissionTiers: Map<String, double>.from((map['commissionTiers'] ?? {})
          .map((k, v) => MapEntry(k, (v as num).toDouble()))),
      riderSplitPercentage:
          (map['riderSplitPercentage'] ?? defaultRiderSplit).toDouble(),
      emergencyPremiumPercentage:
          (map['emergencyPremiumPercentage'] ?? defaultEmergencyPremium)
              .toDouble(),
      areaMultipliers: Map<String, double>.from((map['areaMultipliers'] ?? {})
          .map((k, v) => MapEntry(k, (v as num).toDouble()))),
      seasonalMultipliers: Map<String, Map<String, dynamic>>.from(
          (map['seasonalMultipliers'] ?? {})
              .map((k, v) => MapEntry(k, Map<String, dynamic>.from(v)))),
      timeMultipliers: Map<String, double>.from((map['timeMultipliers'] ?? {})
          .map((k, v) => MapEntry(k, (v as num).toDouble()))),
      vehicleRates: Map<String, dynamic>.from(map['vehicleRates'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'commissionTiers': commissionTiers,
      'riderSplitPercentage': riderSplitPercentage,
      'emergencyPremiumPercentage': emergencyPremiumPercentage,
      'areaMultipliers': areaMultipliers,
      'seasonalMultipliers': seasonalMultipliers,
      'timeMultipliers': timeMultipliers,
      'vehicleRates': vehicleRates,
    };
  }

  CommercialRatesModel copyWith({
    Map<String, double>? commissionTiers,
    double? riderSplitPercentage,
    double? emergencyPremiumPercentage,
    Map<String, double>? areaMultipliers,
    Map<String, Map<String, dynamic>>? seasonalMultipliers,
    Map<String, double>? timeMultipliers,
    Map<String, dynamic>? vehicleRates,
  }) {
    return CommercialRatesModel(
      commissionTiers: commissionTiers ?? this.commissionTiers,
      riderSplitPercentage: riderSplitPercentage ?? this.riderSplitPercentage,
      emergencyPremiumPercentage:
          emergencyPremiumPercentage ?? this.emergencyPremiumPercentage,
      areaMultipliers: areaMultipliers ?? this.areaMultipliers,
      seasonalMultipliers: seasonalMultipliers ?? this.seasonalMultipliers,
      timeMultipliers: timeMultipliers ?? this.timeMultipliers,
      vehicleRates: vehicleRates ?? this.vehicleRates,
    );
  }
}
