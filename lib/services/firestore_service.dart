import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/firebase_config.dart';
import '../models/user_model.dart';
import '../models/hero_model.dart';
import '../models/job_model.dart';
import '../models/message_model.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  FirebaseFirestore get _db => FirebaseConfig.firestore;

  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _heroes =>
      _db.collection('heroes');
  CollectionReference<Map<String, dynamic>> get _jobs => _db.collection('jobs');
  CollectionReference<Map<String, dynamic>> get _dispatchWaves =>
      _db.collection('dispatchWaves');

  Future<UserModel?> getUser(String userId) async {
    final doc = await _users.doc(userId).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Stream<UserModel?> watchUser(String userId) {
    return _users.doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    await _users.doc(userId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<HeroModel?> getHero(String heroId) async {
    final doc = await _heroes.doc(heroId).get();
    if (!doc.exists) return null;
    return HeroModel.fromFirestore(doc);
  }

  Stream<HeroModel?> watchHero(String heroId) {
    return _heroes.doc(heroId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return HeroModel.fromFirestore(doc);
    });
  }

  Future<void> updateHeroStatus(String heroId,
      {required bool isOnline, String? currentJobId}) async {
    await _heroes.doc(heroId).update({
      'status.isOnline': isOnline,
      'status.currentJobId': currentJobId,
      'status.onlineSince': isOnline ? FieldValue.serverTimestamp() : null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateHeroPushToken(String heroId, String token) async {
    await _heroes.doc(heroId).update({
      'settings.pushToken': token,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String> createJob(Map<String, dynamic> jobData) async {
    final docRef = await _jobs.add({
      ...jobData,
      'status': 'pending',
      'timestamps': {
        'createdAt': FieldValue.serverTimestamp(),
      },
    });
    return docRef.id;
  }

  Future<JobModel?> getJob(String jobId) async {
    final doc = await _jobs.doc(jobId).get();
    if (!doc.exists) return null;
    return JobModel.fromFirestore(doc);
  }

  Stream<JobModel?> watchJob(String jobId) {
    return _jobs.doc(jobId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return JobModel.fromFirestore(doc);
    });
  }

  Stream<JobModel?> watchActiveCustomerJob(String customerId) {
    return _jobs
        .where('customer.id', isEqualTo: customerId)
        .where('status', whereIn: [
          'pending',
          'searching',
          'assigned',
          'en_route',
          'arrived',
          'in_progress',
        ])
        .orderBy('timestamps.createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return JobModel.fromFirestore(snapshot.docs.first);
        });
  }

  Stream<JobModel?> watchActiveHeroJob(String heroId) {
    return _jobs
        .where('hero.id', isEqualTo: heroId)
        .where('status', whereIn: [
          'assigned',
          'en_route',
          'arrived',
          'in_progress',
        ])
        .orderBy('timestamps.createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return JobModel.fromFirestore(snapshot.docs.first);
        });
  }

  Stream<List<JobModel>> watchPendingJobs() {
    return _jobs
        .where('status', isEqualTo: 'searching')
        .orderBy('timestamps.createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => JobModel.fromFirestore(doc)).toList();
        });
  }

  String _getTimestampField(String status) {
    switch (status) {
      case 'assigned':
        return 'assignedAt';
      case 'en_route':
        return 'heroEnRouteAt';
      case 'arrived':
        return 'heroArrivedAt';
      case 'in_progress':
        return 'serviceStartedAt';
      case 'completed':
        return 'completedAt';
      case 'cancelled':
        return 'cancelledAt';
      default:
        return 'updatedAt';
    }
  }

  Future<void> updateJobStatus(String jobId, String status) async {
    await _jobs.doc(jobId).update({
      'status': status,
      'statusHistory': FieldValue.arrayUnion([
        {'status': status, 'at': FieldValue.serverTimestamp()}
      ]),
      'timestamps.${_getTimestampField(status)}': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateJobTracking(String jobId, Map<String, dynamic> data) async {
    final updates = <String, dynamic>{};
    for (final e in data.entries) {
      updates['tracking.${e.key}'] = e.value;
    }
    await _jobs.doc(jobId).update(updates);
  }

  Future<bool> acceptJob(String jobId, String heroId) async {
    try {
      await _db.runTransaction((transaction) async {
        final jobDoc = await transaction.get(_jobs.doc(jobId));
        final heroDoc = await transaction.get(_heroes.doc(heroId));

        if (!jobDoc.exists || !heroDoc.exists) {
          throw Exception('Job or Hero not found');
        }

        final job = jobDoc.data()!;
        final hero = heroDoc.data()!;

        if (job['status'] != 'searching') {
          throw Exception('Job is no longer available');
        }

        if (hero['status']?['currentJobId'] != null) {
          throw Exception('Hero already has an active job');
        }

        final now = FieldValue.serverTimestamp();

        transaction.update(_jobs.doc(jobId), {
          'status': 'assigned',
          'hero': {
            'id': heroId,
            'name': hero['displayName'],
            'phone': hero['phone'],
            'photoUrl': hero['photoUrl'],
            'vehicleMake': hero['vehicle']?['make'],
            'vehicleModel': hero['vehicle']?['model'],
            'vehicleColor': hero['vehicle']?['color'],
            'licensePlate': hero['vehicle']?['licensePlate'],
          },
          'dispatch.acceptedBy': heroId,
          'dispatch.acceptedAt': now,
          'timestamps.assignedAt': now,
          'statusHistory': FieldValue.arrayUnion([
            {'status': 'assigned', 'at': now, 'heroId': heroId}
          ]),
        });

        transaction.update(_heroes.doc(heroId), {
          'status.currentJobId': jobId,
          'updatedAt': now,
        });
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  CollectionReference<Map<String, dynamic>> _messages(String jobId) =>
      _jobs.doc(jobId).collection('messages');

  Stream<List<MessageModel>> watchMessages(String jobId) {
    return _messages(jobId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => MessageModel.fromFirestore(doc))
              .toList();
        });
  }

  Future<void> sendMessage(
      String jobId, String senderId, String content) async {
    await _messages(jobId).add({
      'senderId': senderId,
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });
  }

  Stream<Map<String, dynamic>?> watchDispatchProgress(String jobId) {
    return _dispatchWaves.doc(jobId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return doc.data();
    });
  }
}
