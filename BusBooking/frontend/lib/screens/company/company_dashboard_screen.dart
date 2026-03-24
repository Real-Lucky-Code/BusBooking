import 'package:flutter/material.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../repositories/auth_repository.dart';
import '../../services/bus_company_service.dart';

class CompanyDashboardScreen extends StatefulWidget {
  const CompanyDashboardScreen({super.key});

  @override
  State<CompanyDashboardScreen> createState() => _CompanyDashboardScreenState();
}

class _CompanyDashboardScreenState extends State<CompanyDashboardScreen>
    with WidgetsBindingObserver {
  bool _isRefreshing = false;
  late Future<CompanyStatistics?> _statisticsFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshCompanyStatus();
    _statisticsFuture = _loadStatistics();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh when app comes back to foreground (e.g., after registration)
      _refreshCompanyStatus();
    }
  }

  Future<CompanyStatistics?> _loadStatistics() async {
    try {
      return await BusCompanyService.instance.getCompanyStatistics();
    } catch (e) {
      return null;
    }
  }

  Future<void> _refreshCompanyStatus() async {
    if (_isRefreshing) return;
    
    setState(() => _isRefreshing = true);
    
    try {
      final user = AuthRepository.instance.currentUser;
      if (user?.role == 'Provider') {
        final status = await BusCompanyService.instance.getMyCompany();
        // Update currentUser's companyStatus in memory
        AuthRepository.instance.updateCompanyStatus(status);
        if (mounted) {
          setState(() {
            // Force UI refresh with new status
            _statisticsFuture = _loadStatistics();
          });
        }
      }
    } catch (e) {
      // Silently fail, keep old status
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthRepository.instance.currentUser;
    final companyStatus = user?.companyStatus;
    final bool hasCompany = companyStatus?.hasCompany == true;
    final bool managementEnabled = companyStatus?.isApproved == true;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: AppBar(
        automaticallyImplyLeading: false, // keep provider on dashboard as root
        title: const Text('Quản lý nhà xe'),
        actions: [
          IconButton(
            icon: _isRefreshing 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _refreshCompanyStatus,
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthRepository.instance.logout();
              if (!context.mounted) return;
              Navigator.pushReplacementNamed(context, AppRoutes.login);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Company registration status banner
              _buildCompanyStatusBanner(context, user),

              // If company not registered, block management features with prompt
              if (!hasCompany) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.08),
                    borderRadius: AppRadius.medium,
                    border: Border.all(color: Colors.blue.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chức năng quản lý chưa khả dụng',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.blue[900],
                            ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Vui lòng đăng ký công ty để sử dụng các tính năng quản lý nhà xe.',
                        style: TextStyle(color: Colors.black87),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.companyRegistration,
                            arguments: companyStatus,
                          );
                        },
                        icon: const Icon(Icons.domain_add),
                        label: const Text('Đăng ký công ty'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Welcome header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: Theme.of(context).primaryGradient,
                  borderRadius: AppRadius.large,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Xin chào, ${user?.fullName ?? "Nhà xe"}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Quản lý xe, lịch trình và khách hàng của bạn',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Statistics overview
              Text(
                'Tổng quan',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              FutureBuilder<CompanyStatistics?>(
                future: _statisticsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: const [
                        _StatCard(
                          icon: Icons.directions_bus,
                          label: 'Tổng xe',
                          value: '...',
                          color: Colors.blue,
                        ),
                        _StatCard(
                          icon: Icons.route,
                          label: 'Chuyến đi',
                          value: '...',
                          color: Colors.green,
                        ),
                        _StatCard(
                          icon: Icons.people,
                          label: 'Khách hôm nay',
                          value: '...',
                          color: Colors.orange,
                        ),
                        _StatCard(
                          icon: Icons.local_offer,
                          label: 'Đánh giá',
                          value: '...',
                          color: Colors.purple,
                        ),
                      ],
                    );
                  }

                  final stats = snapshot.data;
                  if (stats == null) {
                    return GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: const [
                        _StatCard(
                          icon: Icons.directions_bus,
                          label: 'Tổng xe',
                          value: '0',
                          color: Colors.blue,
                        ),
                        _StatCard(
                          icon: Icons.route,
                          label: 'Chuyến đi',
                          value: '0',
                          color: Colors.green,
                        ),
                        _StatCard(
                          icon: Icons.people,
                          label: 'Khách hôm nay',
                          value: '0',
                          color: Colors.orange,
                        ),
                        _StatCard(
                          icon: Icons.local_offer,
                          label: 'Đánh giá',
                          value: '0',
                          color: Colors.purple,
                        ),
                      ],
                    );
                  }

                  return GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      _StatCard(
                        icon: Icons.directions_bus,
                        label: 'Tổng xe',
                        value: stats.totalBuses.toString(),
                        color: Colors.blue,
                      ),
                      _StatCard(
                        icon: Icons.route,
                        label: 'Chuyến đi',
                        value: stats.totalTrips.toString(),
                        color: Colors.green,
                      ),
                      _StatCard(
                        icon: Icons.people,
                        label: 'Khách hôm nay',
                        value: stats.todayBookings.toString(),
                        color: Colors.orange,
                      ),
                      _StatCard(
                        icon: Icons.star,
                        label: 'Đánh giá',
                        value: stats.averageRating.toStringAsFixed(1),
                        color: Colors.purple,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              
              // Quick actions
              Text(
                'Quản lý nhanh',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              // Only show registration status tracking if not yet approved
              if (!managementEnabled) ...[
                _MenuCard(
                  icon: Icons.track_changes,
                  title: 'Theo dõi yêu cầu đăng ký',
                  subtitle: 'Xem trạng thái và thông tin đăng ký công ty',
                  enabled: true,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.companyRegistrationStatus),
                ),
                const SizedBox(height: 12),
              ],
              _MenuCard(
                icon: Icons.directions_bus,
                title: 'Quản lý xe',
                subtitle: 'Thông tin xe, biển số, loại xe',
                enabled: managementEnabled,
                disabledMessage: 'Vui lòng đăng ký công ty để sử dụng tính năng quản lý.',
                onTap: () => Navigator.pushNamed(context, AppRoutes.companyBuses),
              ),
              const SizedBox(height: 12),
              _MenuCard(
                icon: Icons.schedule,
                title: 'Quản lý lịch trình',
                subtitle: 'Tạo và quản lý chuyến đi',
                enabled: managementEnabled,
                disabledMessage: 'Vui lòng đăng ký công ty để sử dụng tính năng quản lý.',
                onTap: () => Navigator.pushNamed(context, AppRoutes.companyTrips),
              ),
              const SizedBox(height: 12),
              _MenuCard(
                icon: Icons.people_outline,
                title: 'Danh sách khách đặt vé',
                subtitle: 'Xem và xác nhận trạng thái vé',
                enabled: managementEnabled,
                disabledMessage: 'Vui lòng đăng ký công ty để sử dụng tính năng quản lý.',
                onTap: () => Navigator.pushNamed(context, AppRoutes.companyAllBookings),
              ),
              const SizedBox(height: 12),
              _MenuCard(
                icon: Icons.local_offer_outlined,
                title: 'Quản lý khuyến mãi',
                subtitle: 'Giá vé và chương trình ưu đãi',
                enabled: managementEnabled,
                disabledMessage: 'Vui lòng đăng ký công ty để sử dụng tính năng quản lý.',
                onTap: () => Navigator.pushNamed(context, AppRoutes.companyPromotions),
              ),
              const SizedBox(height: 12),
              _MenuCard(
                icon: Icons.star_outline,
                title: 'Xem đánh giá',
                subtitle: 'Đánh giá từ khách hàng về dịch vụ',
                enabled: managementEnabled,
                disabledMessage: 'Vui lòng đăng ký công ty để sử dụng tính năng quản lý.',
                onTap: () => Navigator.pushNamed(context, AppRoutes.companyReviews),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompanyStatusBanner(BuildContext context, dynamic user) {
    final companyStatus = user?.companyStatus;

    if (companyStatus == null) return const SizedBox.shrink();
    if (companyStatus.isApproved) return const SizedBox.shrink();

    Color bannerColor;
    const Color textColor = Colors.white;
    String statusText;
    IconData statusIcon;
    VoidCallback? onTap;

    if (companyStatus.isPending) {
      bannerColor = Colors.orange;
      statusText = '⏱ Công ty của bạn đang chờ phê duyệt';
      statusIcon = Icons.hourglass_top;
    } else if (companyStatus.isRejected) {
      bannerColor = Colors.red;
      statusText = '✗ Công ty bị từ chối. Vui lòng cập nhật thông tin';
      statusIcon = Icons.error;
      onTap = () {
        Navigator.pushNamed(
          context,
          AppRoutes.companyRegistration,
          arguments: companyStatus,
        ).then((_) {
          // Refresh status after returning from registration
          _refreshCompanyStatus();
        });
      };
    } else {
      bannerColor = Colors.blue;
      statusText = '⬆️ Bạn cần đăng ký công ty để tiếp tục';
      statusIcon = Icons.info;
      onTap = () {
        Navigator.pushNamed(
          context,
          AppRoutes.companyRegistration,
          arguments: companyStatus,
        ).then((_) {
          // Refresh status after returning from registration
          _refreshCompanyStatus();
        });
      };
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bannerColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(statusIcon, color: textColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusText,
                    style: const TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (companyStatus.message.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      companyStatus.message,
                      style: TextStyle(
                        color: textColor.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: textColor),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.medium,
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: AppRadius.small,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.black54,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.enabled = true,
    this.disabledMessage,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool enabled;
  final String? disabledMessage;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: AppRadius.medium,
      child: InkWell(
        onTap: enabled
            ? onTap
            : () {
                final msg = disabledMessage ?? 'Chức năng sẽ khả dụng sau khi đăng ký công ty.';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(msg)),
                );
              },
        borderRadius: AppRadius.medium,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: AppRadius.medium,
            border: Border.all(color: Colors.grey.shade200),
            color: enabled ? Colors.white : Colors.grey.shade100,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: enabled
                      ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.15),
                  borderRadius: AppRadius.medium,
                ),
                child: Icon(
                  icon,
                  color: enabled
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: enabled ? null : Colors.grey,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: enabled ? Colors.grey.shade600 : Colors.grey,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: enabled ? Colors.grey.shade400 : Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
