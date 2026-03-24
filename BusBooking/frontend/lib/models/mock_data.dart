import 'package:flutter/material.dart';

class TripSummary {
  TripSummary({
    required this.id,
    required this.busId,
    required this.startLocation,
    required this.endLocation,
    required this.departureTime,
    required this.arrivalTime,
    required this.price,
    required this.busName,
    required this.busType,
    required this.availableSeats,
    required this.rating,
    this.totalSeats = 0,
    this.seats = const [],
    this.busCompanyName = '',
    this.isActive = true,
  });

  final int id;
  final int busId;
  final String startLocation;
  final String endLocation;
  final DateTime departureTime;
  final DateTime arrivalTime;
  final int price;
  final String busName;
  final String busType;
  final int availableSeats;
  final double rating;
  final int totalSeats;
  final List<SeatOption> seats;
  final String busCompanyName;
  final bool isActive;

  factory TripSummary.fromJson(Map<String, dynamic> json) {
    final totalSeats = json['bus']?['totalSeats'] ?? 0;
    final seatsFromJson = (json['seats'] as List?)
        ?.map((e) => SeatOption.fromJson(e as Map<String, dynamic>))
        .toList() ?? const [];
    
    // Tính số ghế còn lại từ dữ liệu seats từ database
    final bookedCount = seatsFromJson.where((s) => s.isBooked).length;
    final calculatedAvailable = totalSeats > 0 ? totalSeats - bookedCount : seatsFromJson.length - bookedCount;
    
    return TripSummary(
      id: json['id'] ?? 0,
      busId: json['busId'] ?? json['bus']?['id'] ?? 0,
      startLocation: json['startLocation'] ?? '',
      endLocation: json['endLocation'] ?? '',
      departureTime: DateTime.tryParse(json['departureTime'] ?? '') ?? DateTime.now(),
      arrivalTime: DateTime.tryParse(json['arrivalTime'] ?? '') ?? DateTime.now(),
      price: (json['price'] ?? 0).toInt(),
      busName: json['bus']?['busCompany']?['name'] ?? json['bus']?['licensePlate'] ?? json['busName'] ?? 'Chưa biết',
      busType: json['bus']?['type'] ?? json['busType'] ?? 'Chưa biết',
      availableSeats: calculatedAvailable,
      rating: (json['averageRating'] ?? json['rating'] ?? 0).toDouble(),
      totalSeats: totalSeats,
      seats: seatsFromJson,  // Use only seats from database
      busCompanyName: json['bus']?['busCompany']?['name'] ?? '',
      isActive: json['isActive'] ?? true,
    );
  }
}

class SeatOption {
  SeatOption({
    required this.id, 
    required this.label, 
    this.isBooked = false,
    double? price,
  }) : price = price ?? 0.0;
  
  final int id;
  final String label;
  final bool isBooked;
  final double price;

  factory SeatOption.fromJson(Map<String, dynamic> json) {
    final priceValue = json['price'];
    final double parsedPrice;
    if (priceValue == null) {
      parsedPrice = 0.0;
    } else if (priceValue is int) {
      parsedPrice = priceValue.toDouble();
    } else if (priceValue is double) {
      parsedPrice = priceValue;
    } else {
      parsedPrice = double.tryParse(priceValue.toString()) ?? 0.0;
    }
    
    // Lấy label từ seatNumber hoặc label, loại bỏ từ "Seat " nếu có
    var rawLabel = json['seatNumber'] ?? json['label'] ?? '${json['id'] ?? 0}';
    var cleanLabel = rawLabel.toString().replaceFirst(RegExp(r'^Seat\s*', caseSensitive: false), '');
    
    return SeatOption(
      id: json['id'] ?? 0,
      label: cleanLabel,
      isBooked: json['isBooked'] ?? false,
      price: parsedPrice,
    );
  }
}

class TicketSummary {
  TicketSummary({
    required this.id,
    required this.trip,
    required this.passengerName,
    required this.status,
    required this.paidAmount,
    required this.originalAmount,
    required this.discountAmount,
    this.promoCode,
    required this.paymentMethod,
    required this.seatIds,
    required this.seatNumbers,
    required this.ticketCode,
    required this.createdAt,
    required this.paymentStatus,
    this.paidAt,
    this.passengerPhone,
    this.passengerCCCD,
    this.cancellationRequestedAt,
    this.cancellationStatus,
    this.refundAmount,
    this.cancellationReason,
    this.cancellationProcessedAt,
    this.cancellationNote,
  });

