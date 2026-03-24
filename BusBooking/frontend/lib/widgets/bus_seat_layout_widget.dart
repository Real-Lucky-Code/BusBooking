import 'package:flutter/material.dart';

import '../../repositories/bus_company_repository.dart';

class BusSeatLayoutWidget extends StatefulWidget {
  final int busId;
  final String busType;
  final int totalSeats;

  const BusSeatLayoutWidget({
    super.key,
    required this.busId,
    required this.busType,
    required this.totalSeats,
  });

  @override
  State<BusSeatLayoutWidget> createState() => _BusSeatLayoutWidgetState();
}

class _BusSeatLayoutWidgetState extends State<BusSeatLayoutWidget> {
  List<Map<String, dynamic>> seats = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSeats();
  }

  Future<void> _loadSeats() async {
    setState(() => isLoading = true);
    try {
      final data = await BusCompanyRepository.instance.getBusSeats(busId: widget.busId);
      setState(() => seats = data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (seats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_seat, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('Chưa có ghế nào', style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    final layout = _generateLayout();

    return Column(
      children: [
        // Stats
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                label: 'Tổng ghế',
                value: seats.length.toString(),
                color: Colors.blue,
              ),
              _StatItem(
                label: 'Hoạt động',
                value: seats.where((s) => s['isActive'] == true).length.toString(),
                color: Colors.green,
              ),
              _StatItem(
                label: 'Bị khóa',
                value: seats.where((s) => s['isActive'] == false).length.toString(),
                color: Colors.red,
              ),
            ],
          ),
        ),
        const Divider(),
        // Seat layout
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Floor Lower
                if (layout['lower']?.isNotEmpty ?? false) ...[
                  Text('TẦNG DƯỚI', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildFloorLayout(layout['lower']!),
                  const SizedBox(height: 24),
                ],
                // Floor Upper
                if (layout['upper']?.isNotEmpty ?? false) ...[
                  Text('TẦNG TRÊN', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildFloorLayout(layout['upper']!),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Map<String, List<List<Map<String, dynamic>>>> _generateLayout() {
    final lower = <List<Map<String, dynamic>>>[];
    final upper = <List<Map<String, dynamic>>>[];

    if (widget.totalSeats == 40) {
      lower.add(_createRow(0, 7));
      lower.add(_createRow(7, 6));
      lower.add(_createRow(13, 7));
      upper.add(_createRow(20, 7));
      upper.add(_createRow(27, 6));
      upper.add(_createRow(33, 7));
    } else if (widget.totalSeats == 34) {
      lower.add(_createRow(0, 6));
      lower.add(_createRow(6, 5));
      lower.add(_createRow(11, 6));
      upper.add(_createRow(17, 6));
      upper.add(_createRow(23, 5));
      upper.add(_createRow(28, 6));
    } else if (widget.totalSeats == 24) {
      lower.add(_createRow(0, 6));
      lower.add(_createRow(6, 6));
      upper.add(_createRow(12, 6));
      upper.add(_createRow(18, 6));
    } else if (widget.totalSeats == 22) {
      lower.add(_createRow(0, 6));
      lower.add(_createRow(6, 6));
      upper.add(_createRow(12, 5));
      upper.add(_createRow(17, 5));
    }

    return {'lower': lower, 'upper': upper};
  }

  List<Map<String, dynamic>> _createRow(int start, int count) {
    final row = <Map<String, dynamic>>[];
    for (int i = 0; i < count && start + i < seats.length; i++) {
      row.add(seats[start + i]);
    }
    return row;
  }

  Widget _buildFloorLayout(List<List<Map<String, dynamic>>> rows) {
    return Column(
      children: rows
          .map((row) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: row
                      .asMap()
                      .entries
                      .map((entry) {
                        final idx = entry.key;
                        final seat = entry.value;
                        return Padding(
                          padding: EdgeInsets.only(right: idx % 2 == 0 ? 8 : (idx == row.length - 1 ? 0 : 8)),
                          child: _SeatButton(
                            seat: seat,
                            onTap: () => _showSeatDialog(seat),
                          ),
                        );
                      })
                      .toList(),
                ),
              ))
          .toList(),
    );
  }

  void _showSeatDialog(Map<String, dynamic> seat) {
    final nameCtrl = TextEditingController(text: seat['seatNumber'] ?? '');
    bool isActive = seat['isActive'] ?? true;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chỉnh sửa ghế ${seat['seatNumber']}'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tên ghế',
                  hintText: 'A1, B2, ...',
                ),
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Hoạt động'),
                value: isActive,
                onChanged: (value) => setState(() => isActive = value ?? true),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              _updateSeat(seat['id'], nameCtrl.text, isActive);
              Navigator.pop(context);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateSeat(int seatId, String seatNumber, bool isActive) async {
    try {
      await BusCompanyRepository.instance.updateBusSeat(
        busId: widget.busId,
        seatId: seatId,
        seatNumber: seatNumber,
        isActive: isActive,
      );
      await _loadSeats();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật ghế thành công'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

class _SeatButton extends StatelessWidget {
  final Map<String, dynamic> seat;
  final VoidCallback onTap;

  const _SeatButton({required this.seat, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isActive = seat['isActive'] ?? true;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isActive ? Colors.green.shade100 : Colors.red.shade100,
          border: Border.all(color: isActive ? Colors.green : Colors.red),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text(
            seat['seatNumber']?.toString() ?? '?',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.green.shade700 : Colors.red.shade700,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: color, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
