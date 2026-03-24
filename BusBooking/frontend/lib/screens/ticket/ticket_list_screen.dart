import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../config/routes.dart';
import '../../models/mock_data.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/ticket_repository.dart';

String getStatusText(String status, DateTime? cancellationRequestedAt) {
  if (cancellationRequestedAt != null) {
    return 'Chờ hủy';
  }
  switch (status.toLowerCase()) {
    case 'booked':
      return 'Đã đặt';
    case 'cancelled':
      return 'Đã hủy';
    case 'cancellationrequested':
      return 'Chờ hủy';
    case 'completed':
      return 'Hoàn thành';
    case 'pending':
      return 'Chờ xử lý';
    default:
      return status;
  }
}

String getPaymentStatusText(String paymentStatus) {
  switch (paymentStatus.toLowerCase()) {
    case 'paid':
      return 'Đã thanh toán';
    case 'unpaid':
      return 'Chưa thanh toán';
    case 'pending':
      return 'Chờ xử lý';
    case 'refunded':
      return 'Đã hoàn tiền';
    default:
      return paymentStatus;
  }
}

class TicketListScreen extends StatefulWidget {
  const TicketListScreen({super.key});

  @override
  State<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends State<TicketListScreen> {
  late Future<List<TicketSummary>> futureTickets;
  String selectedStatus = 'Tất cả';
  String selectedSort = 'Mới nhất';
  DateTimeRange? selectedDateRange;

  @override
  void initState() {
    super.initState();
    final userId = AuthRepository.instance.currentUser?.id ?? 1;
    futureTickets = TicketRepository.instance.getUserTickets(userId);
  }

  List<TicketSummary> _filterAndSortTickets(List<TicketSummary> tickets) {
    var filtered = tickets;

    // Filter by status
    if (selectedStatus != 'Tất cả') {
      filtered = filtered.where((t) {
        switch (selectedStatus) {
          case 'Đã đặt':
            return t.status == 'Booked' && t.cancellationRequestedAt == null;
          case 'Đã hủy':
            return t.status == 'Cancelled';
          case 'Chờ hủy':
            return t.status == 'CancellationRequested' || t.cancellationRequestedAt != null;
          case 'Hoàn thành':
            return t.status == 'Completed';
          default:
            return true;
        }
      }).toList();
    }

    // Filter by date range
    if (selectedDateRange != null) {
      filtered = filtered.where((t) {
        final departureDate = DateTime(t.trip.departureTime.year, t.trip.departureTime.month, t.trip.departureTime.day);
        final startDate = DateTime(selectedDateRange!.start.year, selectedDateRange!.start.month, selectedDateRange!.start.day);
        final endDate = DateTime(selectedDateRange!.end.year, selectedDateRange!.end.month, selectedDateRange!.end.day);
        return (departureDate.isAtSameMomentAs(startDate) || departureDate.isAfter(startDate)) &&
               (departureDate.isAtSameMomentAs(endDate) || departureDate.isBefore(endDate));
      }).toList();
    }

    // Sort
    switch (selectedSort) {
      case 'Mới nhất':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'Cũ nhất':
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'Giá cao':
        filtered.sort((a, b) => b.paidAmount.compareTo(a.paidAmount));
        break;
      case 'Giá thấp':
        filtered.sort((a, b) => a.paidAmount.compareTo(b.paidAmount));
        break;
      case 'Khởi hành sớm':
        filtered.sort((a, b) => a.trip.departureTime.compareTo(b.trip.departureTime));
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF12D8C6), Color(0xFF0F9CD5)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        title: const Text(
          'Vé của tôi',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.filter_list_rounded, color: Colors.white),
              onPressed: _showFilterDialog,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips với gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF0FB9B1).withOpacity(0.05),
                  Colors.white,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  _FilterChip(
                    label: selectedStatus,
                    icon: Icons.filter_alt_rounded,
                    onTap: _showStatusFilter,
                  ),
                  const SizedBox(width: 10),
                  _FilterChip(
                    label: selectedSort,
                    icon: Icons.sort_rounded,
                    onTap: _showSortOptions,
                  ),
                  const SizedBox(width: 10),
                  _FilterChip(
                    label: selectedDateRange == null 
                        ? 'Chọn ngày' 
                        : '${selectedDateRange!.start.day}/${selectedDateRange!.start.month} - ${selectedDateRange!.end.day}/${selectedDateRange!.end.month}',
                    icon: Icons.date_range_rounded,
                    onTap: _showDateRangePicker,
                    onClear: selectedDateRange != null ? () => setState(() => selectedDateRange = null) : null,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<TicketSummary>>(
              future: futureTickets,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Lỗi: ${snapshot.error}'));
                }

                final allTickets = snapshot.data ?? [];
                final tickets = _filterAndSortTickets(allTickets);
                
                if (tickets.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF0FB9B1).withOpacity(0.1),
                                const Color(0xFF0F9CD5).withOpacity(0.1),
                              ],
                            ),
                          ),
                          child: Icon(
                            Icons.confirmation_num_outlined,
                            size: 64,
                            color: const Color(0xFF0FB9B1).withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          allTickets.isEmpty ? 'Chưa có vé nào' : 'Không tìm thấy vé',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF424242),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Vé của bạn sẽ xuất hiện ở đây',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return AnimationLimiter(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tickets.length,
              itemBuilder: (context, index) {
                final t = tickets[index];
                final price = t.paidAmount != 0 ? t.paidAmount : t.trip.price;
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 475),
                  child: SlideAnimation(
                    verticalOffset: 50,
                    curve: Curves.easeOutCubic,
                    child: FadeInAnimation(
                      duration: const Duration(milliseconds: 425),
                      child: GestureDetector(
                        onTap: () => Navigator.pushNamed(context, AppRoutes.ticketDetail, arguments: t),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          child: Stack(
                            children: [
                              // Main ticket body
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF0FB9B1).withOpacity(0.15),
                                      blurRadius: 25,
                                      offset: const Offset(0, 10),
                                      spreadRadius: -5,
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white,
                                          const Color(0xFFF8FFFE),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: Stack(
                                      children: [
                                        // Background pattern decoration
                                        Positioned.fill(
                                          child: Opacity(
                                            opacity: 0.03,
                                            child: CustomPaint(
                                              painter: _TicketPatternPainter(),
                                            ),
                                          ),
                                        ),
                                        // Perforated edge effect
                                        Positioned(
                                          left: 0,
                                          top: 0,
                                          bottom: 0,
                                          child: CustomPaint(
                                            size: const Size(8, double.infinity),
                                            painter: _PerforatedEdgePainter(),
                                          ),
                                        ),
                                        // Content
                                        Padding(
                                          padding: const EdgeInsets.all(20),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Top section - Route & Price
                                              Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  // Left - Route info
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            Container(
                                                              width: 10,
                                                              height: 10,
                                                              decoration: BoxDecoration(
                                                                color: const Color(0xFF0FB9B1),
                                                                shape: BoxShape.circle,
                                                                border: Border.all(
                                                                  color: const Color(0xFF0FB9B1).withOpacity(0.3),
                                                                  width: 3,
                                                                ),
                                                              ),
                                                            ),
                                                            Expanded(
                                                              child: Container(
                                                                height: 2,
                                                                margin: const EdgeInsets.symmetric(horizontal: 8),
                                                                decoration: BoxDecoration(
                                                                  gradient: LinearGradient(
                                                                    colors: [
                                                                      const Color(0xFF0FB9B1),
                                                                      const Color(0xFF0FB9B1).withOpacity(0.3),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                            Container(
                                                              width: 10,
                                                              height: 10,
                                                              decoration: BoxDecoration(
                                                                color: Colors.white,
                                                                shape: BoxShape.circle,
                                                                border: Border.all(
                                                                  color: const Color(0xFF0FB9B1),
                                                                  width: 2,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(height: 8),
                                                        Row(
                                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                          children: [
                                                            Flexible(
                                                              child: Text(
                                                                t.trip.startLocation,
                                                                style: const TextStyle(
                                                                  fontSize: 18,
                                                                  fontWeight: FontWeight.w800,
                                                                  color: Color(0xFF1A1A1A),
                                                                  height: 1.2,
                                                                ),
                                                                maxLines: 2,
                                                                overflow: TextOverflow.ellipsis,
                                                              ),
                                                            ),
                                                            const Padding(
                                                              padding: EdgeInsets.symmetric(horizontal: 8),
                                                              child: Icon(
                                                                Icons.arrow_forward_rounded,
                                                                color: Color(0xFF0FB9B1),
                                                                size: 20,
                                                              ),
                                                            ),
                                                            Flexible(
                                                              child: Text(
                                                                t.trip.endLocation,
                                                                style: const TextStyle(
                                                                  fontSize: 18,
                                                                  fontWeight: FontWeight.w800,
                                                                  color: Color(0xFF1A1A1A),
                                                                  height: 1.2,
                                                                ),
                                                                textAlign: TextAlign.right,
                                                                maxLines: 2,
                                                                overflow: TextOverflow.ellipsis,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 16),
                                              // Dashed divider
                                              CustomPaint(
                                                size: const Size(double.infinity, 1),
                                                painter: _DashedLinePainter(),
                                              ),
                                              const SizedBox(height: 16),
                                              // Middle section - Details
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: _buildTicketInfo(
                                                      Icons.schedule_rounded,
                                                      'Giờ khởi hành',
                                                      formatDateTime(t.trip.departureTime),
                                                    ),
                                                  ),
                                                  Container(
                                                    width: 1,
                                                    height: 40,
                                                    color: Colors.grey.shade200,
                                                  ),
                                                  Expanded(
                                                    child: _buildTicketInfo(
                                                      Icons.event_seat_rounded,
                                                      'Ghế',
                                                      t.seatLabel,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: _buildTicketInfo(
                                                      Icons.person_rounded,
                                                      'Hành khách',
                                                      t.passengerName,
                                                    ),
                                                  ),
                                                  Container(
                                                    width: 1,
                                                    height: 40,
                                                    color: Colors.grey.shade200,
                                                  ),
                                                  Expanded(
                                                    child: _buildTicketInfo(
                                                      Icons.directions_bus_rounded,
                                                      'Xe',
                                                      t.trip.busName,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 16),
                                              // Bottom section - Payment & Code
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Container(
                                                      padding: const EdgeInsets.all(12),
                                                      decoration: BoxDecoration(
                                                        gradient: LinearGradient(
                                                          colors: [
                                                            const Color(0xFF0FB9B1).withOpacity(0.08),
                                                            const Color(0xFF0F9CD5).withOpacity(0.08),
                                                          ],
                                                        ),
                                                        borderRadius: BorderRadius.circular(12),
                                                        border: Border.all(
                                                          color: const Color(0xFF0FB9B1).withOpacity(0.2),
                                                          width: 1,
                                                        ),
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          Icon(
                                                            Icons.credit_card_rounded,
                                                            color: const Color(0xFF0FB9B1),
                                                            size: 18,
                                                          ),
                                                          const SizedBox(width: 8),
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Text(
                                                                  t.paymentMethod.isNotEmpty ? t.paymentMethod : 'Chưa thanh toán',
                                                                  style: const TextStyle(
                                                                    fontSize: 11,
                                                                    fontWeight: FontWeight.w600,
                                                                    color: Color(0xFF666666),
                                                                  ),
                                                                ),
                                                                const SizedBox(height: 2),
                                                                Text(
                                                                  currency(price),
                                                                  style: const TextStyle(
                                                                    fontSize: 20,
                                                                    fontWeight: FontWeight.w900,
                                                                    color: Color(0xFF0FB9B1),
                                                                    letterSpacing: -0.5,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey.shade100,
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                    child: Column(
                                                      children: [
                                                        Icon(
                                                          Icons.qr_code_rounded,
                                                          color: Colors.grey.shade700,
                                                          size: 32,
                                                        ),
                                                        const SizedBox(height: 4),
                                                        Text(
                                                          t.ticketCode.isNotEmpty ? t.ticketCode.substring(0, t.ticketCode.length > 8 ? 8 : t.ticketCode.length) : 'Pending',
                                                          style: TextStyle(
                                                            fontSize: 9,
                                                            fontWeight: FontWeight.w600,
                                                            color: Colors.grey.shade600,
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
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              // Floating status badge
                              Positioned(
                                top: 0,
                                right: 16,
                                child: _buildFloatingStatusBadge(
                                  getStatusText(t.status, t.cancellationRequestedAt),
                                  getPaymentStatusText(t.paymentStatus),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    ),
  ],
),
      backgroundColor: const Color(0xFFF5F7FA),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: 1,
          onTap: (index) {
            if (index == 0) {
              Navigator.pushReplacementNamed(context, AppRoutes.tripSearch);
            } else if (index == 2) {
              Navigator.pushReplacementNamed(context, AppRoutes.profile);
            }
          },
          selectedItemColor: const Color(0xFF0FB9B1),
          unselectedItemColor: Colors.grey.shade600,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Trang chủ'),
            BottomNavigationBarItem(icon: Icon(Icons.confirmation_num_rounded), label: 'Vé của tôi'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Hồ sơ'),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            const Text('Lọc & Sắp xếp', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.filter_alt),
              title: const Text('Trạng thái'),
              subtitle: Text(selectedStatus),
              onTap: () {
                Navigator.pop(context);
                _showStatusFilter();
              },
            ),
            ListTile(
              leading: const Icon(Icons.sort),
              title: const Text('Sắp xếp'),
              subtitle: Text(selectedSort),
              onTap: () {
                Navigator.pop(context);
                _showSortOptions();
              },
            ),
            ListTile(
              leading: const Icon(Icons.date_range),
              title: const Text('Khoảng thời gian'),
              subtitle: Text(selectedDateRange == null 
                  ? 'Chưa chọn' 
                  : '${selectedDateRange!.start.day}/${selectedDateRange!.start.month}/${selectedDateRange!.start.year} - ${selectedDateRange!.end.day}/${selectedDateRange!.end.month}/${selectedDateRange!.end.year}'),
              onTap: () {
                Navigator.pop(context);
                _showDateRangePicker();
              },
            ),
          ],
        ),
      ),
      ),
    );
  }

  void _showStatusFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            const Text('Lọc theo trạng thái', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...[
              'Tất cả',
              'Đã đặt',
              'Chờ hủy',
              'Đã hủy',
              'Hoàn thành',
            ].map((status) => RadioListTile<String>(
              title: Text(status),
              value: status,
              groupValue: selectedStatus,
              onChanged: (value) {
                setState(() => selectedStatus = value!);
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            const Text('Sắp xếp theo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...[
              'Mới nhất',
              'Cũ nhất',
              'Giá cao',
              'Giá thấp',
              'Khởi hành sớm',
            ].map((sort) => RadioListTile<String>(
              title: Text(sort),
              value: sort,
              groupValue: selectedSort,
              onChanged: (value) {
                setState(() => selectedSort = value!);
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
      ),
    );
  }

  Future<void> _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: selectedDateRange,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: Colors.deepPurple),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() => selectedDateRange = picked);
    }
  }

  Widget _modernInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0FB9B1).withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF0FB9B1).withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: const Color(0xFF0FB9B1),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Color(0xFF424242),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketInfo(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: const Color(0xFF0FB9B1),
            size: 20,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingStatusBadge(String status, String paymentStatus) {
    Color bgStart;
    Color bgEnd;
    Color textColor = Colors.white;
    IconData icon;
    
    switch (status) {
      case 'Đã đặt':
        bgStart = const Color(0xFF00C6FF);
        bgEnd = const Color(0xFF0072FF);
        icon = Icons.check_circle_rounded;
        break;
      case 'Chờ hủy':
        bgStart = const Color(0xFFFFA751);
        bgEnd = const Color(0xFFFF6B6B);
        icon = Icons.schedule_rounded;
        break;
      case 'Đã hủy':
        bgStart = const Color(0xFFFE5F75);
        bgEnd = const Color(0xFFFC9842);
        icon = Icons.cancel_rounded;
        break;
      case 'Hoàn thành':
        bgStart = const Color(0xFF00B09B);
        bgEnd = const Color(0xFF96C93D);
        icon = Icons.verified_rounded;
        break;
      case 'Chờ xử lý':
        bgStart = const Color(0xFF7F7FD5);
        bgEnd = const Color(0xFF86A8E7);
        icon = Icons.access_time_rounded;
        break;
      default:
        bgStart = const Color(0xFF12D8C6);
        bgEnd = const Color(0xFF0F9CD5);
        icon = Icons.info_rounded;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            bgStart,
            bgEnd,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: bgEnd.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                status,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              Text(
                paymentStatus,
                style: TextStyle(
                  color: textColor.withOpacity(0.9),
                  fontWeight: FontWeight.w600,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade700),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _statusChip(String label) {
    Color bgColor;
    Color textColor;
    IconData icon;
    
    switch (label) {
      case 'Đã đặt':
        bgColor = const Color(0xFF0FB9B1).withOpacity(0.15);
        textColor = const Color(0xFF0FB9B1);
        icon = Icons.check_circle_rounded;
        break;
      case 'Chờ hủy':
        bgColor = Colors.orange.withOpacity(0.15);
        textColor = Colors.orange.shade700;
        icon = Icons.schedule_rounded;
        break;
      case 'Đã hủy':
        bgColor = Colors.red.withOpacity(0.15);
        textColor = Colors.red.shade700;
        icon = Icons.cancel_rounded;
        break;
      case 'Hoàn thành':
        bgColor = Colors.green.withOpacity(0.15);
        textColor = Colors.green.shade700;
        icon = Icons.verified_rounded;
        break;
      case 'Chờ xử lý':
        bgColor = Colors.grey.withOpacity(0.15);
        textColor = Colors.grey.shade700;
        icon = Icons.access_time_rounded;
        break;
      default:
        bgColor = const Color(0xFF0FB9B1).withOpacity(0.15);
        textColor = const Color(0xFF0FB9B1);
        icon = Icons.info_rounded;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: textColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.white, Color(0xFFFAFAFA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF0FB9B1).withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0FB9B1).withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF12D8C6), Color(0xFF0F9CD5)],
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 14, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Color(0xFF424242),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onClear != null) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onClear,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close, size: 14, color: Colors.grey.shade700),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Custom painter for perforated edge
class _PerforatedEdgePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0FB9B1).withOpacity(0.15)
      ..style = PaintingStyle.fill;

    const circleRadius = 4.0;
    const spacing = 12.0;
    
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawCircle(
        Offset(circleRadius, y),
        circleRadius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom painter for dashed line
class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashWidth = 8.0;
    const dashSpace = 5.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom painter for background pattern
class _TicketPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0FB9B1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const spacing = 30.0;
    
    // Draw diagonal lines
    for (double i = -size.height; i < size.width; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

