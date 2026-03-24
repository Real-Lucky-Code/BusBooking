import '../models/company_model.dart';
import '../services/api_client.dart';
import '../repositories/auth_repository.dart';

class CompanyStatistics {
  final int totalBuses;
  final int totalTrips;
  final int totalBookings;
  final int todayBookings;
  final double totalRevenue;
  final double todayRevenue;
  final double averageRating;
  final int totalReviews;
  final int totalPromotions;

  CompanyStatistics({
    required this.totalBuses,
    required this.totalTrips,
    required this.totalBookings,
    required this.todayBookings,
    required this.totalRevenue,
    required this.todayRevenue,
    required this.averageRating,
    required this.totalReviews,
    required this.totalPromotions,
  });

  factory CompanyStatistics.fromJson(Map<String, dynamic> json) {
    return CompanyStatistics(
      totalBuses: json['totalBuses'] as int? ?? 0,
      totalTrips: json['totalTrips'] as int? ?? 0,
      totalBookings: json['totalBookings'] as int? ?? 0,
      todayBookings: json['todayBookings'] as int? ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      todayRevenue: (json['todayRevenue'] as num?)?.toDouble() ?? 0.0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: json['totalReviews'] as int? ?? 0,
      totalPromotions: json['totalPromotions'] as int? ?? 0,
    );
  }
}

class BusCompanyService {
  BusCompanyService._();
  static final BusCompanyService instance = BusCompanyService._();

  Future<CompanyRegistrationStatus> getMyCompany() async {
    final userId = AuthRepository.instance.currentUser?.id;
    final res = await ApiClient.instance.get(
      '/buscompany/my-company',
      query: userId != null ? {'userId': userId} : null,
    );
    return CompanyRegistrationStatus.fromJson(res);
  }

  Future<CompanyStatistics> getCompanyStatistics() async {
    final userId = AuthRepository.instance.currentUser?.id;
    final res = await ApiClient.instance.get(
      '/buscompany/statistics',
      query: userId != null ? {'userId': userId} : null,
    );
    return CompanyStatistics.fromJson(res);
  }

  Future<CompanyRegistrationStatus> registerCompany({
    required String name,
    required String description,
  }) async {
    final userId = AuthRepository.instance.currentUser?.id;
    final res = await ApiClient.instance.post(
      '/buscompany/register-my-company',
      body: {
        'name': name,
        'description': description,
        if (userId != null) 'ownerId': userId,
      },
    );
    return CompanyRegistrationStatus.fromJson(res);
  }

  Future<BusCompanyInfo> updateCompany({
    required int companyId,
    required String name,
    required String description,
  }) async {
    final res = await ApiClient.instance.put(
      '/buscompany/$companyId',
      body: {
        'name': name,
        'description': description,
      },
    );
    return BusCompanyInfo.fromJson(res);
  }

  Future<void> approveCompany(int companyId) async {
    await ApiClient.instance.post(
      '/buscompany/approve-company/$companyId',
    );
  }

  Future<void> rejectCompany({
    required int companyId,
    String? reason,
  }) async {
    await ApiClient.instance.post(
      '/buscompany/reject-company/$companyId',
      body: {'reason': reason},
    );
  }

  // ============= Ticket Cancellation Management =============

  Future<List<Map<String, dynamic>>> getPendingCancellationRequests() async {
    final res = await ApiClient.instance.get('/buscompany/cancellation-requests');
    // Handle both array and object responses
    final list = (res is List ? res : res['data'] as List? ?? []) as List;
    return list.cast<Map<String, dynamic>>();
  }

  Future<void> processCancellation({
    required int ticketId,
    required bool approve,
    double? refundAmount,
    String? note,
  }) async {
    await ApiClient.instance.post(
      '/buscompany/tickets/$ticketId/process-cancellation',
      body: {
        'approve': approve,
        if (approve && refundAmount != null) 'refundAmount': refundAmount,
        if (note != null) 'note': note,
      },
    );
  }
}
