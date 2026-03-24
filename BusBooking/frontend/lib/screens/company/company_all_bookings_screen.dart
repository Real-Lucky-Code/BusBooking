import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../repositories/bus_company_repository.dart';
import '../../services/api_client.dart';

class CompanyAllBookingsScreen extends StatefulWidget {
  const CompanyAllBookingsScreen({super.key});

  @override
  State<CompanyAllBookingsScreen> createState() => _CompanyAllBookingsScreenState();
}

class _CompanyAllBookingsScreenState extends State<CompanyAllBookingsScreen> {
  String statusFilter = 'all';
  int? tripIdFilter;
  DateTime? fromDateFilter;
  DateTime? toDateFilter;
  String searchQuery = '';
  
  List<Map<String, dynamic>> _allBookings = [];
  List<Map<String, dynamic>> _filteredBookings = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get company ID from current user context
      final myCompanyRes = await ApiClient.instance.get('/buscompany/my-company');
      if (myCompanyRes['hasCompany'] != true || myCompanyRes['company'] == null) {
        setState(() {
          _error = 'Không tìm thấy thông tin nhà xe';
          _isLoading = false;
        });
        return;
      }

      final companyId = myCompanyRes['company']['id'] as int;
      
      // Build query parameters
      final queryParams = <String, String>{};
      if (statusFilter != 'all') queryParams['status'] = statusFilter;
      if (tripIdFilter != null) queryParams['tripId'] = tripIdFilter.toString();
      if (fromDateFilter != null) queryParams['fromDate'] = fromDateFilter!.toIso8601String();
      if (toDateFilter != null) queryParams['toDate'] = toDateFilter!.toIso8601String();

      final queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');
      
      final path = queryString.isEmpty
          ? '/buscompany/$companyId/bookings'
          : '/buscompany/$companyId/bookings?$queryString';
      
      final response = await ApiClient.instance.get(path);
      final bookings = (response['data'] ?? response as List).cast<Map<String, dynamic>>();

