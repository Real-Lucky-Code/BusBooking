import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/bus_company_service.dart';

class CompanyCancellationsTab extends StatefulWidget {
  const CompanyCancellationsTab({super.key});

  @override
  State<CompanyCancellationsTab> createState() => _CompanyCancellationsTabState();
}

class _CompanyCancellationsTabState extends State<CompanyCancellationsTab> {
  late Future<List<Map<String, dynamic>>> _cancellationsFuture;

  @override
  void initState() {
    super.initState();
    _loadCancellations();
  }

  void _loadCancellations() {
    _cancellationsFuture = BusCompanyService.instance.getPendingCancellationRequests();
  }

  Future<void> _refresh() async {
    setState(() {
      _loadCancellations();
    });
  }

  void _showCancellationDetail(BuildContext context, Map<String, dynamic> cancellation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CancellationDetailSheet(
        cancellation: cancellation,
        onApprove: () => _handleApprove(context, cancellation),
        onReject: () => _handleReject(context, cancellation),
      ),
    );
  }

  void _handleApprove(BuildContext context, Map<String, dynamic> cancellation) {
    final ticketId = cancellation['id'] as int;
    final refundAmount = (cancellation['totalAmount'] as num?)?.toDouble() ?? 0.0;

    showDialog(
      context: context,
      builder: (context) => _RefundApprovalDialog(
        ticketCode: cancellation['ticketCode'] as String? ?? 'N/A',
        originalAmount: refundAmount,
        onConfirm: (amount, note) async {
          Navigator.pop(context);
          Navigator.pop(context); // Close detail sheet

          try {
            await BusCompanyService.instance.processCancellation(
              ticketId: ticketId,
              approve: true,
              refundAmount: amount,
              note: note,
            );

            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Đã phê duyệt hủy vé. Hoàn tiền: ${_formatCurrency(amount)} đ'),
                backgroundColor: Colors.green,
              ),
            );

            _refresh();
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Lỗi: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  void _handleReject(BuildContext context, Map<String, dynamic> cancellation) {
    final ticketId = cancellation['id'] as int;

    showDialog(
      context: context,
      builder: (context) => _RejectReasonDialog(
        onConfirm: (reason) async {
          Navigator.pop(context);
          Navigator.pop(context); // Close detail sheet

          try {
            await BusCompanyService.instance.processCancellation(
              ticketId: ticketId,
              approve: false,
              note: reason,
            );

            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã từ chối yêu cầu hủy vé'),
                backgroundColor: Colors.orange,
              ),
            );

            _refresh();
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Lỗi: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  String _formatCurrency(double value) {
    if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)}B';
    } else if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    } else {
      return value.toStringAsFixed(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Yêu cầu hủy vé'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _cancellationsFuture,
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
                    Text(
                      'Không tải được danh sách',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Thử lại'),
                    ),
                  ],
                ),
              );
            }

            final cancellations = snapshot.data ?? [];

            if (cancellations.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'Không có yêu cầu hủy vé',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: cancellations.length,
              itemBuilder: (context, index) {
                final cancellation = cancellations[index];
                return _CancellationCard(
                  cancellation: cancellation,
                  onTap: () => _showCancellationDetail(context, cancellation),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _CancellationCard extends StatelessWidget {
  final Map<String, dynamic> cancellation;
  final VoidCallback onTap;

  const _CancellationCard({
    required this.cancellation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ticketCode = cancellation['ticketCode'] as String? ?? 'N/A';
    final passengerName = cancellation['passengerName'] as String? ?? 'N/A';
    final reason = cancellation['cancellationReason'] as String? ?? 'Không có lý do';
    final amount = (cancellation['totalAmount'] as num?)?.toDouble() ?? 0.0;
    final requestedAt = cancellation['cancellationRequestedAt'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: AppRadius.medium,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.medium,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_outlined, color: Colors.red, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ticketCode,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            passengerName,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Chờ xử lý',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Lý do: $reason',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Số tiền: ${_formatCurrency(amount)} đ',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue,
                      ),
                    ),
                    if (requestedAt != null)
                      Text(
                        'Yêu cầu: ${_formatTime(requestedAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatCurrency(double value) {
    if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)}B';
    } else if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    } else {
      return value.toStringAsFixed(0);
    }
  }

  String _formatTime(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) {
        return 'Vừa xong';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}p trước';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h trước';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d trước';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return 'N/A';
    }
  }
}

