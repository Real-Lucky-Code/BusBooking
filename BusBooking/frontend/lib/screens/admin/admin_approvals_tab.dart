import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../services/admin_service.dart';

class AdminApprovalsTab extends StatefulWidget {
  const AdminApprovalsTab({super.key});

  @override
  State<AdminApprovalsTab> createState() => _AdminApprovalsTabState();
}

class _AdminApprovalsTabState extends State<AdminApprovalsTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<ApprovalItem>> _busCompanyFuture;
  late Future<List<ApprovalItem>> _cancellationFuture;
  late Future<List<ApprovalItem>> _allFuture;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadApprovals();
  }

  void _loadApprovals() {
    _busCompanyFuture = AdminService.instance.getPendingBusCompanyApprovals();
    _cancellationFuture = AdminService.instance.getPendingTicketCancellations();
    _allFuture = AdminService.instance.getAllPendingApprovals();
  }

  Future<void> _refresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      _loadApprovals();
      setState(() {});
      await Future.wait([
        _busCompanyFuture,
        _cancellationFuture,
        _allFuture,
      ]);
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Phê duyệt yêu cầu'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tất cả', icon: Icon(Icons.all_inbox)),
            Tab(text: 'Nhà xe', icon: Icon(Icons.business)),
            Tab(text: 'Hủy vé', icon: Icon(Icons.cancel)),
          ],
        ),
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _refresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: TabBarView(
          controller: _tabController,
          children: [
            // All Approvals
            _buildApprovalList(_allFuture),
            // Bus Company Approvals
            _buildApprovalList(_busCompanyFuture),
            // Ticket Cancellation Approvals
            _buildApprovalList(_cancellationFuture),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalList(Future<List<ApprovalItem>> future) {
    return FutureBuilder<List<ApprovalItem>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = snapshot.data ?? [];

        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'Không có yêu cầu chờ duyệt',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _buildApprovalCard(context, item);
          },
        );
      },
    );
  }

  Widget _buildApprovalCard(BuildContext context, ApprovalItem item) {
    final isBusCompany = item.type == 'bus_company';
    final icon = isBusCompany ? Icons.business : Icons.receipt;
    final color = isBusCompany ? Colors.orange : Colors.blue;
    final backgroundColor = color.withOpacity(0.08);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.medium,
        boxShadow: AppShadows.soft,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showApprovalDetail(context, item),
          borderRadius: AppRadius.medium,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.subtitle,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('dd/MM/yyyy HH:mm')
                                .format(item.requestedAt),
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                    ),
                  ],
                ),
                if (item.description != null &&
                    item.description!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.description!,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (item.contactInfo != null)
                      Text(
                        item.contactInfo!,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Chờ duyệt',
                        style: TextStyle(
                          color: Colors.amber.shade700,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
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

  void _showApprovalDetail(BuildContext context, ApprovalItem item) {
    if (item.type == 'bus_company') {
      _showBusCompanyApprovalDetail(context, item);
    } else if (item.type == 'ticket_cancellation') {
      _showTicketCancellationDetail(context, item);
    }
  }

  void _showBusCompanyApprovalDetail(
      BuildContext context, ApprovalItem item) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      isScrollControlled: true,
      builder: (context) => _BusCompanyApprovalDetail(
        item: item,
        onApprove: () => _handleApprove(context, item),
        onReject: () => _handleReject(context, item),
      ),
    );
  }

  void _showTicketCancellationDetail(
      BuildContext context, ApprovalItem item) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      isScrollControlled: true,
      builder: (context) => _TicketCancellationDetail(
        item: item,
        onApprove: (refundAmount) =>
            _handleCancellationApprove(context, item, refundAmount),
        onReject: () => _handleCancellationReject(context, item),
      ),
    );
  }

  Future<void> _handleApprove(BuildContext context, ApprovalItem item) async {
    try {
      await AdminService.instance.approveBusCompany(item.id);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Phê duyệt nhà xe thành công'),
            backgroundColor: Colors.green,
          ),
        );
        _refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  Future<void> _handleReject(BuildContext context, ApprovalItem item) async {
    final note = await showDialog<String>(
      context: context,
      builder: (context) => _RejectReasonDialog(),
    );

    if (note == null || note.isEmpty) return;

    try {
      await AdminService.instance.rejectBusCompany(item.id, note);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Từ chối nhà xe'),
            backgroundColor: Colors.orange,
          ),
        );
        _refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  Future<void> _handleCancellationApprove(
      BuildContext context, ApprovalItem item, double refundAmount) async {
    final note = await showDialog<String>(
      context: context,
      builder: (context) => _CancellationProcessDialog(
        approve: true,
        defaultRefundAmount: refundAmount,
      ),
    );

    if (note == null) return;

    try {
      await AdminService.instance.processCancellation(
        item.id,
        approve: true,
        refundAmount: refundAmount,
        note: note,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Phê duyệt hủy vé. Hoàn lại: ${_formatCurrency(refundAmount)}'),
            backgroundColor: Colors.green,
          ),
        );
        _refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  Future<void> _handleCancellationReject(
      BuildContext context, ApprovalItem item) async {
    final note = await showDialog<String>(
      context: context,
      builder: (context) =>
          _CancellationProcessDialog(approve: false, defaultRefundAmount: 0),
    );

    if (note == null) return;

    try {
      await AdminService.instance.processCancellation(
        item.id,
        approve: false,
        refundAmount: null,
        note: note,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Từ chối yêu cầu hủy vé'),
            backgroundColor: Colors.orange,
          ),
        );
        _refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  String _formatCurrency(double value) {
    if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)}B đ';
    } else if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M đ';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K đ';
    }
    return '${value.toStringAsFixed(0)} đ';
  }
}

