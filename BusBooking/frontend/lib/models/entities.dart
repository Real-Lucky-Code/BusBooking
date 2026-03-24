class BusInfo {
  BusInfo({
    required this.id,
    required this.busCompanyId,
    required this.licensePlate,
    required this.type,
    required this.totalSeats,
    this.imageUrl,
    this.isActive = true,
  });

  final int id;
  final int busCompanyId;
  final String licensePlate;
  final String type;
  final int totalSeats;
  final String? imageUrl;
  final bool isActive;

  factory BusInfo.fromJson(Map<String, dynamic> json) {
    return BusInfo(
      id: json['id'] ?? 0,
      busCompanyId: json['busCompanyId'] ?? 0,
      licensePlate: json['licensePlate'] ?? '',
      type: json['type'] ?? '',
      totalSeats: (json['totalSeats'] ?? 0).toInt(),
      imageUrl: json['imageUrl'] as String?,
      isActive: json['isActive'] ?? true,
    );
  }
}

class PromotionInfo {
  PromotionInfo({
    required this.id,
    required this.busCompanyId,
    required this.code,
    required this.discountPercent,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
  });

  final int id;
  final int busCompanyId;
  final String code;
  final double discountPercent;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;

  factory PromotionInfo.fromJson(Map<String, dynamic> json) {
    return PromotionInfo(
      id: json['id'] ?? 0,
      busCompanyId: json['busCompanyId'] ?? 0,
      code: json['code'] ?? '',
      discountPercent: (json['discountPercent'] ?? 0).toDouble(),
      startDate: DateTime.tryParse(json['startDate'] ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(json['endDate'] ?? '') ?? DateTime.now(),
      isActive: json['isActive'] ?? true,
    );
  }
}

class BusCompanyInfo {
  BusCompanyInfo({
    required this.id,
    required this.name,
    this.description,
    this.isApproved = false,
    this.isActive = true,
    this.averageRating = 0,
  });

  final int id;
  final String name;
  final String? description;
  final bool isApproved;
  final bool isActive;
  final double averageRating;

  factory BusCompanyInfo.fromJson(Map<String, dynamic> json) {
    return BusCompanyInfo(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] as String?,
      isApproved: json['isApproved'] ?? false,
      isActive: json['isActive'] ?? true,
      averageRating: (json['averageRating'] ?? 0).toDouble(),
    );
  }
}

class SystemStatistics {
  SystemStatistics({
    required this.totalUsers,
    required this.totalBusCompanies,
    required this.approvedBusCompanies,
    required this.totalTrips,
    required this.totalTickets,
    required this.totalRevenue,
  });

  final int totalUsers;
  final int totalBusCompanies;
  final int approvedBusCompanies;
  final int totalTrips;
  final int totalTickets;
  final num totalRevenue;

  factory SystemStatistics.fromJson(Map<String, dynamic> json) {
    return SystemStatistics(
      totalUsers: json['totalUsers'] ?? 0,
      totalBusCompanies: json['totalBusCompanies'] ?? 0,
      approvedBusCompanies: json['approvedBusCompanies'] ?? 0,
      totalTrips: json['totalTrips'] ?? 0,
      totalTickets: json['totalTickets'] ?? 0,
      totalRevenue: json['totalRevenue'] ?? 0,
    );
  }
}
