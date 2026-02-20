import 'package:cloud_firestore/cloud_firestore.dart';
import 'location_model.dart';

class HeroStatus {
  final bool isOnline;
  final bool isVerified;
  final bool isApproved;
  final DateTime? onlineSince;
  final String? currentJobId;

  const HeroStatus({
    this.isOnline = false,
    this.isVerified = false,
    this.isApproved = false,
    this.onlineSince,
    this.currentJobId,
  });

  factory HeroStatus.fromJson(Map<String, dynamic> json) {
    return HeroStatus(
      isOnline: json['isOnline'] ?? false,
      isVerified: json['isVerified'] ?? false,
      isApproved: json['isApproved'] ?? false,
      onlineSince: (json['onlineSince'] as Timestamp?)?.toDate(),
      currentJobId: json['currentJobId'],
    );
  }
}

class Vehicle {
  final String? make;
  final String? model;
  final String? year;
  final String? color;
  final String? licensePlate;
  final String? photoUrl;

  const Vehicle({
    this.make,
    this.model,
    this.year,
    this.color,
    this.licensePlate,
    this.photoUrl,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      make: json['make'],
      model: json['model'],
      year: json['year'],
      color: json['color'],
      licensePlate: json['licensePlate'],
      photoUrl: json['photoUrl'],
    );
  }
}

class HeroSettings {
  final bool pushEnabled;
  final String? pushToken;
  final int maxRadius;
  final bool autoAccept;

  const HeroSettings({
    this.pushEnabled = true,
    this.pushToken,
    this.maxRadius = 15,
    this.autoAccept = false,
  });

  factory HeroSettings.fromJson(Map<String, dynamic> json) {
    return HeroSettings(
      pushEnabled: json['pushEnabled'] ?? true,
      pushToken: json['pushToken'],
      maxRadius: json['maxRadius'] ?? 15,
      autoAccept: json['autoAccept'] ?? false,
    );
  }
}

class HeroModel {
  final String id;
  final String userId;
  final String email;
  final String? phone;
  final String displayName;
  final String? photoUrl;
  final HeroStatus status;
  final Vehicle? vehicle;
  final List<String> servicesOffered;
  final List<String> equipment;
  final LocationModel? lastKnownLocation;
  final String? radarUserId;
  final HeroSettings settings;
  final double rating;
  final int ratingCount;
  final int totalEarned;
  final int pendingPayout;
  final int totalJobs;
  final double completionRate;
  final double acceptanceRate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const HeroModel({
    required this.id,
    required this.userId,
    required this.email,
    this.phone,
    required this.displayName,
    this.photoUrl,
    this.status = const HeroStatus(),
    this.vehicle,
    this.servicesOffered = const [],
    this.equipment = const [],
    this.lastKnownLocation,
    this.radarUserId,
    this.settings = const HeroSettings(),
    this.rating = 5.0,
    this.ratingCount = 0,
    this.totalEarned = 0,
    this.pendingPayout = 0,
    this.totalJobs = 0,
    this.completionRate = 0.0,
    this.acceptanceRate = 0.0,
    this.createdAt,
    this.updatedAt,
  });

  factory HeroModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    // services can be a Map or a List in Firestore; handle both
    final rawServices = data['services'];
    Map<String, dynamic>? services;
    List<String> servicesOffered = [];
    List<String> equipment = [];
    if (rawServices is Map<String, dynamic>) {
      services = rawServices;
      servicesOffered = List<String>.from(services['offered'] ?? []);
      equipment = List<String>.from(services['equipment'] ?? []);
    } else if (rawServices is List) {
      servicesOffered = List<String>.from(rawServices);
    }

    final location = data['location'] is Map<String, dynamic>
        ? data['location'] as Map<String, dynamic>
        : null;
    return HeroModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'],
      displayName: data['displayName'] ?? '',
      photoUrl: data['photoUrl'],
      status: data['status'] != null
          ? HeroStatus.fromJson(data['status'])
          : const HeroStatus(),
      vehicle: data['vehicle'] != null
          ? Vehicle.fromJson(data['vehicle'])
          : null,
      servicesOffered: servicesOffered,
      equipment: equipment,
      lastKnownLocation: location != null && location['lastKnownLocation'] != null
          ? LocationModel.fromFirestore(
              location['lastKnownLocation'] as Map<String, dynamic>)
          : null,
      radarUserId: location?['radarUserId'],
      settings: data['settings'] != null
          ? HeroSettings.fromJson(data['settings'])
          : const HeroSettings(),
      rating: (data['ratings']?['average'] as num?)?.toDouble() ?? 5.0,
      ratingCount: data['ratings']?['count'] ?? 0,
      totalEarned: data['earnings']?['totalEarned'] ?? 0,
      pendingPayout: data['earnings']?['pendingPayout'] ?? 0,
      totalJobs: data['stats']?['totalJobs'] ?? 0,
      completionRate:
          (data['stats']?['completionRate'] as num?)?.toDouble() ?? 0.0,
      acceptanceRate:
          (data['stats']?['acceptanceRate'] as num?)?.toDouble() ?? 0.0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
