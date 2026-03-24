import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/bus_company_repository.dart';
import '../../models/entities.dart';

class CompanyPromotionsScreen extends StatefulWidget {
  const CompanyPromotionsScreen({super.key});

  @override
  State<CompanyPromotionsScreen> createState() => _CompanyPromotionsScreenState();
}

class _CompanyPromotionsScreenState extends State<CompanyPromotionsScreen> {
  String statusFilter = 'Tất cả'; // Tất cả, Đang hiệu lực, Hết hạn
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final companyId = AuthRepository.instance.currentCompanyId;

    if (companyId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quản lý khuyến mãi')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text('Không tìm thấy thông tin công ty',
                  style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: AppBar(
        title: const Text('Quản lý khuyến mãi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPromotionDialog(companyId),
        icon: const Icon(Icons.add),
        label: const Text('Thêm khuyến mãi'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) => setState(() => searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Tìm theo mã khuyến mãi...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => searchQuery = ''),
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // Filter chip
          if (statusFilter != 'Tất cả')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Chip(
                    label: Text(statusFilter),
                    onDeleted: () => setState(() => statusFilter = 'Tất cả'),
                    deleteIcon: const Icon(Icons.close, size: 16),
                  ),
                ],
              ),
            ),
          // Promotions list
          Expanded(
            child: FutureBuilder(
              key: ValueKey('promotions-$statusFilter-$searchQuery'),
              future: BusCompanyRepository.instance.getPromotions(companyId: companyId),
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
                        Text('Không tải được khuyến mãi', style: TextStyle(color: Colors.grey.shade600)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => setState(() {}),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                }
                
                final promotions = snapshot.data ?? [];
                final now = DateTime.now();
                
                // Filter promotions
                var filteredPromotions = promotions.where((promo) {
                  final matchesSearch = searchQuery.isEmpty ||
                      promo.code.toLowerCase().contains(searchQuery.toLowerCase());
                  final isActive = promo.startDate.isBefore(now) && promo.endDate.isAfter(now);
                  final matchesStatus = statusFilter == 'Tất cả' ||
                      (statusFilter == 'Đang hiệu lực' && isActive) ||
                      (statusFilter == 'Hết hạn' && !isActive);
                  return matchesSearch && matchesStatus;
                }).toList();
                
                if (promotions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_offer_outlined, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('Chưa có khuyến mãi', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey.shade600)),
                        const SizedBox(height: 8),
                        Text('Nhấn nút "Thêm khuyến mãi" để bắt đầu', style: TextStyle(color: Colors.grey.shade500)),
                      ],
                    ),
                  );
                }
                
                if (filteredPromotions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text('Không tìm thấy khuyến mãi', style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  );
                }
                
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  itemCount: filteredPromotions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final promo = filteredPromotions[index];
                    return _PromotionCard(
                      promotion: promo,
                      onEdit: () => _showPromotionDialog(companyId, promo),
                      onDelete: () => _deletePromotion(companyId, promo),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Lọc theo trạng thái', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...['Tất cả', 'Đang hiệu lực', 'Hết hạn'].map((status) => RadioListTile<String>(
              title: Text(status),
              value: status,
              groupValue: statusFilter,
              onChanged: (value) {
                setState(() => statusFilter = value!);
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showPromotionDialog(int companyId, [PromotionInfo? promo]) {
    showDialog(
      context: context,
      builder: (context) => _PromotionFormDialog(
        companyId: companyId,
        promotion: promo,
        onSaved: () {
          Navigator.pop(context);
          setState(() {});
        },
      ),
    );
  }

  void _deletePromotion(int companyId, PromotionInfo promo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa khuyến mãi ${promo.code}? Khuyến mãi sẽ không còn khả dụng.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await BusCompanyRepository.instance.deletePromotion(
                  companyId: companyId,
                  promotionId: promo.id,
                );
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã xóa khuyến mãi'), backgroundColor: Colors.green),
                );
                setState(() {});
              } catch (e) {
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi: $e')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}

class _PromotionCard extends StatelessWidget {
  const _PromotionCard({
    required this.promotion,
    required this.onEdit,
    required this.onDelete,
  });

  final PromotionInfo promotion;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isActive = promotion.startDate.isBefore(now) && promotion.endDate.isAfter(now);
    final daysLeft = promotion.endDate.difference(now).inDays;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.medium,
        boxShadow: AppShadows.soft,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.local_offer,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        promotion.code,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Giảm ${promotion.discountPercent}%',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: AppRadius.pill,
                  ),
                  child: Text(
                    isActive ? 'Hiệu lực' : 'Hết hạn',
                    style: TextStyle(
                      color: isActive ? Colors.green.shade700 : Colors.red.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text(
                        'Từ ${promotion.startDate.toLocal().toString().split(' ').first}',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.event, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text(
                        'Đến ${promotion.endDate.toLocal().toString().split(' ').first}',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                  if (isActive && daysLeft <= 7) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.warning_amber, size: 16, color: Colors.orange.shade600),
                        const SizedBox(width: 8),
                        Text(
                          'Còn $daysLeft ngày',
                          style: TextStyle(fontSize: 13, color: Colors.orange.shade700, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Sửa', style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Xóa', style: TextStyle(fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PromotionFormDialog extends StatefulWidget {
  const _PromotionFormDialog({
    required this.companyId,
    required this.promotion,
    required this.onSaved,
  });

  final int companyId;
  final PromotionInfo? promotion;
  final VoidCallback onSaved;

  @override
  State<_PromotionFormDialog> createState() => _PromotionFormDialogState();
}

class _PromotionFormDialogState extends State<_PromotionFormDialog> {
  late TextEditingController codeController;
  late TextEditingController discountController;
  late DateTime startDate;
  late DateTime endDate;
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    codeController = TextEditingController(text: widget.promotion?.code ?? '');
    discountController = TextEditingController(text: widget.promotion?.discountPercent.toString() ?? '');
    startDate = widget.promotion?.startDate ?? DateTime.now();
    endDate = widget.promotion?.endDate ?? DateTime.now().add(const Duration(days: 7));
  }

  @override
  void dispose() {
    codeController.dispose();
    discountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? startDate : endDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
          if (endDate.isBefore(startDate)) {
            endDate = startDate.add(const Duration(days: 7));
          }
        } else {
          endDate = picked;
        }
      });
    }
  }

  String? _validateForm() {
    if (codeController.text.trim().isEmpty) {
      return 'Vui lòng nhập mã khuyến mãi';
    }
    if (discountController.text.trim().isEmpty) {
      return 'Vui lòng nhập phần trăm giảm giá';
    }
    final discount = double.tryParse(discountController.text.trim());
    if (discount == null || discount <= 0 || discount > 100) {
      return 'Phần trăm giảm giá phải từ 1 đến 100';
    }
    if (endDate.isBefore(startDate) || endDate.isAtSameMomentAs(startDate)) {
      return 'Ngày kết thúc phải sau ngày bắt đầu';
    }
    return null;
  }

  Future<void> _submit() async {
    final error = _validateForm();
    if (error != null) {
      setState(() => errorMessage = error);
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final discount = double.parse(discountController.text.trim());
      
      if (widget.promotion == null) {
        // Create
        await BusCompanyRepository.instance.createPromotion(
          companyId: widget.companyId,
          code: codeController.text.trim(),
          discountPercent: discount,
          startDate: startDate,
          endDate: endDate,
        );
      } else {
        // Update
        await BusCompanyRepository.instance.updatePromotion(
          companyId: widget.companyId,
          promotionId: widget.promotion!.id,
          code: codeController.text.trim(),
          discountPercent: discount,
          startDate: startDate,
          endDate: endDate,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.promotion == null ? 'Đã thêm khuyến mãi' : 'Đã cập nhật khuyến mãi'),
          backgroundColor: Colors.green,
        ),
      );
      widget.onSaved();
    } catch (e) {
      setState(() => errorMessage = 'Lỗi: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.promotion == null ? 'Thêm khuyến mãi' : 'Sửa khuyến mãi'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        errorMessage!,
                        style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: codeController,
              decoration: InputDecoration(
                labelText: 'Mã khuyến mãi',
                hintText: 'VD: SUMMER20',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.local_offer),
              ),
              enabled: !isLoading,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: discountController,
              decoration: InputDecoration(
                labelText: 'Phần trăm giảm giá',
                hintText: '20',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.percent),
                suffix: const Text('%'),
              ),
              enabled: !isLoading,
              keyboardType: const TextInputType.numberWithOptions(decimal: false),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: isLoading ? null : () => _selectDate(true),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Ngày bắt đầu', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('dd/MM/yyyy').format(startDate),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: isLoading ? null : () => _selectDate(false),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event, size: 20, color: Colors.grey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Ngày kết thúc', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('dd/MM/yyyy').format(endDate),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : _submit,
          child: isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(widget.promotion == null ? 'Thêm' : 'Cập nhật'),
        ),
      ],
    );
  }
}
