import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/mock_data.dart';

class TicketPdfGenerator {
  static Future<Uint8List> generateTicketPdf(TicketSummary ticket) async {
    final pdf = pw.Document();

    // Load font for Unicode support (Vietnamese characters)
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    // Generate QR code data
    final qrData = _generateQrData(ticket);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#6366f1'),
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'BusGo - Vé điện tử',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 24,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Hệ thống đặt vé xe khách',
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 12,
                            color: PdfColors.white,
                          ),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Text(
                        ticket.status,
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 12,
                          color: PdfColor.fromHex('#6366f1'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),

              // Ticket Code and QR
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 2,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Mã vé', font),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          ticket.ticketCode.isNotEmpty
                              ? ticket.ticketCode
                              : '#${ticket.id}',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 20,
                          ),
                        ),
                        pw.SizedBox(height: 16),
                        _buildLabel('Ngày đặt', font),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          formatDateTime(ticket.createdAt),
                          style: pw.TextStyle(font: font, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 16),
                  pw.Container(
                    width: 150,
                    height: 150,
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: pw.BorderRadius.circular(12),
                    ),
                    child: pw.BarcodeWidget(
                      data: qrData,
                      barcode: pw.Barcode.qrCode(),
                      width: 134,
                      height: 134,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 24),

              // Trip Information
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Thông tin chuyến đi',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 16,
                      ),
                    ),
                    pw.SizedBox(height: 16),
                    pw.Divider(),
                    pw.SizedBox(height: 16),
                    _buildInfoRow(
                      'Tuyến đường',
                      '${ticket.trip.startLocation} → ${ticket.trip.endLocation}',
                      font,
                      fontBold,
                    ),
                    pw.SizedBox(height: 12),
                    _buildInfoRow(
                      'Thời gian khởi hành',
                      formatDateTime(ticket.trip.departureTime),
                      font,
                      fontBold,
                    ),
                    pw.SizedBox(height: 12),
                    _buildInfoRow(
                      'Thời gian đến',
                      formatDateTime(ticket.trip.arrivalTime),
                      font,
                      fontBold,
                    ),
                    pw.SizedBox(height: 12),
                    _buildInfoRow(
                      'Xe khách',
                      '${ticket.trip.busName} - ${ticket.trip.busType}',
                      font,
                      fontBold,
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Passenger and Seat Info
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(16),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: pw.BorderRadius.circular(12),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Thông tin hành khách',
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 14,
                            ),
                          ),
                          pw.SizedBox(height: 12),
                          _buildInfoRow(
                            'Họ tên',
                            ticket.passengerName,
                            font,
                            fontBold,
                          ),
                          if (ticket.passengerPhone?.isNotEmpty == true) ...[
                            pw.SizedBox(height: 8),
                            _buildInfoRow(
                              'Điện thoại',
                              ticket.passengerPhone!,
                              font,
                              fontBold,
                            ),
                          ],
                          if (ticket.passengerCCCD?.isNotEmpty == true) ...[
                            pw.SizedBox(height: 8),
                            _buildInfoRow(
                              'CCCD/Hộ chiếu',
                              ticket.passengerCCCD!,
                              font,
                              fontBold,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 16),
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(16),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: pw.BorderRadius.circular(12),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Chi tiết vé',
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 14,
                            ),
                          ),
                          pw.SizedBox(height: 12),
                          _buildInfoRow(
                            'Số ghế',
                            ticket.seatLabel,
                            font,
                            fontBold,
                          ),
                          pw.SizedBox(height: 8),
                          _buildInfoRow(
                            'Thanh toán',
                            ticket.paymentMethod,
                            font,
                            fontBold,
                          ),
                          pw.SizedBox(height: 8),
                          _buildInfoRow(
                            'Trạng thái',
                            ticket.paymentStatus,
                            font,
                            fontBold,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 16),

              // Payment Total
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#eff6ff'),
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Tổng tiền',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 16,
                      ),
                    ),
                    pw.Text(
                      currency(ticket.paidAmount),
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 20,
                        color: PdfColor.fromHex('#2563eb'),
                      ),
                    ),
                  ],
                ),
              ),
              pw.Spacer(),

              // Footer
              pw.Divider(),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Hotline: 1900-xxxx',
                    style: pw.TextStyle(font: font, fontSize: 10),
                  ),
                  pw.Text(
                    'Email: support@busgo.vn',
                    style: pw.TextStyle(font: font, fontSize: 10),
                  ),
                  pw.Text(
                    'Website: busgo.vn',
                    style: pw.TextStyle(font: font, fontSize: 10),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  'Vui lòng xuất trình vé điện tử này khi lên xe. Chúc quý khách có chuyến đi an toàn!',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 9,
                    color: PdfColors.grey700,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildLabel(String text, pw.Font font) {
    return pw.Text(
      text,
      style: pw.TextStyle(
        font: font,
        fontSize: 10,
        color: PdfColors.grey700,
      ),
    );
  }

  static pw.Widget _buildInfoRow(
    String label,
    String value,
    pw.Font font,
    pw.Font fontBold,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(font: font, fontSize: 12),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(font: fontBold, fontSize: 12),
        ),
      ],
    );
  }

  static String _generateQrData(TicketSummary ticket) {
    return [
      'TICKET',
      'id:${ticket.id}',
      'code:${ticket.ticketCode}',
      'trip:${ticket.trip.id}',
      'route:${ticket.trip.startLocation}-${ticket.trip.endLocation}',
      'seat:${ticket.seatLabel}',
      'passenger:${ticket.passengerName}',
      'amount:${ticket.paidAmount}',
      'time:${ticket.trip.departureTime.millisecondsSinceEpoch}',
    ].join('|');
  }
}
