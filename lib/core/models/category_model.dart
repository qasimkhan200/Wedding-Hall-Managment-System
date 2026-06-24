import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum CategoryType {
  product,
  service,
  rental,
  consumable;

  String get displayName {
    switch (this) {
      case CategoryType.product:
        return 'Product';
      case CategoryType.service:
        return 'Service';
      case CategoryType.rental:
        return 'Rental';
      case CategoryType.consumable:
        return 'Consumable';
    }
  }
}

enum CategoryTier {
  standard,
  premium,
  restricted,
  licensed;

  String get displayName {
    switch (this) {
      case CategoryTier.standard:
        return 'Standard';
      case CategoryTier.premium:
        return 'Premium';
      case CategoryTier.restricted:
        return 'Restricted';
      case CategoryTier.licensed:
        return 'Licensed';
    }
  }

  Color get color {
    switch (this) {
      case CategoryTier.standard:
        return Colors.grey;
      case CategoryTier.premium:
        return Colors.amber;
      case CategoryTier.restricted:
        return Colors.red;
      case CategoryTier.licensed:
        return Colors.blue;
    }
  }

  IconData get icon {
    switch (this) {
      case CategoryTier.standard:
        return Icons.check_circle_outline;
      case CategoryTier.premium:
        return Icons.star;
      case CategoryTier.restricted:
        return Icons.block;
      case CategoryTier.licensed:
        return Icons.verified_user;
    }
  }
}

class PricingConfig {
  final double commissionPercent;
  final double emergencySurchargePercent;
  final double? minPrice;
  final double? maxPrice;
  final double vendorSubscriptionFee;
  final Map<String, double>
      seasonalMultipliers; // Key: Month name, Value: Multiplier (e.g. 1.2 for 20% increase)

  PricingConfig({
    required this.commissionPercent,
    this.emergencySurchargePercent = 0.0,
    this.minPrice,
    this.maxPrice,
    this.vendorSubscriptionFee = 0.0,
    this.seasonalMultipliers = const {},
  });

