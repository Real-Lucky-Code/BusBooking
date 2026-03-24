import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../config/theme.dart';
import '../../models/entities.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/bus_company_repository.dart';
import '../../widgets/bus_seat_layout_widget.dart';

class CompanyBusesScreen extends StatefulWidget {
  const CompanyBusesScreen({super.key});

  @override
  State<CompanyBusesScreen> createState() => _CompanyBusesScreenState();
}

class _CompanyBusesScreenState extends State<CompanyBusesScreen> {
  String searchQuery = '';
  String statusFilter = 'Tất cả'; // Tất cả, Hoạt động, Tạm dừng

  @override
  Widget build(BuildContext context) {
    final companyId = AuthRepository.instance.currentCompanyId;

    if (companyId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quản lý xe')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.business_center, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Không tìm thấy thông tin công ty',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: AppBar(
        title: const Text('Quản lý xe'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBusDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Thêm xe'),
      ),
      body: FutureBuilder(
        future: BusCompanyRepository.instance.getBuses(companyId: companyId),
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
                    'Không tải được danh sách xe',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
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
          final buses = snapshot.data ?? [];
          
          // Filter buses
          var filteredBuses = buses.where((bus) {
            final matchesSearch = searchQuery.isEmpty ||
                bus.licensePlate.toLowerCase().contains(searchQuery.toLowerCase()) ||
                bus.type.toLowerCase().contains(searchQuery.toLowerCase());
            final matchesStatus = statusFilter == 'Tất cả' ||
                (statusFilter == 'Hoạt động' && bus.isActive) ||
                (statusFilter == 'Tạm dừng' && !bus.isActive);
            return matchesSearch && matchesStatus;
          }).toList();
          
          if (buses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_bus_outlined, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có xe nào',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nhấn nút "Thêm xe" để bắt đầu',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }
          
          return Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  onChanged: (value) => setState(() => searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Tìm theo biển số hoặc loại xe...',
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
              // Bus list
              if (filteredBuses.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'Không tìm thấy xe phù hợp',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: filteredBuses.length,
                    padding: const EdgeInsets.all(16),
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final bus = filteredBuses[index];
                      return _BusCard(
                        bus: bus,
                        onEdit: () => _showEditBusDialog(context, bus),
                        onToggleStatus: () => _toggleBusStatus(bus),
                        onShowSeats: () => _showSeatLayoutDialog(context, bus),
                        onDelete: () => _deleteBusForever(bus),
                      );
                    },
                  ),
                ),
            ],
          );
        },
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
            ...['Tất cả', 'Hoạt động', 'Tạm dừng'].map((status) => RadioListTile<String>(
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

  void _showAddBusDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _BusFormDialog(
        title: 'Thêm xe mới',
        onSave: (data) async {
          try {
            final companyId = AuthRepository.instance.currentCompanyId;
            if (companyId == null) throw Exception('Không tìm thấy công ty');

            String? imageUrl = data['imageUrl'];
            final imageFile = data['imageFile'];
            if (imageFile != null) {
              imageUrl = await BusCompanyRepository.instance.uploadBusImage(imageFile);
            }
            
            await BusCompanyRepository.instance.createBus(
              companyId: companyId,
              licensePlate: data['licensePlate'],
              type: data['type'],
              totalSeats: data['totalSeats'],
              imageUrl: imageUrl?.isNotEmpty == true ? imageUrl : null,
            );
            
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã thêm xe mới thành công'),
                backgroundColor: Colors.green,
              ),
            );
            setState(() {});
          } catch (e) {
            if (!context.mounted) return;
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

  void _showEditBusDialog(BuildContext context, BusInfo bus) {
    showDialog(
      context: context,
      builder: (context) => _BusFormDialog(
        title: 'Chỉnh sửa thông tin xe',
        initialData: bus,
        onSave: (data) async {
          try {
            String? imageUrl = data['imageUrl'];
            final imageFile = data['imageFile'];
            if (imageFile != null) {
              imageUrl = await BusCompanyRepository.instance.uploadBusImage(imageFile);
            }

            await BusCompanyRepository.instance.updateBus(
              busId: bus.id,
              licensePlate: data['licensePlate'],
              type: data['type'],
              totalSeats: data['totalSeats'],
              imageUrl: imageUrl?.isNotEmpty == true ? imageUrl : null,
            );
            
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã cập nhật thông tin xe'),
                backgroundColor: Colors.green,
              ),
            );
            setState(() {});
          } catch (e) {
            if (!context.mounted) return;
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

  Future<void> _toggleBusStatus(BusInfo bus) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(bus.isActive ? 'Tạm dừng xe' : 'Kích hoạt xe'),
        content: Text(
          bus.isActive 
            ? 'Xe sẽ không hiển thị trong tìm kiếm chuyến đi. Bạn có chắc chắn?'
            : 'Xe sẽ được kích hoạt lại và hiển thị trong tìm kiếm chuyến đi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: bus.isActive ? Colors.orange : Colors.green,
            ),
            child: Text(bus.isActive ? 'Tạm dừng' : 'Kích hoạt'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await BusCompanyRepository.instance.toggleBusStatus(busId: bus.id);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(bus.isActive ? 'Đã tạm dừng xe' : 'Đã kích hoạt xe'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteBusForever(BusInfo bus) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa xe vĩnh viễn'),
        content: const Text('Hành động này không thể hoàn tác. Xe sẽ bị xóa khỏi hệ thống. Bạn có chắc chắn?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await BusCompanyRepository.instance.deleteBus(busId: bus.id);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xóa xe thành công'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSeatLayoutDialog(BuildContext context, BusInfo bus) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          children: [
            AppBar(
              title: Text('Sơ đồ ghế - ${bus.licensePlate}'),
              automaticallyImplyLeading: true,
            ),
            Expanded(
              child: BusSeatLayoutWidget(
                busId: bus.id,
                busType: bus.type,
                totalSeats: bus.totalSeats,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BusCard extends StatelessWidget {
  const _BusCard({
    required this.bus,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onShowSeats,
    required this.onDelete,
  });

  final BusInfo bus;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;
  final VoidCallback onShowSeats;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.medium,
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        children: [
          // Bus image
          if (bus.imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                bus.imageUrl!,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 160,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.directions_bus, size: 64, color: Colors.grey),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: AppRadius.small,
                      ),
                      child: Icon(
                        Icons.directions_bus,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bus.licensePlate,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            bus.type,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: bus.isActive ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: AppRadius.pill,
                      ),
                      child: Text(
                        bus.isActive ? 'Hoạt động' : 'Tạm ngừng',
                        style: TextStyle(
                          color: bus.isActive ? Colors.green.shade700 : Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _InfoChip(icon: Icons.event_seat, label: '${bus.totalSeats} ghế'),
                    const SizedBox(width: 8),
                    _InfoChip(icon: Icons.category, label: bus.type),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Chỉnh sửa'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onShowSeats,
                        icon: const Icon(Icons.event_seat, size: 18),
                        label: const Text('Ghế'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onToggleStatus,
                        icon: Icon(bus.isActive ? Icons.pause : Icons.play_arrow, size: 18),
                        label: Text(bus.isActive ? 'Tạm dừng' : 'Kích hoạt'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: bus.isActive ? Colors.orange : Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Xóa vĩnh viễn'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _BusFormDialog extends StatefulWidget {
  const _BusFormDialog({
    required this.title,
    required this.onSave,
    this.initialData,
  });

  final String title;
  final BusInfo? initialData;
  final Function(Map<String, dynamic>) onSave;

  @override
  State<_BusFormDialog> createState() => _BusFormDialogState();
}

class _BusFormDialogState extends State<_BusFormDialog> {
  late final TextEditingController licensePlateCtrl;
  late final TextEditingController typeCtrl;
  late final TextEditingController seatsCtrl;
  late final TextEditingController imageUrlCtrl;
  File? selectedImage;
  String? existingImageUrl;

  @override
  void initState() {
    super.initState();
    final bus = widget.initialData;
    licensePlateCtrl = TextEditingController(text: bus?.licensePlate);
    typeCtrl = TextEditingController(text: bus?.type);
    seatsCtrl = TextEditingController(text: bus?.totalSeats.toString());
    imageUrlCtrl = TextEditingController(text: bus?.imageUrl);
    existingImageUrl = bus?.imageUrl;
  }

  @override
  void dispose() {
    licensePlateCtrl.dispose();
    typeCtrl.dispose();
    seatsCtrl.dispose();
    imageUrlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.large),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 20),
              TextField(
                controller: licensePlateCtrl,
                decoration: const InputDecoration(
                  labelText: 'Biển số xe',
                  hintText: '51A-12345',
                  prefixIcon: Icon(Icons.confirmation_number),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: typeCtrl.text.isEmpty ? null : typeCtrl.text,
                decoration: const InputDecoration(
                  labelText: 'Loại xe',
                  prefixIcon: Icon(Icons.category),
                ),
                items: const [
                  DropdownMenuItem(value: 'Limousine', child: Text('Limousine')),
                  DropdownMenuItem(value: 'Giường nằm', child: Text('Giường nằm')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => typeCtrl.text = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: seatsCtrl.text.isEmpty ? null : int.tryParse(seatsCtrl.text),
                decoration: const InputDecoration(
                  labelText: 'Số ghế',
                  prefixIcon: Icon(Icons.event_seat),
                ),
                items: const [
                  DropdownMenuItem(value: 22, child: Text('22 ghế')),
                  DropdownMenuItem(value: 24, child: Text('24 ghế')),
                  DropdownMenuItem(value: 34, child: Text('34 ghế')),
                  DropdownMenuItem(value: 40, child: Text('40 ghế')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => seatsCtrl.text = value.toString());
                  }
                },
              ),
              const SizedBox(height: 16),
              // Image picker section
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: AppRadius.medium,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: selectedImage != null
                      ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: AppRadius.medium,
                              child: Image.file(
                                selectedImage!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () => setState(() => selectedImage = null),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                                ),
                              ),
                            ),
                          ],
                        )
                      : existingImageUrl != null && existingImageUrl!.isNotEmpty
                          ? Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: AppRadius.medium,
                                  child: Image.network(
                                    existingImageUrl!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey.shade200,
                                        child: Center(child: Icon(Icons.broken_image, color: Colors.grey.shade400, size: 48)),
                                      );
                                    },
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: () => setState(() => existingImageUrl = null),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, color: Colors.white, size: 18),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : _buildImagePlaceholder(),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Validate inputs
                        final licensePlate = licensePlateCtrl.text.trim();
                        final type = typeCtrl.text.trim();
                        final seatsText = seatsCtrl.text.trim();
                        
                        if (licensePlate.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Vui lòng nhập biển số xe')),
                          );
                          return;
                        }
                        
                        if (type.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Vui lòng nhập loại xe')),
                          );
                          return;
                        }
                        
                        // Validate bus type (only Limousine or Giường nằm)
                        if (type != 'Limousine' && type != 'Giường nằm') {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Loại xe chỉ được là "Limousine" hoặc "Giường nằm"')),
                          );
                          return;
                        }
                        
                        final totalSeats = int.tryParse(seatsText) ?? 0;
                        
                        // Validate seat count (only 22, 24, 34, 40)
                        if (![22, 24, 34, 40].contains(totalSeats)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Số ghế chỉ được là 22, 24, 34 hoặc 40')),
                          );
                          return;
                        }
                        
                        widget.onSave({
                          'licensePlate': licensePlate,
                          'type': type,
                          'totalSeats': totalSeats,
                          'imageFile': selectedImage,
                          'imageUrl': selectedImage == null ? (existingImageUrl ?? '') : '',
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Lưu'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              'Nhấn để chọn ảnh',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Camera/Thư viện',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Chụp ảnh từ camera'),
              onTap: () {
                Navigator.pop(context);
                _captureImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Chọn từ thư viện'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _captureImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        setState(() {
          selectedImage = File(image.path);
          existingImageUrl = null;
          imageUrlCtrl.clear();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi chụp ảnh: ${e.toString()}')),
      );
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          selectedImage = File(image.path);
          existingImageUrl = null;
          imageUrlCtrl.clear();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi chọn ảnh: ${e.toString()}')),
      );
    }
  }
}
