import 'package:flutter/material.dart';
import '../../models/company_model.dart';
import '../../services/bus_company_service.dart';

class CompanyRegistrationScreen extends StatefulWidget {
  final CompanyRegistrationStatus? initialStatus;
  final Function(CompanyRegistrationStatus)? onRegistrationComplete;

  const CompanyRegistrationScreen({
    super.key,
    this.initialStatus,
    this.onRegistrationComplete,
  });

  @override
  State<CompanyRegistrationScreen> createState() =>
      _CompanyRegistrationScreenState();
}

class _CompanyRegistrationScreenState extends State<CompanyRegistrationScreen> {
  late TextEditingController nameController;
  late TextEditingController descriptionController;
  bool isLoading = false;
  CompanyRegistrationStatus? currentStatus;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(
      text: widget.initialStatus?.company?.name ?? '',
    );
    descriptionController = TextEditingController(
      text: widget.initialStatus?.company?.description ?? '',
    );
    if (widget.initialStatus != null) {
      currentStatus = widget.initialStatus;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitRegistration() async {
    if (nameController.text.isEmpty || descriptionController.text.isEmpty) {
      setState(() => errorMessage = 'Vui lòng điền đầy đủ thông tin');
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await BusCompanyService.instance.registerCompany(
        name: nameController.text.trim(),
        description: descriptionController.text.trim(),
      );

      if (!mounted) return;

      setState(() => currentStatus = result);

      if (result.isApproved) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Future.delayed(Duration(seconds: 1), () {
          if (mounted) Navigator.pop(context, result);
        });
      } else if (result.isPending) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Công ty của bạn đã được tạo. Vui lòng đợi phê duyệt từ admin'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }

      widget.onRegistrationComplete?.call(result);
    } catch (e) {
      setState(() => errorMessage = e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget _buildStatusCard() {
    if (currentStatus == null) return SizedBox.shrink();

    return Card(
      margin: EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trạng thái đăng ký',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12),
            _buildStatusBadge(),
            SizedBox(height: 8),
            Text(
              currentStatus!.message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            if (currentStatus!.company != null) ...[
              SizedBox(height: 12),
              Text(
                'Tên công ty: ${currentStatus!.company!.name}',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 4),
              Text(
                'Mô tả: ${currentStatus!.company!.description}',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color backgroundColor;
    Color textColor = Colors.white;
    String statusText;

    switch (currentStatus?.status) {
      case 'approved':
        backgroundColor = Colors.green;
        statusText = '✓ Đã phê duyệt';
        break;
      case 'pending':
        backgroundColor = Colors.orange;
        statusText = '⏱ Đang chờ xét duyệt';
        break;
      case 'rejected':
        backgroundColor = Colors.red;
        statusText = '✗ Bị từ chối';
        break;
      default:
        backgroundColor = Colors.grey;
        statusText = 'Chưa đăng ký';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Đăng ký công ty nhà xe'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (currentStatus != null) _buildStatusCard(),
            if (currentStatus?.isApproved != true) ...[
              Text(
                'Thông tin công ty',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.black87,
                    ) ??
                    TextStyle(fontSize: 20),
              ),
              SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Tên công ty',
                  hintText: 'VD: Hải Âu Express',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabled: !isLoading && currentStatus?.isPending != true,
                ),
                maxLength: 100,
              ),
              SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Mô tả công ty',
                  hintText:
                      'VD: Chuyên vận chuyển hành khách miền Bắc, dịch vụ chất lượng cao',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabled: !isLoading && currentStatus?.isPending != true,
                ),
                maxLines: 4,
                maxLength: 500,
              ),
              SizedBox(height: 8),
              if (errorMessage != null)
                Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Text(
                      errorMessage!,
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading || currentStatus?.isPending == true
                      ? null
                      : _submitRegistration,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                  child: isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          currentStatus?.company != null &&
                                  !currentStatus!.isApproved
                              ? 'Cập nhật thông tin'
                              : 'Đăng ký công ty',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
              if (currentStatus?.isPending == true) ...[
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Bạn không thể chỉnh sửa khi đơn đang chờ duyệt. Vui lòng liên hệ admin để cập nhật.',
                          style: TextStyle(color: Colors.blue, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: 32),
            ],
          ],
        ),
      ),
    );
  }
}