  final int id;
  final TripSummary trip;
  final String passengerName;
  final String status;
  final int paidAmount;
  final int originalAmount;
  final int discountAmount;
  final String? promoCode;
  final String paymentMethod;
  final List<int> seatIds;
  final List<String> seatNumbers;
  final String ticketCode;
  final DateTime createdAt;
  final String paymentStatus;
  final DateTime? paidAt;
  final String? passengerPhone;
  final String? passengerCCCD;
  
  // Cancellation fields
  final DateTime? cancellationRequestedAt;
  final String? cancellationStatus;
  final int? refundAmount;
  final String? cancellationReason;
  final DateTime? cancellationProcessedAt;
  final String? cancellationNote;

  String get seatLabel {
    if (seatNumbers.isNotEmpty) return seatNumbers.join(', ');
    if (seatIds.isNotEmpty) return 'Ghế ${seatIds.join(', ')}';
    return 'Ghế';
  }

  factory TicketSummary.fromJson(Map<String, dynamic> json) {
    return TicketSummary(
      id: json['id'] ?? 0,
      trip: json['trip'] != null
          ? TripSummary.fromJson(json['trip'] as Map<String, dynamic>)
          : TripSummary(
              id: 0,
              busId: 0,
              startLocation: '',
              endLocation: '',
              departureTime: DateTime.now(),
              arrivalTime: DateTime.now(),
              price: 0,
              busName: '',
              busType: '',
              availableSeats: 0,
              rating: 0,
              isActive: true,
            ),
      passengerName: json['passengerName'] ?? json['passengerProfile']?['fullName'] ?? '',
      status: json['status'] ?? 'Pending',
        paidAmount: (json['payment']?['amount'] ?? json['paidAmount'] ?? json['price'] ?? 0).toInt(),
        originalAmount: (json['payment']?['originalAmount'] ?? json['originalAmount'] ?? json['price'] ?? 0).toInt(),
        discountAmount: (json['payment']?['discountAmount'] ?? json['discountAmount'] ?? 0).toInt(),
        promoCode: json['payment']?['promoCode'] ?? json['promoCode'],
        paymentMethod: json['payment']?['method'] ?? json['paymentMethod'] ?? 'Unknown',
        seatIds: (json['seatIds'] as List?)?.map((e) => (e ?? 0) as int).toList() ??
          (json['seats'] as List?)?.map((e) => (e as Map<String, dynamic>)['id'] ?? 0).cast<int>().toList() ??
          (json['seatId'] != null ? <int>[json['seatId']] : <int>[]),
        seatNumbers: (json['seats'] as List?)
            ?.map((e) => (e as Map<String, dynamic>)['seatNumber'])
            .cast<String>()
            .where((s) => s.isNotEmpty)
            .toList() ??
          (json['seatNumber'] != null ? <String>[json['seatNumber']] : <String>[]),
      ticketCode: json['ticketCode'] ?? json['code'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      paymentStatus: json['payment']?['status'] ?? json['paymentStatus'] ?? 'Pending',
      paidAt: DateTime.tryParse(json['payment']?['paidAt'] ?? ''),
      passengerPhone: json['passengerProfile']?['phone'] ?? '',
      passengerCCCD: json['passengerProfile']?['cccd'] ?? json['passengerProfile']?['identityNumber'] ?? '',
      cancellationRequestedAt: DateTime.tryParse(json['cancellationRequestedAt'] ?? ''),
      cancellationStatus: json['cancellationStatus'],
      refundAmount: json['refundAmount']?.toInt(),
      cancellationReason: json['cancellationReason'],
      cancellationProcessedAt: DateTime.tryParse(json['cancellationProcessedAt'] ?? ''),
      cancellationNote: json['cancellationNote'],
    );
  }
}

class PassengerProfile {
  PassengerProfile({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.identityNumber,
    this.note,
  });

  final int id;
  final String fullName;
  final String phone;
  final String identityNumber;
  final String? note;

