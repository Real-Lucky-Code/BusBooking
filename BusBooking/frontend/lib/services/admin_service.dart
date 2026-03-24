import '../services/api_client.dart';

// Statistics models
class AdminStatistics {
  final int totalUsers;
  final int totalBusCompanies;
  final int approvedBusCompanies;
  final int pendingApprovals;
  final int todayTicketsSold;
  final double todayRevenue;
  final int totalReviews;
  final int totalTrips;
  final int totalTickets;
  final double totalRevenue;

  AdminStatistics({
    required this.totalUsers,
    required this.totalBusCompanies,
    required this.approvedBusCompanies,
    required this.pendingApprovals,
    required this.todayTicketsSold,
    required this.todayRevenue,
    required this.totalReviews,
    required this.totalTrips,
    required this.totalTickets,
    required this.totalRevenue,
  });

  factory AdminStatistics.fromJson(Map<String, dynamic> json) {
    return AdminStatistics(
      totalUsers: json['totalUsers'] as int? ?? 0,
      totalBusCompanies: json['totalBusCompanies'] as int? ?? 0,
      approvedBusCompanies: json['approvedBusCompanies'] as int? ?? 0,
      pendingApprovals: json['pendingApprovals'] as int? ?? 0,
      todayTicketsSold: json['todayTicketsSold'] as int? ?? 0,
      todayRevenue: (json['todayRevenue'] as num?)?.toDouble() ?? 0.0,
      totalReviews: json['totalReviews'] as int? ?? 0,
      totalTrips: json['totalTrips'] as int? ?? 0,
      totalTickets: json['totalTickets'] as int? ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class SeatStatistics {
  final int totalSeats;
  final int bookedSeats;

  SeatStatistics({
    required this.totalSeats,
    required this.bookedSeats,
  });

  factory SeatStatistics.fromJson(Map<String, dynamic> json) {
    return SeatStatistics(
      totalSeats: json['totalSeats'] as int? ?? 0,
      bookedSeats: json['bookedSeats'] as int? ?? 0,
    );
  }
}

// User models
class UserInfo {
  final int id;
  final String email;
  final String fullName;
  final String role;
  final bool isActive;

  UserInfo({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.isActive,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'] as int? ?? 0,
      email: json['email'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      role: json['role'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

// Bus Company models
class BusCompanyInfo {
  final int id;
  final String name;
  final String description;
  final String status;
  final bool isActive;

  BusCompanyInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    required this.isActive,
  });

  factory BusCompanyInfo.fromJson(Map<String, dynamic> json) {
    return BusCompanyInfo(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: json['approvalStatus'] as String? ?? 'pending',
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

// Approval models
class PendingApproval {
  final int id;
  final String name;
  final String description;

  PendingApproval({
    required this.id,
    required this.name,
    required this.description,
  });

  factory PendingApproval.fromJson(Map<String, dynamic> json) {
    return PendingApproval(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }
}

// Comprehensive approval item for multiple types
class ApprovalItem {
  final String type; // 'bus_company' or 'ticket_cancellation'
  final int id;
  final String title;
  final String subtitle;
  final String? description;
  final DateTime requestedAt;
  final String? contactInfo;
  final Map<String, dynamic>? additionalData;

  ApprovalItem({
    required this.type,
    required this.id,
    required this.title,
    required this.subtitle,
    this.description,
    required this.requestedAt,
    this.contactInfo,
    this.additionalData,
  });

  factory ApprovalItem.fromBusCompany(Map<String, dynamic> json) {
    return ApprovalItem(
      type: 'bus_company',
      id: json['id'] as int? ?? 0,
      title: json['name'] as String? ?? '',
      subtitle: 'Nhà xe mới',
      description: json['description'] as String? ?? '',
      requestedAt: DateTime.now(),
      contactInfo: json['phoneNumber'] as String? ?? '',
      additionalData: {
        'email': json['email'] as String? ?? '',
        'address': json['address'] as String? ?? '',
        'licensePlate': json['licensePlate'] as String? ?? '',
      },
    );
  }

  factory ApprovalItem.fromTicketCancellation(Map<String, dynamic> json) {
    final trip = json['trip'] as Map<String, dynamic>?;
    final payment = json['payment'] as Map<String, dynamic>?;
    
    return ApprovalItem(
      type: 'ticket_cancellation',
      id: json['id'] as int? ?? 0,
      title: 'Yêu cầu hủy vé #${json['id']}',
      subtitle: trip != null ? (trip['departureCity'] as String? ?? '') : 'Chuyến xe',
      description: json['cancellationReason'] as String? ?? '',
      requestedAt: json['cancellationRequestedAt'] != null
          ? DateTime.parse(json['cancellationRequestedAt'] as String)
          : DateTime.now(),
      contactInfo: null,
      additionalData: {
        'ticketCode': json['ticketCode'] as String? ?? '',
        'status': json['status'] as String? ?? 'Booked',
        'amount': payment != null ? (payment['amount'] as num?)?.toDouble() ?? 0.0 : 0.0,
        'seatCount': (json['ticketSeats'] as List?)?.length ?? 1,
        'paymentStatus': payment != null ? (payment['status'] as String? ?? '') : '',
      },
    );
  }
}

// Review models
class ReviewInfo {
  final int id;
  final int userId;
  final int busCompanyId;
  final String busCompanyName;
  final String userName;
  final String userEmail;
  final double rating;
  final String comment;
  final bool isActive;
  final DateTime createdAt;

  ReviewInfo({
    required this.id,
    required this.userId,
    required this.busCompanyId,
    required this.busCompanyName,
    required this.userName,
    required this.userEmail,
    required this.rating,
    required this.comment,
    required this.isActive,
    required this.createdAt,
  });

  factory ReviewInfo.fromJson(Map<String, dynamic> json) {
    return ReviewInfo(
      id: json['id'] as int? ?? 0,
      userId: json['userId'] as int? ?? 0,
      busCompanyId: json['busCompanyId'] as int? ?? 0,
      busCompanyName: json['busCompany'] != null 
          ? (json['busCompany'] as Map<String, dynamic>)['name'] as String? ?? ''
          : '',
      userName: json['user'] != null 
          ? (json['user'] as Map<String, dynamic>)['fullName'] as String? ?? ''
          : '',
      userEmail: json['user'] != null
          ? (json['user'] as Map<String, dynamic>)['email'] as String? ?? ''
          : '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      comment: json['comment'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}

// Admin Service
class AdminService {
  AdminService._();
  static final AdminService instance = AdminService._();

  // Statistics
  Future<AdminStatistics?> getStatistics() async {
    final res = await ApiClient.instance.get('/admin/statistics');
    return AdminStatistics.fromJson(res);
  }

  Future<SeatStatistics?> getSeatStatistics() async {
    final res = await ApiClient.instance.get('/admin/statistics/seats');
    return SeatStatistics.fromJson(res);
  }

  // User Management
  Future<List<UserInfo>> getAllUsers() async {
    final res = await ApiClient.instance.get('/admin/users');
    final list = (res is List ? res : res['data'] as List? ?? []) as List<dynamic>;
    return list.map((item) => UserInfo.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<void> deactivateUser(int userId) async {
    await ApiClient.instance.delete('/admin/users/$userId');
  }

  Future<void> reactivateUser(int userId) async {
    await ApiClient.instance.put('/admin/users/$userId/reactivate');
  }

  // Bus Company Management
  Future<List<BusCompanyInfo>> getAllBusCompanies() async {
    final res = await ApiClient.instance.get('/admin/buscompanies');
    final list = (res is List ? res : res['data'] as List? ?? []) as List<dynamic>;
    return list.map((item) => BusCompanyInfo.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<void> deactivateCompany(int companyId) async {
    await ApiClient.instance.delete('/admin/buscompanies/$companyId');
  }

  Future<void> reactivateCompany(int companyId) async {
    await ApiClient.instance.put('/admin/buscompanies/$companyId/reactivate');
  }

  // Approvals - Bus Companies
  Future<List<PendingApproval>> getPendingApprovals() async {
    final res = await ApiClient.instance.get('/admin/buscompanies/pending');
    final list = (res is List ? res : res['data'] as List? ?? []) as List<dynamic>;
    return list.map((item) => PendingApproval.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<ApprovalItem>> getPendingBusCompanyApprovals() async {
    final res = await ApiClient.instance.get('/admin/buscompanies/pending');
    final list = (res is List ? res : res['data'] as List? ?? []) as List<dynamic>;
    return list.map((item) => ApprovalItem.fromBusCompany(item as Map<String, dynamic>)).toList();
  }

  Future<void> approveBusCompany(int companyId) async {
    await ApiClient.instance.put('/admin/buscompanies/$companyId/approve');
  }

  Future<void> rejectBusCompany(int companyId, String note) async {
    await ApiClient.instance.put(
      '/admin/buscompanies/$companyId/reject',
      body: {'rejectionNote': note},
    );
  }

  // Approvals - Ticket Cancellations
  Future<List<ApprovalItem>> getPendingTicketCancellations() async {
    final res = await ApiClient.instance.get('/admin/tickets/cancellation-requests');
    final list = (res is List ? res : res['data'] as List? ?? []) as List<dynamic>;
    return list.map((item) => ApprovalItem.fromTicketCancellation(item as Map<String, dynamic>)).toList();
  }

  Future<void> processCancellation(int ticketId, {
    required bool approve,
    required double? refundAmount,
    required String note,
  }) async {
    await ApiClient.instance.post(
      '/admin/tickets/$ticketId/process-cancellation',
      body: {
        'approve': approve,
        'refundAmount': refundAmount,
        'note': note,
      },
    );
  }

  // Comprehensive approval retrieval
  Future<List<ApprovalItem>> getAllPendingApprovals() async {
    try {
      final busCompanies = await getPendingBusCompanyApprovals();
      final ticketCancellations = await getPendingTicketCancellations();
      
      final all = [...busCompanies, ...ticketCancellations];
      all.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
      return all;
    } catch (e) {
      return [];
    }
  }

  // Reviews
  Future<List<ReviewInfo>> getAllReviews() async {
    final res = await ApiClient.instance.get('/admin/reviews');
    final list = (res is List ? res : res['data'] as List? ?? []) as List<dynamic>;
    return list.map((item) => ReviewInfo.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<void> deleteReview(int reviewId) async {
    await ApiClient.instance.delete('/admin/reviews/$reviewId');
  }

  Future<void> toggleReviewVisibility(int reviewId, bool isActive) async {
    await ApiClient.instance.put(
      '/admin/reviews/$reviewId/visibility',
      body: {'isActive': isActive},
    );
  }
}
