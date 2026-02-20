import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../config/radar_config.dart';
import '../../config/theme.dart';
import '../../models/job_model.dart';
import '../../models/route_model.dart';
import '../../models/service_type_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/hero_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../services/firestore_service.dart';
import '../customer/chat_screen.dart';
import '../review/hero_review_screen.dart';

String get _radarMapStyle =>
    'https://api.radar.io/maps/styles/radar-default-v1/?publishableKey=${RadarConfig.publishableKey}';

class HeroActiveJobScreen extends ConsumerStatefulWidget {
  final String jobId;
  const HeroActiveJobScreen({super.key, required this.jobId});

  @override
  ConsumerState<HeroActiveJobScreen> createState() =>
      _HeroActiveJobScreenState();
}

class _HeroActiveJobScreenState extends ConsumerState<HeroActiveJobScreen> {
  MapLibreMapController? _mapController;
  Circle? _heroCircle;
  Circle? _customerCircle;
  Line? _routeLine;
  StreamSubscription? _jobSub;
  JobModel? _currentJob;
  bool _isUpdating = false;
  bool _mapReady = false;
  LatLng? _fallbackHeroPos;
  String? _lastPolyline;

  // ── Dynamic camera state ────────────────────────────────────────────
  LatLng? _lastCameraPos;
  double? _lastCameraBearing;
  double _smoothedZoom = 17.0;
  static const _defaultNavZoom = 17.0;
  static const _navTilt = 50.0;
  // How far ahead (degrees ≈ 90 m) to offset the camera so the hero sits
  // at roughly 35 % from the bottom of the screen.
  static const _cameraAheadOffset = 0.0008;

  @override
  void initState() {
    super.initState();
    _jobSub = FirestoreService().watchJob(widget.jobId).listen(
      (job) {
        if (!mounted) return;
        setState(() => _currentJob = job);
      },
      onError: (_) {},
    );
    _fetchFallbackLocation();
  }

  Future<void> _fetchFallbackLocation() async {
    try {
      final pos = await geo.Geolocator.getCurrentPosition(
          desiredAccuracy: geo.LocationAccuracy.high);
      if (mounted) setState(() => _fallbackHeroPos = LatLng(pos.latitude, pos.longitude));
    } catch (_) {}
  }

