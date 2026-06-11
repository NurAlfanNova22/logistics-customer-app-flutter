import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../app_theme.dart';
import 'tracking_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrderDetailScreen extends StatefulWidget {
  final Map<String, dynamic> pesanan;
  const OrderDetailScreen({super.key, required this.pesanan});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  bool isLoading = false;
  late Map<String, dynamic> _currentPesanan;
  Map<String, dynamic>? _trackingData;
  bool _isAlreadyRated = false;
  int _savedStars = 5;
  String _savedReview = '';

  @override
  void initState() {
    super.initState();
    _currentPesanan = Map<String, dynamic>.from(widget.pesanan);
    _fetchTrackingProgress();
    _checkIfRated();
  }

  Future<void> _fetchTrackingProgress() async {
    final data = await ApiService.trackingResi(_currentPesanan['resi']);
    if (mounted && data != null) {
      setState(() {
        _trackingData = data;
        // Update seluruh data pesanan terbaru (termasuk link bayar)
        if (data.containsKey('pesanan')) {
          _currentPesanan = Map<String, dynamic>.from(data['pesanan']);
        }
      });
    }
  }
  Future<void> _checkIfRated() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = _currentPesanan['user_id'];
    final orderId = _currentPesanan['id'];
    if (userId != null && orderId != null) {
      final List<String> ratedList = prefs.getStringList('rated_orders_$userId') ?? [];
      final isRated = ratedList.contains(orderId.toString());
      int stars = 5;
      String review = '';
      if (isRated) {
        stars = prefs.getInt('rating_stars_${userId}_$orderId') ?? 5;
        review = prefs.getString('rating_review_${userId}_$orderId') ?? '';
      }
      if (mounted) {
        setState(() {
          _isAlreadyRated = isRated;
          _savedStars = stars;
          _savedReview = review;
        });
      }
    }
  }

  Future<void> _saveAsRated(int stars, String review) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = _currentPesanan['user_id'];
    final orderId = _currentPesanan['id'];
    if (userId != null && orderId != null) {
      final List<String> ratedList = prefs.getStringList('rated_orders_$userId') ?? [];
      if (!ratedList.contains(orderId.toString())) {
        ratedList.add(orderId.toString());
        await prefs.setStringList('rated_orders_$userId', ratedList);
      }
      await prefs.setInt('rating_stars_${userId}_$orderId', stars);
      await prefs.setString('rating_review_${userId}_$orderId', review);
      if (mounted) {
        setState(() {
          _isAlreadyRated = true;
          _savedStars = stars;
          _savedReview = review;
        });
      }
    }
  }
  Future<void> _bayarSekarang() async {
    final urlStr = _currentPesanan['payment_url'];
    if (urlStr != null && urlStr.isNotEmpty) {
      final url = Uri.parse(urlStr);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak dapat membuka link pembayaran.')));
      }
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link pembayaran belum tersedia dari sisi server.')));
    }
  }

  void _showRatingDialog() {
    int selectedStars = 5;
    final reviewController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Center(
                child: Text(
                  'Beri Penilaian',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Bagaimana pengalaman pengiriman Anda?',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starValue = index + 1;
                      return IconButton(
                        icon: Icon(
                          Icons.star_rounded,
                          size: 36,
                          color: starValue <= selectedStars ? Colors.amber : Colors.grey.shade300,
                        ),
                        onPressed: () {
                          setState(() {
                            selectedStars = starValue;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: reviewController,
                    maxLines: 3,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Tulis ulasan Anda di sini (opsional)...',
                      hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _saveAsRated(selectedStars, reviewController.text);
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(
                        content: Text('Terima kasih! Penilaian Anda berhasil dikirim.'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Kirim', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _batalkanPesanan() async {
    setState(() => isLoading = true);
    try {
      final success = await ApiService.batalkanPesanan(_currentPesanan['id']);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pesanan berhasil dibatalkan')));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pesanan tidak dapat dibatalkan')));
        setState(() => isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() => isLoading = false);
    }
  }

  void _showCancelConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan Pesanan?'),
        content: const Text('Apakah Anda yakin ingin membatalkan pesanan ini? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kembali', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _batalkanPesanan();
            },
            child: const Text('Ya, Batalkan', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = (_currentPesanan['status'] ?? '').toString().toLowerCase();
    final statusPengiriman = (_currentPesanan['status_pengiriman'] ?? status).toString().toLowerCase();
    
    // Mapping status label Bahasa Indonesia
    String displayStatus = statusPengiriman;
    if (status == 'menunggu konfirmasi') displayStatus = 'menunggu konfirmasi';
    if (status == 'ditolak') displayStatus = 'ditolak';
    if (statusPengiriman == 'menunggu pickup') displayStatus = 'sopir mengambil barang';
    
    final statusPembayaran = (_currentPesanan['status_pembayaran'] ?? 'BELUM DIBAYAR').toString().toUpperCase();
    final totalBiaya = _currentPesanan['total_biaya'] ?? 0;

    final isShipped = statusPengiriman == 'pesanan telah dikirim';
    final isPaid = statusPembayaran == 'SUDAH DIBAYAR';
    final isCancelled = status == 'dibatalkan';

    final isCompleted = status == 'selesai';
    final isTrackingAvailable = statusPengiriman == 'dalam perjalanan';
    final canBeCancelled = status != 'dibatalkan' && status != 'ditolak' && status != 'selesai' && statusPengiriman != 'dalam perjalanan' && statusPengiriman != 'pesanan telah dikirim';

    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pesanan'),
        actions: [
          if (isTrackingAvailable)
            TextButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TrackingScreen(resi: _currentPesanan['resi']),
                ),
              ),
              icon: const Icon(Icons.location_on_rounded, size: 18),
              label: const Text('Lacak'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchTrackingProgress,
        color: AppColors.primary,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            if (status == 'ditolak')
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.cancel_rounded, color: Colors.red, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pesanan Ditolak',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _currentPesanan['alasan_penolakan'] ?? 'Tidak ada alasan penolakan yang spesifik.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.red[900],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            _SectionCard(
              title: 'Informasi Pabrik',
              icon: Icons.factory_outlined,
              children: [
                _infoRow('Resi', _currentPesanan['resi'], context, highlight: true),
                _infoRow('Nama Pabrik', _currentPesanan['nama_pabrik'], context),
                _infoRow('Alamat Asal', _currentPesanan['alamat_asal_clean'] ?? _currentPesanan['alamat_asal']?.toString().split(' @').first ?? '-', context),
                _infoRow('Alamat Tujuan', _currentPesanan['alamat_tujuan_clean'] ?? _currentPesanan['alamat_tujuan']?.toString().split(' @').first ?? '-', context),
                _infoRow('Status', displayStatus.toUpperCase(), context, highlight: true),
                _infoRow('Tanggal Pesan', DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(_currentPesanan['created_at'].toString())), context),
                if (_currentPesanan['tanggal_pemesanan'] != null)
                  _infoRow('Tgl Rencana Kirim', DateFormat('dd MMM yyyy').format(DateTime.parse(_currentPesanan['tanggal_pemesanan'].toString())), context),
                if (_currentPesanan['estimasi_datang'] != null && _currentPesanan['estimasi_datang'] != '-')
                  _infoRow('Estimasi Barang Datang', _currentPesanan['estimasi_datang'].toString(), context),
                if (_currentPesanan['tanggal_dikirim'] != null)
                  _infoRow('Tanggal Dikirim', DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(_currentPesanan['tanggal_dikirim'].toString())), context),
                if (_currentPesanan['tanggal_selesai'] != null)
                  _infoRow('Diterima pada', DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(_currentPesanan['tanggal_selesai'].toString())), context),
              ],
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Detail Barang',
              icon: Icons.inventory_2_outlined,
              children: [
                _infoRow('Jenis Barang', _currentPesanan['jenis_barang'], context),
                _infoRow('Berat', '${_currentPesanan['berat']} kg', context),
              ],
            ),
            const SizedBox(height: 12),
            if (totalBiaya > 0)
              _SectionCard(
                title: 'Informasi Tagihan & Pembayaran',
                icon: Icons.payments_outlined,
                children: [
                  _infoRow('Estimasi Biaya', formatter.format(totalBiaya), context, highlight: true),
                  _infoRow('Status', statusPembayaran == 'SUDAH DIBAYAR' ? 'LUNAS ✅' : statusPembayaran, context, highlight: statusPembayaran == 'SUDAH DIBAYAR'),
                  if (!isPaid && totalBiaya > 0 && !isCancelled && isShipped) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _bayarSekarang,
                        icon: const Icon(Icons.payment_rounded, size: 20),
                        label: const Text('BAYAR VIA MIDTRANS', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    )
                  ]
                ],
              ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Riwayat Pengiriman',
              icon: Icons.history_rounded,
              children: [
                if (_trackingData != null)
                  _StatusTimeline(progress: _trackingData!['progress'] as List)
                else
                  const Center(child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )),
              ],
            ),
            const SizedBox(height: 20),
            if (isCompleted)
              _isAlreadyRated
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.successSurface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.success.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.stars_rounded, color: AppColors.success, size: 24),
                              const SizedBox(width: 8),
                              const Text(
                                'Penilaian Anda',
                                style: TextStyle(
                                  color: AppColors.success,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Row(
                                children: List.generate(5, (index) {
                                  return Icon(
                                    Icons.star_rounded,
                                    size: 18,
                                    color: index < _savedStars ? Colors.amber : Colors.grey.shade300,
                                  );
                                }),
                              ),
                            ],
                          ),
                          if (_savedReview.trim().isNotEmpty) ...[
                            const SizedBox(height: 12),
                            const Text(
                              'Ulasan:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _savedReview,
                              style: TextStyle(
                                fontSize: 13,
                                color: context.textPrimaryColor,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
                  : SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _showRatingDialog,
                        icon: const Icon(Icons.star_rounded, color: Colors.amber),
                        label: const Text('Beri Penilaian',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 4,
                          shadowColor: AppColors.primary.withOpacity(0.4),
                        ),
                      ),
                    ),
            
            if (canBeCancelled) ...[
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : _showCancelConfirmation,
                  icon: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.cancel_rounded),
                  label: const Text('Batalkan Pesanan',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 4,
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, dynamic value, BuildContext context,
      {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                  fontSize: 13, color: context.textSecondaryColor),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? '-',
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    highlight ? FontWeight.w700 : FontWeight.w500,
                color: highlight
                    ? AppColors.primary
                    : context.textPrimaryColor,
                letterSpacing: highlight ? 0.5 : 0,
              ),
            ),
          ),
        ],
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
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
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children),
          ),
        ],
      ),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  final List<dynamic> progress;
  const _StatusTimeline({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: progress.asMap().entries.map((e) {
        final i = e.key;
        final step = e.value as Map<String, dynamic>;
        
        final label = step['step'] ?? '-';
        final lokasi = step['lokasi'] ?? '-';
        final waktu = step['waktu'] ?? '-';
        final status = (step['status'] ?? '').toString().toLowerCase();
        
        final isActive = status == 'selesai' || status == 'proses';
        final isCurrent = i == 0; // Newest is at index 0 because of array_reverse in PHP
        final isLast = i == progress.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primary.withOpacity(0.1)
                        : context.surface2Color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isActive ? AppColors.primary : context.borderColor,
                      width: isCurrent ? 2 : 1,
                    ),
                  ),
                  child: Icon(
                    isActive
                        ? (status == 'selesai' ? Icons.check_rounded : Icons.local_shipping_rounded)
                        : Icons.radio_button_unchecked_rounded,
                    size: 14,
                    color: isActive ? AppColors.primary : context.textMutedColor,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 1.5,
                    height: 40,
                    color: isActive ? AppColors.primary.withOpacity(0.3) : context.borderColor,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                              color: isActive ? context.textPrimaryColor : context.textMutedColor,
                            ),
                          ),
                        ),
                        Text(
                          waktu,
                          style: TextStyle(fontSize: 11, color: context.textMutedColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      lokasi,
                      style: TextStyle(
                        fontSize: 12,
                        color: isActive ? context.textSecondaryColor : context.textMutedColor,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    if (status == 'proses')
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Sedang berlangsung',
                          style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500),
                        ),
                      ),
                    SizedBox(height: isLast ? 0 : 24),
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
