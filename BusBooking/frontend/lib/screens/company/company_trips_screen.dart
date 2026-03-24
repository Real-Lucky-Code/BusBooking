import 'package:flutter/material.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/mock_data.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/bus_company_repository.dart';

class CompanyTripsScreen extends StatefulWidget {
  const CompanyTripsScreen({super.key});

  @override
  State<CompanyTripsScreen> createState() => _CompanyTripsScreenState();
}

class _CompanyTripsScreenState extends State<CompanyTripsScreen> {
  String statusFilter = 'Tất cả'; // Tất cả, Sắp khởi hành, Đã hoàn thành
  String searchQuery = '';
  String startLocationFilter = '';
  String endLocationFilter = '';
  String busTypeFilter = '';
  bool? isActiveFilter; // null = all, true = active, false = inactive
  DateTimeRange? dateRange;

  Future<List<TripSummary>>? _future;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  @override
  Widget build(BuildContext context) {
    final companyId = AuthRepository.instance.currentCompanyId;

    if (companyId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quản lý chuyến đi')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text('Không tìm thấy thông tin công ty',
                  style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: AppBar(
        title: const Text('Quản lý chuyến đi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTrips,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTripDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Thêm chuyến'),
      ),
      body: Column(
        children: [
          // Filters summary
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.filter_alt_outlined, color: Colors.deepPurple),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tất cả chuyến đi',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _filterSummary(),
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                if (statusFilter != 'Tất cả' || isActiveFilter != null || dateRange != null || busTypeFilter.isNotEmpty)
                  TextButton(
                    onPressed: _clearFilters,
                    child: const Text('Xóa lọc'),
                  ),
              ],
            ),
          ),
          // Search + route filters
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  onChanged: (value) => setState(() => searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Tìm nhanh theo tuyến (bất kỳ từ khóa)',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() => searchQuery = ''),
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (v) => startLocationFilter = v,
                        decoration: const InputDecoration(
                          labelText: 'Điểm đi',
                          prefixIcon: Icon(Icons.location_on_outlined),
                          filled: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        onChanged: (v) => endLocationFilter = v,
                        decoration: const InputDecoration(
                          labelText: 'Điểm đến',
                          prefixIcon: Icon(Icons.flag_outlined),
                          filled: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (v) => busTypeFilter = v,
                        decoration: const InputDecoration(
                          labelText: 'Loại xe (Sleeper, Limousine...)',
                          prefixIcon: Icon(Icons.directions_bus_filled_outlined),
                          filled: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _statusDropdownValue(),
                        decoration: const InputDecoration(
                          labelText: 'Trạng thái hoạt động',
                          filled: true,
                        ),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                          DropdownMenuItem(value: 'active', child: Text('Đang bán')),
                          DropdownMenuItem(value: 'inactive', child: Text('Tạm dừng')),
                        ],
                        onChanged: (val) {
                          setState(() {
                            if (val == 'active') {
                              isActiveFilter = true;
                            } else if (val == 'inactive') {
                              isActiveFilter = false;
                            } else {
                              isActiveFilter = null;
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickDateRange,
                        icon: const Icon(Icons.date_range),
                        label: Text(dateRange == null
                            ? 'Chọn khoảng ngày'
                            : '${_fmt(dateRange!.start)} → ${_fmt(dateRange!.end)}'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _applyFilters,
                      icon: const Icon(Icons.tune),
                      label: const Text('Áp dụng'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Trip list
          Expanded(
            child: FutureBuilder<List<TripSummary>>(
              future: _future,
              builder: (context, snapshot) {
                if (_future == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text('Không tải được danh sách chuyến', style: TextStyle(color: Colors.grey.shade600)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => setState(() {}),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                }
                
                final trips = snapshot.data ?? []..sort((a, b) => a.departureTime.compareTo(b.departureTime));
                
                // Client-side filters: keyword + upcoming/past
                var filteredTrips = trips.where((trip) {
                  final matchesKeyword = searchQuery.isEmpty ||
                      trip.startLocation.toLowerCase().contains(searchQuery.toLowerCase()) ||
                      trip.endLocation.toLowerCase().contains(searchQuery.toLowerCase()) ||
                      trip.busName.toLowerCase().contains(searchQuery.toLowerCase());
                  final now = DateTime.now();
                  final isUpcoming = trip.departureTime.isAfter(now);
                  final matchesStatus = statusFilter == 'Tất cả' ||
                      (statusFilter == 'Sắp khởi hành' && isUpcoming) ||
                      (statusFilter == 'Đã hoàn thành' && !isUpcoming);
                  return matchesKeyword && matchesStatus;
                }).toList();
                
                if (trips.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.route_outlined, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('Chưa có chuyến nào', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey.shade600)),
                        const SizedBox(height: 8),
                        Text('Nhấn nút "Thêm chuyến" để bắt đầu', style: TextStyle(color: Colors.grey.shade500)),
                      ],
                    ),
                  );
                }
                
                if (filteredTrips.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text('Không tìm thấy chuyến phù hợp', style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  );
                }
                
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  itemCount: filteredTrips.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final trip = filteredTrips[index];
                    return _TripCard(
                      trip: trip,
                      onEdit: () => _showTripForm(trip: trip),
                      onDelete: () => _confirmDelete(trip),
                      onViewBookings: () => _viewBookings(trip),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Lọc theo trạng thái thời gian', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...['Tất cả', 'Sắp khởi hành', 'Đã hoàn thành'].map((status) => RadioListTile<String>(
                  title: Text(status),
                  value: status,
                  groupValue: statusFilter,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => statusFilter = value);
                      Navigator.pop(context);
                    }
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _showAddTripDialog() {
    _showTripForm();
  }

  void _viewBookings(TripSummary trip) {
    Navigator.pushNamed(
      context,
      AppRoutes.companyBookingList,
      arguments: trip.id,
    );
  }

  Future<void> _confirmDelete(TripSummary trip) async {
    final companyId = AuthRepository.instance.currentCompanyId;
    if (companyId == null) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa chuyến đi'),
        content: Text('Bạn có chắc muốn tạm dừng chuyến ${trip.startLocation} → ${trip.endLocation}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    try {
      await BusCompanyRepository.instance.deleteTrip(companyId: companyId, tripId: trip.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã tạm dừng chuyến')));
        _loadTrips();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xóa thất bại: $e')),
        );
      }
    }
  }

  Future<void> _showTripForm({TripSummary? trip}) async {
    final companyId = AuthRepository.instance.currentCompanyId;
    if (companyId == null) return;

    final formKey = GlobalKey<FormState>();
    final startCtrl = TextEditingController(text: trip?.startLocation ?? '');
    final endCtrl = TextEditingController(text: trip?.endLocation ?? '');
    final priceCtrl = TextEditingController(text: trip?.price.toString() ?? '');
    DateTime departure = trip?.departureTime ?? DateTime.now().add(const Duration(hours: 4));
    DateTime arrival = trip?.arrivalTime ?? departure.add(const Duration(hours: 4));
    int? selectedBusId = trip?.busId;
    bool submitting = false;

    Future<DateTime?> pickDateTime(BuildContext ctx, DateTime initial) async {
      final pickedDate = await showDatePicker(
        context: ctx,
        initialDate: initial,
        firstDate: DateTime.now().subtract(const Duration(days: 1)),
        lastDate: DateTime.now().add(const Duration(days: 365)),
      );
      if (pickedDate == null) return null;
      final pickedTime = await showTimePicker(
        context: ctx,
        initialTime: TimeOfDay.fromDateTime(initial),
      );
      if (pickedTime == null) return null;
      return DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        final busesFuture = BusCompanyRepository.instance.getBuses(companyId: companyId);
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return FutureBuilder(
                future: busesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
                  }
                  if (snapshot.hasError || snapshot.data == null || (snapshot.data as List).isEmpty) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                        const SizedBox(height: 12),
                        const Text('Không tải được danh sách xe'),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => setSheetState(() {}),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Thử lại'),
                        ),
                      ],
                    );
                  }

                  final buses = snapshot.data!;
                  selectedBusId ??= buses.first.id;

                  return SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(trip == null ? 'Thêm chuyến mới' : 'Cập nhật chuyến', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<int>(
                            initialValue: selectedBusId,
                            decoration: const InputDecoration(labelText: 'Chọn xe'),
                            items: buses
                                .map<DropdownMenuItem<int>>((bus) => DropdownMenuItem(
                                      value: bus.id,
                                      child: Text('${bus.licensePlate} • ${bus.type} (${bus.totalSeats} ghế)'),
                                    ))
                                .toList(),
                            onChanged: submitting
                                ? null
                                : (val) => setSheetState(() {
                                      selectedBusId = val;
                                    }),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: startCtrl,
                            decoration: const InputDecoration(labelText: 'Điểm đi'),
                            validator: (v) => (v == null || v.isEmpty) ? 'Nhập điểm đi' : null,
                            enabled: !submitting,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: endCtrl,
                            decoration: const InputDecoration(labelText: 'Điểm đến'),
                            validator: (v) => (v == null || v.isEmpty) ? 'Nhập điểm đến' : null,
                            enabled: !submitting,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: priceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Giá vé'),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Nhập giá vé';
                              return int.tryParse(v) != null ? null : 'Giá không hợp lệ';
                            },
                            enabled: !submitting,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: submitting
                                      ? null
                                      : () async {
                                          final picked = await pickDateTime(context, departure);
                                          if (picked != null) {
                                            setSheetState(() {
                                              departure = picked;
                                              if (!picked.isBefore(arrival)) {
                                                arrival = picked.add(const Duration(hours: 2));
                                              }
                                            });
                                          }
                                        },
                                  icon: const Icon(Icons.departure_board),
                                  label: Text('Đi: ${formatDateTime(departure)}'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: submitting
                                      ? null
                                      : () async {
                                          final picked = await pickDateTime(context, arrival);
                                          if (picked != null) {
                                            setSheetState(() => arrival = picked);
                                          }
                                        },
                                  icon: const Icon(Icons.schedule),
                                  label: Text('Đến: ${formatDateTime(arrival)}'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: submitting
                                  ? null
                                  : () async {
                                      if (!formKey.currentState!.validate() || selectedBusId == null) return;
                                      setSheetState(() => submitting = true);
                                      try {
                                        if (trip == null) {
                                          await BusCompanyRepository.instance.createTrip(
                                            companyId: companyId,
                                            busId: selectedBusId!,
                                            startLocation: startCtrl.text,
                                            endLocation: endCtrl.text,
                                            departureTime: departure,
                                            arrivalTime: arrival,
                                            price: int.parse(priceCtrl.text),
                                          );
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Đã tạo chuyến mới')),
                                            );
                                          }
                                        } else {
                                          await BusCompanyRepository.instance.updateTrip(
                                            companyId: companyId,
                                            tripId: trip.id,
                                            busId: selectedBusId!,
                                            startLocation: startCtrl.text,
                                            endLocation: endCtrl.text,
                                            departureTime: departure,
                                            arrivalTime: arrival,
                                            price: int.parse(priceCtrl.text),
                                          );
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Đã cập nhật chuyến')),
                                            );
                                          }
                                        }
                                        if (mounted) {
                                          Navigator.pop(context);
                                          _loadTrips();
                                        }
                                      } catch (e) {
                                        setSheetState(() => submitting = false);
                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                                        }
                                      }
                                    },
                              icon: submitting
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : Icon(trip == null ? Icons.add : Icons.save),
                              label: Text(trip == null ? 'Tạo chuyến' : 'Lưu thay đổi'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  void _loadTrips() {
    final companyId = AuthRepository.instance.currentCompanyId;
    if (companyId == null) return;
    setState(() {
      _future = BusCompanyRepository.instance.getTrips(
        companyId: companyId,
        dateFrom: dateRange?.start,
        dateTo: dateRange?.end,
        startLocation: startLocationFilter,
        endLocation: endLocationFilter,
        busType: busTypeFilter,
        isActive: isActiveFilter,
      );
    });
  }

  void _applyFilters() {
    _loadTrips();
  }

  void _clearFilters() {
    setState(() {
      statusFilter = 'Tất cả';
      searchQuery = '';
      startLocationFilter = '';
      endLocationFilter = '';
      busTypeFilter = '';
      isActiveFilter = null;
      dateRange = null;
    });
    _loadTrips();
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 180)),
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: dateRange,
    );
    if (picked != null) {
      setState(() => dateRange = picked);
    }
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';

  String _filterSummary() {
    final parts = <String>[];
    if (dateRange != null) parts.add('${_fmt(dateRange!.start)} → ${_fmt(dateRange!.end)}');
    if (startLocationFilter.isNotEmpty) parts.add('Đi: $startLocationFilter');
    if (endLocationFilter.isNotEmpty) parts.add('Đến: $endLocationFilter');
    if (busTypeFilter.isNotEmpty) parts.add('Loại: $busTypeFilter');
    if (isActiveFilter != null) parts.add(isActiveFilter == true ? 'Đang bán' : 'Tạm dừng');
    if (statusFilter != 'Tất cả') parts.add(statusFilter);
    if (parts.isEmpty) return 'Đang hiển thị tất cả chuyến, sắp xếp theo ngày khởi hành ↑';
    return parts.join(' · ');
  }

  String _statusDropdownValue() {
    if (isActiveFilter == true) return 'active';
    if (isActiveFilter == false) return 'inactive';
    return 'all';
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({
    required this.trip,
    required this.onEdit,
    required this.onDelete,
    required this.onViewBookings,
  });

  final TripSummary trip;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onViewBookings;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isUpcoming = trip.departureTime.isAfter(now);
    final bookedSeats = trip.totalSeats - trip.availableSeats;
    final occupancyRate = (bookedSeats / trip.totalSeats * 100).toStringAsFixed(0);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.medium,
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${trip.startLocation} → ${trip.endLocation}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatDateTime(trip.departureTime),
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isUpcoming ? Colors.blue.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: AppRadius.pill,
                      ),
                      child: Text(
                        isUpcoming ? 'Sắp khởi hành' : 'Đã hoàn thành',
                        style: TextStyle(
                          color: isUpcoming ? Colors.blue.shade700 : Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _InfoChip(icon: Icons.directions_bus, label: trip.busName),
                    const SizedBox(width: 8),
                    _InfoChip(icon: Icons.category, label: trip.busType),
                    const SizedBox(width: 8),
                    _InfoChip(icon: Icons.event_seat, label: '$bookedSeats/${trip.totalSeats} ghế'),
                  ],
                ),
                const SizedBox(height: 12),
                // Occupancy bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Tỷ lệ lấp đầy', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        Text('$occupancyRate%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: AppRadius.small,
                      child: LinearProgressIndicator(
                        value: bookedSeats / trip.totalSeats,
                        minHeight: 6,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation(
                          bookedSeats / trip.totalSeats > 0.8 ? Colors.green : Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Sửa', style: TextStyle(fontSize: 13)),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete, size: 16, color: Colors.redAccent),
                        label: const Text('Xóa', style: TextStyle(fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          foregroundColor: Colors.redAccent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onViewBookings,
                        icon: const Icon(Icons.people, size: 16),
                        label: Text('Khách ($bookedSeats)', style: const TextStyle(fontSize: 13)),
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