  @override
  void dispose() {
    _jobSub?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════════════════════════════════
  //  MAP OVERLAY SYNC
  // ════════════════════════════════════════════════════════════════════════

  Future<void> _syncMapOverlays(NavigationState navState) async {
    final controller = _mapController;
    if (controller == null || !_mapReady) return;
    try {
      await _syncOverlaysInner(controller, navState);
    } catch (e) {
      debugPrint('[MAP] overlay error: $e');
    }
  }

  Future<void> _syncOverlaysInner(
      MapLibreMapController ctrl, NavigationState nav) async {
    if (!mounted) return;
    final user = ref.read(currentUserProvider);
    final heroId = user?.heroProfileId ?? '';
    final heroState = ref.read(heroProvider(heroId));
    final isNav = _currentJob?.status == JobStatus.enRoute;

    // ── Hero dot ──
    final heroLoc = heroState.currentLocation;
    final heroPos = heroLoc != null
        ? LatLng(heroLoc.latitude, heroLoc.longitude)
        : _fallbackHeroPos;

    if (heroPos != null) {
      if (_heroCircle != null) {
        await ctrl.updateCircle(_heroCircle!, CircleOptions(geometry: heroPos));
      } else {
        _heroCircle = await ctrl.addCircle(CircleOptions(
          geometry: heroPos,
          circleRadius: 12,
          circleColor: '#4CAF50',
          circleStrokeWidth: 3,
          circleStrokeColor: '#FFFFFF',
        ));
      }
      if (isNav) {
        _updateNavigationCamera(
          heroPos: heroPos,
          heading: heroLoc?.heading,
          speedMps: heroLoc?.speed,
          navState: nav,
        );
      }
    }

    // ── Customer dot ──
    final job = _currentJob;
    if (job != null) {
      final cPos =
          LatLng(job.pickup.location.latitude, job.pickup.location.longitude);
      if (_customerCircle != null) {
        await ctrl.updateCircle(_customerCircle!, CircleOptions(geometry: cPos));
      } else {
        _customerCircle = await ctrl.addCircle(CircleOptions(
          geometry: cPos,
          circleRadius: 10,
          circleColor: '#E53935',
          circleStrokeWidth: 3,
          circleStrokeColor: '#FFFFFF',
        ));
      }
    }

    // ── Route polyline (trimmed to hero when navigating) ──
    final polyStr = nav.routePolyline;
    if (polyStr != null && polyStr.isNotEmpty) {
      var pts = _decodePolyline(polyStr);
      if (pts.length >= 2) {
        if (isNav && heroPos != null) pts = _trimPolylineAhead(pts, heroPos);
        if (_routeLine != null) {
          await ctrl.updateLine(_routeLine!, LineOptions(geometry: pts));
        } else {
          _routeLine = await ctrl.addLine(LineOptions(
            geometry: pts,
            lineColor: '#4CAF50',
            lineWidth: 6,
            lineOpacity: 0.9,
          ));
        }
        if (_lastPolyline != polyStr) {
          _lastPolyline = polyStr;
          if (!isNav) _fitBoundsToRoute(pts);
        }
      }
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  //  DYNAMIC NAVIGATION CAMERA
  // ════════════════════════════════════════════════════════════════════════

  void _updateNavigationCamera({
    required LatLng heroPos,
    double? heading,
    double? speedMps,
    required NavigationState navState,
  }) {
    final ctrl = _mapController;
    if (ctrl == null || !_mapReady || !mounted) return;

    // ── 1. Heading ──
    final bearing = (heading != null && heading >= 0 && heading <= 360)
        ? heading
        : (_lastCameraBearing ?? 0.0);

    // ── 2. Speed-based zoom ──
    final speedMph = (speedMps ?? 0) * 2.237;
    double targetZoom;
    if (speedMph < 15) {
      targetZoom = 18.0;
    } else if (speedMph < 35) {
      targetZoom = _defaultNavZoom;
    } else if (speedMph < 65) {
      targetZoom = 16.0;
    } else {
      targetZoom = 15.0;
    }

    // ── 3. Turn proximity override (zoom IN near turns) ──
    final feetToTurn = navState.remainingStepDistance;
    if (feetToTurn != null && feetToTurn < 500) {
      targetZoom = max(targetZoom, 18.0);
    }

    // ── 4. Destination proximity override ──
    final distMi = navState.etaDistance;
    if (distMi != null && distMi < 0.2) {
      targetZoom = max(targetZoom, 19.0);
    }

    // ── 5. Smooth zoom interpolation ──
    _smoothedZoom += (targetZoom - _smoothedZoom) * 0.25;

    // ── 6. Throttle — only animate if meaningful change ──
    final movedEnough = _lastCameraPos == null ||
        (heroPos.latitude - _lastCameraPos!.latitude).abs() > 0.00001 ||
        (heroPos.longitude - _lastCameraPos!.longitude).abs() > 0.00001;
    final rotatedEnough =
        _lastCameraBearing == null || (bearing - _lastCameraBearing!).abs() > 2;
    final zoomChanged = (targetZoom - _smoothedZoom).abs() > 0.05 ||
        (_lastCameraPos == null);

    if (!movedEnough && !rotatedEnough && !zoomChanged) return;

    _lastCameraPos = heroPos;
    _lastCameraBearing = bearing;

    // ── 7. Camera-ahead offset (hero at ~35 % from bottom) ──
    final rad = bearing * pi / 180;
    final aheadLat = heroPos.latitude + _cameraAheadOffset * cos(rad);
    final aheadLng = heroPos.longitude +
        _cameraAheadOffset * sin(rad) / cos(heroPos.latitude * pi / 180);

    try {
      ctrl.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
        target: LatLng(aheadLat, aheadLng),
        bearing: bearing,
        tilt: _navTilt,
        zoom: _smoothedZoom,
      )));
    } catch (e) {
      debugPrint('[MAP] camera error: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  //  POLYLINE TRIMMING  (only render what's AHEAD of the hero)
  // ════════════════════════════════════════════════════════════════════════

  List<LatLng> _trimPolylineAhead(List<LatLng> pts, LatLng hero) {
    if (pts.length < 2) return pts;
    int bestIdx = 0;
    double bestDist = double.infinity;
    for (int i = 0; i < pts.length - 1; i++) {
      final d = _segDist(hero, pts[i], pts[i + 1]);
      if (d < bestDist) {
        bestDist = d;
        bestIdx = i;
      }
    }
    final proj = _project(hero, pts[bestIdx], pts[bestIdx + 1]);
    return [proj, ...pts.sublist(bestIdx + 1)];
  }

  double _segDist(LatLng p, LatLng a, LatLng b) {
    final dx = b.longitude - a.longitude, dy = b.latitude - a.latitude;
    if (dx == 0 && dy == 0) return _mDist(p, a);
    var t = ((p.longitude - a.longitude) * dx + (p.latitude - a.latitude) * dy) /
        (dx * dx + dy * dy);
    t = t.clamp(0.0, 1.0);
    return _mDist(p, LatLng(a.latitude + t * dy, a.longitude + t * dx));
  }

  double _mDist(LatLng a, LatLng b) {
    final dLat = (a.latitude - b.latitude) * 111319.9;
    final dLng =
        (a.longitude - b.longitude) * 111319.9 * cos(a.latitude * pi / 180);
    return sqrt(dLat * dLat + dLng * dLng);
  }

  LatLng _project(LatLng p, LatLng a, LatLng b) {
    final dx = b.longitude - a.longitude, dy = b.latitude - a.latitude;
    if (dx == 0 && dy == 0) return a;
    var t = ((p.longitude - a.longitude) * dx + (p.latitude - a.latitude) * dy) /
        (dx * dx + dy * dy);
    t = t.clamp(0.0, 1.0);
    return LatLng(a.latitude + t * dy, a.longitude + t * dx);
  }

  // ════════════════════════════════════════════════════════════════════════
  //  OVERVIEW-MODE BOUNDS  (before navigation starts)
  // ════════════════════════════════════════════════════════════════════════

  void _fitBounds() {
    final ctrl = _mapController;
    if (ctrl == null || !_mapReady || _currentJob == null || !mounted) return;
    final user = ref.read(currentUserProvider);
    final heroId = user?.heroProfileId ?? '';
    final loc = ref.read(heroProvider(heroId)).currentLocation;
    final hp = loc != null ? LatLng(loc.latitude, loc.longitude) : _fallbackHeroPos;
    if (hp == null) return;
    final cLat = _currentJob!.pickup.location.latitude;
    final cLng = _currentJob!.pickup.location.longitude;
    try {
      ctrl.animateCamera(CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(min(hp.latitude, cLat) - 0.005, min(hp.longitude, cLng) - 0.005),
          northeast: LatLng(max(hp.latitude, cLat) + 0.005, max(hp.longitude, cLng) + 0.005),
        ),
        left: 50, right: 50, top: 80, bottom: 320,
      ));
    } catch (_) {}
  }