// Bus Company Approval Detail
class _BusCompanyApprovalDetail extends StatelessWidget {
  final ApprovalItem item;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _BusCompanyApprovalDetail({
    required this.item,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final additionalData = item.additionalData ?? {};

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Text(
                    'Chi tiết nhà xe',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailSection(
                    title: 'Thông tin cơ bản',
                    children: [
                      _DetailRow(
                        label: 'Tên nhà xe',
                        value: item.title,
                      ),
                      _DetailRow(
                        label: 'Điện thoại',
                        value: item.contactInfo ?? 'Không có',
                      ),
                      _DetailRow(
                        label: 'Email',
                        value: additionalData['email'] as String? ?? 'Không có',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _DetailSection(
                    title: 'Chi tiết công ty',
                    children: [
                      _DetailRow(
                        label: 'Địa chỉ',
                        value: additionalData['address'] as String? ?? 'Không có',
                      ),
                      _DetailRow(
                        label: 'Biển số xe',
                        value: additionalData['licensePlate'] as String? ?? 'Không có',
                      ),
                    ],
                  ),
                  if (item.description != null &&
                      item.description!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _DetailSection(
                      title: 'Mô tả',
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.description!,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text(
                      'Từ chối',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onApprove,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Phê duyệt',
                      style: TextStyle(color: Colors.white),
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
}

// Ticket Cancellation Detail
class _TicketCancellationDetail extends StatelessWidget {
  final ApprovalItem item;
  final Function(double) onApprove;
  final VoidCallback onReject;

  const _TicketCancellationDetail({
    required this.item,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final additionalData = item.additionalData ?? {};
    final amount = (additionalData['amount'] as num?)?.toDouble() ?? 0.0;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Text(
                    'Chi tiết yêu cầu hủy vé',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mã vé: ${additionalData['ticketCode']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Số ghế: ${additionalData['seatCount'] ?? 1}',
                              style: const TextStyle(fontSize: 13),
                            ),
                            Text(
                              'Giá vé: ${_formatCurrency(amount)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _DetailSection(
                    title: 'Lý do hủy vé',
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.description ?? 'Không có lý do',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _DetailSection(
                    title: 'Thông tin thanh toán',
                    children: [
                      _DetailRow(
                        label: 'Phương thức',
                        value: additionalData['paymentStatus'] as String? ?? 'Chưa thanh toán',
                      ),
                      _DetailRow(
                        label: 'Số tiền',
                        value: _formatCurrency(amount),
                        valueColor: Colors.green,
                      ),
                      _DetailRow(
                        label: 'Hoàn lại',
                        value: _formatCurrency(amount),
                        valueColor: Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _DetailSection(
                    title: 'Ngày yêu cầu',
                    children: [
                      _DetailRow(
                        label: 'Yêu cầu lúc',
                        value: DateFormat('dd/MM/yyyy HH:mm')
                            .format(item.requestedAt),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text(
                      'Từ chối',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => onApprove(amount),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Phê duyệt',
                      style: TextStyle(color: Colors.white),
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
      return '${(value / 1000000000).toStringAsFixed(1)}B đ';
    } else if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M đ';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K đ';
    }
    return '${value.toStringAsFixed(0)} đ';
  }
}

// Dialogs
class _RejectReasonDialog extends StatefulWidget {
  @override
  State<_RejectReasonDialog> createState() => _RejectReasonDialogState();
}

class _RejectReasonDialogState extends State<_RejectReasonDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Lý do từ chối'),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: 'Nhập lý do từ chối...',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        maxLines: 3,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_controller.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Vui lòng nhập lý do')),
              );
              return;
            }
            Navigator.pop(context, _controller.text);
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Từ chối'),
        ),
      ],
    );
  }
}

class _CancellationProcessDialog extends StatefulWidget {
  final bool approve;
  final double defaultRefundAmount;

  const _CancellationProcessDialog({
    required this.approve,
    required this.defaultRefundAmount,
  });

  @override
  State<_CancellationProcessDialog> createState() =>
      _CancellationProcessDialogState();
}

class _CancellationProcessDialogState
    extends State<_CancellationProcessDialog> {
  late TextEditingController _noteController;
  late TextEditingController _refundController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
    _refundController =
        TextEditingController(text: widget.defaultRefundAmount.toString());
  }

  @override
  void dispose() {
    _noteController.dispose();
    _refundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.approve ? 'Phê duyệt hủy vé' : 'Từ chối hủy vé',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.approve) ...[
              const Text('Số tiền hoàn lại:'),
              const SizedBox(height: 8),
              TextField(
                controller: _refundController,
                decoration: InputDecoration(
                  hintText: 'Nhập số tiền hoàn lại',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixText: 'VND',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
            ],
            const Text('Ghi chú:'),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                hintText: widget.approve
                    ? 'Ghi chú về việc hoàn lại tiền...'
                    : 'Lý do từ chối...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 3,
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
            if (_noteController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Vui lòng nhập ghi chú')),
              );
              return;
            }
            Navigator.pop(context, _noteController.text);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.approve ? Colors.green : Colors.red,
          ),
          child: Text(widget.approve ? 'Phê duyệt' : 'Từ chối'),
        ),
      ],
    );
  }
}

// Detail components
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
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
