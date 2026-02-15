import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/hero_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../models/job_model.dart';
import '../../models/location_model.dart';
import '../../widgets/navigation/navigation_header.dart';
import '../../widgets/navigation/bottom_action_bar.dart';
import '../../utils/polyline_decoder.dart';

class HeroNavigationScreen extends ConsumerStatefulWidget {
  final String jobId;

  const HeroNavigationScreen({super.key, required this.jobId});

  @override
  ConsumerState<HeroNavigationScreen> createState() => _HeroNavigationScreenState();
}

class _HeroNavigationScreenState extends ConsumerState<HeroNavigationScreen> {
  GoogleMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final heroId = user?.heroProfileId ?? '';
    final heroState = ref.watch(heroProvider(heroId));
    final navState = ref.watch(navigationProvider(widget.jobId));

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: heroState.currentLocation != null
                  ? LatLng(heroState.currentLocation!.latitude, heroState.currentLocation!.longitude)
                  : const LatLng(40.7128, -74.0060),
              zoom: 17,
            ),
            onMapCreated: (c) => _mapController = c,
            markers: _buildMarkers(heroState, navState),
            polylines: _buildPolylines(navState),
            myLocationEnabled: false,
            zoomControlsEnabled: false,
          ),
          SafeArea(
            child: Column(
              children: [
                if (navState.currentStep != null)
                  NavigationHeader(
                    step: navState.currentStep!,
                    destinationAddress: _getDestinationAddress(heroState.activeJob),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
                          ),
                          child: const Icon(Icons.close, color: Colors.black),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: Column(
                          children: [
                            Text(navState.etaMinutes != null ? '${navState.etaMinutes} min' : '--', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text(navState.etaDistance != null ? '${navState.etaDistance!.toStringAsFixed(1)} mi' : '--', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BottomActionBar(
              job: heroState.activeJob,
              onArrived: () => _handleArrived(context, heroId),
              onStartService: () => ref.read(heroProvider(heroId).notifier).updateJobStatus('in_progress'),
              onCompleteService: () => ref.read(heroProvider(heroId).notifier).updateJobStatus('completed'),
            ),
          ),
        ],
      ),
    );
  }

  Set<Marker> _buildMarkers(HeroState heroState, NavigationState navState) {
    final markers = <Marker>{};
    if (heroState.currentLocation != null) {
      markers.add(Marker(
        markerId: const MarkerId('hero'),
        position: LatLng(heroState.currentLocation!.latitude, heroState.currentLocation!.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        rotation: heroState.currentLocation!.heading ?? 0,
      ));
    }
    final dest = _getDestination(heroState.activeJob);
    if (dest != null) {
      markers.add(Marker(
        markerId: const MarkerId('destination'),
        position: LatLng(dest.latitude, dest.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ));
    }
    return markers;
  }

  Set<Polyline> _buildPolylines(NavigationState navState) {
    if (navState.routePolyline == null) return {};
    final coordinates = PolylineDecoder.decode(navState.routePolyline!);
    return {
      Polyline(polylineId: const PolylineId('route'), points: coordinates, color: const Color(0xFFDC143C), width: 5),
    };
  }

  LocationModel? _getDestination(JobModel? job) {
    if (job == null) return null;
    if (job.status == JobStatus.enRoute || job.status == JobStatus.assigned) return job.pickup.location;
    return job.destination?.location ?? job.pickup.location;
  }

  String? _getDestinationAddress(JobModel? job) {
    if (job == null) return null;
    if (job.status == JobStatus.enRoute || job.status == JobStatus.assigned) return job.pickup.address?.formatted;
    return job.destination?.address?.formatted ?? job.pickup.address?.formatted;
  }

  void _handleArrived(BuildContext context, String heroId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color(0xFF4CAF50),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, color: Colors.white, size: 48),
            const SizedBox(height: 16),
            const Text('Thank you for being a Hero!', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text('The customer has been notified of your arrival.', style: TextStyle(color: Colors.white70, fontSize: 14), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ref.read(heroProvider(heroId).notifier).updateJobStatus('arrived');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF4CAF50),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("Let's Go!", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
