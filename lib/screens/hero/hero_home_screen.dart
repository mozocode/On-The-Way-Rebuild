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
            onDecline: () => setState(() => _dismissedJobIds.add(job.id)),
            onAccept: () => _acceptAndNavigate(job),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _IncomingJobCard extends StatelessWidget {
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

  double? _distanceMiles() {
    if (heroLocation == null) return null;
    final lat1 = heroLocation!.latitude;
    final lon1 = heroLocation!.longitude;
    final lat2 = job.pickup.location.latitude;
    final lon2 = job.pickup.location.longitude;
    const R = 3958.8; // Earth radius in miles
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _toRad(double deg) => deg * pi / 180;

  @override
  Widget build(BuildContext context) {
    final service = ServiceTypes.getById(job.serviceType);
    final serviceName = service?.name ?? job.serviceType.replaceAll('_', ' ');
    final distance = _distanceMiles();
    final distanceText = distance != null
        ? '${distance.toStringAsFixed(1)} mi away'
        : 'Nearby';
    final payout = '\$${(job.pricing.total / 100).toStringAsFixed(2)}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Text(
              'Incoming Requests',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.grey[900],
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        serviceName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            distanceText,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            payout,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.brandGreen,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Decline button
                Material(
                  color: Colors.red.withOpacity(0.08),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onDecline,
                    child: const SizedBox(
                      width: 44,
                      height: 44,
                      child: Icon(Icons.close, color: Colors.red, size: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Accept button
                Material(
                  color: AppTheme.brandGreen,
                  borderRadius: BorderRadius.circular(22),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: onAccept,
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      alignment: Alignment.center,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check, color: Colors.white, size: 18),
                          SizedBox(width: 4),
                          Text(
                            'Accept',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

