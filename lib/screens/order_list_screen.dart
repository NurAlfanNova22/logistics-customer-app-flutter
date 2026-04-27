import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'order_detail_screen.dart';
import 'order_status_screen.dart';
import '../app_theme.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  List<dynamic> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = await ApiService.getPesanan();
      if (mounted) {
        setState(() {
          _orders = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Menghitung jumlah berdasarkan status dari data _orders
    int sopirMengambil = 0;
    int dikirim = 0;
    int penilaian = 0;

    for (var p in _orders) {
      final status = p['status']?.toString().toUpperCase();
      final statusPengiriman = p['status_pengiriman']?.toString().toUpperCase();

      if (status == 'MENUNGGU' || status == 'PROSES' || status == 'DIPROSES') {
        sopirMengambil++;
      } else if (statusPengiriman == 'DALAM PERJALANAN') {
        dikirim++;
      } else if (status == 'SELESAI') {
        penilaian++;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Pesanan')),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  _OrderSummaryHeader(
                    sopirMengambil: sopirMengambil,
                    dikirim: dikirim,
                    penilaian: penilaian,
                    onItemTap: (index) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderStatusScreen(initialTabIndex: index),
                        ),
                      ).then((_) => _loadData());
                    },
                  ),
                  const SizedBox(height: 24),
                  if (_orders.isEmpty)
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 40),
                          Icon(Icons.inbox_rounded,
                              size: 56, color: context.textMutedColor),
                          const SizedBox(height: 12),
                          Text('Belum ada pesanan',
                              style: TextStyle(color: context.textSecondaryColor)),
                        ],
                      ),
                    )
                  else
                    ...List.generate(_orders.length, (index) {
                      final p = _orders[index];
                      return _OrderCard(
                        pesanan: p,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OrderDetailScreen(pesanan: p),
                            ),
                          ).then((_) => _loadData());
                        },
                      );
                    }),
                ],
              ),
            ),
    );
  }
}

class _OrderSummaryHeader extends StatelessWidget {
  final int sopirMengambil;
  final int dikirim;
  final int penilaian;
  final Function(int) onItemTap;

  const _OrderSummaryHeader({
    required this.sopirMengambil,
    required this.dikirim,
    required this.penilaian,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pesanan Saya',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.textPrimaryColor,
              ),
            ),
            GestureDetector(
              onTap: () => onItemTap(0),
              child: Row(
                children: [
                  Text(
                    'Lihat Riwayat Pesanan',
                    style: TextStyle(
                      fontSize: 13,
                      color: context.textSecondaryColor,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: context.textMutedColor,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatusItem(
              icon: Icons.inventory_2_outlined,
              label: 'Sopir mengambil\nbarang',
              count: sopirMengambil,
              onTap: () => onItemTap(1),
            ),
            _StatusItem(
              icon: Icons.local_shipping_outlined,
              label: 'Dikirim',
              count: dikirim,
              onTap: () => onItemTap(2),
            ),
            _StatusItem(
              icon: Icons.stars_outlined,
              label: 'Penilaian',
              count: penilaian,
              onTap: () => onItemTap(4),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Divider(color: context.borderColor, height: 1),
      ],
    );
  }
}

class _StatusItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final VoidCallback onTap;

  const _StatusItem({
    required this.icon,
    required this.label,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                icon,
                size: 32,
                color: context.textPrimaryColor.withOpacity(0.85),
              ),
              if (count > 0)
                Positioned(
                  right: -6,
                  top: -6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE53935),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      count.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: context.textPrimaryColor,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatefulWidget {
  final Map<String, dynamic> pesanan;
  final VoidCallback onTap;

  const _OrderCard({required this.pesanan, required this.onTap});

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.pesanan;
    final mainStatus = (p['status'] ?? '').toString().toUpperCase();
    final statusText = (mainStatus == 'SELESAI' || mainStatus == 'DIBATALKAN')
        ? mainStatus
        : (p['status_pengiriman'] ?? p['status']);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(


          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _pressed ? context.surface2Color : context.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      p['nama_pabrik'] ?? '-',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: context.textPrimaryColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _statusBadge(statusText, context),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.receipt_outlined,
                      size: 13, color: context.textMutedColor),
                  const SizedBox(width: 4),
                  Text(
                    p['resi'] ?? '-',
                    style: TextStyle(
                        fontSize: 12, color: context.textMutedColor),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Divider(color: context.borderColor, height: 1),
              const SizedBox(height: 8),
              _infoRow(
                  Icons.location_on_outlined, 'Tujuan',
                  p['alamat_tujuan'] ?? '-', context),
              const SizedBox(height: 4),
              _infoRow(
                  Icons.inventory_2_outlined, 'Barang',
                  '${p['jenis_barang'] ?? '-'} • ${p['berat'] ?? 0} kg',
                  context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(
      IconData icon, String label, String value, BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: context.textMutedColor),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 12, color: context.textMutedColor),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
                fontSize: 12,
                color: context.textSecondaryColor,
                fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(String? status, BuildContext context) {
    final s = status?.toLowerCase() ?? '';
    Color bgColor;
    Color textColor;
    String text;

    switch (s) {
      case 'dalam perjalanan':
      case 'menunggu pickup':
        bgColor = AppColors.infoSurface;
        textColor = AppColors.info;
        text = 'AKTIF';
        break;
      case 'pesanan telah dikirim':
        bgColor = AppColors.successSurface;
        textColor = AppColors.success;
        text = 'DIKIRIM';
        break;
      case 'selesai':
        bgColor = AppColors.successSurface;
        textColor = AppColors.success;
        text = 'SELESAI';
        break;
      case 'dibatalkan':
        bgColor = context.isDark ? Colors.red.withOpacity(0.15) : Colors.red.shade50;
        textColor = context.isDark ? Colors.red.shade300 : Colors.red.shade700;
        text = 'DIBATALKAN';
        break;
      default:
        bgColor = AppColors.primarySurface;
        textColor = AppColors.primary;
        text = 'MENUNGGU';
    }

    return Container(


      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}