  void _fitBoundsToRoute(List<LatLng> pts) {
    final ctrl = _mapController;
    if (ctrl == null || !_mapReady || pts.isEmpty) return;
    double minLat = pts.first.latitude, maxLat = minLat;
    double minLng = pts.first.longitude, maxLng = minLng;
    for (final p in pts) {
      minLat = min(minLat, p.latitude);
      maxLat = max(maxLat, p.latitude);
      minLng = min(minLng, p.longitude);
      maxLng = max(maxLng, p.longitude);
    }
    try {
      ctrl.animateCamera(CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat - 0.003, minLng - 0.003),
          northeast: LatLng(maxLat + 0.003, maxLng + 0.003),
        ),
        left: 50, right: 50, top: 80, bottom: 320,
      ));
    } catch (_) {}
  }

  // ════════════════════════════════════════════════════════════════════════
  //  HELPERS
  // ════════════════════════════════════════════════════════════════════════

  List<LatLng> _decodePolyline(String enc, {int prec = 6}) {
    if (enc.isEmpty) return [];
    try {
      final pts = <LatLng>[];
      int i = 0, lat = 0, lng = 0;
      final f = pow(10, prec).toInt();
      while (i < enc.length) {
        int s = 0, r = 0, b;
        do { b = enc.codeUnitAt(i++) - 63; r |= (b & 0x1f) << s; s += 5; } while (b >= 0x20 && i < enc.length);
        lat += (r & 1) != 0 ? ~(r >> 1) : (r >> 1);
        s = 0; r = 0;
        if (i >= enc.length) break;
        do { b = enc.codeUnitAt(i++) - 63; r |= (b & 0x1f) << s; s += 5; } while (b >= 0x20 && i < enc.length);
        lng += (r & 1) != 0 ? ~(r >> 1) : (r >> 1);
        pts.add(LatLng(lat / f, lng / f));
      }
      return pts;
    } catch (e) {
      debugPrint('[MAP] polyline decode error: $e');
      return [];
    }
  }

  String _fmtDist(double? mi) {
    if (mi == null) return '--';
    return mi < 0.1 ? '${(mi * 5280).round()} ft' : '${mi.toStringAsFixed(1)} mi';
  }

  // ════════════════════════════════════════════════════════════════════════
  //  ACTIONS
  // ════════════════════════════════════════════════════════════════════════

  Future<void> _setStatus(String status, String heroId) async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);
    try {
      await ref.read(heroProvider(heroId).notifier).updateJobStatus(status);
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _completeAndReview(String heroId) async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);
    try {
      await ref.read(heroProvider(heroId).notifier).updateJobStatus('completed');
      if (!mounted) return;
      final job = _currentJob;
      if (job != null) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => HeroReviewScreen(job: job, heroId: heroId)));
      } else {
        Navigator.of(context).popUntil((r) => r.isFirst);
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  void _openChat() => Navigator.push(
      context, MaterialPageRoute(builder: (_) => ChatScreen(jobId: widget.jobId)));

  // ════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final heroId = user?.heroProfileId ?? '';
    final heroState = ref.watch(heroProvider(heroId));
    final nav = ref.watch(navigationProvider(widget.jobId));

    final job = _currentJob ?? heroState.activeJob;
    if (job == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final svc = ServiceTypes.getById(job.serviceType);
    final svcName = svc?.name ?? job.serviceType.replaceAll('_', ' ');
    final addr = job.pickup.address?.formatted ?? 'Address not available';
    final isNav = job.status == JobStatus.enRoute;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncMapOverlays(nav);
    });

    return Scaffold(
      body: Column(
        children: [
          // ── MAP ──
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(child: Container(color: const Color(0xFFE8E8E8))),
                if (!kIsWeb)
                  Positioned.fill(
                    child: MapLibreMap(
                      styleString: _radarMapStyle,
                      initialCameraPosition: CameraPosition(
                        target: LatLng(job.pickup.location.latitude,
                            job.pickup.location.longitude),
                        zoom: 14,
                      ),
                      onMapCreated: (c) => _mapController = c,
                      onStyleLoadedCallback: () {
                        _mapReady = true;
                        _syncMapOverlays(nav);
                        if (!isNav) _fitBounds();
                      },
                      myLocationEnabled: true,
                      tiltGesturesEnabled: true,
                      rotateGesturesEnabled: true,
                    ),
                  ),

                // Turn-by-turn banner (navigation only)
                if (isNav)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 60,
                    left: 16,
                    right: 16,
                    child: _TurnByTurnBanner(
                      step: nav.currentStep,
                      remainingFeet: nav.remainingStepDistance,
                    ),
                  ),

                // Top bar
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 16, right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _CircleBtn(
                        icon: isNav ? Icons.close : Icons.arrow_back,
                        onTap: () => Navigator.pop(context),
                      ),
                      _EtaBadge(minutes: nav.etaMinutes, distance: _fmtDist(nav.etaDistance)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── BOTTOM PANEL ──
          _BottomPanel(
            job: job, serviceName: svcName, address: addr,
            isLoading: _isUpdating,
            onStartNavigation: () async {
              await _setStatus('en_route', heroId);
              if (!mounted) return;
              ref.read(navigationProvider(widget.jobId).notifier).startNavigation();
            },
            onArrived: () => _setStatus('arrived', heroId),
            onStartService: () => _setStatus('in_progress', heroId),
            onComplete: () => _completeAndReview(heroId),
            onCancel: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Cancel Request?'),
                  content: const Text('Are you sure you want to cancel this job?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red))),
                  ],
                ),
              );
              if (ok == true) {
                await _setStatus('cancelled', heroId);
                if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
              }
            },
            onChat: _openChat,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  SUB-WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: Colors.white, shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Icon(icon, color: Colors.black, size: 22),
        ),
      );
}

