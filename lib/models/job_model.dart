import 'package:cloud_firestore/cloud_firestore.dart';
import 'location_model.dart';

enum JobStatus {
  pending,
  searching,
  assigned,
  enRoute,
  arrived,
  inProgress,
  completed,
  cancelled,
  noHeroesAvailable,
}

class JobCustomer {
  final String id;
  final String name;
  final String? phone;
  final String? photoUrl;

  const JobCustomer({
    required this.id,
    required this.name,
    this.phone,
    this.photoUrl,
  });

  factory JobCustomer.fromJson(Map<String, dynamic> json) {
    return JobCustomer(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'],
      photoUrl: json['photoUrl'],
    );
  }
}

class JobHero {
  final String id;
  final String name;
  final String? phone;
  final String? photoUrl;
  final String? vehicleMake;
  final String? vehicleModel;
  final String? vehicleColor;
  final String? licensePlate;

  const JobHero({
    required this.id,
    required this.name,
    this.phone,
    this.photoUrl,
    this.vehicleMake,
    this.vehicleModel,
    this.vehicleColor,
    this.licensePlate,
  });

  factory JobHero.fromJson(Map<String, dynamic> json) {
    return JobHero(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'],
      photoUrl: json['photoUrl'],
      vehicleMake: json['vehicleMake'],
      vehicleModel: json['vehicleModel'],
      vehicleColor: json['vehicleColor'],
      licensePlate: json['licensePlate'],
    );
  }
}

class JobAddress {
  final String formatted;
  final String? street;
  final String? city;
  final String? state;
  final String? zip;

  const JobAddress({
    required this.formatted,
    this.street,
    this.city,
    this.state,
    this.zip,
  });

  factory JobAddress.fromJson(Map<String, dynamic> json) {
    return JobAddress(
      formatted: json['formatted'] ?? '',
      street: json['street'],
      city: json['city'],
      state: json['state'],
      zip: json['zip'],
    );
  }
}

class JobLocation {
  final LocationModel location;
  final JobAddress? address;
  final String? geohash;
  final String? notes;

  const JobLocation({
    required this.location,
    this.address,
    this.geohash,
    this.notes,
  });
}

class JobTracking {
  final LocationModel? heroLocation;
  final int? etaMinutes;
  final double? etaDistance;
  final String? etaDistanceUnit;
  final String? routePolyline;
  final DateTime? updatedAt;

  const JobTracking({
    this.heroLocation,
    this.etaMinutes,
    this.etaDistance,
    this.etaDistanceUnit,
    this.routePolyline,
    this.updatedAt,
  });

