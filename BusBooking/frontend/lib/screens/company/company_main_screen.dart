import 'package:flutter/material.dart';

import '../../config/routes.dart';
import '../../repositories/auth_repository.dart';
import 'company_dashboard_tab.dart';
import 'company_manage_tab.dart';
import 'company_promotions_screen.dart';
import 'company_reviews_screen.dart';
import 'company_account_tab.dart';

class CompanyMainScreen extends StatefulWidget {
  const CompanyMainScreen({super.key});

  @override
  State<CompanyMainScreen> createState() => _CompanyMainScreenState();
}

class _CompanyMainScreenState extends State<CompanyMainScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const CompanyDashboardTab(),
      const CompanyManageTab(),
      const CompanyPromotionsScreen(),
      const CompanyReviewsScreen(),
      const CompanyAccountTab(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthRepository.instance.currentUser;
    final companyStatus = user?.companyStatus;
    final bool hasCompany = companyStatus?.hasCompany == true;

    // If no company registered, show registration prompt
    if (!hasCompany) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Quản lý nhà xe'),
          actions: [
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
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.business_outlined, size: 100, color: Colors.grey.shade300),
                const SizedBox(height: 24),
                Text(
                  'Chào mừng đến với hệ thống quản lý',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Vui lòng đăng ký thông tin công ty để sử dụng các tính năng quản lý nhà xe',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.companyRegistration);
                  },
                  icon: const Icon(Icons.add_business),
                  label: const Text('Đăng ký công ty'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey.shade600,
        selectedFontSize: 12,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Tổng quan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Quản lý',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_offer_outlined),
            activeIcon: Icon(Icons.local_offer),
            label: 'Khuyến mãi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star_outline),
            activeIcon: Icon(Icons.star),
            label: 'Đánh giá',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle_outlined),
            activeIcon: Icon(Icons.account_circle),
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }
}
