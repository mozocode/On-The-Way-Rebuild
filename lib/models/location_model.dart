import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

class LocationModel {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? heading;
  final double? speed;
  final double? altitude;
  final String? address;
  final DateTime? updatedAt;

  const LocationModel({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.heading,
    this.speed,
    this.altitude,
    this.address,
    this.updatedAt,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      heading: (json['heading'] as num?)?.toDouble(),
      speed: (json['speed'] as num?)?.toDouble(),
      altitude: (json['altitude'] as num?)?.toDouble(),
      address: json['address'] as String?,
      updatedAt: json['updatedAt'] is Timestamp
          ? (json['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  factory LocationModel.fromFirestore(Map<String, dynamic> data) {
    return LocationModel(
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
      accuracy: (data['accuracy'] as num?)?.toDouble(),
      heading: (data['heading'] as num?)?.toDouble(),
      speed: (data['speed'] as num?)?.toDouble(),
      altitude: (data['altitude'] as num?)?.toDouble(),
      address: data['address'] as String?,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  factory LocationModel.fromRealtimeDb(Map<dynamic, dynamic> data) {
    return LocationModel(
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
      accuracy: (data['accuracy'] as num?)?.toDouble(),
      heading: (data['heading'] as num?)?.toDouble(),
      speed: (data['speed'] as num?)?.toDouble(),
      altitude: (data['altitude'] as num?)?.toDouble(),
      address: data['address'] as String?,
      updatedAt: data['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch((data['updatedAt'] as num).toInt())
          : null,
    );
  }

  Map<String, dynamic> toRealtimeDb() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'heading': heading,
      'speed': speed,
      'altitude': altitude,
      'address': address,
      'updatedAt': ServerValue.timestamp,
    };
  }
}
