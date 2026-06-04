import 'dart:math';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../app_theme.dart';
import 'map_picker_screen.dart';
import '../services/notification_service.dart';

class OrderFormScreen extends StatefulWidget {
  final Function(int)? onOrderSuccess;
  const OrderFormScreen({super.key, this.onOrderSuccess});

  @override
  State<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends State<OrderFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final namaPabrikController = TextEditingController();
  final alamatAsalController = TextEditingController();
  final alamatTujuanController = TextEditingController();
  final jenisBarangController = TextEditingController();
  final beratController = TextEditingController();

  bool isLoading = false;
  String? _alamatAsalRaw;
  String? _alamatTujuanRaw;

  @override
  void initState() {
    super.initState();
    alamatAsalController.addListener(() {
      if (alamatAsalController.text != (_alamatAsalRaw?.split(' @').first ?? '')) {
        _alamatAsalRaw = null;
      }
      setState(() {});
    });
    alamatTujuanController.addListener(() {
      if (alamatTujuanController.text != (_alamatTujuanRaw?.split(' @').first ?? '')) {
        _alamatTujuanRaw = null;
      }
      setState(() {});
    });
    beratController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    namaPabrikController.dispose();
    alamatAsalController.dispose();
    alamatTujuanController.dispose();
    jenisBarangController.dispose();
    beratController.dispose();
    super.dispose();
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 - cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) *
        (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  Map<String, double>? _getCoordinates(String? rawAddress) {
    if (rawAddress == null) return null;
    final parts = rawAddress.split(' @');
    if (parts.length < 2) return null;
    final coords = parts[1].split(',');
    if (coords.length < 2) return null;
    final lat = double.tryParse(coords[0]);
    final lng = double.tryParse(coords[1]);
    if (lat != null && lng != null) {
      return {'lat': lat, 'lng': lng};
    }
    return null;
  }

  int get calculatedTotalBiaya {
    double tonase = double.tryParse(beratController.text.replaceAll(',', '.')) ?? 0.0;
    if (tonase <= 0 || alamatTujuanController.text.isEmpty) return 0;
    
    int rate = 150000; // Harga default per Ton jika jarak tidak terdeteksi
    final origin = _getCoordinates(_alamatAsalRaw);
    final dest = _getCoordinates(_alamatTujuanRaw);

    if (origin != null && dest != null) {
      double distance = _calculateDistance(origin['lat']!, origin['lng']!, dest['lat']!, dest['lng']!);
      
      // Hitung rate per ton berdasarkan jarak (semakin jauh semakin mahal)
      if (distance <= 10) {
        rate = 85000;      // Sangat dekat (dalam kota)
      } else if (distance <= 20) {
        rate = 95000;      // Dekat
      } else if (distance <= 35) {
        rate = 110000;     // Blitar - Tulungagung Kota / Kediri (sekitar 30 km) -> 110.000 / ton (8 Ton = 880.000)
      } else if (distance <= 50) {
        rate = 118750;     // Blitar - Bandung Tulungagung / Trenggalek (sekitar 43 km) -> 118.750 / ton (8 Ton = 950.000)
      } else if (distance <= 75) {
        rate = 130000;     // Agak jauh
      } else if (distance <= 100) {
        rate = 145000;     // Jauh
      } else if (distance <= 150) {
        rate = 180000;     // Sangat Jauh (Surabaya ke Blitar)
      } else if (distance <= 250) {
        rate = 250000;     // Antar kota jauh / perbatasan provinsi (Jawa Tengah ke Blitar)
      } else {
        // Untuk jarak di atas 250 km, gunakan tarif per km tambahan agar adil
        // Tarif dasar 250.000 + (jarak - 250 km) * 1.500 per km
        double extraDistance = distance - 250;
        rate = 250000 + (extraDistance * 1500).toInt();
      }
    } else {
      // Fallback jika salah satu alamat tidak memiliki koordinat (diinput manual tanpa peta picker)
      String asal = alamatAsalController.text.toLowerCase();
      String tujuan = alamatTujuanController.text.toLowerCase();
      
      // Tentukan kecocokan wilayah (Asal & Tujuan)
      bool hasJateng = asal.contains('jawa tengah') || asal.contains('jateng') || asal.contains('solo') || asal.contains('semarang') ||
                       tujuan.contains('jawa tengah') || tujuan.contains('jateng') || tujuan.contains('solo') || tujuan.contains('semarang');
                       
      bool hasSurabaya = asal.contains('surabaya') || tujuan.contains('surabaya');
      bool hasKediri = asal.contains('kediri') || tujuan.contains('kediri') || asal.contains('pare') || tujuan.contains('pare');
      bool hasTulungagung = asal.contains('tulungagung') || tujuan.contains('tulungagung');
      bool hasBlitar = asal.contains('blitar') || tujuan.contains('blitar');
      bool hasBandungTug = (asal.contains('bandung') && (asal.contains('tulungagung') || asal.contains('ta'))) ||
                           (tujuan.contains('bandung') && (tujuan.contains('tulungagung') || tujuan.contains('ta')));

      if (hasJateng) {
        rate = 280000; // Antar provinsi Jawa Tengah
      } else if (hasSurabaya) {
        rate = 180000; // Surabaya - Blitar / sekitarnya
      } else if (hasBandungTug) {
        rate = 118750; // Bandung Tulungagung
      } else if (hasKediri || hasTulungagung) {
        rate = 110000; // Kediri / Tulungagung ke Blitar
      } else if (hasBlitar) {
        rate = 85000;  // Sama-sama Blitar (lokal)
      } else if (tujuan.contains('bandung')) {
        rate = 350000; // Bandung Jawa Barat
      } else {
        rate = 150000; // Default
      }
    }
    return (tonase * rate).toInt();
  }

  String _formatCurrency(int amount) {
    final stringAmount = amount.toString();
    String result = '';
    int count = 0;
    for (int i = stringAmount.length - 1; i >= 0; i--) {
      if (count == 3) {
        result = '.$result';
        count = 0;
      }
      result = stringAmount[i] + result;
      count++;
    }
    return 'Rp $result';
  }

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    double tonase = double.tryParse(beratController.text.replaceAll(',', '.')) ?? 0.0;
    int beratKg = (tonase * 1000).toInt();

    final result = await ApiService.kirimPesanan({
      'nama_pabrik': namaPabrikController.text,
      'alamat_asal': _alamatAsalRaw ?? alamatAsalController.text,
      'alamat_tujuan': _alamatTujuanRaw ?? alamatTujuanController.text,
      'jenis_barang': jenisBarangController.text,
      'berat': beratKg,
      'total_biaya': calculatedTotalBiaya,
    });

    setState(() => isLoading = false);

    if (result != null) {
      final resi = result['resi'];
      if (!mounted) return;
      
      // Munculkan notifikasi instan di HP
      NotificationService.showNotification(
        title: 'Pesanan Berhasil Dibuat ✅',
        body: 'Pesanan Anda (Resi: ${result['resi']}) sedang menunggu konfirmasi.',
        payload: 'order_created',
      );
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Pesanan Berhasil'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.successSurface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: AppColors.success, size: 30),
              ),
              const SizedBox(height: 14),
              Text('Pesanan berhasil dibuat',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    const Text('Nomor Resi',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(
                      resi ?? '-',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Gunakan nomor resi ini untuk melacak pengiriman',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onOrderSuccess?.call(0); // Navigate back to Dashboard (Index 0)
                },
                child: const Text('Tutup'),
              ),
            ),
          ],
        ),
      );
      _formKey.currentState!.reset();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengirim pesanan')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Pesanan')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            _SectionCard(
              title: 'Informasi Pabrik',
              icon: Icons.factory_outlined,
              children: [
                _input(
                  controller: namaPabrikController,
                  label: 'Nama Pabrik',
                  icon: Icons.business_outlined,
                  hint: 'Contoh: PT. Sumber Makmur Jaya',
                ),
              ],
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: 'Alamat Pengiriman',
              icon: Icons.place_outlined,
              children: [
                _input(
                  controller: alamatAsalController,
                  label: 'Alamat Asal (Pengambilan)',
                  icon: Icons.my_location_rounded,
                  hint: 'Contoh: Jl. Diponegoro No. 12, Kec. Sananwetan, Kota Blitar (Patokan: Sebelah utara Indomaret)',
                  maxLines: 3,
                  isAddress: true,
                ),
                const SizedBox(height: 14),
                _input(
                  controller: alamatTujuanController,
                  label: 'Alamat Tujuan (Pengiriman)',
                  icon: Icons.location_on_outlined,
                  hint: 'Contoh: Gudang Indah Cargo, Kec. Bandung, Kab. Tulungagung',
                  maxLines: 3,
                  isAddress: true,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: 'Detail Barang',
              icon: Icons.inventory_2_outlined,
              children: [
                _input(
                  controller: jenisBarangController,
                  label: 'Jenis Barang',
                  icon: Icons.category_outlined,
                  hint: 'Contoh: Pupuk Organik, Beras, Semen',
                ),
                const SizedBox(height: 10),
                _input(
                  controller: beratController,
                  label: 'Berat (Ton)',
                  icon: Icons.scale_outlined,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  hint: 'Contoh: 1.5 (Gunakan koma/titik)',
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Berat wajib diisi';
                    final cleanedInput = v.replaceAll(',', '.');
                    if (double.tryParse(cleanedInput) == null) return 'Masukkan angka';
                    if (double.parse(cleanedInput) <= 0) return 'Berat tidak valid';
                    return null;
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          border:
              Border(top: BorderSide(color: context.borderColor, width: 0.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (calculatedTotalBiaya > 0)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Estimasi Total Biaya:', 
                        style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primaryDark)),
                    Text(_formatCurrency(calculatedTotalBiaya), 
                        style: const TextStyle(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isLoading ? null : submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.primary.withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 4,
                  shadowColor: AppColors.primary.withOpacity(0.4),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text('Kirim Pesanan',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    String? hint,
    bool isAddress = false,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      validator: validator ??
          (v) => v == null || v.isEmpty ? '$label wajib diisi' : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 15),
        floatingLabelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13, height: 1.4),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        alignLabelWithHint: maxLines > 1,
        prefixIcon: Padding(
          padding: EdgeInsets.only(bottom: maxLines > 1 ? 40.0 : 0),
          child: Icon(icon, size: 22),
        ),
        suffixIcon: isAddress 
            ? IconButton(
                icon: const Icon(Icons.map_rounded, color: AppColors.primary),
                tooltip: 'Pilih dari Peta',
                onPressed: () async {
                   final result = await Navigator.push(
                     context,
                     MaterialPageRoute(builder: (context) => const MapPickerScreen()),
                   );
                    if (result != null && result is String) {
                      if (label.contains('Asal')) {
                        _alamatAsalRaw = result;
                      } else {
                        _alamatTujuanRaw = result;
                      }
                      controller.text = result.split(' @').first;
                    }
                },
              )
            : null,
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Icon(icon, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}