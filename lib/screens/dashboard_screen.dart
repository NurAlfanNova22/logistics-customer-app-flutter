import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../app_theme.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int)? onChangeTab;
  const DashboardScreen({super.key, this.onChangeTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late Future<Map<String, dynamic>> futureDashboard;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    futureDashboard = ApiService.getDashboard();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: FutureBuilder<Map<String, dynamic>>(
            future: futureDashboard,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return Center(
                  child: Text(
                    'Gagal memuat dashboard',
                    style: TextStyle(color: context.textMutedColor),
                  ),
                );
              }
              final data = snapshot.data!;
              return _buildContent(context, data);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Map<String, dynamic> data) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selamat datang 👋',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: context.textPrimaryColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pantau dan kelola pengiriman Anda',
                          style: TextStyle(
                            fontSize: 13,
                            color: context.textMutedColor,
                          ),
                        ),
                      ],
                    ),
                    _NotifButton(),
                  ],
                ),

                const SizedBox(height: 28),

                // Stats Grid
                Row(
                  children: [
                    _StatCard(
                      title: 'Total',
                      value: data['total'] ?? 0,
                      icon: Icons.list_alt_rounded,
                      color: context.textPrimaryColor,
                    ),
                    const SizedBox(width: 10),
                    _StatCard(
                      title: 'Dikirim',
                      value: data['dikirim'] ?? 0,
                      icon: Icons.local_shipping_rounded,
                      color: AppColors.info,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _StatCard(
                      title: 'Selesai',
                      value: data['selesai'] ?? 0,
                      icon: Icons.check_circle_outline_rounded,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 10),
                    _StatCard(
                      title: 'Diproses',
                      value: data['diproses'] ?? 0,
                      icon: Icons.schedule_rounded,
                      color: AppColors.primary,
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                Text(
                  'AKSI CEPAT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.4,
                    color: context.textMutedColor,
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _ActionTile(
                icon: Icons.add_box_outlined,
                label: 'Buat Pesanan Baru',
                subtitle: 'Tambah pesanan pengiriman',
                iconColor: AppColors.primary,
                onTap: () => widget.onChangeTab?.call(2),
              ),
              const SizedBox(height: 10),
              _ActionTile(
                icon: Icons.location_on_outlined,
                label: 'Lacak Pesanan',
                subtitle: 'Lihat status pengiriman',
                iconColor: AppColors.info,
                onTap: () => widget.onChangeTab?.call(3),
              ),
              const SizedBox(height: 10),
              _ActionTile(
                icon: Icons.list_alt_outlined,
                label: 'Daftar Pesanan',
                subtitle: 'Lihat semua pesanan Anda',
                iconColor: AppColors.success,
                onTap: () => widget.onChangeTab?.call(1),
              ),
              const SizedBox(height: 24),
            ]),
          ),
        ),
      ],
    );
  }
}

// ─── Notif Button ─────────────────────────────────────────────────────────────

class _NotifButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor),
      ),
      child: Icon(
        Icons.notifications_none_rounded,
        size: 20,
        color: context.textSecondaryColor,
      ),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String title;
  final int value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 14),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: context.textPrimaryColor,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: context.textMutedColor),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Action Tile ──────────────────────────────────────────────────────────────

class _ActionTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color iconColor;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.iconColor,
    required this.onTap,
  });

  @override
  State<_ActionTile> createState() => _ActionTileState();
}

class _ActionTileState extends State<_ActionTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _pressed ? context.surface2Color : context.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: widget.iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon, size: 20, color: widget.iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                          fontSize: 12, color: context.textMutedColor),
                    ),
                  ],
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
      ),
    );
  }
}