import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import '../../config/radar_config.dart';
import '../../config/theme.dart';
import '../../models/location_model.dart';
import '../../models/service_type_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/hero_provider.dart';
import '../../providers/job_provider.dart';
import '../../models/job_model.dart';
import 'hero_drawer.dart';
import 'hero_map_web.dart' if (dart.library.io) 'hero_map_stub.dart' as hero_map;
import 'hero_active_job_screen.dart';


/// Default map center (e.g. Pittsburgh area). Replace with hero's location when available.
const _defaultMapCenter = LatLng(40.4406, -79.9959);
const _defaultZoom = 12.0;

/// Radar map style URL (Radar.com tiles).
String get _radarMapStyle =>
    'https://api.radar.io/maps/styles/radar-default-v1/?publishableKey=${RadarConfig.publishableKey}';

class HeroHomeScreen extends ConsumerStatefulWidget {
  const HeroHomeScreen({super.key});

  @override
  ConsumerState<HeroHomeScreen> createState() => _HeroHomeScreenState();
}

class _HeroHomeScreenState extends ConsumerState<HeroHomeScreen> {
  MapLibreMapController? _mapController;

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  /// Animate the map to the user's current location (blue dot).
  void _goToMyLocation() async {
    final c = _mapController;
    if (c == null) return;
    try {
      final latLng = await c.requestMyLocationLatLng();
      if (latLng != null) {
        c.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
      }
    } catch (e) {
      print('Could not get user location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final heroId = user?.heroProfileId;

    if (heroId == null) {
      return const Scaffold(
        body: Center(child: Text('Hero profile not found. Link a hero account in profile.')),
      );
    }

    final heroState = ref.watch(heroProvider(heroId));
    final isOnline = heroState.isOnline;

    return Scaffold(
      body: Stack(
        children: [
          // Map: on web use iframe fallback; on iOS/Android use Radar/MapLibre
          if (kIsWeb)
            Positioned.fill(
              child: hero_map.HeroWebMap(
                lat: _defaultMapCenter.latitude,
                lng: _defaultMapCenter.longitude,
                zoom: _defaultZoom,
              ),
            )
          else
            Positioned.fill(
              child: MapLibreMap(
                styleString: _radarMapStyle,
                initialCameraPosition: const CameraPosition(
                  target: _defaultMapCenter,
                  zoom: _defaultZoom,
                ),
                onMapCreated: (c) {
                  _mapController = c;
                  // Center on user location once map is ready
                  Future.delayed(const Duration(milliseconds: 500), _goToMyLocation);
                },
                myLocationEnabled: true,
                tiltGesturesEnabled: false,
                rotateGesturesEnabled: false,
              ),
            ),
          // Overlay UI
          SafeArea(
            child: Column(
              children: [
                // Top row: Offline toggle, Daily earnings, Menu (no Camera)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      const Spacer(),
                      _OfflineToggle(
                        isOnline: isOnline,
                        onChanged: (value) {
                          if (value) {
                            ref.read(heroProvider(heroId).notifier).goOnline();
                          } else {
                            ref.read(heroProvider(heroId).notifier).goOffline();
                          }
                        },
                        isLoading: heroState.isLoading,
                      ),
                      const Spacer(),
                      _DailyEarningsCard(
                        amount: ref.watch(heroDailyEarningsProvider(heroId)).valueOrNull ?? 0.00,
                      ),
                      const Spacer(),
                      _MapOverlayButton(
                        icon: Icons.menu,
                        onPressed: () => HeroDrawer.show(context),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
                const Spacer(),
                // Bottom row: Zoom out, Radar / my location
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
                  child: Row(
                    children: [
                      _MapOverlayButton(
                        icon: Icons.remove,
                        onPressed: () {
                          final c = _mapController;
                          if (c != null) {
                            c.moveCamera(CameraUpdate.zoomOut());
                          }
                        },
                      ),
                      const Spacer(),
                      _MapOverlayButton(
                        icon: Icons.my_location,
                        iconColor: AppTheme.brandGreen,
                        onPressed: _goToMyLocation,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Active job card (if any) - show above bottom buttons
          if (heroState.activeJob != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 80,
              child: _ActiveJobCard(job: heroState.activeJob!, heroId: heroId),
            ),
          // Incoming job card -- shows when hero is online and a pending job exists
          if (isOnline && heroState.activeJob == null)
            _IncomingJobBanner(
              heroId: heroId,
              heroLocation: heroState.currentLocation,
            ),
        ],
      ),
    );
  }

}

class _OfflineToggle extends StatelessWidget {
  final bool isOnline;
  final ValueChanged<bool> onChanged;
  final bool isLoading;

  const _OfflineToggle({
    required this.isOnline,
    required this.onChanged,
    required this.isLoading,
  });

  static const double _chipHeight = 44.0;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          height: _chipHeight,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isOnline ? 'Online' : 'Offline',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 6),
              if (isLoading)
                const SizedBox(
                  width: 28,
                  height: 18,
                  child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))),
                )
              else
                SizedBox(
                  width: 40,
                  height: 24,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Switch(
                      value: isOnline,
                      onChanged: onChanged,
                      activeColor: Colors.green,
                      activeTrackColor: Colors.green.withOpacity(0.5),
                      inactiveThumbColor: Colors.red,
                      inactiveTrackColor: Colors.red.withOpacity(0.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyEarningsCard extends StatelessWidget {
  final double amount;

  const _DailyEarningsCard({required this.amount});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          height: _OfflineToggle._chipHeight,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '\$${amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'DAILY\nEARNINGS',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapOverlayButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? iconColor;

  const _MapOverlayButton({
    required this.icon,
    required this.onPressed,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.5),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: _OfflineToggle._chipHeight,
          height: _OfflineToggle._chipHeight,
          alignment: Alignment.center,
          child: Icon(icon, color: iconColor ?? Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _ActiveJobCard extends StatelessWidget {
  final JobModel job;
  final String heroId;

  const _ActiveJobCard({required this.job, required this.heroId});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => HeroActiveJobScreen(jobId: job.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.brandGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.directions_car, color: AppTheme.brandGreen, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Active Job', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      job.serviceType.toUpperCase().replaceAll('_', ' '),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      job.pickup.address?.formatted ?? 'Address',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _IncomingJobBanner extends ConsumerStatefulWidget {
  final String heroId;
  final LocationModel? heroLocation;

  const _IncomingJobBanner({
    required this.heroId,
    this.heroLocation,
  });

  @override
  ConsumerState<_IncomingJobBanner> createState() => _IncomingJobBannerState();
}

class _IncomingJobBannerState extends ConsumerState<_IncomingJobBanner> {
  LocationModel? _fallbackLocation;
  final _dismissedJobIds = <String>{};

  @override
  void initState() {
    super.initState();
    if (widget.heroLocation == null) _fetchFallbackLocation();
  }

  Future<void> _fetchFallbackLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      if (mounted) {
        setState(() {
          _fallbackLocation = LocationModel(
            latitude: pos.latitude,
            longitude: pos.longitude,
          );
        });
      }
    } catch (_) {}
  }

  Future<void> _acceptAndNavigate(JobModel job) async {
    try {
      final success = await ref
          .read(heroProvider(widget.heroId).notifier)
          .acceptJob(job.id);
      if (!mounted) return;
      if (success) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HeroActiveJobScreen(jobId: job.id),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to accept job. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error accepting job: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingJobs = ref.watch(pendingJobsProvider);
    final loc = widget.heroLocation ?? _fallbackLocation;

    return pendingJobs.when(
      data: (jobs) {
        final visible =
            jobs.where((j) => !_dismissedJobIds.contains(j.id)).toList();
        if (visible.isEmpty) return const SizedBox.shrink();
        final job = visible.first;
        return Positioned(
          left: 0,
          right: 0,
          bottom: 70,
          child: _IncomingJobCard(
            job: job,
            heroId: widget.heroId,
            heroLocation: loc,
            onDecline: () {
              setState(() => _dismissedJobIds.add(job.id));
              ref.read(heroProvider(widget.heroId).notifier).declineJob(job.id);
            },
            onAccept: () => _acceptAndNavigate(job),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _IncomingJobCard extends StatefulWidget {
  final JobModel job;
  final String heroId;
  final LocationModel? heroLocation;
  final VoidCallback? onDecline;
  final VoidCallback? onAccept;

  const _IncomingJobCard({
    required this.job,
    required this.heroId,
    this.heroLocation,
    this.onDecline,
    this.onAccept,
  });

  @override
  State<_IncomingJobCard> createState() => _IncomingJobCardState();
}

class _IncomingJobCardState extends State<_IncomingJobCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _timerController;

  static const _dark = Color(0xFF1A1A2E);
  static const _cardDark = Color(0xFF222236);
  static const _dimText = Color(0xFF8E8E9E);
  static const _accentBlue = Color(0xFF3B82F6);

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..forward();

    _timerController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onDecline?.call();
      }
    });
  }

  @override
  void dispose() {
    _timerController.dispose();
    super.dispose();
  }

  double? _distanceMiles() {
    if (widget.heroLocation == null) return null;
    final lat1 = widget.heroLocation!.latitude;
    final lon1 = widget.heroLocation!.longitude;
    final lat2 = widget.job.pickup.location.latitude;
    final lon2 = widget.job.pickup.location.longitude;
    const R = 3958.8;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _toRad(double deg) => deg * pi / 180;

  int? _estimateMinutes(double? miles) {
    if (miles == null) return null;
    return (miles * 3).round().clamp(1, 999);
  }

  String _shortAddress(JobAddress? addr) {
    if (addr == null) return 'Unknown';
    if (addr.street != null && addr.city != null) {
      return '${addr.street}, ${addr.city}';
    }
    return addr.formatted;
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final service = ServiceTypes.getById(job.serviceType);
    final serviceName = service?.name ?? job.serviceType.replaceAll('_', ' ');
    final pickupDist = _distanceMiles();
    final pickupEta = job.tracking.etaMinutes ?? _estimateMinutes(pickupDist);
    final payout = '\$${(job.pricing.total / 100).toStringAsFixed(2)}';
    final hasDestination = job.destination != null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: _dark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Countdown timer bar
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: AnimatedBuilder(
              animation: _timerController,
              builder: (context, child) {
                return LinearProgressIndicator(
                  value: 1 - _timerController.value,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation(
                    _timerController.value > 0.3
                        ? _accentBlue
                        : Colors.orange,
                  ),
                  minHeight: 5,
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 12, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _cardDark,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_serviceIcon(job.serviceType), color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        serviceName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (job.serviceSubType != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.brandGreen.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      job.serviceSubType!.replaceAll('_', ' '),
                      style: TextStyle(
                        color: AppTheme.brandGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: widget.onDecline,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white54, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Text(
              payout,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                const Text(
                  '5.0',
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 10),
                Icon(Icons.verified, color: _accentBlue, size: 15),
                const SizedBox(width: 4),
                Text(
                  'Verified',
                  style: TextStyle(color: _accentBlue, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                AnimatedBuilder(
                  animation: _timerController,
                  builder: (context, child) {
                    final remaining = (
                      (1 - _timerController.value) * 20
                    ).ceil();
                    return Text(
                      '${remaining}s',
                      style: TextStyle(
                        color: _timerController.value > 0.3
                            ? Colors.white38
                            : Colors.orange,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        if (hasDestination)
                          Container(
                            width: 2,
                            height: 30,
                            color: Colors.white24,
                          ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pickupEta != null && pickupDist != null
                                ? '$pickupEta min (${pickupDist.toStringAsFixed(1)} mi)'
                                : pickupDist != null
                                    ? '${pickupDist.toStringAsFixed(1)} mi away'
                                    : 'Nearby',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _shortAddress(job.pickup.address),
                            style: const TextStyle(color: _dimText, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (hasDestination) ...[
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _shortAddress(job.destination!.address),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              job.destination!.address?.city ?? '',
                              style: const TextStyle(color: _dimText, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          if (job.pickup.notes != null && job.pickup.notes!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: _dimText, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      job.pickup.notes!,
                      style: const TextStyle(color: _dimText, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 18),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: widget.onAccept,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Accept',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _serviceIcon(String id) {
    switch (id) {
      case 'flat_tire':
        return Icons.circle_outlined;
      case 'dead_battery':
        return Icons.battery_0_bar;
      case 'lockout':
        return Icons.key;
      case 'fuel_delivery':
        return Icons.local_gas_station;
      case 'towing':
        return Icons.local_shipping;
      case 'transportation':
        return Icons.directions_car;
      default:
        return Icons.build;
    }
  }
}

