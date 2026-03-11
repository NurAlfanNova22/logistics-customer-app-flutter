import 'package:flutter/material.dart';

class OrderDetailScreen extends StatelessWidget {
  final Map<String, dynamic> pesanan;

  const OrderDetailScreen({super.key, required this.pesanan});

  @override
  Widget build(BuildContext context) {
    final status = (pesanan['status'] ?? '').toString().toLowerCase();

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        title: const Text('Detail Pesanan'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionCard(
            title: "Informasi Pabrik",
            children: [
              _infoRow("Resi", pesanan['resi']),
              _infoRow("Nama Pabrik", pesanan['nama_pabrik']),
              _infoRow("Alamat Asal", pesanan['alamat_asal']),
              _infoRow("Alamat Tujuan", pesanan['alamat_tujuan']),
            ],
          ),

          const SizedBox(height: 16),

          _sectionCard(
            title: "Detail Barang",
            children: [
              _infoRow("Jenis Barang", pesanan['jenis_barang']),
              _infoRow("Berat", "${pesanan['berat']} kg"),
            ],
          ),

          const SizedBox(height: 16),

          _sectionCard(
            title: "Status Pengiriman",
            children: [
              _statusTimeline(status),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value?.toString() ?? '-',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusTimeline(String status) {
    int currentStep = 0;

    if (status == 'menunggu pickup') {
      currentStep = 0;
    } else if (status == 'dalam perjalanan') {
      currentStep = 1;
    } else if (status == 'selesai') {
      currentStep = 2;
    }

    return Column(
      children: [
        _timelineItem("Driver mengambil barang", currentStep >= 0),
        _timelineItem("Dalam perjalanan", currentStep >= 1),
        _timelineItem("Barang sampai", currentStep >= 2),
      ],
    );
  }

  Widget _timelineItem(String title, bool isActive) {
    return Row(
      children: [
        Icon(
          isActive ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isActive ? Colors.green : Colors.grey,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isActive ? Colors.green : Colors.grey,
          ),
        ),
      ],
    );
  }
}
