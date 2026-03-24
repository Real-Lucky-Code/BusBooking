import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../repositories/bus_company_repository.dart';

class CompanySeatLayoutScreen extends StatefulWidget {
  const CompanySeatLayoutScreen({super.key, required this.tripId});

  final int tripId;

  @override
  State<CompanySeatLayoutScreen> createState() => _CompanySeatLayoutScreenState();
}

class _CompanySeatLayoutScreenState extends State<CompanySeatLayoutScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: AppBar(
        title: const Text('Sơ đồ ghế'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showLegend,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        key: ValueKey(widget.tripId),
        future: BusCompanyRepository.instance.getSeats(tripId: widget.tripId),
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
                  Text('Không tải được sơ đồ ghế', style: TextStyle(color: Colors.grey.shade600)),
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

          final seats = snapshot.data ?? [];
          final bookedCount = seats.where((s) => s['isBooked'] == true).length;
          final availableCount = seats.length - bookedCount;

          return Column(
            children: [
              // Stats
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatBox(
                        label: 'Tổng ghế',
                        value: seats.length.toString(),
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatBox(
                        label: 'Đã đặt',
                        value: bookedCount.toString(),
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatBox(
                        label: 'Còn trống',
                        value: availableCount.toString(),
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              // Legend
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendItem(color: Colors.green.shade100, label: 'Trống'),
                const SizedBox(width: 16),
                _LegendItem(color: Colors.red.shade100, label: 'Đã đặt'),
              ],
            ),
          ),
          // Seat layout
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppRadius.large,
                  boxShadow: AppShadows.soft,
                ),
                child: Column(
                  children: [
                    // Driver section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.drive_eta, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 16),
                    // Seats grid (2 columns layout)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.9,
                      ),
                      itemCount: seats.length,
                      itemBuilder: (context, index) {
                        // Add aisle space after column 2
                        if (index % 4 == 2) {
                          return const SizedBox.shrink();
                        }
                        
                        final seatIndex = index - (index ~/ 4);
                        if (seatIndex >= seats.length) {
                          return const SizedBox.shrink();
                        }
                        
                        final seat = seats[seatIndex];
                        return _SeatWidget(
                          seat: seat,
                          onTap: () => _handleSeatTap(seat),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
        },
      ),
    );
  }

  void _handleSeatTap(Map<String, dynamic> seat) {
    if (seat['isBooked'] == true) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Ghế ${seat['number']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Trạng thái: Đã đặt'),
              if (seat['bookedBy'] != null) Text('Khách hàng: ${seat['bookedBy']}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _releaseSeat(seat);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Hủy đặt ghế'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ghế ${seat['number']} đang trống')),
      );
    }
  }

  void _releaseSeat(Map<String, dynamic> seat) async {
    try {
      await BusCompanyRepository.instance.releaseSeat(
        tripId: widget.tripId,
        seatNumber: seat['number'].toString(),
      );
      setState(() {}); // Reload data
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã hủy đặt ghế ${seat['number']}'),
          backgroundColor: Colors.green.shade600,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }

  void _showLegend() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chú thích'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Ghế trống'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Ghế đã đặt'),
              ],
            ),
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

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}

class _SeatWidget extends StatelessWidget {
  const _SeatWidget({
    required this.seat,
    required this.onTap,
  });

  final Map<String, dynamic> seat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isBooked = seat['isBooked'] == true;
    final seatNumber = seat['number'].toString();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isBooked ? Colors.red.shade100 : Colors.green.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isBooked ? Colors.red.shade300 : Colors.green.shade300,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_seat,
              color: isBooked ? Colors.red.shade700 : Colors.green.shade700,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              seatNumber,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isBooked ? Colors.red.shade700 : Colors.green.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
