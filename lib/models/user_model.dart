import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { customer, hero, admin }

class UserSettings {
  final bool pushEnabled;
  final String? pushToken;
  final String language;
  final bool emailNotifications;
  final bool smsNotifications;

  const UserSettings({
    this.pushEnabled = true,
    this.pushToken,
    this.language = 'en',
    this.emailNotifications = true,
    this.smsNotifications = true,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      pushEnabled: json['pushEnabled'] ?? true,
      pushToken: json['pushToken'],
      language: json['language'] ?? 'en',
      emailNotifications: json['emailNotifications'] ?? true,
      smsNotifications: json['smsNotifications'] ?? true,
    );
  }
}

class SavedLocation {
  final String id;
  final String label;
  final double latitude;
  final double longitude;
  final String? address;
  final String? notes;

  const SavedLocation({
    required this.id,
    required this.label,
    required this.latitude,
    required this.longitude,
    this.address,
    this.notes,
  });

  factory SavedLocation.fromJson(Map<String, dynamic> json) {
    return SavedLocation(
      id: json['id'] ?? '',
      label: json['label'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      address: json['address'],
      notes: json['notes'],
    );
  }
}

class UserModel {
  final String id;
  final String email;
  final String? phone;
  final String? displayName;
  final String? firstName;
  final String? lastName;
  final String? photoUrl;
  final UserRole role;
  final String? heroProfileId;
  final UserSettings settings;
  final List<SavedLocation> savedLocations;
  final String? stripeCustomerId;
  final bool emailVerified;
  final bool phoneVerified;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLoginAt;

  const UserModel({
    required this.id,
    required this.email,
    this.phone,
    this.displayName,
    this.firstName,
    this.lastName,
    this.photoUrl,
    this.role = UserRole.customer,
    this.heroProfileId,
    this.settings = const UserSettings(),
    this.savedLocations = const [],
    this.stripeCustomerId,
    this.emailVerified = false,
    this.phoneVerified = false,
    this.createdAt,
    this.updatedAt,
    this.lastLoginAt,
  });

  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return displayName ?? email;
  }

  bool get isHero => role == UserRole.hero;
  bool get isAdmin => role == UserRole.admin;

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      phone: data['phone'],
      displayName: data['displayName'],
      firstName: data['firstName'],
      lastName: data['lastName'],
      photoUrl: data['photoUrl'],
      role: _parseUserRole(data['role']),
      heroProfileId: data['heroProfileId'],
      settings: data['settings'] != null
          ? UserSettings.fromJson(data['settings'])
          : const UserSettings(),
      savedLocations: (data['savedLocations'] as List?)
              ?.map((e) => SavedLocation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      stripeCustomerId: data['stripeCustomerId'],
      emailVerified: data['emailVerified'] ?? false,
      phoneVerified: data['phoneVerified'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
    );
  }

  static UserRole _parseUserRole(String? role) {
    switch (role) {
      case 'hero':
        return UserRole.hero;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.customer;
    }
  }
}
