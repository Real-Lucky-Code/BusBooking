import 'package:flutter/material.dart';

import '../models/mock_data.dart';

/// Hỗ trợ 5 loại xe:
/// - Limousine giường đôi 22 phòng: Tầng dưới 12 (2 dãy×6), Tầng trên 10 (2 dãy×5)
/// - Xe tiêu chuẩn 41 chỗ: Tầng dưới 18 (3 dãy×6), Tầng trên 23 (3 dãy×6 + hàng cuối 5)
/// - Xe Limousine 34 chỗ: Tầng dưới 16 (3 dãy: 4+8+4), Tầng trên 18 (3 dãy×6)
/// - Xe tiêu chuẩn 45 chỗ: Tầng dưới 21 (3 dãy×7), Tầng trên 24 (3 dãy×8)
/// - Limousine giường đôi 24 phòng: Tầng dưới 12 (2 dãy×6), Tầng trên 12 (2 dãy×6)

class SeatLayout extends StatelessWidget {
  const SeatLayout({
    super.key,
    required this.seats,
    required this.busType,
    required this.selected,
    required this.onToggle,
  });

  final List<SeatOption> seats;
  final String busType; // 'Sleeper', 'Limousine', etc.
  final Set<int> selected;
  final Function(int) onToggle;

  @override
  Widget build(BuildContext context) {
    final layoutData = _generateLayout();
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // Luôn dùng layout ngang, ghế sẽ tự thu nhỏ khi màn hình hẹp
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              flex: 1,
              child: _buildFloor('TẦNG DƯỚI', layoutData['lower']!, context),
            ),
            const SizedBox(width: 12),
            Flexible(
              flex: 1,
              child: _buildFloor('TẦNG TRÊN', layoutData['upper']!, context),
            ),
          ],
        );
      },
    );
  }

  /// Tạo layout dựa vào loại xe và số ghế
  Map<String, List<List<SeatInfo>>> _generateLayout() {
    final lower = <List<SeatInfo>>[];
    final upper = <List<SeatInfo>>[];
    final totalSeats = seats.length;

    // Xác định loại xe dựa vào số ghế và tên
    if (totalSeats == 40 || busType.toLowerCase().contains('40') || busType.toLowerCase().contains('tiêu chuẩn 40')) {
      // Xe tiêu chuẩn 40 chỗ: 20 dưới (7+6+7), 20 trên (7+6+7)
      lower.add(_createRow(seats, 0, 7));
      lower.add(_createRow(seats, 7, 6));
      lower.add(_createRow(seats, 13, 7));
      upper.add(_createRow(seats, 20, 7));
      upper.add(_createRow(seats, 27, 6));
      upper.add(_createRow(seats, 33, 7));
    } else if (totalSeats == 34 || busType.toLowerCase().contains('34') || busType.toLowerCase().contains('limousine 34')) {
      // Limousine 34 chỗ: 17 dưới (6+5+6), 17 trên (6+5+6)
      lower.add(_createRow(seats, 0, 6));
      lower.add(_createRow(seats, 6, 5));
      lower.add(_createRow(seats, 11, 6));
      upper.add(_createRow(seats, 17, 6));
      upper.add(_createRow(seats, 23, 5));
      upper.add(_createRow(seats, 28, 6));
    } else if (totalSeats == 24 || busType.toLowerCase().contains('giường đôi 24') || busType.toLowerCase().contains('double 24')) {
      // Limousine giường đôi 24 phòng: 12 dưới (2 dãy×6), 12 trên (2 dãy×6)
      lower.add(_createRow(seats, 0, 6));
      lower.add(_createRow(seats, 6, 6));
      upper.add(_createRow(seats, 12, 6));
      upper.add(_createRow(seats, 18, 6));
    } else if (totalSeats == 22 || busType.toLowerCase().contains('giường đôi 22') || busType.toLowerCase().contains('double 22')) {
      // Limousine giường đôi 22 phòng: 12 dưới (2 dãy×6), 10 trên (2 dãy×5)
      lower.add(_createRow(seats, 0, 6));
      lower.add(_createRow(seats, 6, 6));
      upper.add(_createRow(seats, 12, 5));
      upper.add(_createRow(seats, 17, 5));
    } else {
      // Fallback: chia đều
      final half = (totalSeats / 2).ceil();
      final lowerRows = (half / 3).ceil();
      final upperRows = ((totalSeats - half) / 3).ceil();
      
      int index = 0;
      for (int i = 0; i < lowerRows && index < half; i++) {
        final count = (half - index).clamp(0, 3);
        lower.add(_createRow(seats, index, count));
        index += count;
      }
      
      for (int i = 0; i < upperRows && index < totalSeats; i++) {
        final count = (totalSeats - index).clamp(0, 3);
        upper.add(_createRow(seats, index, count));
        index += count;
      }
    }

    return {'lower': lower, 'upper': upper};
  }

  /// Tạo một hàng ghế từ chỉ số start và count
  List<SeatInfo> _createRow(List<SeatOption> allSeats, int start, int count) {
    final row = <SeatInfo>[];
    for (int i = 0; i < count && start + i < allSeats.length; i++) {
      final seat = allSeats[start + i];
      row.add(SeatInfo(
        id: seat.id,
        label: seat.label,
        isBooked: seat.isBooked,
      ));
    }
    return row;
  }

  Widget _buildFloor(String floorName, List<List<SeatInfo>> rows, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF12D8C6), Color(0xFF0F9CD5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0FB9B1).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.layers, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(
                floorName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        16.vSpace,
        LayoutBuilder(
          builder: (context, constraints) {
            final isSmall = constraints.maxWidth < 250;
            final padding = isSmall ? 12.0 : 18.0;
            
            return Container(
              padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white,
                const Color(0xFFF8F9FA),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF0FB9B1).withOpacity(0.15),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0FB9B1).withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Các dãy ghế
              LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = MediaQuery.of(context).size.width < 600;
                  final isVerySmall = constraints.maxWidth < 200;
                  final maxSeatSize = isVerySmall ? 38.0 : (isMobile ? 42.0 : 50.0);
                  const minSeatSize = 28.0;
                  final gap = isVerySmall ? 8.0 : 12.0;
                  final columns = rows.isEmpty ? 1 : rows.length;
                  final totalGap = gap * (columns - 1);
                  final available = (constraints.maxWidth - totalGap).clamp(0, constraints.maxWidth);
                  final seatSize = (available / columns).clamp(minSeatSize, maxSeatSize);

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: rows.asMap().entries.map((entry) {
                      final row = entry.value;
                      return Padding(
                        padding: EdgeInsets.only(right: entry.key == rows.length - 1 ? 0 : gap),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Dãy ghế (hiển thị từ trên xuống)
                            Column(
                              spacing: isVerySmall ? 4 : 6,
                              children: row.map((seatInfo) => _buildSeat(seatInfo, seatSize)).toList(),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSeat(SeatInfo seatInfo, double seatSize) {
    final isSelected = selected.contains(seatInfo.id);
    final isBooked = seatInfo.isBooked;
    final fontSize = (seatSize * 0.3).clamp(10.0, 14.0);
    final radius = (seatSize * 0.2).clamp(7.0, 10.0);

    return GestureDetector(
      onTap: isBooked ? null : () => onToggle(seatInfo.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        width: seatSize,
        height: seatSize,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateX(isSelected ? -0.05 : 0),
        decoration: BoxDecoration(
          gradient: isBooked
              ? LinearGradient(
                  colors: [
                    const Color(0xFFE0E0E0),
                    const Color(0xFFBDBDBD).withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : isSelected
                  ? const LinearGradient(
                      colors: [Color(0xFF12D8C6), Color(0xFF0F9CD5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : LinearGradient(
                      colors: [
                        Colors.white,
                        const Color(0xFFF8F9FA),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: isBooked
                ? const Color(0xFFBDBDBD)
                : isSelected
                    ? const Color(0xFF0FB9B1)
                    : const Color(0xFFD0D0D0),
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: [
            if (isSelected) ...[
              BoxShadow(
                color: const Color(0xFF0FB9B1).withOpacity(0.5),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: const Color(0xFF0FB9B1).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ] else if (!isBooked) ...[
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ] else ...[
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ],
        ),
        child: Stack(
          children: [
            // Seat background decoration
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Seat icon
                  Icon(
                    isBooked ? Icons.event_seat : Icons.event_seat_outlined,
                    size: seatSize * 0.35,
                    color: isBooked
                        ? const Color(0xFF9E9E9E)
                        : isSelected
                            ? Colors.white.withOpacity(0.9)
                            : const Color(0xFF0FB9B1).withOpacity(0.6),
                  ),
                  SizedBox(height: seatSize * 0.03),
                  // Seat label (number only)
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: isBooked
                            ? Colors.transparent
                            : isSelected
                                ? Colors.white.withOpacity(0.2)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        seatInfo.label,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                          color: isBooked
                              ? const Color(0xFF9E9E9E)
                              : isSelected
                                  ? Colors.white
                                  : const Color(0xFF424242),
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Check icon for selected seats
            if (isSelected)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: seatSize * 0.22,
                  height: seatSize * 0.22,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.check,
                    size: seatSize * 0.16,
                    color: const Color(0xFF0FB9B1),
                  ),
                ),
              ),
            // Lock icon for booked seats
            if (isBooked)
              Positioned(
                top: 4,
                right: 4,
                child: Icon(
                  Icons.lock,
                  size: seatSize * 0.2,
                  color: const Color(0xFF9E9E9E),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class SeatInfo {
  SeatInfo({
    required this.id,
    required this.label,
    required this.isBooked,
  });

  final int id;
  final String label;
  final bool isBooked;
}
