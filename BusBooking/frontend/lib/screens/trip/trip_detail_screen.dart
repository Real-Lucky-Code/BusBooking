import 'package:flutter/material.dart';
import '../../models/mock_data.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../repositories/trip_repository.dart';
import '../../widgets/seat_layout.dart';
import 'booking_confirmation_screen.dart';

class TripDetailScreen extends StatefulWidget {
  const TripDetailScreen({super.key, this.trip});

  final TripSummary? trip;

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  final Set<int> selectedSeats = {};
  bool isBooking = false;
  String? error;
  TripSummary? tripDetails;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // Always clear selected seats for new trip
    selectedSeats.clear();
    if (widget.trip != null) {
      _loadTripDetails();
    }
  }

  @override
  void didUpdateWidget(TripDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset selected seats when trip changes
    if (oldWidget.trip?.id != widget.trip?.id) {
      setState(() {
        selectedSeats.clear();
        error = null;
      });
      if (widget.trip != null) {
        _loadTripDetails();
      }
    }
  }

  Future<void> _loadTripDetails() async {
    setState(() => isLoading = true);
    try {
      final details = await TripRepository.instance.getTripDetail(widget.trip!.id);
      setState(() {
        tripDetails = details;
        // Reset selected seats when loading a new trip
        selectedSeats.clear();
        error = null;
      });
    } catch (e) {
      setState(() => error = 'Không thể tải chi tiết chuyến đi: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.trip == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết chuyến đi')),
        body: const Center(child: Text('Không có thông tin chuyến đi')),
      );
    }

    final trip = tripDetails ?? widget.trip!;
    
    // Tính tổng tiền dựa trên ghế đã chọn
    final totalPrice = selectedSeats.fold<double>(0.0, (sum, seatId) {
      try {
        final seat = trip.seats.firstWhere((s) => s.id == seatId);
        // Nếu ghế có giá thì dùng giá ghế, không thì dùng giá chuyến
        return sum + (seat.price > 0 ? seat.price : trip.price);
      } catch (e) {
        // Nếu không tìm thấy ghế, dùng giá chuyến
        return sum + trip.price;
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${trip.startLocation} → ${trip.endLocation}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
            ),
            Text(
              formatDateTime(trip.departureTime),
              style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
            ),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: selectedSeats.isEmpty ? 16 : 120,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Trip Info Card với gradient
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF12D8C6), Color(0xFF0F9CD5)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0FB9B1).withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.directions_bus, color: Colors.white, size: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          trip.busName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            trip.busType,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.star, color: Color(0xFFFFA500), size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          trip.rating.toStringAsFixed(1),
                                          style: const TextStyle(
                                            color: Color(0xFF1A1A1A),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _buildInfoItem(
                                        icon: Icons.event_seat,
                                        label: 'Tổng số ghế',
                                        value: '${trip.totalSeats}',
                                      ),
                                    ),
                                    Container(
                                      width: 1,
                                      height: 40,
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                    Expanded(
                                      child: _buildInfoItem(
                                        icon: Icons.check_circle_outline,
                                        label: 'Còn trống',
                                        value: '${trip.availableSeats}',
                                      ),
                                    ),
                                    Container(
                                      width: 1,
                                      height: 40,
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                    Expanded(
                                      child: _buildInfoItem(
                                        icon: Icons.block,
                                        label: 'Đã đặt',
                                        value: '${trip.totalSeats - trip.availableSeats}',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Seat Legend
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Chú thích',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _buildLegendItem(
                                  color: Colors.white,
                                  borderColor: const Color(0xFFD0D0D0),
                                  label: 'Còn trống',
                                  icon: Icons.event_seat_outlined,
                                ),
                                const SizedBox(width: 16),
                                _buildLegendItem(
                                  color: const Color(0xFF0FB9B1),
                                  borderColor: const Color(0xFF0FB9B1),
                                  label: 'Đang chọn',
                                  icon: Icons.check_circle,
                                  iconColor: Colors.white,
                                ),
                                const SizedBox(width: 16),
                                _buildLegendItem(
                                  color: Colors.grey.shade300,
                                  borderColor: Colors.grey.shade400,
                                  label: 'Đã đặt',
                                  icon: Icons.block,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Seat Layout Section
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white,
                              const Color(0xFF0FB9B1).withOpacity(0.02),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF0FB9B1).withOpacity(0.2),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0FB9B1).withOpacity(0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF12D8C6), Color(0xFF0F9CD5)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0FB9B1).withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.event_seat,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Chọn ghế của bạn',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'Nhấn vào ghế để chọn hoặc bỏ chọn',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            if (trip.seats.isEmpty)
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.all(32.0),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.event_busy,
                                        size: 64,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Không có thông tin ghế',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              SeatLayout(
                                seats: trip.seats,
                                busType: trip.busType,
                                selected: selectedSeats,
                                onToggle: (id) {
                                  final seat = trip.seats.firstWhere((s) => s.id == id);
                                  if (seat.isBooked) {
                                    // Không cho phép chọn ghế đã đặt
                                    return;
                                  }
                                  setState(() {
                                    if (selectedSeats.contains(id)) {
                                      selectedSeats.remove(id);
                                    } else {
                                      selectedSeats.add(id);
                                    }
                                  });
                                },
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (error != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  error!,
                                  style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Bottom Sticky Bar
                if (selectedSeats.isNotEmpty)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${selectedSeats.length} ghế đã chọn',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF666666),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${totalPrice.toStringAsFixed(0)}₫',
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0FB9B1),
                                        ),
                                      ),
                                    ],
                                  ),
                                  ElevatedButton(
                                    onPressed: isBooking
                                        ? null
                                        : () async {
                                            setState(() {
                                              isBooking = true;
                                              error = null;
                                            });
                                            try {
                                              final userId = AuthRepository.instance.currentUser?.id ?? 1;
                                              final profiles = await ProfileRepository.instance.listPassengerProfiles(userId);
                                              if (profiles.isEmpty) {
                                                throw Exception('Vui lòng tạo hồ sơ hành khách trước khi đặt vé');
                                              }
                                              
                                              // Filter seats: only real seats (positive IDs) from current trip
                                              final validSeatIds = selectedSeats
                                                  .where((seatId) => trip.seats.any((s) => s.id == seatId))
                                                  .toList();
                                              
                                              if (validSeatIds.isEmpty) {
                                                throw Exception('Vui lòng chọn ghế hợp lệ trong chuyến đi này');
                                              }
                                              
                                              final chosenSeats = trip.seats.where((s) => validSeatIds.contains(s.id)).toList();
                                              if (chosenSeats.length != validSeatIds.length) {
                                                throw Exception('Không tìm thấy thông tin ghế đã chọn');
                                              }

                                              if (!mounted) return;
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => BookingConfirmationScreen(
                                                    trip: trip,
                                                    selectedSeatIds: validSeatIds,
                                                    selectedSeats: chosenSeats,
                                                    passenger: profiles.first,
                                                  ),
                                                ),
                                              );
                                            } catch (e) {
                                              setState(() => error = e.toString());
                                            } finally {
                                              if (mounted) setState(() => isBooking = false);
                                            }
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0FB9B1),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: isBooking
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Row(
                                            children: const [
                                              Icon(Icons.arrow_forward, size: 20),
                                              SizedBox(width: 8),
                                              Text(
                                                'Tiếp tục',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
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
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildInfoItem({required IconData icon, required String label, required String value}) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required Color borderColor,
    required String label,
    required IconData icon,
    Color? iconColor,
  }) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: Icon(
              icon,
              size: 14,
              color: iconColor ?? borderColor,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF666666),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
