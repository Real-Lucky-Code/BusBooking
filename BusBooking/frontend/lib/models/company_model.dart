class BusCompanyInfo {
  BusCompanyInfo({
    required this.id,
    required this.name,
    required this.description,
    this.ownerId,
    required this.isApproved,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
    this.averageRating,
  });

  final int id;
  final String name;
  final String description;
  final int? ownerId;
  final bool isApproved;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final double? averageRating;

  factory BusCompanyInfo.fromJson(Map<String, dynamic> json) {
    return BusCompanyInfo(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      ownerId: json['ownerId'],
      isApproved: json['isApproved'] ?? false,
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      averageRating: json['averageRating'] != null
          ? (json['averageRating'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'ownerId': ownerId,
    'isApproved': isApproved,
    'isActive': isActive,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'averageRating': averageRating,
  };
}

class CompanyRegistrationStatus {
  CompanyRegistrationStatus({
    required this.hasCompany,
    required this.status, // "none", "pending", "approved", "rejected"
    this.company,
    required this.message,
  });

  final bool hasCompany;
  final String status;
  final BusCompanyInfo? company;
  final String message;

  factory CompanyRegistrationStatus.fromJson(Map<String, dynamic> json) {
    return CompanyRegistrationStatus(
      hasCompany: json['hasCompany'] ?? false,
      status: json['status'] ?? 'none',
      company: json['company'] != null
          ? BusCompanyInfo.fromJson(json['company'] as Map<String, dynamic>)
          : null,
      message: json['message'] ?? '',
    );
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isNone => status == 'none';
}
