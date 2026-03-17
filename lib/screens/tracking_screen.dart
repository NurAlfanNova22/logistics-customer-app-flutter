import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import '../app_theme.dart';

class TrackingScreen extends StatefulWidget {
  final String? resi;
  const TrackingScreen({super.key, this.resi});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  GoogleMapController? _controller;
  final Set<Marker> _markers = {};
  
  // Default position (Jakarta) if no location data yet
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(-6.200000, 106.816666),
    zoom: 14.4746,
  );

  @override
  void initState() {
    super.initState();
    if (widget.resi != null) {
      _listenToLocation();
    }
  }

  void _listenToLocation() {
    FirebaseDatabase.instance
        .ref('tracking/${widget.resi}')
        .onValue
        .listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        final lat = (data['lat'] as num).toDouble();
        final lng = (data['lng'] as num).toDouble();
        final pos = LatLng(lat, lng);

        setState(() {
          _markers.clear();
          _markers.add(
            Marker(
              markerId: const MarkerId('driver'),
              position: pos,
              infoWindow: InfoWindow(
                title: 'Lokasi Driver',
                snippet: 'Pesanan: ${widget.resi}',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
            ),
          );
        });

        _controller?.animateCamera(CameraUpdate.newLatLng(pos));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.resi != null ? 'Lacak ${widget.resi}' : 'Tracking'),
      ),
      body: widget.resi == null
          ? _buildEmptyState(context)
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: _initialPosition,
                  onMapCreated: (controller) => _controller = controller,
                  markers: _markers,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                ),
                if (_markers.isEmpty)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('Menunggu lokasi driver...'),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_off_rounded, size: 64, color: context.textMutedColor),
          const SizedBox(height: 16),
          Text(
            'Pilih pesanan untuk dilacak',
            style: TextStyle(color: context.textSecondaryColor),
          ),
        ],
      ),
    );
  }
}