  factory PassengerProfile.fromJson(Map<String, dynamic> json) {
    return PassengerProfile(
      id: json['id'] ?? 0,
      fullName: json['fullName'] ?? '',
      phone: json['phone'] ?? '',
      identityNumber: json['identityNumber'] ?? json['CCCD'] ?? json['cccd'] ?? json['citizenId'] ?? '',
      note: json['note'],
    );
  }
}

class MockData {
  static List<TripSummary> trips = [
    TripSummary(
      id: 1,
      busId: 1,
      startLocation: 'Ha Noi',
      endLocation: 'TP.HCM',
      departureTime: DateTime.now().add(const Duration(hours: 6)),
      arrivalTime: DateTime.now().add(const Duration(hours: 18)),
      price: 250000,
      busName: 'BusGo 51A-12345',
      busType: 'Sleeper',
      availableSeats: 25,
      rating: 4.5,
      seats: List.generate(
        20,
        (index) => SeatOption(
          id: index + 1,
          label: 'A${index + 1}',
          isBooked: index % 5 == 0,
          price: 200000,
        ),
      ),
      isActive: true,
    ),
    TripSummary(
      id: 2,
      busId: 2,
      startLocation: 'Da Nang',
      endLocation: 'Hue',
      departureTime: DateTime.now().add(const Duration(hours: 3)),
      arrivalTime: DateTime.now().add(const Duration(hours: 6)),
      price: 150000,
      busName: 'Central Coach 43C-9876',
      busType: 'Limousine',
      availableSeats: 8,
      rating: 4.8,
      seats: List.generate(
        12,
        (index) => SeatOption(
          id: index + 21,
          label: 'B${index + 1}',
          isBooked: index % 4 == 0,
          price: 150000,
        ),
      ),
      isActive: true,
    ),
  ];

  static List<TicketSummary> tickets = [
    TicketSummary(
      id: 101,
      trip: trips[0],
      passengerName: 'Alex Nguyen',
      status: 'Confirmed',
      paidAmount: 225000,
      originalAmount: 250000,
      discountAmount: 25000,
      promoCode: 'HAIAU10',
      paymentMethod: 'Momo',
      seatIds: const [1],
      seatNumbers: const ['A1'],
      ticketCode: 'TK123456',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      paymentStatus: 'Paid',
      paidAt: DateTime.now().subtract(const Duration(days: 1)).add(const Duration(hours: 1)),
      passengerPhone: '0901234567',
      passengerCCCD: '012345678',
    ),
    TicketSummary(
      id: 102,
      trip: trips[1],
      passengerName: 'Linh Tran',
      status: 'Pending',
      paidAmount: 150000,
      originalAmount: 150000,
      discountAmount: 0,
      paymentMethod: 'Cash',
      seatIds: const [2],
      seatNumbers: const ['B2'],
      ticketCode: 'TK654321',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      paymentStatus: 'Pending',
      paidAt: null,
      passengerPhone: '0912345678',
      passengerCCCD: '987654321',
    ),
  ];

  static List<PassengerProfile> passengers = [
    PassengerProfile(
      id: 1,
      fullName: 'Alex Nguyen',
      phone: '0901234567',
      identityNumber: '012345678',
      note: 'Wheelchair support',
    ),
    PassengerProfile(
      id: 2,
      fullName: 'Linh Tran',
      phone: '0912345678',
      identityNumber: '987654321',
    ),
  ];

  static List<UserProfile> users = [
    UserProfile(
      id: 1,
      email: 'alex@example.com',
      fullName: 'Alex Nguyen',
      phone: '0901234567',
      role: 'User',
    ),
  ];

  static List<Map<String, dynamic>> buses = [
    {
      'name': 'BusGo 51A-12345',
      'type': 'Sleeper 40 seats',
      'status': 'Active',
    },
    {
      'name': 'Central Coach 43C-9876',
      'type': 'Limousine 18 seats',
      'status': 'Maintenance',
    },
  ];

  static List<Map<String, dynamic>> promotions = [
    {'title': 'Tet Early Bird', 'discount': '15%', 'valid': '2025-01-31'},
    {'title': 'Weekend Saver', 'discount': '10%', 'valid': '2025-02-28'},
  ];

