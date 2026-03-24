import 'package:flutter/material.dart';

import '../../models/mock_data.dart';
import '../../repositories/ticket_repository.dart';
import '../../services/api_client.dart';
import 'booking_success_screen.dart';
import 'payment_screen.dart';

class BookingConfirmationScreen extends StatefulWidget {
  const BookingConfirmationScreen({
    super.key,
    required this.trip,
    required this.selectedSeatIds,
    required this.selectedSeats,
    required this.passenger,
  });

  final TripSummary trip;
  final List<int> selectedSeatIds;
  final List<SeatOption> selectedSeats;
  final PassengerProfile passenger;

  @override
  State<BookingConfirmationScreen> createState() => _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  bool isConfirming = false;
  bool isApplyingPromo = false;
  String? error;
  late PassengerProfile selectedPassenger;
  String paymentMethod = 'Cash';
  final TextEditingController promoCtrl = TextEditingController();
  double discountPercent = 0;
  String? promoMessage;

  @override
  void initState() {
    super.initState();
    selectedPassenger = widget.passenger;
  }

  Future<void> _confirmBooking() async {
    setState(() {
      isConfirming = true;
      error = null;
    });
    try {
      final promoCode = promoCtrl.text.trim().toUpperCase();
      final subtotal = widget.trip.price * widget.selectedSeatIds.length;
      final discountAmount = paymentMethod.toLowerCase() == 'cash'
          ? 0
          : (subtotal * discountPercent).toInt();
      if (paymentMethod.toLowerCase() == 'cash') {
        final ticket = await TicketRepository.instance.bookTicketsBulk(
          tripId: widget.trip.id,
          seatIds: widget.selectedSeatIds,
          passengerProfileId: selectedPassenger.id,
          paymentMethod: paymentMethod,
          promoCode: promoCode.isNotEmpty ? promoCode : null,
          discountAmount: discountAmount,
        );

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => BookingSuccessScreen(ticket: ticket),
          ),
        );
      } else {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentScreen(
              trip: widget.trip,
              selectedSeatIds: widget.selectedSeatIds,
              selectedSeats: widget.selectedSeats,
              passenger: selectedPassenger,
              paymentMethod: paymentMethod,
              discountPercent: discountPercent,
              promoCode: promoCode.isNotEmpty ? promoCode : null,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => error = _friendlyError(e));
    } finally {
      if (mounted) setState(() => isConfirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = widget.trip.price * widget.selectedSeatIds.length;
    final discountAmount = subtotal * discountPercent;
    final total = subtotal - discountAmount;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: AppBar(title: const Text('Xác nhận đặt vé')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thông tin chuyến đi
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Thông tin chuyến đi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    16.vSpace,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.trip.startLocation,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              Text(
                                formatDateTime(widget.trip.departureTime),
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Column(
                            children: [
                              Icon(Icons.arrow_forward, color: Colors.grey.shade400),
                              const SizedBox(height: 4),
                              Text(
                                '${widget.trip.arrivalTime.difference(widget.trip.departureTime).inHours}h',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                widget.trip.endLocation,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              Text(
                                formatDateTime(widget.trip.arrivalTime),
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    12.vSpace,
                    const Divider(),
                    12.vSpace,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Xe', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                              Text(
                                widget.trip.busName,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Loại xe', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                              Text(
                                widget.trip.busType,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
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
            16.vSpace,

            // Ưu đãi / mã giảm giá
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ưu đãi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    12.vSpace,
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: promoCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Nhập mã giảm giá (ví dụ: SALE10, SALE15, TET20)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: isApplyingPromo
                              ? null
                              : () async {
                                  final code = promoCtrl.text.trim().toUpperCase();
                                  if (code.isEmpty) {
                                    setState(() {
                                      discountPercent = 0;
                                      promoMessage = 'Vui lòng nhập mã giảm giá';
                                    });
                                    return;
                                  }
                                  setState(() {
                                    isApplyingPromo = true;
                                    promoMessage = null;
                                  });
                                  try {
                                    final res = await ApiClient.instance.post('/ticket/validate-promo', body: {
                                      'tripId': widget.trip.id,
                                      'seatIds': widget.selectedSeatIds,
                                      'paymentMethod': paymentMethod,
                                      'promoCode': code,
                                    });
                                    final data = res['data'] ?? res;
                                    final percent = (data['discountPercent'] ?? 0) as num;
                                    setState(() {
                                      discountPercent = percent.toDouble();
                                      promoMessage = data['message'] ?? 'Áp dụng mã thành công';
                                    });
                                  } catch (e) {
                                    setState(() {
                                      discountPercent = 0;
                                      promoMessage = _friendlyError(e);
                                    });
                                  } finally {
                                    setState(() => isApplyingPromo = false);
                                  }
                                },
                          child: isApplyingPromo
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Áp dụng'),
                        ),
                      ],
                    ),
                    if (promoMessage != null) ...[
                      8.vSpace,
                      Text(promoMessage!, style: TextStyle(color: discountPercent > 0 ? Colors.green.shade700 : Colors.red.shade700)),
                    ],
                  ],
                ),
              ),
            ),
            16.vSpace,

            // Thông tin ghế và hành khách
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Chi tiết đặt vé', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    16.vSpace,
                    _buildDetailRow(
                      'Ghế đã chọn',
                      widget.selectedSeats.map((s) => s.label).join(', '),
                    ),
                    12.vSpace,
                    _buildDetailRow('Hành khách', selectedPassenger.fullName),
                    12.vSpace,
                    _buildDetailRow('CCCD/Passport', selectedPassenger.identityNumber),
                    12.vSpace,
                    _buildDetailRow('Số điện thoại', selectedPassenger.phone),
                    12.vSpace,
                    _buildDetailRow('Phương thức', paymentMethod),
                  ],
                ),
              ),
            ),
            16.vSpace,

            // Chọn phương thức thanh toán
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Chọn phương thức thanh toán', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    12.vSpace,
                    _buildPaymentOption('Cash', 'Thanh toán tiền mặt khi lên xe'),
                    _buildPaymentOption('MoMo', 'Thanh toán ví MoMo / QR'),
                    _buildPaymentOption('VNPay', 'Thanh toán VNPay / ngân hàng'),
                  ],
                ),
              ),
            ),
            16.vSpace,

            // Tổng tiền
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Giá vé'),
                        Text(currency(widget.trip.price.toInt())),
                      ],
                    ),
                    8.vSpace,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Số ghế'),
                        Text('${widget.selectedSeatIds.length}'),
                      ],
                    ),
                    8.vSpace,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tạm tính'),
                        Text(currency(subtotal.toInt())),
                      ],
                    ),
                    if (discountPercent > 0) ...[
                      8.vSpace,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Giảm giá (${(discountPercent * 100).toStringAsFixed(0)}%)'),
                          Text('- ${currency(discountAmount.toInt())}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                    8.vSpace,
                    const Divider(),
                    8.vSpace,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tổng cộng', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        Text(
                          currency(total.toInt()),
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.blue),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            16.vSpace,

            // Error
            if (error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                child: Text(error!, style: TextStyle(color: Colors.red.shade700)),
              ),
              12.vSpace,
            ],

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isConfirming ? null : () => Navigator.pop(context),
                    child: const Text('Quay lại'),
                  ),
                ),
                12.vSpace,
                Expanded(
                  child: ElevatedButton(
                    onPressed: isConfirming ? null : _confirmBooking,
                    child: isConfirming
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Xác nhận đặt vé'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOption(String method, String subtitle) {
    return RadioListTile<String>(
      value: method,
      groupValue: paymentMethod,
      onChanged: (v) {
        if (v == null) return;
        setState(() => paymentMethod = v);
      },
      title: Text(method),
      subtitle: Text(subtitle),
    );
  }

  String _friendlyError(Object e) {
    final raw = e.toString();
    final idx = raw.indexOf(':');
    if (idx != -1 && idx + 1 < raw.length) {
      final trimmed = raw.substring(idx + 1).trimLeft();
      if (trimmed.isNotEmpty) return trimmed;
    }
    return raw;
  }
}