  factory PricingConfig.fromMap(Map<String, dynamic> map) {
    return PricingConfig(
      commissionPercent: (map['commissionPercent'] ?? 0.0).toDouble(),
      emergencySurchargePercent:
          (map['emergencySurchargePercent'] ?? 0.0).toDouble(),
      minPrice: map['minPrice']?.toDouble(),
      maxPrice: map['maxPrice']?.toDouble(),
      vendorSubscriptionFee: (map['vendorSubscriptionFee'] ?? 0.0).toDouble(),
      seasonalMultipliers:
          Map<String, double>.from(map['seasonalMultipliers'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'commissionPercent': commissionPercent,
      'emergencySurchargePercent': emergencySurchargePercent,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'vendorSubscriptionFee': vendorSubscriptionFee,
      'seasonalMultipliers': seasonalMultipliers,
    };
  }
}

class DeliveryConfig {
  final bool requiresRefrigeration;
  final bool requiresHeavyLifting;
  final List<String> requiredVehicleTypes;
  final double? maxDeliveryDistanceKm;

  DeliveryConfig({
    this.requiresRefrigeration = false,
    this.requiresHeavyLifting = false,
    this.requiredVehicleTypes = const [],
    this.maxDeliveryDistanceKm,
  });

  factory DeliveryConfig.fromMap(Map<String, dynamic> map) {
    return DeliveryConfig(
      requiresRefrigeration: map['requiresRefrigeration'] ?? false,
      requiresHeavyLifting: map['requiresHeavyLifting'] ?? false,
      requiredVehicleTypes:
          List<String>.from(map['requiredVehicleTypes'] ?? []),
      maxDeliveryDistanceKm: map['maxDeliveryDistanceKm']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'requiresRefrigeration': requiresRefrigeration,
      'requiresHeavyLifting': requiresHeavyLifting,
      'requiredVehicleTypes': requiredVehicleTypes,
      'maxDeliveryDistanceKm': maxDeliveryDistanceKm,
    };
  }
}

class InventoryConfig {
  final bool lowStockAlertEnabled;
  final int lowStockThreshold;
  final bool allowBackorder;

  InventoryConfig({
    this.lowStockAlertEnabled = true,
    this.lowStockThreshold = 5,
    this.allowBackorder = false,
  });

  factory InventoryConfig.fromMap(Map<String, dynamic> map) {
    return InventoryConfig(
      lowStockAlertEnabled: map['lowStockAlertEnabled'] ?? true,
      lowStockThreshold: map['lowStockThreshold'] ?? 5,
      allowBackorder: map['allowBackorder'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lowStockAlertEnabled': lowStockAlertEnabled,
      'lowStockThreshold': lowStockThreshold,
      'allowBackorder': allowBackorder,
    };
  }
}

class CategoryModel {
  final String id;
  final String name;
  final String icon;
  final String? imageUrl; // Category image URL
  final Color color;
  final String description;
  final int productCount;

  // New Fields
  final CategoryType type;
  final CategoryTier tier;
  final String? parentId;
  final Map<String, dynamic> attributes;
  final PricingConfig pricing;
  final DeliveryConfig delivery;
  final InventoryConfig inventory;
  final List<String> requiredDocs;

  // Wedding Specifics
  final int emergencyDeliveryMinutes;
  final List<String> compatibleCategories;
  final Map<String, dynamic> weddingSpecificAttributes;

  final bool isFeatured;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    this.imageUrl,
    required this.color,
    required this.description,
    this.productCount = 0,
    this.type = CategoryType.product,
    this.tier = CategoryTier.standard,
    this.parentId,
    this.attributes = const {},
    required this.pricing,
    required this.delivery,
    required this.inventory,
    this.requiredDocs = const [],
    this.emergencyDeliveryMinutes = 30,
    this.compatibleCategories = const [],
    this.weddingSpecificAttributes = const {},
    this.isFeatured = false,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  static List<CategoryModel> getCategories() {
    // Migration helper for existing hardcoded usage
    // We create minimal valid instances for the mock data
    final now = DateTime.now();
    final defaultPricing = PricingConfig(commissionPercent: 10.0);
    final defaultDelivery = DeliveryConfig();
    final defaultInventory = InventoryConfig();

    return [
      CategoryModel(
        id: 'chairs_tables',
        name: 'Chairs & Tables',
        icon: '🪑',
        color: AppColors.categoryChairs,
        description: 'Extra seating and tables for guests',
        type: CategoryType.rental,
        tier: CategoryTier.standard,
        pricing: defaultPricing,
        delivery: defaultDelivery,
        inventory: defaultInventory,
        createdAt: now,
        updatedAt: now,
      ),
      CategoryModel(
        id: 'crockery_utensils',
        name: 'Crockery & Utensils',
        icon: '🍽️',
        color: AppColors.categoryCrockery,
        description: 'Plates, glasses, spoons, and serving items',
        type: CategoryType.rental,
        tier: CategoryTier.standard,
        pricing: defaultPricing,
        delivery: defaultDelivery,
        inventory: defaultInventory,
        createdAt: now,
        updatedAt: now,
      ),
      CategoryModel(
        id: 'ice_beverages',
        name: 'Ice & Beverages',
        icon: '🧊',
        color: AppColors.categoryIce,
        description: 'Ice blocks, cubes, and cold drinks',
        type: CategoryType.consumable,
        tier: CategoryTier.standard,
        pricing: defaultPricing,
        delivery: DeliveryConfig(requiresRefrigeration: true),
        inventory: defaultInventory,
        createdAt: now,
        updatedAt: now,
        emergencyDeliveryMinutes: 20,
      ),
      CategoryModel(
        id: 'fuel_gas',
        name: 'Fuel & Gas',
        icon: '🔥',
        color: AppColors.categoryFuel,
        description: 'LPG cylinders and cooking fuel',
        type: CategoryType.consumable,
        tier: CategoryTier.licensed,
        pricing: defaultPricing,
        delivery: DeliveryConfig(requiresHeavyLifting: true),
        inventory: defaultInventory,
        requiredDocs: ['LPG License', 'Safety Certificate'],
        createdAt: now,
        updatedAt: now,
      ),
      CategoryModel(
        id: 'decor_items',
        name: 'Decor Items',
        icon: '🎀',
        color: AppColors.categoryDecor,
        description: 'Flowers, lights, and decorative items',
        type: CategoryType.product,
        tier: CategoryTier.premium,
        pricing: defaultPricing,
        delivery: defaultDelivery,
        inventory: defaultInventory,
        createdAt: now,
        updatedAt: now,
      ),
      CategoryModel(
        id: 'manpower',
        name: 'Manpower',
        icon: '👷',
        color: AppColors.categoryManpower,
        description: 'Helpers, servers, and cleaners',
        type: CategoryType.service,
        tier: CategoryTier.standard,
        pricing: defaultPricing,
        delivery: defaultDelivery,
        inventory: defaultInventory,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map, String id) {
    return CategoryModel(
      id: id,
      name: map['name'] ?? '',
      icon: map['icon'] ?? '📦',
      imageUrl: map['imageUrl'],
      color: Color(map['color'] ?? 0xFF757575),
      description: map['description'] ?? '',
      productCount: map['productCount'] ?? 0,
      type: CategoryType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => CategoryType.product,
      ),
      tier: CategoryTier.values.firstWhere(
        (e) => e.name == map['tier'],
        orElse: () => CategoryTier.standard,
      ),
      parentId: map['parentId'],
      attributes: map['attributes'] ?? {},
      pricing: PricingConfig.fromMap(map['pricing'] ?? {}),
      delivery: DeliveryConfig.fromMap(map['delivery'] ?? {}),
      inventory: InventoryConfig.fromMap(map['inventory'] ?? {}),
      requiredDocs: List<String>.from(map['requiredDocs'] ?? []),
      emergencyDeliveryMinutes: map['emergencyDeliveryMinutes'] ?? 30,
      compatibleCategories:
          List<String>.from(map['compatibleCategories'] ?? []),
      weddingSpecificAttributes: map['weddingSpecificAttributes'] ?? {},
      isFeatured: map['isFeatured'] ?? false,
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'icon': icon,
      'imageUrl': imageUrl,
      'color': color.value,
      'description': description,
      'productCount': productCount,
      'type': type.name,
      'tier': tier.name,
      'parentId': parentId,
      'attributes': attributes,
      'pricing': pricing.toMap(),
      'delivery': delivery.toMap(),
      'inventory': inventory.toMap(),
      'requiredDocs': requiredDocs,
      'emergencyDeliveryMinutes': emergencyDeliveryMinutes,
      'compatibleCategories': compatibleCategories,
      'weddingSpecificAttributes': weddingSpecificAttributes,
      'isFeatured': isFeatured,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
