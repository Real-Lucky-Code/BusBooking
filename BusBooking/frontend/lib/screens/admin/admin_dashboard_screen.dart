import 'package:flutter/material.dart';

import '../../models/mock_data.dart';
import '../../repositories/admin_repository.dart';
import 'admin_company_approval_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin dashboard')),
      backgroundColor: const Color(0xFFF7F7F9),
      body: FutureBuilder(
        future: AdminRepository.instance.getStatistics(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Không tải được thống kê'));
          }
          final stats = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('System statistics', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                12.vSpace,
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _StatCard(label: 'Users', value: stats.totalUsers.toString()),
                    _StatCard(label: 'Bus companies', value: stats.totalBusCompanies.toString()),
                    _StatCard(label: 'Nhà xe đã duyệt', value: stats.approvedBusCompanies.toString()),
                    _StatCard(label: 'Trips', value: stats.totalTrips.toString()),
                    _StatCard(label: 'Tickets', value: stats.totalTickets.toString()),
                    _StatCard(label: 'Revenue', value: stats.totalRevenue.toString()),
                  ],
                ),
                24.vSpace,
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.people_alt_outlined),
                  label: const Text('Manage users'),
                ),
                12.vSpace,
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => const AdminCompanyApprovalScreen(),
                    ));
                  },
                  icon: const Icon(Icons.approval),
                  label: const Text('Approve bus companies'),
                ),
                12.vSpace,
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.reviews_outlined),
                  label: const Text('Moderate reviews'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueGrey.shade50),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          6.vSpace,
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
