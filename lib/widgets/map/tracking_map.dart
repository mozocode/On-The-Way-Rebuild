import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/location_model.dart';
import '../../utils/polyline_decoder.dart';

class TrackingMap extends StatefulWidget {
  final LocationModel? heroLocation;
  final LocationModel? customerLocation;
  final String? routePolyline;
  final double initialZoom;

  const TrackingMap({
    super.key,
    this.heroLocation,
    this.customerLocation,
    this.routePolyline,
    this.initialZoom = 15,
  });

  @override
  State<TrackingMap> createState() => _TrackingMapState();
}

class _TrackingMapState extends State<TrackingMap> {
  GoogleMapController? _mapController;

  @override
  void didUpdateWidget(covariant TrackingMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.heroLocation != null &&
        widget.heroLocation != oldWidget.heroLocation) {
      _animateToHero();
    }
  }

  void _animateToHero() {
    if (_mapController == null || widget.heroLocation == null) return;
    _mapController!.animateCamera(
      CameraUpdate.newLatLng(
        LatLng(
          widget.heroLocation!.latitude,
          widget.heroLocation!.longitude,
        ),
      ),
    );
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};

    if (widget.heroLocation != null) {
      markers.add(Marker(
        markerId: const MarkerId('hero'),
        position: LatLng(
          widget.heroLocation!.latitude,
          widget.heroLocation!.longitude,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        rotation: widget.heroLocation!.heading ?? 0,
        anchor: const Offset(0.5, 0.5),
        flat: true,
      ));
    }

    if (widget.customerLocation != null) {
      markers.add(Marker(
        markerId: const MarkerId('customer'),
        position: LatLng(
          widget.customerLocation!.latitude,
          widget.customerLocation!.longitude,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ));
    }

    return markers;
  }

  Set<Polyline> _buildPolylines() {
    if (widget.routePolyline == null || widget.routePolyline!.isEmpty) {
      return {};
    }

    final coordinates = PolylineDecoder.decode(widget.routePolyline!);
    return {
      Polyline(
        polylineId: const PolylineId('route_shadow'),
        points: coordinates,
        color: const Color(0xFF8B0000),
        width: 8,
      ),
      Polyline(
        polylineId: const PolylineId('route'),
        points: coordinates,
        color: const Color(0xFFDC143C),
        width: 5,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final initialTarget = widget.heroLocation != null
        ? LatLng(
            widget.heroLocation!.latitude, widget.heroLocation!.longitude)
        : const LatLng(40.7128, -74.0060);

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: initialTarget,
        zoom: widget.initialZoom,
      ),
      onMapCreated: (controller) => _mapController = controller,
      markers: _buildMarkers(),
      polylines: _buildPolylines(),
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      rotateGesturesEnabled: false,
    );
  }
}
