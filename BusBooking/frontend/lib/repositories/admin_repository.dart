import '../models/entities.dart';
import '../services/api_client.dart';

class AdminRepository {
  AdminRepository._();
  static final AdminRepository instance = AdminRepository._();

  Future<SystemStatistics> getStatistics() async {
    final res = await ApiClient.instance.get('/admin/statistics');
    final data = res['data'] ?? res;
    return SystemStatistics.fromJson(data as Map<String, dynamic>);
  }

  Future<List<BusCompanyInfo>> getPendingCompanies() async {
    final res = await ApiClient.instance.get('/admin/buscompanies/pending');
    final list = res['data'] ?? res;
    return (list as List)
        .map((e) => BusCompanyInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> approveCompany(int id) async {
    await ApiClient.instance.put('/admin/buscompanies/$id/approve');
  }

  Future<void> rejectCompany(int id) async {
    await ApiClient.instance.put('/admin/buscompanies/$id/reject');
  }
}
