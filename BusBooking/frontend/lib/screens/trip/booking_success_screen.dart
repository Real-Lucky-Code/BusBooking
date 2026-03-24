import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/mock_data.dart';
import '../../utils/ticket_pdf_generator.dart';

class BookingSuccessScreen extends StatelessWidget {
  const BookingSuccessScreen({super.key, required this.ticket});

  final TicketSummary ticket;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Đặt vé thành công'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                size: 80,
                color: Colors.green.shade600,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Đặt vé thành công!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.green.shade700,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Vé điện tử của bạn đã được tạo',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey.shade600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.confirmation_number, color: primaryColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mã vé',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              ticket.ticketCode.isNotEmpty ? ticket.ticketCode : '#${ticket.id}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    icon: Icons.route,
                    label: 'Tuyến đường',
                    value: '${ticket.trip.startLocation} → ${ticket.trip.endLocation}',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    icon: Icons.access_time,
                    label: 'Thời gian',
                    value: formatDateTime(ticket.trip.departureTime),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    icon: Icons.event_seat,
                    label: 'Ghế',
                    value: ticket.seatLabel,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    icon: Icons.person,
                    label: 'Hành khách',
                    value: ticket.passengerName,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    icon: Icons.directions_bus,
                    label: 'Xe',
                    value: '${ticket.trip.busName} · ${ticket.trip.busType}',
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tổng tiền',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        currency(ticket.paidAmount),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                _printTicketPDF(context, ticket);
              },
              icon: const Icon(Icons.print_outlined),
              label: const Text('In vé điện tử (PDF)'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 54),
                backgroundColor: Colors.blue.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.ticketDetail, arguments: ticket);
              },
              icon: const Icon(Icons.receipt_long_outlined),
              label: const Text('Xem chi tiết vé'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 54),
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bạn có thể đánh giá chuyến đi sau khi chuyến đi hoàn thành. Vào chi tiết vé để gửi đánh giá.',
                      style: TextStyle(color: Colors.amber.shade900),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.tripSearch,
                  (route) => false,
                );
              },
              icon: const Icon(Icons.home_rounded),
              label: const Text('Về trang chủ'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 54),
                side: BorderSide(color: primaryColor),
                foregroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _printTicketPDF(BuildContext context, TicketSummary ticket) async {
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
}
