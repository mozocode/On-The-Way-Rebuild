import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/hero_application_model.dart';

class HeroApplicationService {
  static final HeroApplicationService _instance =
      HeroApplicationService._internal();
  factory HeroApplicationService() => _instance;
  HeroApplicationService._internal();

  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _functions = FirebaseFunctions.instance;

  CollectionReference<Map<String, dynamic>> get _applications =>
      _firestore.collection('heroApplications');

  // ── Application CRUD ──

  Future<HeroApplicationModel> getOrCreateApplication(
      String userId, String email) async {
    final query = await _applications
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return HeroApplicationModel.fromFirestore(query.docs.first);
    }

    final docRef = await _applications.add({
      'userId': userId,
      'userEmail': email,
      'status': 'draft',
      'currentStep': 1,
      'completedSteps': <int>[],
      'documents': <Map<String, dynamic>>[],
      'reviewNotes': <Map<String, dynamic>>[],
      'statusHistory': <Map<String, dynamic>>[],
      'trainingCompleted': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final doc = await docRef.get();
    return HeroApplicationModel.fromFirestore(doc);
  }

  Future<HeroApplicationModel?> getApplication(String applicationId) async {
    final doc = await _applications.doc(applicationId).get();
    if (!doc.exists) return null;
    return HeroApplicationModel.fromFirestore(doc);
  }

  Stream<HeroApplicationModel?> watchApplication(String applicationId) {
    return _applications.doc(applicationId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return HeroApplicationModel.fromFirestore(doc);
    });
  }

  Stream<HeroApplicationModel?> watchUserApplication(String userId) {
    return _applications
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return HeroApplicationModel.fromFirestore(snapshot.docs.first);
    });
  }

  // ── Step 1: Personal Info ──

  Future<void> updatePersonalInfo(
      String applicationId, PersonalInfo info) async {
    await _applications.doc(applicationId).update({
      'personalInfo': info.toJson(),
      'completedSteps': FieldValue.arrayUnion([1]),
      'currentStep': 2,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Step 2: Vehicle Info ──

  Future<void> updateVehicleInfo(
      String applicationId, VehicleInfo info) async {
    await _applications.doc(applicationId).update({
      'vehicleInfo': info.toJson(),
      'completedSteps': FieldValue.arrayUnion([2]),
      'currentStep': 3,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Step 3: Service Capabilities ──

  Future<void> updateServiceCapabilities(
    String applicationId,
    ServiceCapabilities capabilities,
  ) async {
    await _applications.doc(applicationId).update({
      'serviceCapabilities': capabilities.toJson(),
      'completedSteps': FieldValue.arrayUnion([3]),
      'currentStep': 4,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Step 4: Documents ──

  Future<UploadedDocument> uploadDocument(
    String applicationId,
    String userId,
    DocumentType type,
    File file, {
    String? expirationDate,
  }) async {
    final ext = file.path.split('.').last.toLowerCase();
    final fileName =
        '${type.name}_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final storagePath =
        'hero_applications/$userId/$applicationId/$fileName';

    final ref = _storage.ref(storagePath);
    final uploadTask = await ref.putFile(
      file,
      SettableMetadata(
        contentType: _contentType(ext),
        customMetadata: {
          'applicationId': applicationId,
          'documentType': type.name,
        },
      ),
    );

    final downloadUrl = await uploadTask.ref.getDownloadURL();

    final docData = {
      'type': type.name,
      'url': downloadUrl,
      'storagePath': storagePath,
      'uploadedAt': Timestamp.now(),
      'verified': false,
      'expirationDate': expirationDate,
    };

    await _applications.doc(applicationId).update({
      'documents': FieldValue.arrayUnion([docData]),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return UploadedDocument(
      type: type,
      url: downloadUrl,
      storagePath: storagePath,
      uploadedAt: DateTime.now(),
      expirationDate: expirationDate,
    );
  }

  Future<void> removeDocument(
    String applicationId,
    UploadedDocument document,
  ) async {
    try {
      await _storage.ref(document.storagePath).delete();
    } catch (_) {}

    // Re-fetch then filter to avoid arrayRemove ordering issues
    final doc = await _applications.doc(applicationId).get();
    final data = doc.data();
    if (data == null) return;

    final docs = (data['documents'] as List?) ?? [];
    docs.removeWhere(
        (d) => d['storagePath'] == document.storagePath);

    await _applications.doc(applicationId).update({
      'documents': docs,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> completeDocumentsStep(String applicationId) async {
    await _applications.doc(applicationId).update({
      'completedSteps': FieldValue.arrayUnion([4]),
      'currentStep': 5,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Step 5: Agreements ──

  Future<void> updateAgreements(
      String applicationId, Agreements agreements) async {
    await _applications.doc(applicationId).update({
      'agreements': agreements.toJson(),
      'completedSteps': FieldValue.arrayUnion([5]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Submission ──

  Future<Map<String, dynamic>> submitApplication(
      String applicationId) async {
    try {
      final callable =
          _functions.httpsCallable('submitHeroApplication');
      final result = await callable.call({'applicationId': applicationId});
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      rethrow;
    }
  }

  String _contentType(String ext) {
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      case 'heic':
        return 'image/heic';
      default:
        return 'application/octet-stream';
    }
  }
}
