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

class JobPricing {
  final String currency;
  final int basePrice;
  final int mileagePrice;
  final int priorityFee;
  final int winchFee;
  final int subtotal;
  final int serviceFee;
  final int total;

  const JobPricing({
    this.currency = 'usd',
    this.basePrice = 0,
    this.mileagePrice = 0,
    this.priorityFee = 0,
    this.winchFee = 0,
    this.subtotal = 0,
    this.serviceFee = 0,
    this.total = 0,
  });

  factory JobPricing.fromJson(Map<String, dynamic> json) {
    return JobPricing(
      currency: json['currency'] ?? 'usd',
      basePrice: json['basePrice'] ?? 0,
      mileagePrice: json['mileagePrice'] ?? 0,
      priorityFee: json['priorityFee'] ?? 0,
      winchFee: json['winchFee'] ?? 0,
      subtotal: json['subtotal'] ?? 0,
      serviceFee: json['serviceFee'] ?? 0,
      total: json['total'] ?? 0,
    );
  }
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
