import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../app_theme.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late GoogleMapController _mapController;
  
  LatLng _currentCenter = const LatLng(-8.0983, 112.1609);
  bool _isLoading = false;
  bool _isSearching = false;
  
  List<dynamic> _searchResults = [];
  Timer? _debounce;
  final TextEditingController _searchController = TextEditingController();

  void _onCameraMove(CameraPosition position) {
    _currentCenter = position.target;
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      _fetchAutocomplete(query);
    });
  }

  Future<void> _fetchAutocomplete(String query) async {
    if (query.trim().isEmpty) {
      if (mounted) setState(() => _searchResults = []);
      return;
    }
    
    setState(() => _isSearching = true);
    try {
      final response = await http.get(Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=$query&format=json&countrycodes=id&addressdetails=1&limit=5'),
          headers: {
            'User-Agent': 'LancarEkspedisiApp/1.0',
          });
          
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _searchResults = data;
          });
        }
      }
    } catch (e) {
      print(e);
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _cariLokasiSubmit(String query) async {
     FocusManager.instance.primaryFocus?.unfocus();
     if (_searchResults.isNotEmpty) {
        final loc = _searchResults.first;
        final lat = double.parse(loc['lat']);
        final lon = double.parse(loc['lon']);
        _mapController.animateCamera(CameraUpdate.newLatLngZoom(LatLng(lat, lon), 16));
        setState(() => _searchResults = []);
     }
  }

  Future<void> _konfirmasiLokasi() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/reverse?lat=${_currentCenter.latitude}&lon=${_currentCenter.longitude}&format=json'),
        headers: {
          'User-Agent': 'LancarEkspedisiApp/1.0',
        }
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['display_name'] != null && data['display_name'].toString().isNotEmpty) {
           if (mounted) Navigator.pop(context, data['display_name']);
           return;
        }
      }
      throw Exception("Gagal mendapatkan nama lokasi");
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Terjadi kendala saat membaca titik karena server sibuk. Mohon klik sekali lagi!')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Lokasi dari Peta'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentCenter,
              zoom: 15,
            ),
            onMapCreated: (controller) => _mapController = controller,
            onCameraMove: _onCameraMove,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
          
          // Fixed Pin in the center
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 40.0), // Adjust to make the pin point to the center
              child: Icon(
                Icons.location_on,
                size: 50,
                color: Colors.red,
              ),
            ),
          ),
          
          // Target focus indicator (optional, makes it look cool)
          Center(
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
              ),
            ),
          ),
          
          // Kotak Pencarian Pintar (Search Bar)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 3)),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari Kota, Kecamatan, atau Jalan...',
                  hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  suffixIcon: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20, 
                            height: 20, 
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)
                          ),
                        )
                      : (_searchController.text.isNotEmpty ? IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                             _searchController.clear();
                             setState(() => _searchResults = []);
                          },
                        ) : null),
                ),
                textInputAction: TextInputAction.search,
                onChanged: _onSearchChanged,
                onSubmitted: _cariLokasiSubmit,
              ),
            ),
          ),

          // Autocomplete Dropdown List
          if (_searchResults.isNotEmpty)
            Positioned(
              top: 76,
              left: 16,
              right: 16,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 250),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: _searchResults.length,
                  separatorBuilder: (c, i) => const Divider(height: 1, color: Colors.black12),
                  itemBuilder: (context, index) {
                    final item = _searchResults[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: const Icon(Icons.location_on, color: Colors.red),
                      title: Text(item['display_name'] ?? '', style: const TextStyle(fontSize: 13, height: 1.3)),
                      onTap: () {
                         final lat = double.parse(item['lat']);
                         final lon = double.parse(item['lon']);
                         
                         FocusManager.instance.primaryFocus?.unfocus();
                         setState(() {
                            _searchResults = [];
                            _searchController.text = item['name'] ?? item['display_name'] ?? '';
                         });
                         
                         _mapController.animateCamera(CameraUpdate.newLatLngZoom(LatLng(lat, lon), 16));
                      },
                    );
                  },
                ),
              ),
            ),
          
          // Confirm Button
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  )
                ]
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Geser peta untuk menentukan titik biru. Pastikan titiknya akurat.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _konfirmasiLokasi,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading 
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Pilih Titik Ini', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
