import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'order_detail_screen.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  late Future<List<dynamic>> futurePesanan;

  @override
  void initState() {
    super.initState();
    futurePesanan = ApiService.getPesanan();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        title: const Text('Daftar Pesanan'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: futurePesanan,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Belum ada pesanan'),
            );
          }

          final pesananList = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pesananList.length,
            itemBuilder: (context, index) {
              final p = pesananList[index];

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderDetailScreen(pesanan: p),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            p['nama_pabrik'] ?? '-',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          _statusBadge(p['status_pengiriman'] ?? p['status']),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Resi: ${p['resi'] ?? '-'}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),

                      Text(
                        'Tujuan: ${p['alamat_tujuan'] ?? '-'}',
                        style: const TextStyle(color: Color(0xFF6B7280)),
                      ),
                      const SizedBox(height: 4),

                      Text(
                        'Barang: ${p['jenis_barang'] ?? '-'}',
                        style: const TextStyle(color: Color(0xFF6B7280)),
                      ),
                      const SizedBox(height: 4),

                      Text(
                        'Berat: ${p['berat'] ?? 0} kg',
                        style: const TextStyle(color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _statusBadge(String? status) {
    final s = status?.toLowerCase() ?? '';

    Color bgColor;
    Color textColor;
    String text;

    switch (s) {
      case 'aktif':
        bgColor = Colors.blue.withOpacity(0.1);
        textColor = Colors.blue;
        text = 'AKTIF';
        break;

      case 'selesai':
        bgColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green;
        text = 'SELESAI';
        break;

      case 'menunggu':
      default:
        bgColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange;
        text = 'MENUNGGU';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
