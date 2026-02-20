import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../config/radar_config.dart';
import '../../config/theme.dart';
import '../../models/job_model.dart';
import '../../models/service_type_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_provider.dart';
import '../../providers/tracking_provider.dart';
import '../../services/firestore_service.dart';
import '../review/customer_review_screen.dart';
import 'chat_screen.dart';

String get _radarMapStyle =>
    'https://api.radar.io/maps/styles/radar-default-v1/?publishableKey=${RadarConfig.publishableKey}';

class CustomerTrackingScreen extends ConsumerStatefulWidget {
  final String jobId;

  const CustomerTrackingScreen({super.key, required this.jobId});

  @override
  ConsumerState<CustomerTrackingScreen> createState() =>
      _CustomerTrackingScreenState();
}

class _CustomerTrackingScreenState
    extends ConsumerState<CustomerTrackingScreen> {
  MapLibreMapController? _mapController;
  Circle? _heroCircle;
  Circle? _customerCircle;
  Line? _routeLine;
  StreamSubscription? _jobSub;
  JobModel? _currentJob;
  bool _mapReady = false;
  String? _lastPolyline;
  bool _hasNavigatedToReview = false;
  bool _isCancelling = false;
  LatLng? _lastHeroCameraPos;
  Timer? _cameraRefitTimer;

  @override
  void initState() {
    super.initState();
    _jobSub = FirestoreService().watchJob(widget.jobId).listen(
      (job) {
        if (!mounted) return;
        setState(() => _currentJob = job);
        if (job?.status == JobStatus.completed && !_hasNavigatedToReview) {
          _hasNavigatedToReview = true;
          _navigateToReview(job!);
        }
      },
      onError: (_) {},
    );
  }

  @override
  void dispose() {
    _jobSub?.cancel();
    _cameraRefitTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _navigateToReview(JobModel job) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final user = ref.read(currentUserProvider);
      if (user == null) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CustomerReviewScreen(job: job, customerId: user.id),
        ),
      );
    });
  }

  Future<void> _cancelRequest() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Request?'),
        content: const Text('Are you sure you want to cancel this request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _isCancelling = true);
    try {
      await FirestoreService().updateJobStatus(widget.jobId, 'cancelled');
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (mounted) {
        setState(() => _isCancelling = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel: $e')),
        );
      }
    }
  }

  void _openChat() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatScreen(jobId: widget.jobId)),
    );
  }

  // ── Map overlay methods ──────────────────────────────────────────────────

  Future<void> _syncMapOverlays(TrackingState trackingState) async {
    final controller = _mapController;
    if (controller == null || !_mapReady) return;
    try {
      await _syncMapOverlaysInner(controller, trackingState);
    } catch (e) {
      debugPrint('[MAP] _syncMapOverlays error: $e');
    }
  }

  Future<void> _syncMapOverlaysInner(
      MapLibreMapController controller, TrackingState trackingState) async {
    if (!mounted) return;
    final job = _currentJob;
    if (job == null) return;

    // Customer circle (red)
    final custPos = LatLng(
      job.pickup.location.latitude,
      job.pickup.location.longitude,
    );
    if (_customerCircle != null) {
      await controller.updateCircle(
          _customerCircle!, CircleOptions(geometry: custPos));
    } else {
      _customerCircle = await controller.addCircle(CircleOptions(
        geometry: custPos,
        circleRadius: 10,
        circleColor: '#E53935',
        circleStrokeWidth: 3,
        circleStrokeColor: '#FFFFFF',
      ));
    }

    // Hero circle (green) – only when hero is assigned and location available
    final heroLoc = trackingState.displayLocation;
    if (heroLoc != null) {
      final heroPos = LatLng(heroLoc.latitude, heroLoc.longitude);
      if (_heroCircle != null) {
        await controller.updateCircle(
            _heroCircle!, CircleOptions(geometry: heroPos));
      } else {
        _heroCircle = await controller.addCircle(CircleOptions(
          geometry: heroPos,
          circleRadius: 12,
          circleColor: '#4CAF50',
          circleStrokeWidth: 3,
          circleStrokeColor: '#FFFFFF',
        ));
      }
      _refitCameraIfNeeded(heroPos, custPos);
    }

    // Route polyline
    final polyStr = trackingState.routePolyline;
    if (polyStr != null && polyStr.isNotEmpty) {
      final points = _decodePolyline(polyStr);
      if (points.length >= 2) {
        if (_routeLine != null) {
          await controller.updateLine(
              _routeLine!, LineOptions(geometry: points));
        } else {
          _routeLine = await controller.addLine(LineOptions(
            geometry: points,
            lineColor: '#4CAF50',
            lineWidth: 5,
            lineOpacity: 0.85,
          ));
        }
        if (_lastPolyline != polyStr) {
          _lastPolyline = polyStr;
          _fitBoundsToRoute(points);
        }
      }
    }
  }

  void _fitBounds({TrackingState? tracking}) {
    final controller = _mapController;
    if (controller == null || !_mapReady || _currentJob == null || !mounted) {
      return;
    }
    final cLat = _currentJob!.pickup.location.latitude;
    final cLng = _currentJob!.pickup.location.longitude;

    double minLat = cLat, maxLat = cLat;
    double minLng = cLng, maxLng = cLng;

    final heroLoc = tracking?.displayLocation;
    if (heroLoc != null) {
      minLat = min(minLat, heroLoc.latitude);
      maxLat = max(maxLat, heroLoc.latitude);
      minLng = min(minLng, heroLoc.longitude);
      maxLng = max(maxLng, heroLoc.longitude);
    }

    try {
      controller.animateCamera(CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat - 0.005, minLng - 0.005),
          northeast: LatLng(maxLat + 0.005, maxLng + 0.005),
        ),
        left: 50,
        right: 50,
        top: 80,
        bottom: 320,
      ));
    } catch (e) {
      debugPrint('[MAP] _fitBounds error: $e');
    }
  }

  void _fitBoundsToRoute(List<LatLng> points) {
    final controller = _mapController;
    if (controller == null || !_mapReady || points.isEmpty) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;
    for (final p in points) {
      minLat = min(minLat, p.latitude);
      maxLat = max(maxLat, p.latitude);
      minLng = min(minLng, p.longitude);
      maxLng = max(maxLng, p.longitude);
    }
    try {
      controller.animateCamera(CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat - 0.003, minLng - 0.003),
          northeast: LatLng(maxLat + 0.003, maxLng + 0.003),
        ),
        left: 50,
        right: 50,
        top: 80,
        bottom: 320,
      ));
    } catch (e) {
      debugPrint('[MAP] _fitBoundsToRoute error: $e');
    }
  }

  void _refitCameraIfNeeded(LatLng heroPos, LatLng customerPos) {
    if (_lastHeroCameraPos != null) {
      final dLat = (heroPos.latitude - _lastHeroCameraPos!.latitude).abs();
      final dLng = (heroPos.longitude - _lastHeroCameraPos!.longitude).abs();
      if (dLat < 0.0005 && dLng < 0.0005) return;
    }
    _lastHeroCameraPos = heroPos;

    final controller = _mapController;
    if (controller == null || !_mapReady || !mounted) return;

    final minLat = min(heroPos.latitude, customerPos.latitude);
    final maxLat = max(heroPos.latitude, customerPos.latitude);
    final minLng = min(heroPos.longitude, customerPos.longitude);
    final maxLng = max(heroPos.longitude, customerPos.longitude);

    try {
      controller.animateCamera(CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat - 0.003, minLng - 0.003),
          northeast: LatLng(maxLat + 0.003, maxLng + 0.003),
        ),
        left: 50,
        right: 50,
        top: 80,
        bottom: 320,
      ));
    } catch (e) {
      debugPrint('[MAP] _refitCameraIfNeeded error: $e');
    }
  }

  List<LatLng> _decodePolyline(String encoded, {int precision = 6}) {
    if (encoded.isEmpty) return [];
    final points = <LatLng>[];
    int index = 0, lat = 0, lng = 0;
    final factor = pow(10, precision).toInt();
    while (index < encoded.length) {
      int shift = 0, result = 0, byte;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      shift = 0;
      result = 0;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      points.add(LatLng(lat / factor, lng / factor));
    }
    return points;
  }

  String _formatDistance(double? miles) {
    if (miles == null) return '';
    if (miles < 0.19) return '${(miles * 5280).toStringAsFixed(1)} ft away';
    return '${miles.toStringAsFixed(1)} mi away';
  }

  bool _isSearchingState(JobModel? job) {
    return job == null ||
        job.status == JobStatus.pending ||
        job.status == JobStatus.searching;
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final trackingState = ref.watch(trackingProvider(widget.jobId));
    final job = _currentJob;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncMapOverlays(trackingState);
    });

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(color: const Color(0xFFE8E8E8)),
                ),
                if (!kIsWeb)
                  Positioned.fill(
                    child: MapLibreMap(
                      styleString: _radarMapStyle,
                      initialCameraPosition: CameraPosition(
                        target: job != null
                            ? LatLng(job.pickup.location.latitude,
                                job.pickup.location.longitude)
                            : const LatLng(40.4568, -79.9183),
                        zoom: 15,
                      ),
                      onMapCreated: (c) => _mapController = c,
                      onStyleLoadedCallback: () {
                        _mapReady = true;
                        _syncMapOverlays(trackingState);
                        _fitBounds(tracking: trackingState);
                      },
                      myLocationEnabled: false,
                      tiltGesturesEnabled: false,
                      rotateGesturesEnabled: false,
                    ),
                  ),
                // Top bar
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 16,
                  right: 16,
                  child: Row(
                    children: [
                      _CircleButton(
                        icon: _isSearchingState(job)
                            ? Icons.arrow_back
                            : Icons.close,
                        onTap: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      if (!_isSearchingState(job) &&
                          trackingState.etaMinutes != null)
                        _EtaBadge(minutes: trackingState.etaMinutes!),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildBottomPanel(job, trackingState),
        ],
      ),
    );
  }

  Widget _buildBottomPanel(JobModel? job, TrackingState tracking) {
    if (job == null) return _buildSearchingPanel(null, null);
    switch (job.status) {
      case JobStatus.pending:
      case JobStatus.searching:
        return _buildSearchingPanel(job, tracking);
      case JobStatus.assigned:
      case JobStatus.enRoute:
        return _buildHeroEnRoutePanel(job, tracking);
      case JobStatus.arrived:
        return _buildArrivedPanel(job);
      case JobStatus.inProgress:
        return _buildInProgressPanel(job);
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Finding Hero Panel ───────────────────────────────────────────────────

  Widget _buildSearchingPanel(JobModel? job, TrackingState? tracking) {
    final service =
        job != null ? ServiceTypes.getById(job.serviceType) : null;
    final serviceName =
        service?.name ?? job?.serviceType.replaceAll('_', ' ') ?? 'Service';
    final address =
        job?.pickup.address?.formatted ?? 'Locating...';

    return _PanelShell(
      children: [
        Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.brandGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppTheme.brandGreen.withOpacity(0.4)),
              ),
              child: Text(
                'Finding Hero...',
                style: TextStyle(
                  color: AppTheme.brandGreen,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Spacer(),
            Text(
              serviceName,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                  color: Color(0xFFE53935), shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                address,
                style: const TextStyle(fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _openChat,
            icon: const Icon(Icons.chat_bubble_outline, size: 18),
            label: const Text('Chat'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.brandGreen,
              side: const BorderSide(
                  color: AppTheme.brandGreen, width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Finding a Hero nearby...',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _isCancelling ? null : _cancelRequest,
          child: Text(
            'Cancel Request',
            style: TextStyle(
              color: _isCancelling ? Colors.grey : Colors.red,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // ── Hero En Route Panel ──────────────────────────────────────────────────

  Widget _buildHeroEnRoutePanel(JobModel job, TrackingState tracking) {
    final hero = job.hero;
    if (hero == null) return _buildSearchingPanel(job, tracking);

    final isAssigned = job.status == JobStatus.assigned;
    final statusLabel =
        isAssigned ? 'Hero is on the way' : 'Hero arriving in';
    final etaMinutes = tracking.etaMinutes;
    final distanceText = _formatDistance(tracking.etaDistance);

    return _PanelShell(
      children: [
        // Drag handle
        Center(
          child: Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Text(
          statusLabel,
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 2),
        Text(
          etaMinutes != null ? '$etaMinutes min' : '--',
          style: const TextStyle(
              fontSize: 36, fontWeight: FontWeight.w800),
        ),
        if (distanceText.isNotEmpty)
          Text(
            distanceText,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        const SizedBox(height: 16),
        _HeroInfoRow(hero: hero),
        const SizedBox(height: 16),
        _ActionButtonRow(onContact: _openChat, onSafety: () {}),
        if (isAssigned) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: _isCancelling ? null : _cancelRequest,
            child: Text(
              'Cancel Request',
              style: TextStyle(
                color: _isCancelling ? Colors.grey : Colors.red,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ── Hero Arrived Panel ───────────────────────────────────────────────────

  Widget _buildArrivedPanel(JobModel job) {
    final hero = job.hero;
    if (hero == null) return const SizedBox.shrink();

    return _PanelShell(
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const Text(
          'Hero has arrived',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.keyboard_arrow_up,
                size: 18, color: AppTheme.brandGreen),
            Text(
              'Tap to see Hero details',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.brandGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _HeroInfoRow(hero: hero),
        const SizedBox(height: 16),
        _ActionButtonRow(onContact: _openChat, onSafety: () {}),
      ],
    );
  }

  // ── Service In Progress Panel ────────────────────────────────────────────

  Widget _buildInProgressPanel(JobModel job) {
    final hero = job.hero;
    if (hero == null) return const SizedBox.shrink();

    return _PanelShell(
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const Text(
          'Service in progress',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        _HeroInfoRow(hero: hero),
        const SizedBox(height: 16),
        _ActionButtonRow(onContact: _openChat, onSafety: () {}),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _PanelShell extends StatelessWidget {
  final List<Widget> children;
  const _PanelShell({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 34),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
              color: Colors.black12, blurRadius: 16, offset: Offset(0, -4)),
        ],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Icon(icon, color: Colors.black, size: 22),
      ),
    );
  }
}

class _EtaBadge extends StatelessWidget {
  final int minutes;
  const _EtaBadge({required this.minutes});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.brandGreen,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Text(
        '$minutes min',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _HeroInfoRow extends StatelessWidget {
  final JobHero hero;
  const _HeroInfoRow({required this.hero});

  @override
  Widget build(BuildContext context) {
    final vehicleInfo = [
      if (hero.vehicleMake != null && hero.vehicleModel != null)
        '${hero.vehicleMake} ${hero.vehicleModel}',
    ].join(' ');

    return Row(
      children: [
        // Left: Hero details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hero.name,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700),
              ),
              if (vehicleInfo.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  vehicleInfo,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
              if (hero.vehicleColor != null) ...[
                const SizedBox(height: 1),
                Text(
                  hero.vehicleColor!,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
              const SizedBox(height: 4),
              Row(
                children: [
                  ...List.generate(
                    5,
                    (i) => const Icon(Icons.star,
                        color: Color(0xFFFFC107), size: 16),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '5.0',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Right: Avatar + vehicle image + plate
        SizedBox(
          width: 110,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Hero avatar
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.brandGreen.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: AppTheme.brandGreen, width: 2),
                    ),
                    child: hero.photoUrl != null
                        ? ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: hero.photoUrl!,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => const Icon(
                                  Icons.person,
                                  color: AppTheme.brandGreen,
                                  size: 24),
                              errorWidget: (_, __, ___) => const Icon(
                                  Icons.person,
                                  color: AppTheme.brandGreen,
                                  size: 24),
                            ),
                          )
                        : const Icon(Icons.person,
                            color: AppTheme.brandGreen, size: 24),
                  ),
                  const SizedBox(width: 6),
                  // Vehicle thumbnail
                  Container(
                    width: 56,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Icon(Icons.directions_car,
                          size: 28, color: Colors.grey[500]),
                    ),
                  ),
                ],
              ),
              if (hero.licensePlate != null) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2C),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    hero.licensePlate!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButtonRow extends StatelessWidget {
  final VoidCallback onContact;
  final VoidCallback onSafety;
  const _ActionButtonRow(
      {required this.onContact, required this.onSafety});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: onContact,
              icon: const Icon(Icons.phone, size: 18),
              label: const Text('Contact'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2C2C2C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: onSafety,
              icon: const Icon(Icons.verified_user, size: 18),
              label: const Text('Safety tools'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2C2C2C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
