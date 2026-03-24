import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../config/routes.dart';
import '../../models/mock_data.dart';
import '../../services/ticket_service.dart';
import '../../utils/ticket_pdf_generator.dart';

String getStatusText(String status, DateTime? cancellationRequestedAt) {
  if (cancellationRequestedAt != null) return 'Chờ hủy';
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

class TicketDetailScreen extends StatefulWidget {
  const TicketDetailScreen({super.key, this.ticket});

  final TicketSummary? ticket;

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  bool isRequesting = false;
  String? error;
  final TicketService _ticketService = TicketService();
  late TicketSummary _currentTicket;

  @override
  void initState() {
    super.initState();
    _currentTicket = widget.ticket!;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.ticket == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết vé')),
        body: const Center(child: Text('Không có thông tin vé')),
      );
    }

    final data = _currentTicket;
    final normalizedStatus = data.status.toLowerCase();
    final isDoneOrCancelled = normalizedStatus == 'completed' || normalizedStatus == 'cancelled';
    final normalizedPayment = data.paymentStatus.toLowerCase();
    final isConfirmed =
        normalizedPayment.contains('đã') ||
        normalizedPayment.contains('paid') ||
        normalizedStatus.contains('xác nhận') ||
        normalizedStatus.contains('hoàn tất') ||
        normalizedStatus.contains('confirmed');
    final tripCompleted = data.trip.arrivalTime.isBefore(DateTime.now());
    final canReview = isConfirmed && tripCompleted;

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
        title: Text(
          data.ticketCode.isNotEmpty ? 'Vé ${data.ticketCode}' : 'Vé #${data.id}',
          style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
        ),
        actions: [
          if (!isDoneOrCancelled)
            Container(
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.print_outlined, color: Colors.white),
                tooltip: 'In vé PDF',
                onPressed: () => _printTicketPDF(context, data),
              ),
            ),
        ],
      ),
      backgroundColor: const Color(0xFFF7F7F9),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _summaryCard(data, currency(data.paidAmount), isDoneOrCancelled),
            12.vSpace,
            _sectionCard(
              title: 'Chuyến đi',
              children: [
                _InfoRow(label: 'Tuyến', value: '${data.trip.startLocation} → ${data.trip.endLocation}'),
                _InfoRow(label: 'Khởi hành', value: formatDateTime(data.trip.departureTime)),
                _InfoRow(label: 'Đến nơi', value: formatDateTime(data.trip.arrivalTime)),
                _InfoRow(label: 'Xe', value: '${data.trip.busName} · ${data.trip.busType}'),
                _InfoRow(label: 'Ghế', value: data.seatLabel),
                _InfoRow(label: 'Mã vé', value: data.ticketCode.isNotEmpty ? data.ticketCode : 'Đang cấp'),
              ],
            ),
            12.vSpace,
            _sectionCard(
              title: 'Thanh toán',
              children: [
                _InfoRow(label: 'Phương thức', value: data.paymentMethod),
                _InfoRow(label: 'Trạng thái', value: getPaymentStatusText(data.paymentStatus)),
                _InfoRow(label: 'Số tiền', value: currency(data.paidAmount)),
                _InfoRow(label: 'Thanh toán lúc', value: data.paidAt != null ? formatDateTime(data.paidAt!) : 'Chưa thanh toán'),
              ],
            ),
            if (data.cancellationRequestedAt != null) ...[
              12.vSpace,
              _sectionCard(
                title: 'Thông tin hủy vé',
                children: [
                  _InfoRow(label: 'Trạng thái hủy', value: _ticketService.getCancellationStatusText(data.cancellationStatus)),
                  _InfoRow(label: 'Yêu cầu lúc', value: formatDateTime(data.cancellationRequestedAt!)),
                  if (data.cancellationReason?.isNotEmpty == true)
                    _InfoRow(label: 'Lý do', value: data.cancellationReason!),
                  if (data.cancellationProcessedAt != null)
                    _InfoRow(label: 'Xử lý lúc', value: formatDateTime(data.cancellationProcessedAt!)),
                  if (data.refundAmount != null)
                    _InfoRow(label: 'Số tiền hoàn', value: currency(data.refundAmount!)),
                  if (data.cancellationNote?.isNotEmpty == true)
                    _InfoRow(label: 'Ghi chú', value: data.cancellationNote!),
                ],
              ),
            ],
            12.vSpace,
            _sectionCard(
              title: 'Thông tin khác',
              children: [
                _InfoRow(label: 'Hành khách', value: data.passengerName),
                _InfoRow(label: 'Số điện thoại', value: data.passengerPhone?.isNotEmpty == true ? data.passengerPhone! : 'N/A'),
                _InfoRow(label: 'CCCD/Hộ chiếu', value: data.passengerCCCD?.isNotEmpty == true ? data.passengerCCCD! : 'N/A'),
                _InfoRow(label: 'Tạo lúc', value: formatDateTime(data.createdAt)),
              ],
            ),
            if (error != null) ...[
              8.vSpace,
              Text(error!, style: TextStyle(color: Colors.red.shade700)),
            ],
            12.vSpace,
            if (data.status == 'Booked' &&
                data.cancellationRequestedAt == null &&
                data.status != 'CancellationRequested' &&
                data.status != 'Cancelled' &&
                _ticketService.canCancelTicket(data.trip.departureTime)) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isRequesting ? null : () => _showCancelDialog(data),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                  ),
                  icon: isRequesting
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.cancel_outlined),
                  label: Text(isRequesting ? 'Đang gửi yêu cầu...' : 'Yêu cầu hủy vé'),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Lưu ý: Yêu cầu hủy vé phải chờ nhà xe xác nhận và thông báo hoàn tiền (nếu có).',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
              ),
              12.vSpace,
            ],
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.tripSearch,
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.home_rounded),
                    label: const Text('Về trang chủ'),
                  ),
                ),
                if (!isDoneOrCancelled) ...[
                  12.hSpace,
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _printTicketPDF(context, data),
                      icon: const Icon(Icons.download_outlined),
                      label: const Text('Tải vé PDF'),
                    ),
                  ),
                ],
              ],
            ),
            if (canReview) ...[
              12.vSpace,
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.addReview,
                      arguments: {
                        'busCompanyId': data.trip.id,
                        'busCompanyName': data.trip.busCompanyName.isNotEmpty ? data.trip.busCompanyName : data.trip.busName,
                        'tripId': data.trip.id,
                        'arrivalTime': data.trip.arrivalTime,
                      },
                    );
                  },
                  icon: const Icon(Icons.star_outline),
                  label: const Text('Đánh giá chuyến đi'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.amber.shade600),
                    foregroundColor: Colors.amber.shade700,
                  ),
                ),
              ),
            ],
            if (isConfirmed && !tripCompleted) ...[
              12.vSpace,
              Text(
                'Bạn chỉ có thể đánh giá sau khi chuyến đi đã hoàn thành.',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _printTicketPDF(BuildContext context, TicketSummary ticket) async {
    try {
      final pdfData = await TicketPdfGenerator.generateTicketPdf(ticket);
      await Printing.layoutPdf(
        onLayout: (format) async => pdfData,
        name: 'Vé_${ticket.ticketCode.isNotEmpty ? ticket.ticketCode : ticket.id}.pdf',
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tạo PDF: $e'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  Future<void> _showCancelDialog(TicketSummary ticket) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận hủy vé'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bạn có chắc muốn gửi yêu cầu hủy vé này?', style: TextStyle(color: Colors.grey.shade800)),
            const SizedBox(height: 12),
            const Text('Lý do hủy (tùy chọn):'),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Nhập lý do hủy vé...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Lưu ý: Yêu cầu sẽ được gửi đến nhà xe và chờ xác nhận.',
              style: TextStyle(fontSize: 12, color: Colors.orange.shade700, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade600),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() {
        isRequesting = true;
        error = null;
      });

      try {
        final result = await _ticketService.requestCancellation(
          ticketId: ticket.id,
          reason: reasonController.text.trim().isEmpty ? null : reasonController.text.trim(),
        );

        if (!mounted) return;

        if (result['success'] == true) {
          setState(() {
            _currentTicket = TicketSummary(
              id: _currentTicket.id,
              trip: _currentTicket.trip,
              passengerName: _currentTicket.passengerName,
              status: 'CancellationRequested',
              paidAmount: _currentTicket.paidAmount,
              originalAmount: _currentTicket.originalAmount,
              discountAmount: _currentTicket.discountAmount,
              promoCode: _currentTicket.promoCode,
              paymentMethod: _currentTicket.paymentMethod,
              seatIds: _currentTicket.seatIds,
              seatNumbers: _currentTicket.seatNumbers,
              ticketCode: _currentTicket.ticketCode,
              createdAt: _currentTicket.createdAt,
              paymentStatus: _currentTicket.paymentStatus,
              paidAt: _currentTicket.paidAt,
              passengerPhone: _currentTicket.passengerPhone,
              passengerCCCD: _currentTicket.passengerCCCD,
              cancellationRequestedAt: DateTime.now(),
              cancellationStatus: 'Pending',
              cancellationReason: reasonController.text.trim().isEmpty ? null : reasonController.text.trim(),
              cancellationProcessedAt: _currentTicket.cancellationProcessedAt,
              cancellationNote: _currentTicket.cancellationNote,
              refundAmount: _currentTicket.refundAmount,
            );
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Yêu cầu hủy vé đã được gửi. Vui lòng chờ nhà xe xác nhận.'), backgroundColor: Colors.green.shade600),
          );
        } else {
          setState(() => error = _friendlyError(result['message'] ?? 'Không thể gửi yêu cầu hủy vé'));
        }
      } catch (e) {
        setState(() => error = _friendlyError(e));
      } finally {
        if (mounted) setState(() => isRequesting = false);
      }
    }
    reasonController.dispose();
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}

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

class _TicketPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0FB9B1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const spacing = 30.0;

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

Widget _sectionCard({required String title, required List<Widget> children}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFFFFFFF), Color(0xFFF0FFFD)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFF0FB9B1).withOpacity(0.18)),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF0FB9B1).withOpacity(0.12),
          blurRadius: 20,
          offset: const Offset(0, 12),
          spreadRadius: -6,
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF12D8C6), Color(0xFF0F9CD5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.confirmation_num_rounded, color: Color(0xFFFFFFFF), size: 16),
            ),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1A1A1A))),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    ),
  );
}

