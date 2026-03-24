import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../repositories/auth_repository.dart';
import '../../services/bus_company_service.dart';

class CompanyDashboardTab extends StatefulWidget {
  const CompanyDashboardTab({super.key});

  @override
  State<CompanyDashboardTab> createState() => _CompanyDashboardTabState();
}

class _CompanyDashboardTabState extends State<CompanyDashboardTab> {
  bool _isRefreshing = false;
  late Future<CompanyStatistics?> _statisticsFuture;

  @override
  void initState() {
    super.initState();
    _statisticsFuture = _loadStatistics();
  }

  Future<CompanyStatistics?> _loadStatistics() async {
    try {
      return await BusCompanyService.instance.getCompanyStatistics();
    } catch (e) {
      return null;
    }
  }

  Future<void> _refresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    
    try {
      setState(() {
        _statisticsFuture = _loadStatistics();
      });
      await _statisticsFuture;
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
    final bool isApproved = companyStatus?.isApproved == true;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tổng quan', style: TextStyle(fontSize: 18)),
            if (companyStatus?.company?.name != null)
              Text(
                companyStatus!.company!.name,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _refresh,
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status banner
              if (!isApproved) _buildStatusBanner(context, companyStatus),

              // Welcome card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: AppRadius.large,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.waving_hand, color: Colors.white.withOpacity(0.9)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Xin chào, ${user?.fullName ?? "Admin"}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('EEEE, dd MMMM yyyy', 'vi_VN').format(DateTime.now()),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              // Statistics
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Thống kê hôm nay',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(height: 12),

              FutureBuilder<CompanyStatistics?>(
                future: _statisticsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final stats = snapshot.data;
                  return Column(
                    children: [
                      // Main stats
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                icon: Icons.people,
                                label: 'Khách hàng',
                                value: stats?.todayBookings.toString() ?? '0',
                                subtitle: 'Hôm nay',
                                color: Colors.blue,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                icon: Icons.attach_money,
                                label: 'Doanh thu',
                                value: '${stats?.todayRevenue?.toStringAsFixed(0) ?? '0'}đ',
                                subtitle: 'Hôm nay',
                                color: Colors.green,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Grid stats
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.3,
                          children: [
                            _SmallStatCard(
                              icon: Icons.directions_bus,
                              label: 'Tổng xe',
                              value: stats?.totalBuses.toString() ?? '0',
                              color: Colors.orange,
                            ),
                            _SmallStatCard(
                              icon: Icons.route,
                              label: 'Chuyến đi',
                              value: stats?.totalTrips.toString() ?? '0',
                              color: Colors.purple,
                            ),
                            _SmallStatCard(
                              icon: Icons.star,
                              label: 'Đánh giá',
                              value: stats?.averageRating.toStringAsFixed(1) ?? '0.0',
                              color: Colors.amber,
                            ),
                            _SmallStatCard(
                              icon: Icons.local_offer,
                              label: 'Khuyến mãi',
                              value: stats?.totalPromotions.toString() ?? '0',
                              color: Colors.pink,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),

              // Quick actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Hành động nhanh',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _QuickActionButton(
                      icon: Icons.directions_bus,
                      label: 'Thêm xe',
                      color: Colors.blue,
                      enabled: isApproved,
                      onTap: () => Navigator.pushNamed(context, AppRoutes.companyBuses),
                    ),
                    _QuickActionButton(
                      icon: Icons.add_road,
                      label: 'Tạo chuyến',
                      color: Colors.green,
                      enabled: isApproved,
                      onTap: () => Navigator.pushNamed(context, AppRoutes.companyTrips),
                    ),
                    _QuickActionButton(
                      icon: Icons.local_offer,
                      label: 'Khuyến mãi',
                      color: Colors.orange,
                      enabled: isApproved,
                      onTap: () => Navigator.pushNamed(context, AppRoutes.companyPromotions),
                    ),
                    _QuickActionButton(
                      icon: Icons.people,
                      label: 'Xem khách',
                      color: Colors.purple,
                      enabled: isApproved,
                      onTap: () => Navigator.pushNamed(context, AppRoutes.companyAllBookings),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBanner(BuildContext context, dynamic companyStatus) {
    if (companyStatus == null) return const SizedBox.shrink();
    if (companyStatus.isApproved) return const SizedBox.shrink();

    Color bannerColor;
    String statusText;
    IconData statusIcon;

    if (companyStatus.isPending) {
      bannerColor = Colors.orange;
      statusText = 'Công ty đang chờ phê duyệt';
      statusIcon = Icons.hourglass_top;
    } else if (companyStatus.isRejected) {
      bannerColor = Colors.red;
      statusText = 'Công ty bị từ chối. Vui lòng cập nhật';
      statusIcon = Icons.error;
    } else {
      bannerColor = Colors.blue;
      statusText = 'Vui lòng hoàn tất đăng ký công ty';
      statusIcon = Icons.info;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bannerColor,
        borderRadius: AppRadius.medium,
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              statusText,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (!companyStatus.isApproved)
            TextButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  companyStatus.isPending
                      ? AppRoutes.companyRegistrationStatus
                      : AppRoutes.companyRegistration,
                  arguments: companyStatus,
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.white.withOpacity(0.2),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              child: Text(companyStatus.isPending ? 'Xem' : 'Cập nhật'),
            ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.gradient,
  });

  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final Color color;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: AppRadius.medium,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallStatCard extends StatelessWidget {
  const _SmallStatCard({
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: AppRadius.medium,
        child: Container(
          width: (MediaQuery.of(context).size.width - 48) / 2,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppRadius.medium,
            boxShadow: AppShadows.soft,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
