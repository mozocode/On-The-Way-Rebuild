class ServiceTypeModel {
  final String id;
  final String name;
  final String description;
  final String icon;
  final int basePrice;
  final int pricePerMile;
  final List<String> subTypes;
  final List<String> requiredEquipment;
  final bool isActive;
  final int? estimatedDuration;

  const ServiceTypeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.basePrice,
    required this.pricePerMile,
    this.subTypes = const [],
    this.requiredEquipment = const [],
    this.isActive = true,
    this.estimatedDuration,
  });

  factory ServiceTypeModel.fromJson(Map<String, dynamic> json) {
    return ServiceTypeModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? '',
      basePrice: json['basePrice'] ?? 0,
      pricePerMile: json['pricePerMile'] ?? 0,
      subTypes: List<String>.from(json['subTypes'] ?? []),
      requiredEquipment: List<String>.from(json['requiredEquipment'] ?? []),
      isActive: json['isActive'] ?? true,
      estimatedDuration: json['estimatedDuration'],
    );
  }
}

class ServiceTypes {
  static const List<ServiceTypeModel> all = [
    ServiceTypeModel(
      id: 'flat_tire',
      name: 'Flat Tire',
      description: 'Tire change or repair',
      icon: 'tire',
      basePrice: 5000,
      pricePerMile: 200,
      subTypes: ['spare_mount', 'tire_repair', 'tire_inflation'],
      requiredEquipment: ['jack', 'lug_wrench', 'tire_repair_kit'],
      estimatedDuration: 30,
    ),
    ServiceTypeModel(
      id: 'dead_battery',
      name: 'Dead Battery',
      description: 'Jump start or battery replacement',
      icon: 'battery',
      basePrice: 4500,
      pricePerMile: 200,
      subTypes: ['jump_start', 'battery_replacement'],
      requiredEquipment: ['jumper_cables', 'portable_battery'],
      estimatedDuration: 20,
    ),
    ServiceTypeModel(
      id: 'lockout',
      name: 'Lockout',
      description: 'Locked out of vehicle',
      icon: 'key',
      basePrice: 6500,
      pricePerMile: 200,
      subTypes: ['door_unlock', 'trunk_unlock'],
      requiredEquipment: ['lockout_kit'],
      estimatedDuration: 25,
    ),
    ServiceTypeModel(
      id: 'fuel_delivery',
      name: 'Fuel Delivery',
      description: 'Out of gas',
      icon: 'fuel',
      basePrice: 5500,
      pricePerMile: 200,
      subTypes: ['gasoline', 'diesel'],
      requiredEquipment: ['fuel_can'],
      estimatedDuration: 30,
    ),
    ServiceTypeModel(
      id: 'towing',
      name: 'Towing',
      description: 'Vehicle towing service',
      icon: 'tow_truck',
      basePrice: 9500,
      pricePerMile: 400,
      subTypes: ['flatbed', 'dolly', 'wheel_lift'],
      requiredEquipment: ['tow_truck'],
      estimatedDuration: 60,
    ),
    ServiceTypeModel(
      id: 'winch_out',
      name: 'Winch Out',
      description: 'Vehicle stuck in ditch/mud',
      icon: 'winch',
      basePrice: 8500,
      pricePerMile: 300,
      subTypes: ['mud', 'snow', 'ditch', 'sand'],
      requiredEquipment: ['winch', 'recovery_straps'],
      estimatedDuration: 45,
    ),
  ];

  static ServiceTypeModel? getById(String id) {
    try {
      return all.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }
}
