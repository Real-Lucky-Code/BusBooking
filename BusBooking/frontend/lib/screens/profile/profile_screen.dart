import 'package:flutter/material.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/mock_data.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/profile_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<_ProfileData> futureProfile;

  @override
  void initState() {
    super.initState();
    futureProfile = _load();
  }

  Future<void> _refresh() async {
    setState(() {
      futureProfile = _load();
    });
    await futureProfile;
  }

  Future<_ProfileData> _load() async {
    final userId = AuthRepository.instance.currentUser?.id ?? 1;
    final user = await ProfileRepository.instance.getProfile(userId);
    final passengers = await ProfileRepository.instance.listPassengerProfiles(userId);
    return _ProfileData(user: user, passengers: passengers);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: AppBar(
        title: const Text('Hồ sơ cá nhân'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _showComingSoon('Cài đặt tài khoản sắp có'),
          ),
        ],
      ),
      body: FutureBuilder<_ProfileData>(
        future: futureProfile,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('Không thể tải thông tin', style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _refresh,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }
          
          final data = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildProfileHeader(context, data.user),
                const SizedBox(height: 20),
                _buildQuickActions(context),
                const SizedBox(height: 20),
                _buildPassengerSection(context, data.passengers),
                const SizedBox(height: 20),
                _buildMenuSection(context),
                const SizedBox(height: 20),
                _buildLogoutButton(context),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, AppRoutes.tripSearch);
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, AppRoutes.ticketList);
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.confirmation_num_outlined), label: 'Vé của tôi'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Hồ sơ'),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, UserProfile user) {
    return Container(
      decoration: gradientCard(borderRadius: AppRadius.large),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          CircleAvatar(
            radius: 38,
            backgroundColor: Colors.white.withOpacity(0.16),
            child: const Icon(Icons.person, color: Colors.white, size: 38),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName.isNotEmpty ? user.fullName : 'Người dùng',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  user.phone,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () async {
              await Navigator.pushNamed(context, AppRoutes.profileEdit, arguments: user);
              if (mounted) {
                await _refresh();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Container(
      decoration: glassSurface(),
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _quickActionItem(Icons.history, 'Lịch sử\nvé', () => Navigator.pushNamed(context, AppRoutes.ticketList)),
          _quickActionItem(Icons.wallet, 'Ví của tôi', () => _showComingSoon('Ví điện tử đang được phát triển')),
          _quickActionItem(Icons.card_giftcard, 'Ưu đãi', () => _showComingSoon('Ưu đãi sẽ cập nhật sớm')), 
          _quickActionItem(Icons.support_agent, 'Hỗ trợ', () => _showComingSoon('Chat hỗ trợ sẽ sớm khả dụng')),
        ],
      ),
    );
  }

  Widget _quickActionItem(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: primaryColor, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, height: 1.2),
          ),
        ],
      ),
    );
  }

  Widget _buildPassengerSection(BuildContext context, List<PassengerProfile> passengers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hồ sơ hành khách',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              TextButton.icon(
                icon: const Icon(Icons.add_circle_outline, size: 20),
                label: const Text('Thêm mới'),
                onPressed: () => _openPassengerProfile(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: glassSurface(),
          child: passengers.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 26),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.person_outline, size: 36, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Chưa có hồ sơ hành khách'),
                        SizedBox(height: 4),
                        Text('Thêm mới để đặt vé nhanh hơn', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: passengers.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final p = passengers[index];
                    return ListTile(
                      onTap: () => _openPassengerProfile(p),
                      leading: CircleAvatar(
                        backgroundColor: primaryColor.withOpacity(0.12),
                        child: Text(
                          p.fullName.isNotEmpty ? p.fullName[0].toUpperCase() : 'H',
                          style: const TextStyle(color: primaryColor, fontWeight: FontWeight.w600),
                        ),
                      ),
                      title: Text(p.fullName),
                      subtitle: Text('${p.phone} · ${p.identityNumber}'),
                      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    return Container(
      decoration: glassSurface(),
      child: Column(
        children: [
          _menuTile(Icons.receipt_long_outlined, 'Lịch sử giao dịch', () => Navigator.pushNamed(context, AppRoutes.ticketList)),
          const Divider(height: 1),
          _menuTile(Icons.notifications_outlined, 'Thông báo', () => _showComingSoon('Thông báo đang được hoàn thiện')), 
          const Divider(height: 1),
          _menuTile(Icons.privacy_tip_outlined, 'Bảo mật & Quyền riêng tư', () => _showComingSoon('Tùy chọn bảo mật sẽ sớm có')),
          const Divider(height: 1),
          _menuTile(Icons.info_outline, 'Về chúng tôi', () => _showComingSoon('Trang giới thiệu đang cập nhật')),
        ],
      ),
    );
  }

  Widget _menuTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: primaryColor),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        backgroundColor: Colors.red.shade400,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
      ),
      onPressed: () async {
        await AuthRepository.instance.logout();
        if (context.mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.login,
            (route) => false,
          );
        }
      },
      child: const Text('Đăng xuất', style: TextStyle(fontWeight: FontWeight.w600)),
    );
  }

  Future<void> _openPassengerProfile([PassengerProfile? profile]) async {
    await Navigator.pushNamed(context, AppRoutes.passengerProfile, arguments: profile);
    if (mounted) {
      await _refresh();
    }
  }

  void _showComingSoon(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _ProfileData {
  _ProfileData({required this.user, required this.passengers});
  final UserProfile user;
  final List<PassengerProfile> passengers;
}