  static List<Map<String, dynamic>> reviews = [
    {
      'user': 'Hoang',
      'rating': 4.5,
      'content': 'Bus was clean and on time.',
    },
    {
      'user': 'Mai',
      'rating': 4.0,
      'content': 'Comfortable seats, would ride again.',
    },
  ];

  static List<Map<String, dynamic>> adminStats = [
    {'label': 'Users', 'value': 1250},
    {'label': 'Trips', 'value': 320},
    {'label': 'Tickets', 'value': 5400},
    {'label': 'Pending Companies', 'value': 6},
  ];
}

class UserProfile {
  UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phone,
    required this.role,
    this.companyStatus,
  });

  final int id;
  final String email;
  final String fullName;
  final String phone;
  final String role;
  final CompanyRegistrationStatusModel? companyStatus;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'User',
      companyStatus: json['companyStatus'] != null
          ? CompanyRegistrationStatusModel.fromJson(
              json['companyStatus'] as Map<String, dynamic>)
          : null,
    );
  }
}

class CompanyRegistrationStatusModel {
  CompanyRegistrationStatusModel({
    required this.hasCompany,
    required this.status,
    this.company,
    required this.message,
  });

  final bool hasCompany;
  final String status; // "none", "pending", "approved", "rejected"
  final BusCompanyDetailModel? company;
  final String message;

  factory CompanyRegistrationStatusModel.fromJson(Map<String, dynamic> json) {
    return CompanyRegistrationStatusModel(
      hasCompany: json['hasCompany'] ?? false,
      status: json['status'] ?? 'none',
      company: json['company'] != null
          ? BusCompanyDetailModel.fromJson(
              json['company'] as Map<String, dynamic>)
          : null,
      message: json['message'] ?? '',
    );
  }

  // Create from CompanyRegistrationStatus (from API)
  factory CompanyRegistrationStatusModel.fromStatus(dynamic status) {
    return CompanyRegistrationStatusModel(
      hasCompany: status.hasCompany ?? false,
      status: status.status ?? 'none',
      company: status.company != null
          ? BusCompanyDetailModel(
              id: status.company.id,
              name: status.company.name,
              description: status.company.description,
              ownerId: status.company.ownerId,
              isApproved: status.company.isApproved,
              isActive: status.company.isActive,
            )
          : null,
      message: status.message ?? '',
    );
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isNone => status == 'none';
}

class BusCompanyDetailModel {
  BusCompanyDetailModel({
    required this.id,
    required this.name,
    required this.description,
    this.ownerId,
    required this.isApproved,
    required this.isActive,
  });

  final int id;
  final String name;
  final String description;
  final int? ownerId;
  final bool isApproved;
  final bool isActive;

  factory BusCompanyDetailModel.fromJson(Map<String, dynamic> json) {
    return BusCompanyDetailModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      ownerId: json['ownerId'],
      isApproved: json['isApproved'] ?? false,
      isActive: json['isActive'] ?? true,
    );
  }
}

String formatDateTime(DateTime time) {
  return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} - ${time.day}/${time.month}/${time.year}';
}

String currency(int value) {
  final formatted = value.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match.group(1)}.',
  );
  return '$formatted VND';
}

extension Spacing on num {
  SizedBox get vSpace => SizedBox(height: toDouble());
  SizedBox get hSpace => SizedBox(width: toDouble());
}

class SearchResult {
  SearchResult({
    required this.trips,
    required this.startLocation,
    required this.endLocation,
    required this.departureDate,
  });

  final List<TripSummary> trips;
  final String startLocation;
  final String endLocation;
  final DateTime departureDate;
}

class HotRoute {
  HotRoute({
    required this.startLocation,
    required this.endLocation,
  });

  final String startLocation;
  final String endLocation;

  String get displayName => '$startLocation → $endLocation';
}

class Review {
  Review({
    required this.id,
    required this.userId,
    required this.busCompanyId,
    required this.rating,
    required this.comment,
    required this.isActive,
    required this.createdAt,
    this.user,
  });

  final int id;
  final int userId;
  final int busCompanyId;
  final int rating;
  final String comment;
  final bool isActive;
  final DateTime createdAt;
  final UserProfile? user;

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      busCompanyId: json['busCompanyId'] ?? 0,
      rating: json['rating'] ?? 0,
      comment: json['comment'] ?? '',
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      user: json['user'] != null
          ? UserProfile.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }
}
