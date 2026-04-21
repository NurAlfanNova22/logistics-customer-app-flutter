import 'dart:ui' as ui;
import 'dart:typed_data';
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
  BitmapDescriptor? _truckIcon;
  bool _isFirstLocation = true;
  
  // Default position (Jakarta) if no location data yet
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(-6.200000, 106.816666),
    zoom: 14.4746,
  );

  @override
  void initState() {
    super.initState();
    _loadTruckIcon().then((_) {
      if (widget.resi != null) {
        _listenToLocation();
      }
    });
  }

  Future<void> _loadTruckIcon() async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = AppColors.primary;
    
    // Gambar lingkaran background icon
    canvas.drawCircle(const Offset(30.0, 30.0), 30.0, paint);
    canvas.drawCircle(const Offset(30.0, 30.0), 28.0, Paint()..color = Colors.white);
    canvas.drawCircle(const Offset(30.0, 30.0), 25.0, paint);

    TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(Icons.local_shipping_rounded.codePoint),
      style: TextStyle(
        fontSize: 34.0,
        fontFamily: Icons.local_shipping_rounded.fontFamily,
        package: Icons.local_shipping_rounded.fontPackage,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(13.0, 13.0));

    final ui.Image image = await pictureRecorder.endRecording().toImage(60, 60);
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    
    if (mounted) {
      setState(() {
        _truckIcon = BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
      });
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
              icon: _truckIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
            ),
          );
        });

        if (_isFirstLocation) {
          _isFirstLocation = false;
          _controller?.animateCamera(CameraUpdate.newLatLngZoom(pos, 15));
        } else {
          _controller?.animateCamera(CameraUpdate.newLatLng(pos));
        }
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