class _CancellationDetailSheet extends StatelessWidget {
  final Map<String, dynamic> cancellation;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _CancellationDetailSheet({
    required this.cancellation,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final ticketCode = cancellation['ticketCode'] as String? ?? 'N/A';
    final passengerName = cancellation['passengerName'] as String? ?? 'N/A';
    final passengerPhone = cancellation['passengerPhone'] as String? ?? 'N/A';
    final passengerCCCD = cancellation['passengerCCCD'] as String? ?? 'N/A';
    final startLocation = cancellation['startLocation'] as String? ?? 'N/A';
    final endLocation = cancellation['endLocation'] as String? ?? 'N/A';
    final departureTime = cancellation['departureTime'] as String?;
    final seatNumbers = (cancellation['seatNumbers'] as List?)?.cast<String>() ?? [];
    final amount = (cancellation['totalAmount'] as num?)?.toDouble() ?? 0.0;
    final reason = cancellation['cancellationReason'] as String? ?? 'Không có lý do';
    final requestedAt = cancellation['cancellationRequestedAt'] as String?;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Chi tiết yêu cầu hủy vé',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ticket Info Box (highlighted)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Vé cần hủy',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _DetailRow(label: 'Mã vé', value: ticketCode),
                        _DetailRow(label: 'Ghế', value: seatNumbers.isNotEmpty ? seatNumbers.join(', ') : 'N/A'),
                        _DetailRow(label: 'Số tiền', value: '${_formatCurrency(amount)} đ', valueColor: Colors.blue),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Passenger Info
                  _DetailSection(
                    title: 'Thông tin hành khách',
                    children: [
                      _DetailRow(label: 'Tên', value: passengerName),
                      _DetailRow(label: 'Điện thoại', value: passengerPhone),
                      _DetailRow(label: 'CCCD/CMND', value: passengerCCCD),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Trip Info
                  _DetailSection(
                    title: 'Thông tin chuyến đi',
                    children: [
                      _DetailRow(label: 'Điểm đi', value: startLocation),
                      _DetailRow(label: 'Điểm đến', value: endLocation),
                      if (departureTime != null)
                        _DetailRow(label: 'Giờ khởi hành', value: _formatDateTime(departureTime)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Cancellation Reason
                  _DetailSection(
                    title: 'Lý do hủy',
                    children: [
                      Text(
                        reason,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Request Time
                  if (requestedAt != null)
                    _DetailSection(
                      title: 'Thời gian',
                      children: [
                        _DetailRow(label: 'Yêu cầu lúc', value: _formatDateTime(requestedAt)),
                      ],
                    ),
                ],
              ),
            ),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: onReject,
                    child: const Text(
                      'Từ chối',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: onApprove,
                    child: const Text(
                      'Phê duyệt',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double value) {
    if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)}B';
    } else if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    } else {
      return value.toStringAsFixed(0);
    }
  }

  String _formatDateTime(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }
}

class _RefundApprovalDialog extends StatefulWidget {
  final String ticketCode;
  final double originalAmount;
  final Function(double amount, String note) onConfirm;

  const _RefundApprovalDialog({
    required this.ticketCode,
    required this.originalAmount,
    required this.onConfirm,
  });

  @override
  State<_RefundApprovalDialog> createState() => _RefundApprovalDialogState();
}

class _RefundApprovalDialogState extends State<_RefundApprovalDialog> {
  late TextEditingController _amountController;
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.originalAmount.toString());
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Phê duyệt hoàn tiền'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mã vé: ${widget.ticketCode}'),
            const SizedBox(height: 16),
            const Text(
              'Số tiền hoàn lại:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'Nhập số tiền',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ghi chú (tùy chọn):',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Nhập ghi chú',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
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
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          onPressed: () {
            final amount = double.tryParse(_amountController.text) ?? widget.originalAmount;
            final note = _noteController.text;
            Navigator.pop(context);
            widget.onConfirm(amount, note);
          },
          child: const Text('Phê duyệt', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

class _RejectReasonDialog extends StatefulWidget {
  final Function(String reason) onConfirm;

  const _RejectReasonDialog({required this.onConfirm});

  @override
  State<_RejectReasonDialog> createState() => _RejectReasonDialogState();
}

class _RejectReasonDialogState extends State<_RejectReasonDialog> {
  late TextEditingController _reasonController;

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Lý do từ chối'),
      content: TextField(
        controller: _reasonController,
        maxLines: 3,
        decoration: InputDecoration(
          hintText: 'Nhập lý do từ chối',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () {
            if (_reasonController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Vui lòng nhập lý do từ chối')),
              );
              return;
            }
            Navigator.pop(context);
            widget.onConfirm(_reasonController.text);
          },
          child: const Text('Từ chối', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _DetailSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: valueColor ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
