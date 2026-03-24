import 'package:flutter/material.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../repositories/auth_repository.dart';

class CompanyManageTab extends StatelessWidget {
  const CompanyManageTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthRepository.instance.currentUser;
    final companyStatus = user?.companyStatus;
    final bool isApproved = companyStatus?.isApproved == true;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Quản lý'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!isApproved) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: AppRadius.medium,
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Công ty chưa được phê duyệt. Các tính năng quản lý bị giới hạn.',
                      style: TextStyle(color: Colors.orange.shade900, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          _SectionTitle(title: 'Quản lý tài sản'),
          const SizedBox(height: 12),

          _ManageCard(
            icon: Icons.directions_bus,
            iconColor: Colors.blue,
            title: 'Quản lý xe',
            subtitle: 'Thông tin xe, biển số, loại xe',
            trailing: '${0} xe',
            enabled: isApproved,
            onTap: () => Navigator.pushNamed(context, AppRoutes.companyBuses),
          ),
          const SizedBox(height: 12),

          _ManageCard(
            icon: Icons.route,
            iconColor: Colors.green,
            title: 'Quản lý chuyến đi',
            subtitle: 'Lịch trình, tuyến đường, giá vé',
            trailing: '${0} chuyến',
            enabled: isApproved,
            onTap: () => Navigator.pushNamed(context, AppRoutes.companyTrips),
          ),

          const SizedBox(height: 24),
          _SectionTitle(title: 'Quản lý đặt vé'),
          const SizedBox(height: 12),

          _ManageCard(
            icon: Icons.people_outline,
            iconColor: Colors.purple,
            title: 'Danh sách đặt vé',
            subtitle: 'Xem và xác nhận đặt vé',
            trailing: 'Xem tất cả',
            enabled: isApproved,
            onTap: () => Navigator.pushNamed(context, AppRoutes.companyAllBookings),
          ),

          const SizedBox(height: 12),

          _ManageCard(
            icon: Icons.close_outlined,
            iconColor: Colors.red,
            title: 'Yêu cầu hủy vé',
            subtitle: 'Phê duyệt hoặc từ chối hủy vé',
            enabled: isApproved,
            onTap: () => Navigator.pushNamed(context, AppRoutes.companyCancellations),
          ),

          const SizedBox(height: 24),
          _SectionTitle(title: 'Dịch vụ khác'),
          const SizedBox(height: 12),

          _ManageCard(
            icon: Icons.local_offer,
            iconColor: Colors.orange,
            title: 'Quản lý khuyến mãi',
            subtitle: 'Mã giảm giá và ưu đãi',
            enabled: isApproved,
            onTap: () => Navigator.pushNamed(context, AppRoutes.companyPromotions),
          ),
          const SizedBox(height: 12),

          _ManageCard(
            icon: Icons.star,
            iconColor: Colors.amber,
            title: 'Xem đánh giá',
            subtitle: 'Phản hồi từ khách hàng',
            enabled: isApproved,
            onTap: () => Navigator.pushNamed(context, AppRoutes.companyReviews),
          ),

          const SizedBox(height: 24),
          _SectionTitle(title: 'Hệ thống'),
          const SizedBox(height: 12),

          _ManageCard(
            icon: Icons.business,
            iconColor: Colors.teal,
            title: 'Thông tin công ty',
            subtitle: 'Xem và cập nhật thông tin',
            enabled: true,
            onTap: () => Navigator.pushNamed(
              context,
              companyStatus?.isPending == true
                  ? AppRoutes.companyRegistrationStatus
                  : AppRoutes.companyRegistration,
              arguments: companyStatus,
            ),
          ),
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

class _ManageCard extends StatelessWidget {
  const _ManageCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? trailing;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: Colors.white,
        borderRadius: AppRadius.medium,
        child: InkWell(
          onTap: enabled ? onTap : null,
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
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
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    trailing!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