class _EtaBadge extends StatelessWidget {
  final int? minutes;
  final String distance;
  const _EtaBadge({this.minutes, required this.distance});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(minutes != null ? '$minutes min' : '--',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(distance, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ]),
      );
}

class _TurnByTurnBanner extends StatelessWidget {
  final RouteStep? step;
  final double? remainingFeet;
  const _TurnByTurnBanner({this.step, this.remainingFeet});

  @override
  Widget build(BuildContext context) {
    final instr = step?.instruction ?? 'Navigating to customer';
    final man = step?.maneuver ?? 'depart';
    final ft = remainingFeet ?? step?.distance ?? 0;
    final dist = ft < 5280 ? '${ft.round()} ft' : '${(ft / 5280).toStringAsFixed(1)} mi';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.brandGreen,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        Icon(_icon(man), color: Colors.white, size: 32),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(instr,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(dist, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          ]),
        ),
      ]),
    );
  }

  static IconData _icon(String m) {
    switch (m.toLowerCase()) {
      case 'turn-left': return Icons.turn_left;
      case 'turn-right': return Icons.turn_right;
      case 'slight-left': return Icons.turn_slight_left;
      case 'slight-right': return Icons.turn_slight_right;
      case 'uturn': return Icons.u_turn_left;
      case 'roundabout': return Icons.roundabout_left;
      case 'merge': return Icons.merge;
      case 'arrive': return Icons.flag;
      case 'depart': return Icons.navigation;
      default: return Icons.straight;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
      );
}