Widget _summaryCard(TicketSummary data, String priceText, bool isDoneOrCancelled) {
  final statusLabel = getStatusText(data.status, data.cancellationRequestedAt);
  final paymentLabel = getPaymentStatusText(data.paymentStatus);
  final statusColor = _statusColors(statusLabel);
  final paymentColor = _paymentColors(paymentLabel);

  Widget infoPill(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF0FB9B1).withOpacity(0.2),
          blurRadius: 28,
          offset: const Offset(0, 14),
          spreadRadius: -8,
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0FD9C6), Color(0xFF0F9CD5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.08,
                      child: CustomPaint(painter: _TicketPatternPainter()),
                    ),
                  ),
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: 10,
                        child: CustomPaint(painter: _PerforatedEdgePainter()),
                      ),
                    ),
                  ),
                  Positioned(
                    top: -40,
                    right: -20,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _chip(statusLabel, statusColor),
                          _chip(paymentLabel, paymentColor),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFF6E3), Color(0xFFFFD9A8)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withOpacity(0.35)),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.14), blurRadius: 14, offset: const Offset(0, 8)),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Tổng thanh toán',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade800, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    priceText,
                                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A), letterSpacing: 0.2),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                  child: Row(
                    children: [
                      Flexible(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(formatDateTime(data.trip.departureTime), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text(
                              data.trip.startLocation,
                              style: TextStyle(color: Colors.white.withOpacity(0.85)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFFFFFF), Color(0xFF12D8C6)],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 10, offset: const Offset(0, 4)),
                                  ],
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.directions_bus_filled, size: 16, color: Color(0xFF0F9CD5)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Flexible(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(formatDateTime(data.trip.arrivalTime), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text(
                              data.trip.endLocation,
                              style: TextStyle(color: Colors.white.withOpacity(0.85)),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    infoPill('Ghế ${data.seatLabel}', Icons.event_seat_rounded),
                    infoPill(data.trip.busType, Icons.directions_bus),
                    infoPill(data.paymentMethod, Icons.credit_card),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hành khách', style: TextStyle(color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(data.passengerName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                          const SizedBox(height: 8),
                          Text('Mã đặt chỗ', style: TextStyle(color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(data.ticketCode.isNotEmpty ? data.ticketCode : 'Đang cấp', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 96,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 14, offset: const Offset(0, 6)),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.qr_code_rounded, size: 56, color: Color(0xFF0F9CD5)),
                          const SizedBox(height: 8),
                          Text(
                            data.ticketCode.isNotEmpty ? data.ticketCode.substring(0, data.ticketCode.length > 8 ? 8 : data.ticketCode.length) : 'Pending',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
                            textAlign: TextAlign.center,
                          ),
                          // inline print CTA removed per request
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
  );
}

Widget _chip(String text, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [color.withOpacity(0.9), color],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(10),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.35),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Text(
      text,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
    ),
  );
}

Color _statusColors(String statusLabel) {
  switch (statusLabel) {
    case 'Đã đặt':
      return const Color(0xFF00C6FF);
    case 'Chờ hủy':
      return const Color(0xFFFF6B6B);
    case 'Đã hủy':
      return const Color(0xFFFC9842);
    case 'Hoàn thành':
      return const Color(0xFF00B09B);
    case 'Chờ xử lý':
      return const Color(0xFFFFA45B);
    default:
      return const Color(0xFF0FB9B1);
  }
}

Color _paymentColors(String paymentLabel) {
  switch (paymentLabel) {
    case 'Đã thanh toán':
      return const Color(0xFF1ABC9C);
    case 'Chờ xử lý':
      return const Color(0xFFFFB347);
    case 'Chưa thanh toán':
      return const Color(0xFFEF476F);
    case 'Đã hoàn tiền':
      return const Color(0xFF6C63FF);
    default:
      return const Color(0xFF21D19F);
  }
}