      setState(() {
        _allBookings = bookings;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    var filtered = List<Map<String, dynamic>>.from(_allBookings);

    // Apply search query
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((booking) {
        final passengerName = (booking['passengerName'] ?? '').toString().toLowerCase();
        final phone = (booking['passengerPhone'] ?? '').toString();
        final ticketCode = (booking['ticketCode'] ?? '').toString().toLowerCase();
        final seats = (booking['seatNumbers'] as List?)?.join(', ').toLowerCase() ?? '';
        
        final query = searchQuery.toLowerCase();
        return passengerName.contains(query) ||
               phone.contains(query) ||
               ticketCode.contains(query) ||
               seats.contains(query);
      }).toList();
    }

    setState(() {
      _filteredBookings = filtered;
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bộ lọc'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Trạng thái vé:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Tất cả'),
                    selected: statusFilter == 'all',
                    onSelected: (selected) {
                      if (selected) setState(() => statusFilter = 'all');
                    },
                  ),
                  FilterChip(
                    label: const Text('Đã đặt'),
                    selected: statusFilter == 'Booked',
                    onSelected: (selected) {
                      if (selected) setState(() => statusFilter = 'Booked');
                    },
                  ),
                  FilterChip(
                    label: const Text('Đã hủy'),
                    selected: statusFilter == 'Cancelled',
                    onSelected: (selected) {
                      if (selected) setState(() => statusFilter = 'Cancelled');
                    },
                  ),
                  FilterChip(
                    label: const Text('Hoàn thành'),
                    selected: statusFilter == 'Completed',
                    onSelected: (selected) {
                      if (selected) setState(() => statusFilter = 'Completed');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: fromDateFilter ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (date != null) {
                          setState(() => fromDateFilter = date);
                        }
                      },
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(
                        fromDateFilter == null
                            ? 'Từ ngày'
                            : DateFormat('dd/MM/yyyy').format(fromDateFilter!),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: toDateFilter ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (date != null) {
                          setState(() => toDateFilter = date);
                        }
                      },
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(
                        toDateFilter == null
                            ? 'Đến ngày'
                            : DateFormat('dd/MM/yyyy').format(toDateFilter!),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
              if (fromDateFilter != null || toDateFilter != null)
                TextButton(
                  onPressed: () {
                    setState(() {
                      fromDateFilter = null;
                      toDateFilter = null;
                    });
                  },
                  child: const Text('Xóa bộ lọc ngày'),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadBookings();
            },
            child: const Text('Áp dụng'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Booked':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      case 'CancellationRequested':
        return Colors.orange;
      case 'Completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'Booked':
        return 'Đã đặt';
      case 'Cancelled':
        return 'Đã hủy';
      case 'CancellationRequested':
        return 'Yêu cầu hủy';
      case 'Completed':
        return 'Hoàn thành';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: AppBar(
        title: const Text('Danh sách đặt vé'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBookings,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm theo tên, SĐT, mã vé, ghế...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                  _applyFilters();
                });
              },
            ),
          ),
          
          // Stats summary
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _StatBox(
                    label: 'Tổng vé',
                    value: _allBookings.length.toString(),
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatBox(
                    label: 'Đã đặt',
                    value: _allBookings.where((b) => b['status'] == 'Booked').length.toString(),
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatBox(
                    label: 'Đã hủy',
                    value: _allBookings.where((b) => b['status'] == 'Cancelled').length.toString(),
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Booking list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(_error!, style: TextStyle(color: Colors.grey.shade600)),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _loadBookings,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      )
                    : _filteredBookings.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                Text('Không có vé nào', style: TextStyle(color: Colors.grey.shade600)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredBookings.length,
                            itemBuilder: (context, index) {
                              final booking = _filteredBookings[index];
                              return _BookingCard(
                                booking: booking,
                                onTap: () => _showBookingDetail(booking),
                                statusColor: _getStatusColor(booking['status']),
                                statusText: _getStatusText(booking['status']),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  void _showBookingDetail(Map<String, dynamic> booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BookingDetailSheet(booking: booking),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
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
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  final VoidCallback onTap;
  final Color statusColor;
  final String statusText;

  const _BookingCard({
    required this.booking,
    required this.onTap,
    required this.statusColor,
    required this.statusText,
  });

  @override
  Widget build(BuildContext context) {
    final seats = (booking['seatNumbers'] as List?)?.cast<String>() ?? [];
    final departureTime = DateTime.parse(booking['departureTime']);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking['passengerName'] ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          booking['passengerPhone'] ?? 'N/A',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${booking['startLocation']} → ${booking['endLocation']}',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(departureTime),
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                  const Spacer(),
                  Icon(Icons.event_seat, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    seats.join(', '),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.directions_bus, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    booking['busLicensePlate'] ?? 'N/A',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                  const Spacer(),
                  Text(
                    '${NumberFormat('#,###', 'vi_VN').format(booking['totalAmount'])}đ',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookingDetailSheet extends StatelessWidget {
  final Map<String, dynamic> booking;

  const _BookingDetailSheet({required this.booking});

  @override
  Widget build(BuildContext context) {
    final seats = (booking['seatNumbers'] as List?)?.cast<String>() ?? [];
    final createdAt = DateTime.parse(booking['createdAt']);
    final departureTime = DateTime.parse(booking['departureTime']);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Chi tiết đặt vé',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _DetailRow(label: 'Mã vé', value: booking['ticketCode'] ?? 'N/A'),
            _DetailRow(label: 'Trạng thái', value: booking['status'] ?? 'N/A'),
            _DetailRow(label: 'Hành khách', value: booking['passengerName'] ?? 'N/A'),
            _DetailRow(label: 'CCCD', value: booking['passengerCCCD'] ?? 'N/A'),
            _DetailRow(label: 'Số điện thoại', value: booking['passengerPhone'] ?? 'N/A'),
            const Divider(height: 32),
            _DetailRow(label: 'Điểm đi', value: booking['startLocation'] ?? 'N/A'),
            _DetailRow(label: 'Điểm đến', value: booking['endLocation'] ?? 'N/A'),
            _DetailRow(label: 'Thời gian khởi hành', value: DateFormat('dd/MM/yyyy HH:mm').format(departureTime)),
            _DetailRow(label: 'Biển số xe', value: booking['busLicensePlate'] ?? 'N/A'),
            _DetailRow(label: 'Ghế', value: seats.join(', ')),
            const Divider(height: 32),
            _DetailRow(label: 'Tổng tiền', value: '${NumberFormat('#,###', 'vi_VN').format(booking['totalAmount'])}đ'),
            _DetailRow(label: 'Phương thức TT', value: booking['paymentMethod'] ?? 'N/A'),
            _DetailRow(label: 'Ngày đặt', value: DateFormat('dd/MM/yyyy HH:mm').format(createdAt)),
            if (booking['cancellationStatus'] != null) ...[
              const Divider(height: 32),
              _DetailRow(label: 'Trạng thái hủy', value: booking['cancellationStatus']),
              if (booking['cancellationReason'] != null)
                _DetailRow(label: 'Lý do hủy', value: booking['cancellationReason']),
              if (booking['refundAmount'] != null)
                _DetailRow(label: 'Hoàn tiền', value: '${NumberFormat('#,###', 'vi_VN').format(booking['refundAmount'])}đ'),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
