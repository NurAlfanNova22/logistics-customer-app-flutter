import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../app_theme.dart';
import 'order_detail_screen.dart';

class OrderStatusScreen extends StatefulWidget {
  final int initialTabIndex;
  const OrderStatusScreen({super.key, this.initialTabIndex = 0});

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen> {
  List<dynamic> _allOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getPesanan();
      if (mounted) {
        setState(() {
          _allOrders = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> _filterOrders(String type) {
    if (type == 'Semua') return _allOrders;
    
    return _allOrders.where((p) {
      final status = p['status']?.toString().toUpperCase();
      final statusPengiriman = p['status_pengiriman']?.toString().toUpperCase();

      if (type == 'Sopir Mengambil') {
        return (status == 'MENUNGGU' || status == 'PROSES' || status == 'DIPROSES');
      } else if (type == 'Dikirim') {
        return statusPengiriman == 'DALAM PERJALANAN';
      } else if (type == 'Selesai') {
        return status == 'SELESAI';
      } else if (type == 'Penilaian') {
        return status == 'SELESAI';
      }
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: widget.initialTabIndex,
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pesanan Saya'),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'Semua'),
              Tab(text: 'Sopir Mengambil'),
              Tab(text: 'Dikirim'),
              Tab(text: 'Selesai'),
              Tab(text: 'Penilaian'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : TabBarView(
                children: [
                  _OrderListTab(orders: _filterOrders('Semua'), onRefresh: _loadData),
                  _OrderListTab(orders: _filterOrders('Sopir Mengambil'), onRefresh: _loadData),
                  _OrderListTab(orders: _filterOrders('Dikirim'), onRefresh: _loadData),
                  _OrderListTab(orders: _filterOrders('Selesai'), onRefresh: _loadData),
                  _OrderListTab(orders: _filterOrders('Penilaian'), onRefresh: _loadData),
                ],
              ),
      ),
    );
  }
}

class _OrderListTab extends StatelessWidget {
  final List<dynamic> orders;
  final Future<void> Function() onRefresh;

  const _OrderListTab({required this.orders, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_rounded, size: 56, color: context.textMutedColor),
            const SizedBox(height: 12),
            Text('Tidak ada pesanan', style: TextStyle(color: context.textSecondaryColor)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final p = orders[index];
          return OrderCard(
            pesanan: p,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderDetailScreen(pesanan: p),
                ),
              ).then((_) => onRefresh());
            },
          );
        },
      ),
    );
  }
}

// Global OrderCard to be shared
class OrderCard extends StatefulWidget {
  final Map<String, dynamic> pesanan;
  final VoidCallback onTap;

  const OrderCard({super.key, required this.pesanan, required this.onTap});

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
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
                  _statusBadge(statusText),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.receipt_outlined, size: 13, color: context.textMutedColor),
                  const SizedBox(width: 4),
                  Text(
                    p['resi'] ?? '-',
                    style: TextStyle(fontSize: 12, color: context.textMutedColor),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Divider(color: context.borderColor, height: 1),
              const SizedBox(height: 8),
              _infoRow(Icons.location_on_outlined, 'Tujuan', p['alamat_tujuan'] ?? '-', context),
              const SizedBox(height: 4),
              _infoRow(Icons.inventory_2_outlined, 'Barang', '${p['jenis_barang'] ?? '-'} • ${p['berat'] ?? 0} kg', context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, BuildContext context) {
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
            style: TextStyle(fontSize: 12, color: context.textSecondaryColor, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(String? status) {
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
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
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
        style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 11),
      ),
    );
  }
}
