import 'package:flutter/material.dart';
import '../services/api_service.dart';

class OrderFormScreen extends StatefulWidget {
  const OrderFormScreen({super.key});

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

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final result = await ApiService.kirimPesanan({
      'nama_pabrik': namaPabrikController.text,
      'alamat_asal': alamatAsalController.text,
      'alamat_tujuan': alamatTujuanController.text,
      'jenis_barang': jenisBarangController.text,
      'berat': int.parse(beratController.text),
    });

    setState(() => isLoading = false);

    if (result != null) {
      final resi = result['resi'];

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text("Pesanan Berhasil"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 48,
                ),
                const SizedBox(height: 12),
                const Text(
                  "Pesanan berhasil dibuat",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Nomor Resi",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        resi ?? "-",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Gunakan nomor resi ini untuk melacak pengiriman",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Tutup"),
              )
            ],
          );
        },
      );

      _formKey.currentState!.reset();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengirim pesanan')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        title: const Text('Buat Pesanan'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            _sectionTitle('Informasi Pabrik'),
            _input(
              controller: namaPabrikController,
              label: 'Nama Pabrik',
            ),

            const SizedBox(height: 20),

            _sectionTitle('Alamat Pengiriman'),
            _input(
              controller: alamatAsalController,
              label: 'Alamat Asal',
              maxLines: 2,
            ),
            _input(
              controller: alamatTujuanController,
              label: 'Alamat Tujuan',
              maxLines: 2,
            ),

            const SizedBox(height: 20),

            _sectionTitle('Detail Barang'),
            _input(
              controller: jenisBarangController,
              label: 'Jenis Barang',
            ),
            _input(
              controller: beratController,
              label: 'Berat (kg)',
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return 'Berat wajib diisi';
                }
                if (int.tryParse(v) == null) {
                  return 'Berat harus berupa angka';
                }
                if (int.parse(v) <= 0) {
                  return 'Berat tidak valid';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color(0xFFE5E7EB)),
          ),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: isLoading ? null : submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1F2937),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF1F2937),
                    ),
                  )
                : const Text(
                    'Kirim Pesanan',
                    style: TextStyle(fontSize: 16),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF6B7280),
        ),
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator ??
            (v) => v == null || v.isEmpty ? '$label wajib diisi' : null,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1F2937)),
          ),
        ),
      ),
    );
  }
}