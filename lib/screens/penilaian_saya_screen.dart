import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../app_theme.dart';
import 'order_detail_screen.dart';

class PenilaianSayaScreen extends StatefulWidget {
  const PenilaianSayaScreen({super.key});

  @override
  State<PenilaianSayaScreen> createState() => _PenilaianSayaScreenState();
}

class _PenilaianSayaScreenState extends State<PenilaianSayaScreen> {
  List<dynamic> _unratedOrders = [];
  List<dynamic> _ratedOrders = [];
  Map<String, int> _savedStars = {};
  Map<String, String> _savedReviews = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final allOrders = await ApiService.getPesanan();
      final prefs = await SharedPreferences.getInstance();

      final completedOrders = allOrders.where((p) {
        final status = (p['status'] ?? '').toString().toUpperCase();
        return status == 'SELESAI';
      }).toList();

      List<dynamic> unrated = [];
      List<dynamic> rated = [];
      Map<String, int> starsMap = {};
      Map<String, String> reviewsMap = {};

      for (var p in completedOrders) {
        final userId = p['user_id'];
        final orderId = p['id'];
        if (userId != null && orderId != null) {
          final List<String> ratedList = prefs.getStringList('rated_orders_$userId') ?? [];
          final isRated = ratedList.contains(orderId.toString());
          if (isRated) {
            rated.add(p);
            starsMap[orderId.toString()] = prefs.getInt('rating_stars_${userId}_$orderId') ?? 5;
            reviewsMap[orderId.toString()] = prefs.getString('rating_review_${userId}_$orderId') ?? '';
          } else {
            unrated.add(p);
          }
        } else {
          unrated.add(p);
        }
      }

      if (mounted) {
        setState(() {
          _unratedOrders = unrated;
          _ratedOrders = rated;
          _savedStars = starsMap;
          _savedReviews = reviewsMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveRating(int orderId, int userId, int stars, String review) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> ratedList = prefs.getStringList('rated_orders_$userId') ?? [];
    if (!ratedList.contains(orderId.toString())) {
      ratedList.add(orderId.toString());
      await prefs.setStringList('rated_orders_$userId', ratedList);
    }
    await prefs.setInt('rating_stars_${userId}_$orderId', stars);
    await prefs.setString('rating_review_${userId}_$orderId', review);
    _loadData();
  }

  void _showRatingDialog(BuildContext context, Map<String, dynamic> pesanan) {
    int selectedStars = 5;
    final reviewController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: context.surfaceColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.rate_review_rounded, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text('Beri Penilaian', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Bagaimana pelayanan pengiriman untuk pesanan resi ${pesanan['resi']}?',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: context.textSecondaryColor),
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
                    _saveRating(
                      pesanan['id'],
                      pesanan['user_id'],
                      selectedStars,
                      reviewController.text,
                    );
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(
                        content: Text('Terima kasih! Penilaian Anda berhasil disimpan.'),
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

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Penilaian Saya'),
          bottom: const TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'Belum Dinilai'),
              Tab(text: 'Sudah Dinilai'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : TabBarView(
                children: [
                  _buildOrderList(_unratedOrders, isRatedTab: false),
                  _buildOrderList(_ratedOrders, isRatedTab: true),
                ],
              ),
      ),
    );
  }

  Widget _buildOrderList(List<dynamic> orders, {required bool isRatedTab}) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isRatedTab ? Icons.rate_review_outlined : Icons.playlist_add_check_rounded,
              size: 56,
              color: context.textMutedColor,
            ),
            const SizedBox(height: 12),
            Text(
              isRatedTab ? 'Belum ada pesanan yang dinilai' : 'Semua pesanan selesai telah dinilai!',
              style: TextStyle(color: context.textSecondaryColor),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final p = orders[index];
          final orderIdStr = p['id'].toString();

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.surfaceColor,
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
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: context.textPrimaryColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isRatedTab ? AppColors.successSurface : AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isRatedTab ? 'SUDAH DINILAI' : 'BELUM DINILAI',
                        style: TextStyle(
                          color: isRatedTab ? AppColors.success : AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
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
                _infoRow(Icons.location_on_outlined, 'Tujuan', p['alamat_tujuan'] ?? '-'),
                const SizedBox(height: 4),
                _infoRow(Icons.inventory_2_outlined, 'Barang', '${p['jenis_barang'] ?? '-'} • ${p['berat'] ?? 0} kg'),
                
                if (isRatedTab) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.successSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.success.withOpacity(0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Penilaian Anda:',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.success),
                            ),
                            Row(
                              children: List.generate(5, (starIdx) {
                                final stars = _savedStars[orderIdStr] ?? 5;
                                return Icon(
                                  Icons.star_rounded,
                                  size: 16,
                                  color: starIdx < stars ? Colors.amber : Colors.grey.shade300,
                                );
                              }),
                            ),
                          ],
                        ),
                        if ((_savedReviews[orderIdStr] ?? '').trim().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            '"${_savedReviews[orderIdStr]}"',
                            style: TextStyle(
                              fontSize: 13,
                              color: context.textPrimaryColor,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OrderDetailScreen(pesanan: p),
                            ),
                          ).then((_) => _loadData());
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: context.borderColor),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        child: Text(
                          'Detail',
                          style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _showRatingDialog(context, p),
                        icon: const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                        label: const Text('Beri Penilaian', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
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
}
