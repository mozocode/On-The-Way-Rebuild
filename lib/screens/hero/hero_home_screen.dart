import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import '../../config/radar_config.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/hero_provider.dart';
import '../../models/job_model.dart';
import '../../widgets/common/custom_button.dart';
import 'hero_drawer.dart';
import 'hero_map_web.dart' if (dart.library.io) 'hero_map_stub.dart' as hero_map;

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
      drawer: HeroDrawer(),
      body: Stack(
        children: [
          // Map: on web use iframe fallback (MapLibre often fails to load); on mobile use Radar/MapLibre
          if (kIsWeb)
            hero_map.HeroWebMap(
              lat: _defaultMapCenter.latitude,
              lng: _defaultMapCenter.longitude,
              zoom: _defaultZoom,
            )
          else
            MapLibreMap(
              styleString: _radarMapStyle,
              initialCameraPosition: const CameraPosition(
                target: _defaultMapCenter,
                zoom: _defaultZoom,
              ),
              onMapCreated: (c) => _mapController = c,
              myLocationEnabled: true,
              tiltGesturesEnabled: false,
              rotateGesturesEnabled: false,
            ),
          // Overlay UI
          SafeArea(
            child: Column(
              children: [
                // Top row: Offline toggle, Daily earnings, Menu (no Camera)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      const SizedBox(width: 12),
                      _DailyEarningsCard(amount: 0.00),
                      const Spacer(),
                      _MapOverlayButton(
                        icon: Icons.menu,
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
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
                        onPressed: () {
                          final c = _mapController;
                          if (c != null) {
                            c.moveCamera(CameraUpdate.newLatLngZoom(_defaultMapCenter, 15));
                          }
                        },
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
          // Browse jobs when online and no active job
          if (heroState.isOnline && heroState.activeJob == null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 80,
              child: CustomButton(
                onPressed: () {},
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search),
                    SizedBox(width: 8),
                    Text('Browse Available Jobs'),
                  ],
                ),
              ),
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

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Offline',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 10),
              if (isLoading)
                const SizedBox(
                  width: 36,
                  height: 22,
                  child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))),
                )
              else
                Switch(
                  value: isOnline,
                  onChanged: onChanged,
                  activeColor: Colors.red,
                  activeTrackColor: Colors.red.withOpacity(0.5),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '\$${amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'DAILY EARNINGS',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
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
          width: 48,
          height: 48,
          alignment: Alignment.center,
          child: Icon(icon, color: iconColor ?? Colors.white, size: 24),
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
        onTap: () {},
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
