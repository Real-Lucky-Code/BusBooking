import 'package:flutter/material.dart';

import '../../config/routes.dart';
import '../../models/mock_data.dart';
import '../../repositories/location_repository.dart';
import '../../repositories/trip_repository.dart';

class TripSearchScreen extends StatefulWidget {
  const TripSearchScreen({super.key});

  @override
  State<TripSearchScreen> createState() => _TripSearchScreenState();
}

class _TripSearchScreenState extends State<TripSearchScreen> {
  // Danh sách tỉnh lấy từ API
  List<String> provinces = const [];
  bool isLoadingLocations = false;
  String? locationError;

  // Chỉ giữ ba trường: nơi xuất phát, điểm đến, ngày đi
  String? startProvince = 'Hà Nội';
  String? endProvince = 'Đà Nẵng';
  DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
  bool isSearching = false;
  String? error;

  static const List<String> _fallbackProvinces = [
    'Hà Nội', 'TP Hồ Chí Minh', 'Đà Nẵng', 'Hải Phòng', 'Cần Thơ',
    'Quảng Ninh', 'Lào Cai', 'Lạng Sơn', 'Quảng Bình', 'Quảng Trị',
    'Thừa Thiên Huế', 'Quảng Nam', 'Quảng Ngãi', 'Bình Định', 'Phú Yên',
    'Khánh Hòa', 'Ninh Thuận', 'Bình Thuận', 'Gia Lai', 'Kon Tum',
    'Đắk Lắk', 'Đắk Nông', 'Lâm Đồng', 'Bình Dương', 'Bình Phước',
    'Đồng Nai', 'Bà Rịa - Vũng Tàu', 'Long An', 'Tiền Giang', 'Bến Tre',
    'Trà Vinh', 'Vĩnh Long', 'Đồng Tháp', 'An Giang', 'Kiên Giang',
    'Cà Mau', 'Sóc Trăng', 'Bạc Liêu', 'Hậu Giang', 'Tây Ninh',
    'Vĩnh Phúc', 'Bắc Ninh', 'Bắc Giang', 'Thái Nguyên', 'Phú Thọ',
    'Tuyên Quang', 'Yên Bái', 'Hà Giang', 'Cao Bằng', 'Bắc Kạn',
    'Lai Châu', 'Điện Biên', 'Sơn La', 'Hòa Bình', 'Thanh Hóa',
    'Nghệ An', 'Hà Tĩnh', 'Quảng Nam', 'Nam Định', 'Ninh Bình',
    'Thái Bình', 'Hưng Yên'
  ];

  @override
  void initState() {
    super.initState();
    _loadProvinces();
  }

  Future<void> _loadProvinces() async {
    setState(() {
      isLoadingLocations = true;
      locationError = null;
    });
    try {
      final list = await LocationRepository.instance.getProvinces();
      setState(() {
        provinces = list;
        // Nếu giá trị mặc định không nằm trong danh sách, chọn phần tử đầu
        if (!provinces.contains(startProvince)) startProvince = provinces.isNotEmpty ? provinces.first : startProvince;
        if (!provinces.contains(endProvince)) endProvince = provinces.length > 1 ? provinces[1] : provinces.firstOrNull ?? endProvince;
      });
    } catch (e) {
      setState(() {
        locationError = e.toString();
        provinces = _fallbackProvinces;
      });
    } finally {
      if (mounted) {
        setState(() => isLoadingLocations = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Trips'),
        toolbarHeight: 56,
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.ticketList),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.profile),
          ),
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.directions_bus, size: 28),
                8.hSpace,
                const Text('Plan your ride', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              ],
            ),
            16.vSpace,
            _buildProvinceDropdown(
              label: 'Start location',
              value: startProvince,
              icon: Icons.location_on,
              onChanged: (v) => setState(() => startProvince = v),
            ),
            12.vSpace,
            _buildProvinceDropdown(
              label: 'Destination',
              value: endProvince,
              icon: Icons.flag,
              onChanged: (v) => setState(() => endProvince = v),
            ),
            12.vSpace,
            _DatePickerField(
              label: 'Departure date',
              date: selectedDate,
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime.now().subtract(const Duration(days: 1)),
                  lastDate: DateTime.now().add(const Duration(days: 180)),
                  initialDate: selectedDate,
                );
                if (picked != null) {
                  setState(() => selectedDate = picked);
                }
              },
            ),
            12.vSpace,
            ElevatedButton.icon(
              onPressed: isSearching
                  ? null
                  : () async {
                      setState(() {
                        isSearching = true;
                        error = null;
                      });
                      try {
                        final provinceList = provinces.isNotEmpty ? provinces : _fallbackProvinces;
                        final trips = await TripRepository.instance.searchTrips(
                          startLocation: (startProvince ?? provinceList.first).trim(),
                          endLocation: (endProvince ?? provinceList.elementAt(provinceList.length > 1 ? 1 : 0)).trim(),
                          departureDate: selectedDate,
                        );
                        if (!mounted) return;
                        final startLoc = (startProvince ?? provinceList.first).trim();
                        final endLoc = (endProvince ?? provinceList.elementAt(provinceList.length > 1 ? 1 : 0)).trim();
                        Navigator.pushNamed(
                          context,
                          AppRoutes.tripResults,
                          arguments: SearchResult(
                            trips: trips,
                            startLocation: startLoc,
                            endLocation: endLoc,
                            departureDate: selectedDate,
                          ),
                        );
                      } catch (e) {
                        setState(() => error = e.toString());
                      } finally {
                        if (mounted) setState(() => isSearching = false);
                      }
                    },
              icon: isSearching
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.search),
              label: const Text('Search trips'),
            ),
            if (error != null) ...[
              12.vSpace,
              Text(error!, style: TextStyle(color: Colors.red.shade700)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProvinceDropdown({
    required String label,
    required String? value,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    final items = provinces.isNotEmpty ? provinces : _fallbackProvinces;
    return DropdownButtonFormField<String>(
      initialValue: items.contains(value) ? value : items.first,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      items: items
          .map((p) => DropdownMenuItem(value: p, child: Text(p)))
          .toList(),
      onChanged: isLoadingLocations ? null : onChanged,
    );
  }
}


class _DatePickerField extends StatelessWidget {
  const _DatePickerField({required this.label, required this.date, required this.onTap});
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${date.day}/${date.month}/${date.year}'),
            const Icon(Icons.calendar_today, size: 18),
          ],
        ),
      ),
    );
  }
}
