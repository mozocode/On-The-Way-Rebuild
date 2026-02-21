import 'dart:math' as math;
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

  Stream<List<JobModel>> watchPendingJobs({
    double? heroLat,
    double? heroLng,
    double radiusMiles = 30,
  }) {
    return _jobs
        .where('status', isEqualTo: 'searching')
        .orderBy('timestamps.createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          var jobs = snapshot.docs.map((doc) => JobModel.fromFirestore(doc)).toList();
          if (heroLat != null && heroLng != null) {
            jobs = jobs.where((job) {
              final lat = job.pickup.location.latitude;
              final lng = job.pickup.location.longitude;
              if (lat == 0 && lng == 0) return true;
              return _distanceMiles(heroLat, heroLng, lat, lng) <= radiusMiles;
            }).toList();
          }
          return jobs;
        });
  }

  static double _distanceMiles(double lat1, double lng1, double lat2, double lng2) {
    const r = 3958.8;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLng = (lng2 - lng1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) * math.cos(lat2 * math.pi / 180) *
        math.sin(dLng / 2) * math.sin(dLng / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
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

  static const _validTransitions = <String, Set<String>>{
    'searching': {'assigned', 'cancelled'},
    'assigned': {'en_route', 'cancelled'},
    'en_route': {'arrived', 'cancelled'},
    'arrived': {'in_progress', 'cancelled'},
    'in_progress': {'completed', 'cancelled'},
  };

  Future<void> updateJobStatus(String jobId, String status) async {
    await _db.runTransaction((transaction) async {
      final jobDoc = await transaction.get(_jobs.doc(jobId));
      if (!jobDoc.exists) throw Exception('Job not found');

      final currentStatus = jobDoc.data()?['status'] as String?;
      final allowed = _validTransitions[currentStatus];
      if (allowed == null || !allowed.contains(status)) {
        throw Exception('Invalid status transition: $currentStatus -> $status');
      }

      transaction.update(_jobs.doc(jobId), {
        'status': status,
        'statusHistory': FieldValue.arrayUnion([
          {'status': status, 'at': Timestamp.now()}
        ]),
        'timestamps.${_getTimestampField(status)}': FieldValue.serverTimestamp(),
      });
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

        final existingJobId = hero['status']?['currentJobId'];
        if (existingJobId != null) {
          final oldJobDoc =
              await transaction.get(_jobs.doc(existingJobId as String));
          if (oldJobDoc.exists) {
            final oldStatus = oldJobDoc.data()?['status'];
            if (oldStatus != null &&
                oldStatus != 'completed' &&
                oldStatus != 'cancelled') {
              throw Exception('Hero already has an active job');
            }
          }
          // Stale reference – will be overwritten below
        }

        final now = FieldValue.serverTimestamp();
        final nowTimestamp = Timestamp.now();

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
            {'status': 'assigned', 'at': nowTimestamp, 'heroId': heroId}
          ]),
        });

        transaction.update(_heroes.doc(heroId), {
          'status.currentJobId': jobId,
          'updatedAt': now,
        });
      });
      return true;
    } catch (e, st) {
      print('acceptJob error: $e\n$st');
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

  Future<void> submitReview({
    required String jobId,
    required String reviewerId,
    required String revieweeId,
    required String reviewerRole,
    required int rating,
    List<String> tags = const [],
    String? comment,
    int? tipAmountCents,
  }) async {
    final reviewData = {
      'jobId': jobId,
      'reviewerId': reviewerId,
      'revieweeId': revieweeId,
      'reviewerRole': reviewerRole,
      'rating': rating,
      'tags': tags,
      'comment': comment,
      'tipAmountCents': tipAmountCents,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _jobs.doc(jobId).collection('reviews').doc(reviewerRole).set(reviewData);

    if (tipAmountCents != null && tipAmountCents > 0) {
      await _jobs.doc(jobId).update({
        'pricing.tipAmountCents': tipAmountCents,
      });
    }
  }

  Stream<List<JobModel>> watchHeroCompletedJobsToday(String heroId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final startOfTomorrow = startOfDay.add(const Duration(days: 1));

    return _jobs
        .where('hero.id', isEqualTo: heroId)
        .where('status', isEqualTo: 'completed')
        .where('timestamps.completedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('timestamps.completedAt',
            isLessThan: Timestamp.fromDate(startOfTomorrow))
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => JobModel.fromFirestore(doc))
              .toList();
        });
  }

  Stream<JobModel?> watchLatestCompletedCustomerJob(String customerId) {
    return _jobs
        .where('customer.id', isEqualTo: customerId)
        .where('status', isEqualTo: 'completed')
        .orderBy('timestamps.completedAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return JobModel.fromFirestore(snapshot.docs.first);
        });
  }

  Future<bool> hasReview(String jobId, String role) async {
    final doc = await _jobs.doc(jobId).collection('reviews').doc(role).get();
    return doc.exists;
  }
}
