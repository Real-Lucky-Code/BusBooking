import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/mock_data.dart';
import '../../repositories/ticket_repository.dart';
import 'booking_success_screen.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({
    super.key,
    required this.trip,
    required this.selectedSeatIds,
    required this.selectedSeats,
    required this.passenger,
    required this.paymentMethod,
    this.discountPercent = 0,
    this.promoCode,
  });

  final TripSummary trip;
  final List<int> selectedSeatIds;
  final List<SeatOption> selectedSeats;
  final PassengerProfile passenger;
  final String paymentMethod;
  final double discountPercent;
  final String? promoCode;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool isPaying = false;
  String? error;
  late final String paymentCode;

  @override
  void initState() {
    super.initState();
    paymentCode = _generatePaymentCode();
  }

  String _generatePaymentCode() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    return 'PAY-${widget.trip.id}-${ts.toString().substring(ts.toString().length - 6)}';
  }

  Future<void> _confirmPaid() async {
    setState(() {
      isPaying = true;
      error = null;
    });
    try {
      final subtotal = widget.trip.price * widget.selectedSeatIds.length;
      final discountAmount = (subtotal * widget.discountPercent).toInt();
      final ticket = await TicketRepository.instance.bookTicketsBulk(
        tripId: widget.trip.id,
        seatIds: widget.selectedSeatIds,
        passengerProfileId: widget.passenger.id,
        paymentMethod: widget.paymentMethod,
        promoCode: widget.promoCode,
        discountAmount: discountAmount,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BookingSuccessScreen(ticket: ticket),
        ),
      );
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => isPaying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = widget.trip.price * widget.selectedSeatIds.length;
    final discountAmount = subtotal * widget.discountPercent;
    final total = subtotal - discountAmount;
    final qrData = _buildQrData(total);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: AppBar(title: const Text('Thanh toán')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Phương thức: ${widget.paymentMethod}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text('Tổng tiền: ${currency(total.toInt())}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (widget.discountPercent > 0) ...[
                      const SizedBox(height: 6),
                      Text('Đã áp dụng giảm ${(widget.discountPercent * 100).toStringAsFixed(0)}% (${currency(discountAmount.toInt())})',
                          style: TextStyle(color: Colors.green.shade700)),
                    ],
                    const SizedBox(height: 8),
                    Text('Ghế: ${widget.selectedSeats.map((s) => s.label).join(', ')}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: Colors.grey.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('Mã thanh toán', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    if (widget.paymentMethod.toLowerCase() == 'cash')
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          'Thanh toán tiền mặt, không cần mã QR\nMã tham chiếu: $paymentCode',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      )
                    else
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: QrImageView(
                              data: qrData,
                              version: QrVersions.auto,
                              size: 200,
                              gapless: true,
                              eyeStyle: const QrEyeStyle(color: Colors.black),
                              dataModuleStyle: const QrDataModuleStyle(color: Colors.black),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Quét QR để thanh toán qua ${widget.paymentMethod}',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Mã tham chiếu: $paymentCode',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                child: Text(error!, style: TextStyle(color: Colors.red.shade700)),
              ),
              const SizedBox(height: 12),
            ],
            ElevatedButton(
              onPressed: isPaying ? null : _confirmPaid,
              child: isPaying
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Tôi đã thanh toán'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: isPaying ? null : () => Navigator.pop(context),
              child: const Text('Quay lại'),
            ),
          ],
        ),
      ),
    );
  }

    String _buildQrData(num total) {
      // Payload đơn giản mang thông tin cần thiết; backend quét/đối soát theo paymentCode
      return [
        'pay',
        widget.paymentMethod,
        'trip:${widget.trip.id}',
        'seats:${widget.selectedSeatIds.join(',')}',
        'amount:${total.toStringAsFixed(0)}',
        'code:$paymentCode',
      ].join('|');
    }
}
