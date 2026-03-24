import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/mock_data.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/location_repository.dart';
import '../../repositories/trip_repository.dart';
import '../../utils/animation_utils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;
  DateTime selectedDate = DateTime.now().add(const Duration(days: 1));

  final TextEditingController fromCtrl = TextEditingController(text: 'Hà Nội');
  final TextEditingController toCtrl = TextEditingController(text: 'Đà Nẵng');

  List<String> provinces = [];
  bool loadingProvinces = false;

  @override
  void initState() {
    super.initState();
    _redirectIfNotCustomer();
    _loadProvinces();
  }

  void _redirectIfNotCustomer() {
    final user = AuthRepository.instance.currentUser;
    if (user == null) return;
    final role = user.role.toLowerCase();
    if (role == 'provider') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, AppRoutes.companyDashboard);
      });
    } else if (role == 'admin') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
      });
    }
  }

  Future<void> _loadProvinces() async {
    setState(() => loadingProvinces = true);
    try {
      final result = await LocationRepository.instance.getProvinces();
      setState(() => provinces = result);
    } catch (e) {
      setState(() => provinces = [
        'Hà Nội', 'TP Hồ Chí Minh', 'Đà Nẵng', 'Hải Phòng', 'Cần Thơ',
        'Thừa Thiên Huế', 'Lâm Đồng', 'Khánh Hòa', 'Bình Dương', 'Đồng Nai',
      ]);
    } finally {
      setState(() => loadingProvinces = false);
    }
  }

  Future<void> _goSearch() async {
    if (fromCtrl.text.isEmpty || toCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn điểm đi và đến')),
      );
      return;
    }

    try {
      final trips = await TripRepository.instance.searchTrips(
        startLocation: fromCtrl.text,
        endLocation: toCtrl.text,
        departureDate: selectedDate,
      );

      if (!mounted) return;
      Navigator.pushNamed(
        context,
        AppRoutes.tripResults,
        arguments: SearchResult(
          trips: trips,
          startLocation: fromCtrl.text.trim(),
          endLocation: toCtrl.text.trim(),
          departureDate: selectedDate,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tìm kiếm: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("BusGo"),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned(
            top: -120,
            right: -80,
            child: Opacity(
              opacity: 0.14,
              child: Container(
                height: 280,
                width: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: Theme.of(context).primaryGradient,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -140,
            left: -60,
            child: Opacity(
              opacity: 0.12,
              child: Container(
                height: 260,
                width: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: Theme.of(context).accentGradient,
                ),
              ),
            ),
          ),
          AnimationLimiter(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              children: AnimationConfiguration.toStaggeredList(
                duration: const Duration(milliseconds: 500),
                childAnimationBuilder: (widget) => ScaleAnimation(
                  scale: 0.92,
                  curve: Curves.easeOutBack,
                  child: SlideAnimation(
                    verticalOffset: 40,
                    curve: Curves.easeOutQuart,
                    child: FadeInAnimation(child: widget),
                  ),
                ),
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.95, end: 1),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutBack,
                    builder: (context, scale, child) => Transform.scale(
                      scale: scale,
                      child: child,
                    ),
                    child: Container(
                      decoration: gradientCard(borderRadius: AppRadius.large),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.16),
                                  borderRadius: AppRadius.pill,
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.flash_on, color: Colors.white, size: 18),
                                    SizedBox(width: 6),
                                    Text("Ưu tiên", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: 1),
                                duration: const Duration(milliseconds: 800),
                                curve: Curves.easeOutBack,
                                builder: (context, value, _) => Transform.scale(
                                  scale: value,
                                  child: Transform.rotate(
                                    angle: value * 6.28,
                                    child: Icon(Icons.star_rounded, color: Colors.amber.shade300, size: 28),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Đặt vé nhanh, chọn ghế dễ",
                            style: Theme.of(context).textTheme.displayMedium?.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "So sánh giá, chọn chuyến yêu thích và giữ chỗ trong vài giây.",
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: _metricChip("4.9/5", "Hài lòng")),
                              const SizedBox(width: 6),
                              Expanded(child: _metricChip("+120k", "Vé đã bán")),
                              const SizedBox(width: 6),
                              Expanded(child: _metricChip("< 30s", "Xác nhận")),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    decoration: glassSurface(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text("Tìm chuyến", style: Theme.of(context).textTheme.titleLarge),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: _swapLocations,
                              icon: const Icon(Icons.swap_vert_rounded),
                              label: const Text("Đổi"),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _locationDropdown(
                          label: "Điểm đi",
                          hint: "Chọn thành phố",
                          icon: Icons.place_outlined,
                          controller: fromCtrl,
                          items: provinces,
                        ),
                        const SizedBox(height: 12),
                        _locationDropdown(
                          label: "Điểm đến",
                          hint: "Chọn thành phố",
                          icon: Icons.flag_outlined,
                          controller: toCtrl,
                          items: provinces,
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() => selectedDate = picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: AppRadius.medium,
                              boxShadow: AppShadows.soft,
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, color: primary, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Ngày đi: ${selectedDate.toLocal().toString().split(' ')[0]}",
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Icon(Icons.chevron_right, color: Colors.grey.shade500, size: 20),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 54),
                            shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
                          ),
                          onPressed: _goSearch,
                          icon: const Icon(Icons.search),
                          label: const Text("Tìm chuyến phù hợp"),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text("Lộ trình hot", style: Theme.of(context).textTheme.titleLarge),
                      const Spacer(),
                      TextButton(onPressed: _goSearch, child: const Text("Xem tất cả")),
                    ],
                  ),
                  SizedBox(
                    height: 200,
                    child: FutureBuilder<List<HotRoute>>(
                      future: TripRepository.instance.getHotRoutes(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, color: Colors.grey, size: 40),
                                const SizedBox(height: 10),
                                Text('Lỗi tải lộ trình', style: Theme.of(context).textTheme.bodyLarge),
                              ],
                            ),
                          );
                        }

                        final hotRoutes = snapshot.data ?? [];

                        if (hotRoutes.isEmpty) {
                          return Center(
                            child: Text('Không có lộ trình hot', style: Theme.of(context).textTheme.bodyLarge),
                          );
                        }

                        return ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: hotRoutes.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 14),
                          itemBuilder: (context, index) {
                            final route = hotRoutes[index];
                            return ProfessionalCardReveal(
                              index: index,
                              delay: const Duration(milliseconds: 100),
                              child: GestureDetector(
                                onTap: () => _selectDateForRoute(context, route),
                                child: MouseRegion(
                                  onEnter: (_) {},
                                  onExit: (_) {},
                                  child: Container(
                                    width: 240,
                                    decoration: glassSurface(borderRadius: AppRadius.large),
                                    clipBehavior: Clip.antiAlias,
                                    child: Stack(
                                      children: [
                                        Positioned.fill(
                                          child: CachedNetworkImage(
                                            imageUrl: 'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=900&q=80',
                                            fit: BoxFit.cover,
                                            color: Colors.black.withValues(alpha: 0.15),
                                            colorBlendMode: BlendMode.darken,
                                          ),
                                        ),
                                        Positioned.fill(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [Colors.black.withValues(alpha: 0.55), Colors.black.withValues(alpha: 0.15)],
                                                begin: Alignment.bottomCenter,
                                                end: Alignment.topCenter,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withValues(alpha: 0.16),
                                                  borderRadius: AppRadius.pill,
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: const [
                                                    Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 18),
                                                    SizedBox(width: 6),
                                                    Text("Nổi bật", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                                  ],
                                                ),
                                              ),
                                              const Spacer(),
                                              Text(
                                                route.displayName,
                                                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                'Chọn ngày để tìm chuyến',
                                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                                              ),
                                              const SizedBox(height: 12),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withValues(alpha: 0.2),
                                                  borderRadius: AppRadius.medium,
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: const [
                                                    Icon(Icons.calendar_today, color: Colors.white, size: 16),
                                                    SizedBox(width: 6),
                                                    Text('Chọn ngày', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Text("Tiện ích dành cho bạn", style: Theme.of(context).textTheme.titleLarge),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _featureChip(Icons.event_seat, "Chọn ghế"),
                      _featureChip(Icons.local_drink, "Nước & wifi"),
                      _featureChip(Icons.timer, "Nhắc giờ lên xe"),
                      _featureChip(Icons.shield_outlined, "Bảo hiểm"),
                      _featureChip(Icons.support_agent, "Hỗ trợ 24/7"),
                      _featureChip(Icons.card_giftcard, "Voucher tuần"),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    decoration: glassSurface(),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.percent, color: accentColor),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Ưu đãi cuối năm", style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 4),
                              const Text("Giảm 15% khi thanh toán online, áp dụng cho tất cả tuyến."),
                            ],
                          ),
                        ),
                        TextButton(onPressed: _goSearch, child: const Text("Đặt ngay")),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          if (index == 1) {
            Navigator.pushReplacementNamed(context, AppRoutes.ticketList);
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, AppRoutes.profile);
          } else {
            setState(() => currentIndex = index);
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: "Trang chủ"),
          BottomNavigationBarItem(icon: Icon(Icons.confirmation_num_outlined), label: "Vé của tôi"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Hồ sơ"),
        ],
      ),
    );
  }

  void _swapLocations() {
    final currentFrom = fromCtrl.text;
    fromCtrl.text = toCtrl.text;
    toCtrl.text = currentFrom;
    setState(() {});
  }

  Future<void> _selectDateForRoute(BuildContext context, HotRoute route) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (picked == null) return;

    if (!mounted) return;

    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đang tìm chuyến...')),
    );

    try {
      final trips = await TripRepository.instance.searchTrips(
        startLocation: route.startLocation,
        endLocation: route.endLocation,
        departureDate: picked,
      );

      if (!mounted) return;
      Navigator.pushNamed(
        context,
        AppRoutes.tripResults,
        arguments: SearchResult(
          trips: trips,
          startLocation: route.startLocation,
          endLocation: route.endLocation,
          departureDate: picked,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tìm kiếm: $e')),
      );
    }
  }

  @override
  void dispose() {
    fromCtrl.dispose();
    toCtrl.dispose();
    super.dispose();
  }
}

Widget _featureChip(IconData icon, String label) {
  return Chip(
    avatar: CircleAvatar(
      backgroundColor: primaryColor.withValues(alpha: 0.12),
      child: Icon(icon, color: primaryColor, size: 18),
    ),
    label: Text(label),
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
  );
}

Widget _metricChip(String value, String label) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.18),
      borderRadius: AppRadius.medium,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}

Widget _locationDropdown({
  required String label,
  required String hint,
  required IconData icon,
  required TextEditingController controller,
  required List<String> items,
}) {
  return DropdownButtonFormField<String>(
    initialValue: items.contains(controller.text) ? controller.text : null,
    items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
    onChanged: (value) {
      if (value != null) controller.text = value;
    },
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
    ),
  );
}
