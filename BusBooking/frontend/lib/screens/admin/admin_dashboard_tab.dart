import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../services/admin_service.dart';

class AdminDashboardTab extends StatefulWidget {
  final Function(int)? onSwitchTab;

  const AdminDashboardTab({super.key, this.onSwitchTab});

  @override
  State<AdminDashboardTab> createState() => _AdminDashboardTabState();
}

class _AdminDashboardTabState extends State<AdminDashboardTab> {
  late Future<AdminStatistics?> _statisticsFuture;
  late Future<SeatStatistics?> _seatStatsFuture;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _statisticsFuture = _loadStatistics();
    _seatStatsFuture = _loadSeatStatistics();
  }

  Future<AdminStatistics?> _loadStatistics() async {
    try {
      return await AdminService.instance.getStatistics();
    } catch (e) {
      return null;
    }
  }

  Future<SeatStatistics?> _loadSeatStatistics() async {
    try {
      return await AdminService.instance.getSeatStatistics();
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
        _seatStatsFuture = _loadSeatStatistics();
      });
      await Future.wait([_statisticsFuture, _seatStatsFuture]);
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  String _formatCurrency(double value) {
    if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)}B đ';
    } else if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M đ';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K đ';
    }
    return '${value.toStringAsFixed(0)} đ';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Bảng điều khiển'),
        elevation: 0,
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
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                        Icon(Icons.admin_panel_settings, color: Colors.white.withOpacity(0.9), size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Chào mừng quay lại',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('EEEE, dd MMMM yyyy', 'vi_VN').format(DateTime.now()),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Key Performance Indicators (KPIs)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Chỉ số chính',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(height: 12),

              FutureBuilder<AdminStatistics?>(
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
                      // Top 4 KPIs
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _KPICard(
                                    icon: Icons.receipt_long,
                                    label: 'Tổng vé bán',
                                    value: stats?.totalTickets.toString() ?? '0',
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _KPICard(
                                    icon: Icons.trending_up,
                                    label: 'Tổng doanh thu',
                                    value: _formatCurrency(stats?.totalRevenue ?? 0),
                                    color: Colors.green,
                                    isLarge: true,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _KPICard(
                                    icon: Icons.people_outline,
                                    label: 'Người dùng',
                                    value: stats?.totalUsers.toString() ?? '0',
                                    color: Colors.purple,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _KPICard(
                                    icon: Icons.business,
                                    label: 'Nhà xe',
                                    value: stats?.totalBusCompanies.toString() ?? '0',
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Quick Actions & Alerts
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Cần xử lý',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            _AlertCard(
                              icon: Icons.check_circle_outline,
                              label: 'Chờ duyệt nhà xe',
                              value: stats?.pendingApprovals.toString() ?? '0',
                              color: Colors.amber,
                              onTap: () => widget.onSwitchTab?.call(3),
                            ),
                            const SizedBox(height: 10),
                            _AlertCard(
                              icon: Icons.rate_review,
                              label: 'Đánh giá',
                              value: stats?.totalReviews.toString() ?? '0',
                              color: Colors.pink,
                              onTap: () => widget.onSwitchTab?.call(4),
                            ),
                            const SizedBox(height: 10),
                            _AlertCard(
                              icon: Icons.trip_origin,
                              label: 'Chuyến xe',
                              value: stats?.totalTrips.toString() ?? '0',
                              color: Colors.teal,
                              onTap: () => widget.onSwitchTab?.call(2),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Performance Card
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Hiệu suất',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: AppRadius.medium,
                            boxShadow: AppShadows.soft,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Nhà xe đã duyệt',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  Text(
                                    '${stats?.approvedBusCompanies ?? 0}/${stats?.totalBusCompanies ?? 0}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: (stats?.totalBusCompanies ?? 0) > 0
                                      ? (stats?.approvedBusCompanies ?? 0).toDouble() / (stats?.totalBusCompanies ?? 1).toDouble()
                                      : 0.0,
                                  minHeight: 12,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.green.shade400,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),

              // Seat Statistics
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Thống kê ghế ngồi',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(height: 12),

              FutureBuilder<SeatStatistics?>(
                future: _seatStatsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final seatStats = snapshot.data;
                  final occupancyRate = seatStats != null && seatStats.totalSeats > 0
                      ? (seatStats.bookedSeats / seatStats.totalSeats * 100).toStringAsFixed(1)
                      : '0';

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: AppRadius.medium,
                        boxShadow: AppShadows.soft,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Tỷ lệ sử dụng',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              Text(
                                '$occupancyRate%',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: (seatStats?.bookedSeats ?? 0).toDouble() / max((seatStats?.totalSeats ?? 1).toDouble(), 1.0),
                              minHeight: 12,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.blue.shade400,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _SeatStat(
                                label: 'Tổng ghế',
                                value: seatStats?.totalSeats.toString() ?? '0',
                                color: Colors.grey,
                              ),
                              _SeatStat(
                                label: 'Đã đặt',
                                value: seatStats?.bookedSeats.toString() ?? '0',
                                color: Colors.blue,
                              ),
                              _SeatStat(
                                label: 'Trống',
                                value: ((seatStats?.totalSeats ?? 0) - (seatStats?.bookedSeats ?? 0)).toString(),
                                color: Colors.green,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _KPICard extends StatelessWidget {
  const _KPICard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.isLarge = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isLarge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.medium,
        boxShadow: AppShadows.soft,
        border: Border(
          left: BorderSide(color: color, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: isLarge ? 22 : 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
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
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Cần xem xét',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

class _SeatStat extends StatelessWidget {
  const _SeatStat({
    required this.label,
    required this.value,
    this.color = Colors.grey,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

double max(double a, double b) => a > b ? a : b;
