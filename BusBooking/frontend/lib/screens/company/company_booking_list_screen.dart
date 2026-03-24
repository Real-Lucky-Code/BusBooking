import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../repositories/bus_company_repository.dart';

class CompanyBookingListScreen extends StatefulWidget {
  const CompanyBookingListScreen({super.key, required this.tripId});

  final int tripId;

  @override
  State<CompanyBookingListScreen> createState() => _CompanyBookingListScreenState();
}

class _CompanyBookingListScreenState extends State<CompanyBookingListScreen> {
  String statusFilter = 'Tất cả'; // Tất cả, Đã thanh toán, Chưa thanh toán, Đã lên xe
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: AppBar(
        title: const Text('Danh sách khách đặt vé'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        key: ValueKey('${widget.tripId}-$statusFilter-$searchQuery'),
        future: BusCompanyRepository.instance.getBookings(tripId: widget.tripId),
        builder: (context, snapshot) {
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
                  Text('Không tải được danh sách', style: TextStyle(color: Colors.grey.shade600)),
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

          final bookings = snapshot.data ?? [];

          // Filter bookings
          var filteredBookings = bookings.where((booking) {
            final matchesSearch = searchQuery.isEmpty ||
                booking['passengerName'].toString().toLowerCase().contains(searchQuery.toLowerCase()) ||
                booking['phone'].toString().contains(searchQuery) ||
                (booking['seatNumbers'] as List).any((seat) => seat.toString().toLowerCase().contains(searchQuery.toLowerCase()));
            final matchesStatus = statusFilter == 'Tất cả' ||
                (statusFilter == 'Đã thanh toán' && booking['paymentStatus'] == 'Đã thanh toán') ||
                (statusFilter == 'Chưa thanh toán' && booking['paymentStatus'] == 'Chưa thanh toán') ||
                (statusFilter == 'Đã lên xe' && booking['boardingStatus'] == 'Đã lên xe');
            return matchesSearch && matchesStatus;
          }).toList();

          return Column(
            children: [
              // Stats summary
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatBox(
                        label: 'Tổng số vé',
                        value: bookings.length.toString(),
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatBox(
                        label: 'Đã lên xe',
                        value: bookings.where((b) => b['boardingStatus'] == 'Đã lên xe').length.toString(),
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatBox(
                        label: 'Chờ lên xe',
                        value: bookings.where((b) => b['boardingStatus'] == 'Chưa lên xe').length.toString(),
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
              // Search bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  onChanged: (value) => setState(() => searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Tìm theo tên, SĐT hoặc số ghế...',
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
              ),
              // Filter chip
              if (statusFilter != 'Tất cả')
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Chip(
                        label: Text(statusFilter),
                        onDeleted: () => setState(() => statusFilter = 'Tất cả'),
                        deleteIcon: const Icon(Icons.close, size: 16),
                      ),
                    ],
                  ),
                ),
              // Booking list
              Expanded(
                child: filteredBookings.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              bookings.isEmpty ? 'Chưa có vé nào' : 'Không tìm thấy kết quả',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: filteredBookings.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final booking = filteredBookings[index];
                          return _BookingCard(
                            booking: booking,
                            onCheckIn: () => _handleCheckIn(booking),
                            onViewDetails: () => _viewDetails(booking),
                          );
                        },
                      ),
              ),
            ],
          );
        },
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
            const Text('Lọc theo trạng thái', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...['Tất cả', 'Đã thanh toán', 'Chưa thanh toán', 'Đã lên xe'].map((status) => RadioListTile<String>(
              title: Text(status),
              value: status,
              groupValue: statusFilter,
              onChanged: (value) {
                setState(() => statusFilter = value!);
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _handleCheckIn(Map<String, dynamic> booking) async {
    try {
      await BusCompanyRepository.instance.checkInPassenger(
        tripId: widget.tripId,
        ticketId: booking['id'] as int,
      );
      setState(() {}); // Reload data
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(booking['boardingStatus'] == 'Đã lên xe' ? 'Đã hủy check-in' : 'Đã check-in thành công'),
          backgroundColor: Colors.green.shade600,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }

  void _viewDetails(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chi tiết đặt vé'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow(label: 'Họ tên', value: booking['passengerName'].toString()),
            _DetailRow(label: 'Điện thoại', value: booking['phone'].toString()),
            _DetailRow(label: 'Ghế', value: (booking['seatNumbers'] as List).join(', ')),
            _DetailRow(label: 'Thanh toán', value: booking['paymentStatus'].toString()),
            _DetailRow(label: 'Trạng thái', value: booking['boardingStatus'].toString()),
            if (booking['bookingTime'] != null)
              _DetailRow(label: 'Đặt lúc', value: DateTime.parse(booking['bookingTime'].toString()).toString()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppRadius.medium,
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    required this.onCheckIn,
    required this.onViewDetails,
  });

  final Map<String, dynamic> booking;
  final VoidCallback onCheckIn;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    final isBoarded = booking['boardingStatus'] == 'Đã lên xe';
    final isPaid = booking['paymentStatus'] == 'Đã thanh toán';
    final passengerName = booking['passengerName'].toString();
    final phone = booking['phone'].toString();
    final seatNumbers = (booking['seatNumbers'] as List).join(', ');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.medium,
        boxShadow: AppShadows.soft,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      passengerName.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        passengerName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        phone,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isBoarded ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                    borderRadius: AppRadius.pill,
                  ),
                  child: Text(
                    booking['boardingStatus'].toString(),
                    style: TextStyle(
                      color: isBoarded ? Colors.green.shade700 : Colors.orange.shade700,
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
                _InfoChip(icon: Icons.event_seat, label: 'Ghế $seatNumbers'),
                const SizedBox(width: 8),
                _InfoChip(
                  icon: isPaid ? Icons.check_circle : Icons.error,
                  label: booking['paymentStatus'].toString(),
                  color: isPaid ? Colors.green : Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onViewDetails,
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: const Text('Chi tiết', style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: onCheckIn,
                    icon: Icon(isBoarded ? Icons.cancel_outlined : Icons.check_circle_outline, size: 16),
                    label: Text(
                      isBoarded ? 'Hủy check-in' : 'Check-in',
                      style: const TextStyle(fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isBoarded ? Colors.orange : Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? Colors.grey).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// Model class for booking
class BookingInfo {
  final int id;
  final String passengerName;
  final String phone;
  final List<String> seatNumbers;
  final String paymentStatus;
  final DateTime bookingTime;
  final String boardingStatus;

  BookingInfo({
    required this.id,
    required this.passengerName,
    required this.phone,
    required this.seatNumbers,
    required this.paymentStatus,
    required this.bookingTime,
    required this.boardingStatus,
  });

  BookingInfo copyWith({
    int? id,
    String? passengerName,
    String? phone,
    List<String>? seatNumbers,
    String? paymentStatus,
    DateTime? bookingTime,
    String? boardingStatus,
  }) {
    return BookingInfo(
      id: id ?? this.id,
      passengerName: passengerName ?? this.passengerName,
      phone: phone ?? this.phone,
      seatNumbers: seatNumbers ?? this.seatNumbers,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      bookingTime: bookingTime ?? this.bookingTime,
      boardingStatus: boardingStatus ?? this.boardingStatus,
    );
  }
}
