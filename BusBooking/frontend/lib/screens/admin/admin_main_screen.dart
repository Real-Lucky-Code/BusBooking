import 'package:flutter/material.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../repositories/auth_repository.dart';
import 'admin_dashboard_tab.dart';
import 'admin_users_tab.dart';
import 'admin_bus_companies_tab.dart';
import 'admin_approvals_tab.dart';
import 'admin_reviews_tab.dart';
import 'admin_account_tab.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _selectedIndex = 0;

  void _switchTab(int tabIndex) {
    setState(() => _selectedIndex = tabIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          AdminDashboardTab(onSwitchTab: _switchTab),
          const AdminUsersTab(),
          const AdminBusCompaniesTab(),
          const AdminApprovalsTab(),
          const AdminReviewsTab(),
          const AdminAccountTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Tổng quan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Người dùng',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business),
            label: 'Nhà xe',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle),
            label: 'Phê duyệt',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star),
            label: 'Đánh giá',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }
}
