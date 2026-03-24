import 'package:flutter/material.dart';
import '../../models/company_model.dart';
import '../../services/bus_company_service.dart';

class AdminCompanyApprovalScreen extends StatefulWidget {
  const AdminCompanyApprovalScreen({super.key});

  @override
  State<AdminCompanyApprovalScreen> createState() =>
      _AdminCompanyApprovalScreenState();
}

class _AdminCompanyApprovalScreenState
    extends State<AdminCompanyApprovalScreen> {
  late Future<List<BusCompanyInfo>> _pendingCompanies;

  @override
  void initState() {
    super.initState();
    _loadPendingCompanies();
  }

  void _loadPendingCompanies() {
    _pendingCompanies = _fetchPendingCompanies();
  }

  Future<List<BusCompanyInfo>> _fetchPendingCompanies() async {
    try {
      // Call API to get pending companies
      // For now, return empty list as this would be implemented in backend
      return [];
    } catch (e) {
      throw Exception('Lỗi tải danh sách công ty: $e');
    }
  }

  Future<void> _approveCompany(BusCompanyInfo company) async {
    try {
      await BusCompanyService.instance.approveCompany(company.id);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã phê duyệt công ty: ${company.name}'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _loadPendingCompanies();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectCompany(BusCompanyInfo company) async {
    final reason = await _showRejectDialog(context);
    if (reason == null) return;

    try {
      await BusCompanyService.instance.rejectCompany(
        companyId: company.id,
        reason: reason,
      );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã từ chối công ty: ${company.name}'),
          backgroundColor: Colors.red,
        ),
      );

      setState(() {
        _loadPendingCompanies();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String?> _showRejectDialog(BuildContext context) async {
    String? reason;
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Từ chối công ty'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Lý do từ chối',
                hintText: 'VD: Thông tin không đầy đủ',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (value) => reason = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, reason ?? ''),
            child: Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Phê duyệt công ty nhà xe'),
      ),
      body: FutureBuilder<List<BusCompanyInfo>>(
        future: _pendingCompanies,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Lỗi: ${snapshot.error}'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() => _loadPendingCompanies()),
                    child: Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          final companies = snapshot.data ?? [];

          if (companies.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Colors.green,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Không có công ty chờ phê duyệt',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: companies.length,
            itemBuilder: (context, index) {
              final company = companies[index];
              return _buildCompanyCard(context, company);
            },
          );
        },
      ),
    );
  }

  Widget _buildCompanyCard(BuildContext context, BusCompanyInfo company) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              company.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              company.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => _approveCompany(company),
                  icon: Icon(Icons.check),
                  label: Text('Phê duyệt'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => _rejectCompany(company),
                  icon: Icon(Icons.close),
                  label: Text('Từ chối'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: BorderSide(color: Colors.red),
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
