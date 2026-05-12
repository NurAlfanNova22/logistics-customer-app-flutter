import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../app_theme.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool _isLoading = true;
  List<dynamic> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    final data = await ApiService.getNotifications();
    if (mounted) {
      setState(() {
        _notifications = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(int id, int index) async {
    if (_notifications[index]['is_read'] == true) return;

    final success = await ApiService.markNotificationAsRead(id);
    if (success && mounted) {
      setState(() {
        _notifications[index]['is_read'] = true;
      });
    }
  }

  Future<void> _markAllAsRead() async {
    final success = await ApiService.markAllNotificationsAsRead();
    if (success && mounted) {
      await _fetchNotifications();
    }
  }

  String _formatDateTime(String dateTime) {
    try {
      final dt = DateTime.parse(dateTime).toLocal();
      final now = DateTime.now();
      
      if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
        return DateFormat('HH:mm').format(dt);
      }
      return DateFormat('dd MMM, HH:mm').format(dt);
    } catch (e) {
      return '';
    }
  }

  IconData _getIcon(String? type) {
    switch (type) {
      case 'order_created':
        return Icons.note_add_rounded;
      case 'order_shipped':
        return Icons.local_shipping_rounded;
      case 'order_arrived':
        return Icons.location_on_rounded;
      case 'payment_success':
        return Icons.account_balance_wallet_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getColor(String? type) {
    switch (type) {
      case 'order_created':
        return Colors.blue;
      case 'order_shipped':
        return Colors.orange;
      case 'order_arrived':
        return Colors.green;
      case 'payment_success':
        return Colors.teal;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Notifikasi', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded),
            tooltip: 'Tandai semua dibaca',
            onPressed: _markAllAsRead,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _fetchNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final item = _notifications[index] as Map<String, dynamic>;
                      final bool isRead = item['is_read'] == true;
                      final String? type = item['type']?.toString();

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: isRead ? Colors.white : AppColors.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isRead ? Colors.grey.withOpacity(0.1) : AppColors.primary.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _getColor(type).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(_getIcon(type), color: _getColor(type), size: 24),
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item['title']?.toString() ?? 'Notifikasi',
                                  style: TextStyle(
                                    fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                                    fontSize: 14,
                                    color: isRead ? Colors.black87 : Colors.black,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatDateTime(item['created_at']?.toString() ?? ''),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              item['body']?.toString() ?? '',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                                height: 1.3,
                              ),
                            ),
                          ),
                          onTap: () => _markAsRead(int.tryParse(item['id']?.toString() ?? '0') ?? 0, index),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notifications_none_rounded, size: 64, color: Colors.grey[400]),
          ),
          const SizedBox(height: 20),
          Text(
            'Belum ada notifikasi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Semua pemberitahuan tentang pesanan Anda\nakan muncul di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