  factory JobTracking.fromJson(Map<String, dynamic> json) {
    return JobTracking(
      heroLocation: json['heroLocation'] != null
          ? LocationModel.fromFirestore(
              json['heroLocation'] as Map<String, dynamic>)
          : null,
      etaMinutes: json['etaMinutes'] as int?,
      etaDistance: (json['etaDistance'] as num?)?.toDouble(),
      etaDistanceUnit: json['etaDistanceUnit'],
      routePolyline: json['routePolyline'],
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}

class SurgePricingData {
  final double timeMultiplier;
  final double dayMultiplier;
  final double demandMultiplier;
  final double holidayMultiplier;
  final double combinedMultiplier;
  final int surgeAmount;

  const SurgePricingData({
    this.timeMultiplier = 1.0,
    this.dayMultiplier = 1.0,
    this.demandMultiplier = 1.0,
    this.holidayMultiplier = 1.0,
    this.combinedMultiplier = 1.0,
    this.surgeAmount = 0,
  });

  factory SurgePricingData.fromJson(Map<String, dynamic> json) {
    return SurgePricingData(
      timeMultiplier: (json['timeMultiplier'] as num?)?.toDouble() ?? 1.0,
      dayMultiplier: (json['dayMultiplier'] as num?)?.toDouble() ?? 1.0,
      demandMultiplier: (json['demandMultiplier'] as num?)?.toDouble() ?? 1.0,
      holidayMultiplier: (json['holidayMultiplier'] as num?)?.toDouble() ?? 1.0,
      combinedMultiplier: (json['combinedMultiplier'] as num?)?.toDouble() ?? 1.0,
      surgeAmount: (json['surgeAmount'] as num?)?.toInt() ?? 0,
    );
  }

  bool get isActive => combinedMultiplier > 1.0;
  String get formattedMultiplier => '${combinedMultiplier.toStringAsFixed(1)}x';
}

class AddOnFeesData {
  final int priorityFee;
  final int winchFee;
  final int fuelFee;
  final int afterHoursFee;
  final int weekendFee;
  final int holidayFee;
  final int total;

  const AddOnFeesData({
    this.priorityFee = 0,
    this.winchFee = 0,
    this.fuelFee = 0,
    this.afterHoursFee = 0,
    this.weekendFee = 0,
    this.holidayFee = 0,
    this.total = 0,
  });

  factory AddOnFeesData.fromJson(Map<String, dynamic> json) {
    return AddOnFeesData(
      priorityFee: (json['priorityFee'] as num?)?.toInt() ?? 0,
      winchFee: (json['winchFee'] as num?)?.toInt() ?? 0,
      fuelFee: (json['fuelFee'] as num?)?.toInt() ?? 0,
      afterHoursFee: (json['afterHoursFee'] as num?)?.toInt() ?? 0,
      weekendFee: (json['weekendFee'] as num?)?.toInt() ?? 0,
      holidayFee: (json['holidayFee'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }
}

class DiscountData {
  final int promoDiscount;
  final String? promoCode;
  final int membershipDiscount;
  final String? membershipTier;
  final int referralDiscount;
  final int loyaltyPointsUsed;
  final int loyaltyDiscount;
  final int totalDiscount;

  const DiscountData({
    this.promoDiscount = 0,
    this.promoCode,
    this.membershipDiscount = 0,
    this.membershipTier,
    this.referralDiscount = 0,
    this.loyaltyPointsUsed = 0,
    this.loyaltyDiscount = 0,
    this.totalDiscount = 0,
  });

  factory DiscountData.fromJson(Map<String, dynamic> json) {
    return DiscountData(
      promoDiscount: (json['promoDiscount'] as num?)?.toInt() ?? 0,
      promoCode: json['promoCode'],
      membershipDiscount: (json['membershipDiscount'] as num?)?.toInt() ?? 0,
      membershipTier: json['membershipTier'],
      referralDiscount: (json['referralDiscount'] as num?)?.toInt() ?? 0,
      loyaltyPointsUsed: (json['loyaltyPointsUsed'] as num?)?.toInt() ?? 0,
      loyaltyDiscount: (json['loyaltyDiscount'] as num?)?.toInt() ?? 0,
      totalDiscount: (json['totalDiscount'] as num?)?.toInt() ?? 0,
    );
  }

  bool get hasDiscount => totalDiscount > 0;
  String get formattedDiscount => '-\$${(totalDiscount / 100).toStringAsFixed(2)}';
}

class HeroPayoutData {
  final int basePayout;
  final int distancePayout;
  final int tierBonus;
  final int performanceBonus;
  final int totalPayout;

  const HeroPayoutData({
    this.basePayout = 0,
    this.distancePayout = 0,
    this.tierBonus = 0,
    this.performanceBonus = 0,
    this.totalPayout = 0,
  });

  factory HeroPayoutData.fromJson(Map<String, dynamic> json) {
    return HeroPayoutData(
      basePayout: (json['basePayout'] as num?)?.toInt() ?? 0,
      distancePayout: (json['distancePayout'] as num?)?.toInt() ?? 0,
      tierBonus: (json['tierBonus'] as num?)?.toInt() ?? 0,
      performanceBonus: (json['performanceBonus'] as num?)?.toInt() ?? 0,
      totalPayout: (json['totalPayout'] as num?)?.toInt() ?? 0,
    );
  }

  String get formattedPayout => '\$${(totalPayout / 100).toStringAsFixed(2)}';
}

class JobPricing {
  final String currency;
  final int basePrice;
  final int mileagePrice;
  final int priorityFee;
  final int winchFee;
  final int subtotal;
  final int serviceFee;
  final int total;

  // Extended fields from v2 pricing engine
  final double subTypeModifier;
  final int subTypeAdditionalFee;
  final int heroTravelFee;
  final double heroTravelMiles;
  final int towingDistanceFee;
  final double towingDistanceMiles;
  final double freeIncludedMiles;
  final SurgePricingData surgePricing;
  final AddOnFeesData addOns;
  final int subtotalBeforeDiscounts;
  final DiscountData discounts;
  final int subtotalAfterDiscounts;
  final double serviceFeePercent;
  final double taxRate;
  final int taxAmount;
  final int estimatedMin;
  final int estimatedMax;
  final HeroPayoutData heroPayout;
  final String? configVersion;

  const JobPricing({
    this.currency = 'usd',
    this.basePrice = 0,
    this.mileagePrice = 0,
    this.priorityFee = 0,
    this.winchFee = 0,
    this.subtotal = 0,
    this.serviceFee = 0,
    this.total = 0,
    this.subTypeModifier = 1.0,
    this.subTypeAdditionalFee = 0,
    this.heroTravelFee = 0,
    this.heroTravelMiles = 0,
    this.towingDistanceFee = 0,
    this.towingDistanceMiles = 0,
    this.freeIncludedMiles = 0,
    this.surgePricing = const SurgePricingData(),
    this.addOns = const AddOnFeesData(),
    this.subtotalBeforeDiscounts = 0,
    this.discounts = const DiscountData(),
    this.subtotalAfterDiscounts = 0,
    this.serviceFeePercent = 0,
    this.taxRate = 0,
    this.taxAmount = 0,
    this.estimatedMin = 0,
    this.estimatedMax = 0,
    this.heroPayout = const HeroPayoutData(),
    this.configVersion,
  });

  factory JobPricing.fromJson(Map<String, dynamic> json) {
    return JobPricing(
      currency: json['currency'] ?? 'usd',
      basePrice: (json['basePrice'] as num?)?.toInt() ?? 0,
      mileagePrice: (json['mileagePrice'] as num?)?.toInt() ?? 0,
      priorityFee: (json['priorityFee'] as num?)?.toInt() ?? 0,
      winchFee: (json['winchFee'] as num?)?.toInt() ?? 0,
      subtotal: (json['subtotal'] as num?)?.toInt() ?? 0,
      serviceFee: (json['serviceFee'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
      subTypeModifier: (json['subTypeModifier'] as num?)?.toDouble() ?? 1.0,
      subTypeAdditionalFee: (json['subTypeAdditionalFee'] as num?)?.toInt() ?? 0,
      heroTravelFee: (json['heroTravelFee'] as num?)?.toInt() ?? 0,
      heroTravelMiles: (json['heroTravelMiles'] as num?)?.toDouble() ?? 0,
      towingDistanceFee: (json['towingDistanceFee'] as num?)?.toInt() ?? 0,
      towingDistanceMiles: (json['towingDistanceMiles'] as num?)?.toDouble() ?? 0,
      freeIncludedMiles: (json['freeIncludedMiles'] as num?)?.toDouble() ?? 0,
      surgePricing: json['surgePricing'] != null
          ? SurgePricingData.fromJson(json['surgePricing'] as Map<String, dynamic>)
          : const SurgePricingData(),
      addOns: json['addOns'] != null
          ? AddOnFeesData.fromJson(json['addOns'] as Map<String, dynamic>)
          : const AddOnFeesData(),
      subtotalBeforeDiscounts: (json['subtotalBeforeDiscounts'] as num?)?.toInt() ?? 0,
      discounts: json['discounts'] != null
          ? DiscountData.fromJson(json['discounts'] as Map<String, dynamic>)
          : const DiscountData(),
      subtotalAfterDiscounts: (json['subtotalAfterDiscounts'] as num?)?.toInt() ?? 0,
      serviceFeePercent: (json['serviceFeePercent'] as num?)?.toDouble() ?? 0,
      taxRate: (json['taxRate'] as num?)?.toDouble() ?? 0,
      taxAmount: (json['taxAmount'] as num?)?.toInt() ?? 0,
      estimatedMin: (json['estimatedRange']?['min'] as num?)?.toInt() ?? (json['total'] as num?)?.toInt() ?? 0,
      estimatedMax: (json['estimatedRange']?['max'] as num?)?.toInt() ?? 0,
      heroPayout: json['heroPayout'] != null
          ? HeroPayoutData.fromJson(json['heroPayout'] as Map<String, dynamic>)
          : const HeroPayoutData(),
      configVersion: json['configVersion'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currency': currency,
      'basePrice': basePrice,
      'mileagePrice': mileagePrice,
      'priorityFee': priorityFee,
      'winchFee': winchFee,
      'subtotal': subtotal,
      'serviceFee': serviceFee,
      'total': total,
      'subTypeModifier': subTypeModifier,
      'subTypeAdditionalFee': subTypeAdditionalFee,
      'heroTravelFee': heroTravelFee,
      'heroTravelMiles': heroTravelMiles,
      'towingDistanceFee': towingDistanceFee,
      'towingDistanceMiles': towingDistanceMiles,
      'freeIncludedMiles': freeIncludedMiles,
      'surgePricing': {
        'timeMultiplier': surgePricing.timeMultiplier,
        'dayMultiplier': surgePricing.dayMultiplier,
        'demandMultiplier': surgePricing.demandMultiplier,
        'holidayMultiplier': surgePricing.holidayMultiplier,
        'combinedMultiplier': surgePricing.combinedMultiplier,
        'surgeAmount': surgePricing.surgeAmount,
      },
      'addOns': {
        'priorityFee': addOns.priorityFee,
        'winchFee': addOns.winchFee,
        'fuelFee': addOns.fuelFee,
        'afterHoursFee': addOns.afterHoursFee,
        'total': addOns.total,
      },
      'subtotalBeforeDiscounts': subtotalBeforeDiscounts,
      'discounts': {
        'promoDiscount': discounts.promoDiscount,
        if (discounts.promoCode != null) 'promoCode': discounts.promoCode,
        'membershipDiscount': discounts.membershipDiscount,
        'totalDiscount': discounts.totalDiscount,
      },
      'subtotalAfterDiscounts': subtotalAfterDiscounts,
      'serviceFeePercent': serviceFeePercent,
      'estimatedRange': {'min': estimatedMin, 'max': estimatedMax},
      'heroPayout': {
        'basePayout': heroPayout.basePayout,
        'distancePayout': heroPayout.distancePayout,
        'tierBonus': heroPayout.tierBonus,
        'performanceBonus': heroPayout.performanceBonus,
        'totalPayout': heroPayout.totalPayout,
      },
      if (configVersion != null) 'configVersion': configVersion,
    };
  }

  bool get hasSurge => surgePricing.isActive;
  bool get hasDiscounts => discounts.hasDiscount;
  String get formattedTotal => '\$${(total / 100).toStringAsFixed(2)}';
  String get formattedRange =>
      '\$${(estimatedMin / 100).toStringAsFixed(2)} - \$${(estimatedMax / 100).toStringAsFixed(2)}';
}

class JobDispatch {
  final DateTime? startedAt;
  final int currentWave;
  final List<String> notifiedHeroes;
  final List<String> declinedHeroes;
  final String? acceptedBy;
  final DateTime? acceptedAt;

  const JobDispatch({
    this.startedAt,
    this.currentWave = 0,
    this.notifiedHeroes = const [],
    this.declinedHeroes = const [],
    this.acceptedBy,
    this.acceptedAt,
  });

  factory JobDispatch.fromJson(Map<String, dynamic> json) {
    return JobDispatch(
      startedAt: (json['startedAt'] as Timestamp?)?.toDate(),
      currentWave: json['currentWave'] ?? 0,
      notifiedHeroes: List<String>.from(json['notifiedHeroes'] ?? []),
      declinedHeroes: List<String>.from(json['declinedHeroes'] ?? []),
      acceptedBy: json['acceptedBy'],
      acceptedAt: (json['acceptedAt'] as Timestamp?)?.toDate(),
    );
  }
}

class JobModel {
  final String id;
  final String? shortCode;
  final JobCustomer customer;
  final JobHero? hero;
  final String serviceType;
  final String? serviceSubType;
  final JobLocation pickup;
  final JobLocation? destination;
  final JobStatus status;
  final List<Map<String, dynamic>> statusHistory;
  final JobDispatch dispatch;
  final JobTracking tracking;
  final JobPricing pricing;
  final String? paymentIntentId;
  final String? paymentStatus;
  final DateTime? createdAt;
  final DateTime? assignedAt;
  final DateTime? heroEnRouteAt;
  final DateTime? heroArrivedAt;
  final DateTime? serviceStartedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;

  const JobModel({
    required this.id,
    this.shortCode,
    required this.customer,
    this.hero,
    required this.serviceType,
    this.serviceSubType,
    required this.pickup,
    this.destination,
    this.status = JobStatus.pending,
    this.statusHistory = const [],
    this.dispatch = const JobDispatch(),
    this.tracking = const JobTracking(),
    this.pricing = const JobPricing(),
    this.paymentIntentId,
    this.paymentStatus,
    this.createdAt,
    this.assignedAt,
    this.heroEnRouteAt,
    this.heroArrivedAt,
    this.serviceStartedAt,
    this.completedAt,
    this.cancelledAt,
  });

  static JobStatus _parseJobStatus(String? status) {
    switch (status) {
      case 'pending':
        return JobStatus.pending;
      case 'searching':
        return JobStatus.searching;
      case 'assigned':
        return JobStatus.assigned;
      case 'en_route':
        return JobStatus.enRoute;
      case 'arrived':
        return JobStatus.arrived;
      case 'in_progress':
        return JobStatus.inProgress;
      case 'completed':
        return JobStatus.completed;
      case 'cancelled':
        return JobStatus.cancelled;
      case 'no_heroes_available':
        return JobStatus.noHeroesAvailable;
      default:
        return JobStatus.pending;
    }
  }

  factory JobModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final timestamps = data['timestamps'] as Map<String, dynamic>? ?? {};
    final pickupData = data['pickup'] as Map<String, dynamic>? ?? {};
    final destData = data['destination'] as Map<String, dynamic>?;

    return JobModel(
      id: doc.id,
      shortCode: data['shortCode'],
      customer: JobCustomer.fromJson(data['customer'] ?? {}),
      hero: data['hero'] != null ? JobHero.fromJson(data['hero']) : null,
      serviceType: data['service']?['type'] ?? '',
      serviceSubType: data['service']?['subType'],
      pickup: JobLocation(
        location: LocationModel.fromFirestore(
            pickupData['location'] as Map<String, dynamic>? ?? {}),
        address: pickupData['address'] != null
            ? JobAddress.fromJson(pickupData['address'])
            : null,
        geohash: pickupData['geohash'],
        notes: pickupData['notes'],
      ),
      destination: destData != null
          ? JobLocation(
              location: LocationModel.fromFirestore(
                  destData['location'] as Map<String, dynamic>? ?? {}),
              address: destData['address'] != null
                  ? JobAddress.fromJson(destData['address'])
                  : null,
              geohash: destData['geohash'],
            )
          : null,
      status: _parseJobStatus(data['status']),
      statusHistory:
          List<Map<String, dynamic>>.from(data['statusHistory'] ?? []),
      dispatch: data['dispatch'] != null
          ? JobDispatch.fromJson(data['dispatch'])
          : const JobDispatch(),
      tracking: data['tracking'] != null
          ? JobTracking.fromJson(data['tracking'])
          : const JobTracking(),
      pricing: data['pricing'] != null
          ? JobPricing.fromJson(data['pricing'])
          : const JobPricing(),
      paymentIntentId: data['payment']?['paymentIntentId'],
      paymentStatus: data['payment']?['status'],
      createdAt: (timestamps['createdAt'] as Timestamp?)?.toDate(),
      assignedAt: (timestamps['assignedAt'] as Timestamp?)?.toDate(),
      heroEnRouteAt: (timestamps['heroEnRouteAt'] as Timestamp?)?.toDate(),
      heroArrivedAt: (timestamps['heroArrivedAt'] as Timestamp?)?.toDate(),
      serviceStartedAt:
          (timestamps['serviceStartedAt'] as Timestamp?)?.toDate(),
      completedAt: (timestamps['completedAt'] as Timestamp?)?.toDate(),
      cancelledAt: (timestamps['cancelledAt'] as Timestamp?)?.toDate(),
    );
  }
}
