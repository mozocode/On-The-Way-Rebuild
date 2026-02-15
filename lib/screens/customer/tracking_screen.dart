import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../providers/tracking_provider.dart';
import '../../providers/job_provider.dart';
import '../../models/job_model.dart';
import '../../widgets/map/hero_marker.dart';
import '../../widgets/job/eta_card.dart';
import '../../widgets/job/hero_info_card.dart';
import '../../utils/polyline_decoder.dart';

class CustomerTrackingScreen extends ConsumerStatefulWidget {
  final String jobId;

  const CustomerTrackingScreen({super.key, required this.jobId});

  @override
  ConsumerState<CustomerTrackingScreen> createState() => _CustomerTrackingScreenState();
}

class _CustomerTrackingScreenState extends ConsumerState<CustomerTrackingScreen> {
  GoogleMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    final trackingState = ref.watch(trackingProvider(widget.jobId));
    final jobAsync = ref.watch(jobStreamProvider(widget.jobId));

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(40.7128, -74.0060),
              zoom: 15,
            ),
            onMapCreated: (c) => _mapController = c,
            markers: _buildMarkers(trackingState),
            polylines: _buildPolylines(trackingState),
            myLocationEnabled: true,
            zoomControlsEnabled: false,
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: ETACard(
              minutes: trackingState.etaMinutes,
              distance: trackingState.etaDistance,
              isLoading: trackingState.isLoading,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: jobAsync.when(
              data: (job) => job?.hero != null
                  ? HeroInfoCard(
                      hero: job!.hero!,
                      onChat: () => context.push('/chat/${job.id}'),
                      onCall: () {},
                    )
                  : const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Set<Marker> _buildMarkers(TrackingState state) {
    if (state.displayLocation == null) return {};
    return {
      Marker(
        markerId: const MarkerId('hero'),
        position: LatLng(state.displayLocation!.latitude, state.displayLocation!.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        rotation: state.displayLocation!.heading ?? 0,
      ),
    };
  }

  Set<Polyline> _buildPolylines(TrackingState state) {
    if (state.routePolyline == null) return {};
    final coordinates = PolylineDecoder.decode(state.routePolyline!);
    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: coordinates,
        color: const Color(0xFFDC143C),
        width: 5,
      ),
    };
  }
}
