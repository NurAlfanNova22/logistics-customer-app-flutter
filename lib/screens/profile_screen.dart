import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import '../app_theme.dart';
import '../main.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? user;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final data = await AuthService.getProfile();
    if (mounted) {
      setState(() {
      user = data;
      isLoading = false;
    });
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
      (route) => false,
    );
  }

  void _showEditProfileDialog() {
    if (user == null) return;
    
    final nameController = TextEditingController(text: user!['name']);
    final emailController = TextEditingController(text: user!['email']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nama Lengkap'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await AuthService.updateProfile(
                nameController.text.trim(),
                emailController.text.trim(),
              );

              if (success && mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profil berhasil diperbarui')),
                );
                _loadProfile();
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Gagal memperbarui profil')),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : user == null
              ? Center(
                  child: Text('Gagal memuat profil',
                      style: TextStyle(color: context.textSecondaryColor)))
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Avatar + Info
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.primaryDark
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                _getInitials(user!['name']?.toString()),
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            user!['name'] ?? '-',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: context.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user!['email'] ?? '-',
                            style: TextStyle(
                                fontSize: 14,
                                color: context.textSecondaryColor),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _showEditProfileDialog,
                            icon: const Icon(Icons.edit_rounded, size: 16),
                            label: const Text('Edit Profil'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Settings Card
                    Container(
                      decoration: BoxDecoration(
                        color: context.surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: context.borderColor),
                      ),
                      child: Column(
                        children: [
                          // Dark Mode Toggle
                          ValueListenableBuilder<ThemeMode>(
                            valueListenable: themeModeNotifier,
                            builder: (context, themeMode, _) {
                              final isDark = themeMode == ThemeMode.dark;
                              return _SettingRow(
                                icon: isDark
                                    ? Icons.dark_mode_rounded
                                    : Icons.light_mode_rounded,
                                label: 'Mode Gelap',
                                trailing: Switch(
                                  value: isDark,
                                  onChanged: (val) {
                                    themeModeNotifier.value =
                                        val ? ThemeMode.dark : ThemeMode.light;
                                  },
                                ),
                              );
                            },
                          ),
                          Divider(
                              height: 1,
                              color: context.borderColor,
                              indent: 56),

                          _SettingRow(
                            icon: Icons.notifications_none_rounded,
                            label: 'Notifikasi',
                            trailing: Icon(Icons.chevron_right_rounded,
                                size: 18, color: context.textMutedColor),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // App Info Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: context.borderColor),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.primarySurface,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.local_shipping_rounded,
                                size: 18, color: AppColors.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Lancar Ekspedisi',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: context.textPrimaryColor)),
                                Text('Versi 1.0.0',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: context.textMutedColor)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Logout
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout_rounded,
                            color: AppColors.error),
                        label: const Text('Keluar',
                            style: TextStyle(color: AppColors.error)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.error),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;

  const _SettingRow({
    required this.icon,
    required this.label,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: context.surface2Color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: context.textSecondaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 14, color: context.textPrimaryColor)),
          ),
          trailing,
        ],
      ),
    );
  }
}