// ═══════════════════════════════════════════════════════════════════════════════
//  BOTTOM PANEL
// ═══════════════════════════════════════════════════════════════════════════════

class _BottomPanel extends StatelessWidget {
  final JobModel job;
  final String serviceName, address;
  final bool isLoading;
  final VoidCallback onStartNavigation, onArrived, onStartService, onComplete, onCancel, onChat;

  const _BottomPanel({
    required this.job, required this.serviceName, required this.address,
    required this.isLoading, required this.onStartNavigation, required this.onArrived,
    required this.onStartService, required this.onComplete, required this.onCancel, required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    switch (job.status) {
      case JobStatus.assigned:
        return _shell([
          _header(const _StatusBadge(label: 'Hero Assigned', color: AppTheme.brandGreen), serviceName),
          const SizedBox(height: 10), _addr(address),
          const SizedBox(height: 14), _chat(onChat),
          const SizedBox(height: 10), _primary('Start Navigation', onStartNavigation),
          const SizedBox(height: 8), _cancelLink(onCancel),
        ]);
      case JobStatus.enRoute:
        return _shell([
          Text(serviceName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Navigating to customer', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          const SizedBox(height: 16), _primary('I Have Arrived', onArrived),
        ]);
      case JobStatus.arrived:
        return _shell([
          _header(const _StatusBadge(label: 'Hero Arrived', color: AppTheme.brandGreen), serviceName),
          const SizedBox(height: 10), _addr(address),
          const SizedBox(height: 14), _chat(onChat),
          const SizedBox(height: 10), _primary('Start Service', onStartService),
        ]);
      case JobStatus.inProgress:
        return _shell([
          _header(const _StatusBadge(label: 'In Progress', color: AppTheme.brandGreen), serviceName),
          const SizedBox(height: 10), _addr(address),
          const SizedBox(height: 14), _chat(onChat),
          const SizedBox(height: 10), _primary('Complete Job', onComplete),
        ]);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _shell(List<Widget> c) => Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 34),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, -4))],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: c),
      );

  Widget _header(_StatusBadge badge, String title) => Row(children: [
        badge, const Spacer(),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ]);

  Widget _addr(String a) => Row(children: [
        Container(width: 12, height: 12, decoration: const BoxDecoration(color: Color(0xFFE53935), shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Expanded(child: Text(a, style: const TextStyle(fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis)),
      ]);

  Widget _chat(VoidCallback fn) => SizedBox(
        width: double.infinity, height: 48,
        child: OutlinedButton.icon(
          onPressed: fn, icon: const Icon(Icons.chat_bubble_outline, size: 18), label: const Text('Chat'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.brandGreen,
            side: const BorderSide(color: AppTheme.brandGreen, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );

  Widget _primary(String label, VoidCallback fn) => SizedBox(
        width: double.infinity, height: 52,
        child: ElevatedButton(
          onPressed: isLoading ? null : fn,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.brandGreen, foregroundColor: Colors.white,
            disabledBackgroundColor: AppTheme.brandGreen.withOpacity(0.6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          child: isLoading
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
              : Text(label),
        ),
      );

  Widget _cancelLink(VoidCallback fn) => TextButton(
        onPressed: fn,
        child: const Text('Cancel Request', style: TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.w500)),
      );
}
