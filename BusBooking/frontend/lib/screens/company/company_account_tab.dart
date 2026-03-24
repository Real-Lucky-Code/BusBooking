import 'package:flutter/material.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../repositories/auth_repository.dart';

class CompanyAccountTab extends StatelessWidget {
  const CompanyAccountTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthRepository.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Tài khoản'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.large,
              boxShadow: AppShadows.soft,
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withOpacity(0.7),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      (user?.fullName ?? 'A').substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user?.fullName ?? 'Người dùng',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: AppRadius.pill,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, size: 14, color: Colors.green.shade700),
                      const SizedBox(width: 4),
                      Text(
                        'Nhà xe',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.profileEdit),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Chỉnh sửa thông tin'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Account section
          _SectionTitle(title: 'Thông tin tài khoản'),
          const SizedBox(height: 12),

          _AccountMenuItem(
            icon: Icons.person_outline,
            iconColor: Colors.blue,
            title: 'Thông tin cá nhân',
            subtitle: 'Cập nhật thông tin cá nhân',
            onTap: () => Navigator.pushNamed(context, AppRoutes.profileEdit),
          ),
          const SizedBox(height: 12),

          _AccountMenuItem(
            icon: Icons.business_outlined,
            iconColor: Colors.green,
            title: 'Thông tin công ty',
            subtitle: 'Quản lý thông tin nhà xe',
            onTap: () {
              Navigator.pushNamed(
                context,
                user?.companyStatus?.isPending == true
                    ? AppRoutes.companyRegistrationStatus
                    : AppRoutes.companyRegistration,
                arguments: user?.companyStatus,
              );
            },
          ),
          const SizedBox(height: 12),

          _AccountMenuItem(
            icon: Icons.lock_outline,
            iconColor: Colors.orange,
            title: 'Đổi mật khẩu',
            subtitle: 'Thay đổi mật khẩu đăng nhập',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng đang phát triển')),
              );
            },
          ),

          const SizedBox(height: 24),

          // Settings section
          _SectionTitle(title: 'Cài đặt'),
          const SizedBox(height: 12),

          _AccountMenuItem(
            icon: Icons.notifications_outlined,
            iconColor: Colors.purple,
            title: 'Thông báo',
            subtitle: 'Cài đặt nhận thông báo',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng đang phát triển')),
              );
            },
          ),
          const SizedBox(height: 12),

          _AccountMenuItem(
            icon: Icons.language_outlined,
            iconColor: Colors.teal,
            title: 'Ngôn ngữ',
            subtitle: 'Tiếng Việt',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng đang phát triển')),
              );
            },
          ),

          const SizedBox(height: 24),

          // Support section
          _SectionTitle(title: 'Hỗ trợ'),
          const SizedBox(height: 12),

          _AccountMenuItem(
            icon: Icons.help_outline,
            iconColor: Colors.indigo,
            title: 'Trợ giúp',
            subtitle: 'Câu hỏi thường gặp và hỗ trợ',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng đang phát triển')),
              );
            },
          ),
          const SizedBox(height: 12),

          _AccountMenuItem(
            icon: Icons.info_outline,
            iconColor: Colors.cyan,
            title: 'Về ứng dụng',
            subtitle: 'Phiên bản 1.0.0',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Bus Booking',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2026 Bus Booking System',
              );
            },
          ),

          const SizedBox(height: 24),

          // Logout button
          ElevatedButton.icon(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Đăng xuất'),
                  content: const Text('Bạn có chắc muốn đăng xuất?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Hủy'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Đăng xuất'),
                    ),
                  ],
                ),
              );

              if (confirm == true && context.mounted) {
                await AuthRepository.instance.logout();
                if (!context.mounted) return;
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              }
            },
            icon: const Icon(Icons.logout),
            label: const Text('Đăng xuất'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
    );
  }
}

class _AccountMenuItem extends StatelessWidget {
  const _AccountMenuItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: AppRadius.medium,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.medium,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: AppRadius.medium,
            boxShadow: AppShadows.soft,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
