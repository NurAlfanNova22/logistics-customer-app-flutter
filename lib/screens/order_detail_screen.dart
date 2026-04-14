import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../app_theme.dart';
import 'tracking_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

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

  @override
  void initState() {
    super.initState();
    _currentPesanan = Map<String, dynamic>.from(widget.pesanan);
    _fetchTrackingProgress();
  }

  Future<void> _fetchTrackingProgress() async {
    final data = await ApiService.trackingResi(_currentPesanan['resi']);
    if (mounted && data != null) {
      setState(() {
        _trackingData = data;
        // Update shipping status from tracking data if available
        if (data.containsKey('status_pengiriman')) {
          _currentPesanan['status_pengiriman'] = data['status_pengiriman'];
        }
      });
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

  Future<void> _selesaikanPesanan() async {
    setState(() => isLoading = true);
    try {
      final success =
          await ApiService.selesaikanPesanan(_currentPesanan['id']);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pesanan berhasil diselesaikan')));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal menyelesaikan pesanan')));
        setState(() => isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() => isLoading = false);
    }
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

  @override
  Widget build(BuildContext context) {
    final status = (_currentPesanan['status'] ?? '').toString().toLowerCase();
    final statusPengiriman = (_currentPesanan['status_pengiriman'] ?? status).toString().toLowerCase();
    
    // Mapping status label Bahasa Indonesia
    String displayStatus = statusPengiriman;
    if (status == 'menunggu konfirmasi') displayStatus = 'menunggu konfirmasi';
    if (statusPengiriman == 'menunggu pickup') displayStatus = 'sopir mengambil barang';
    
    final canBeCompleted = status != 'selesai' && statusPengiriman == 'pesanan telah dikirim';
    final isTrackingAvailable = statusPengiriman == 'dalam perjalanan';
    final canBeCancelled = status != 'dibatalkan' && status != 'selesai' && statusPengiriman != 'dalam perjalanan' && statusPengiriman != 'pesanan telah dikirim';

    final statusPembayaran = (_currentPesanan['status_pembayaran'] ?? 'BELUM DIBAYAR').toString().toUpperCase();
    final totalBiaya = _currentPesanan['total_biaya'] ?? 0;
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
            _SectionCard(
              title: 'Informasi Pabrik',
              icon: Icons.factory_outlined,
              children: [
                _infoRow('Resi', _currentPesanan['resi'], context, highlight: true),
                _infoRow('Nama Pabrik', _currentPesanan['nama_pabrik'], context),
                _infoRow('Alamat Asal', _currentPesanan['alamat_asal'], context),
                _infoRow('Alamat Tujuan', _currentPesanan['alamat_tujuan'], context),
                _infoRow('Status', displayStatus.toUpperCase(), context, highlight: true),
                _infoRow('Tanggal Pesan', DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(_currentPesanan['created_at'].toString())), context),
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
                  if (statusPembayaran != 'SUDAH DIBAYAR' && totalBiaya > 0 && status != 'dibatalkan') ...[
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
            if (canBeCompleted)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : _selesaikanPesanan,
                  icon: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_rounded),
                  label: const Text('Pesanan Telah Diterima',
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
              if (canBeCompleted) const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : _batalkanPesanan,
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
