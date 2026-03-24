import 'dart:io';

import '../models/entities.dart';
import '../models/mock_data.dart';
import '../services/api_client.dart';

class BusCompanyRepository {
  BusCompanyRepository._();
  static final BusCompanyRepository instance = BusCompanyRepository._();

  Future<List<BusInfo>> getBuses({required int companyId}) async {
    final res = await ApiClient.instance.get('/buscompany/$companyId/buses');
    final list = res['data'] ?? res;
    return (list as List)
        .map((e) => BusInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<BusInfo> createBus({
    required int companyId,
    required String licensePlate,
    required String type,
    required int totalSeats,
    String? imageUrl,
  }) async {
    final res = await ApiClient.instance.post(
      '/buscompany/$companyId/buses',
      body: {
        'licensePlate': licensePlate,
        'type': type,
        'totalSeats': totalSeats,
        'imageUrl': imageUrl ?? 'https://via.placeholder.com/300x200',
      },
    );
    final data = res['data'] ?? res;
    return BusInfo.fromJson(data as Map<String, dynamic>);
  }

  Future<BusInfo> updateBus({
    required int busId,
    String? licensePlate,
    String? type,
    int? totalSeats,
    String? imageUrl,
  }) async {
    final res = await ApiClient.instance.put(
      '/buscompany/bus/$busId',
      body: {
        if (licensePlate != null) 'licensePlate': licensePlate,
        if (type != null) 'type': type,
        if (totalSeats != null) 'totalSeats': totalSeats,
        if (imageUrl != null) 'imageUrl': imageUrl,
      },
    );
    final data = res['bus'] ?? res['data'] ?? res;
    return BusInfo.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteBus({required int busId}) async {
    await ApiClient.instance.delete('/buscompany/bus/$busId');
  }

  Future<void> toggleBusStatus({required int busId}) async {
    await ApiClient.instance.put('/buscompany/bus/$busId/toggle-status');
  }

  Future<String> uploadBusImage(File file) async {
    final res = await ApiClient.instance.uploadFile('/upload/bus-image', file: file);
    return (res['url'] ?? res['data']?['url']) as String;
  }

  Future<List<PromotionInfo>> getPromotions({required int companyId}) async {
    final res = await ApiClient.instance.get('/buscompany/$companyId/promotions');
    final list = res['data'] ?? res;
    return (list as List)
        .map((e) => PromotionInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<TripSummary>> getTrips({
    required int companyId,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? startLocation,
    String? endLocation,
    String? busType,
    bool? isActive,
  }) async {
    final query = <String, String>{};
    if (dateFrom != null) query['dateFrom'] = dateFrom.toIso8601String();
    if (dateTo != null) query['dateTo'] = dateTo.toIso8601String();
    if (startLocation != null && startLocation.isNotEmpty) query['startLocation'] = startLocation;
    if (endLocation != null && endLocation.isNotEmpty) query['endLocation'] = endLocation;
    if (busType != null && busType.isNotEmpty) query['busType'] = busType;
    if (isActive != null) query['isActive'] = isActive.toString();

    final queryString = query.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    final path = queryString.isEmpty
        ? '/buscompany/$companyId/trips'
        : '/buscompany/$companyId/trips?$queryString';

    final res = await ApiClient.instance.get(path);
    final list = res['data'] ?? res;

    return (list as List)
        .map((e) => TripSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TripSummary> createTrip({
    required int companyId,
    required int busId,
    required String startLocation,
    required String endLocation,
    required DateTime departureTime,
    required DateTime arrivalTime,
    required int price,
  }) async {
    final res = await ApiClient.instance.post(
      '/buscompany/$companyId/trips',
      body: {
        'busId': busId,
        'startLocation': startLocation,
        'endLocation': endLocation,
        'departureTime': departureTime.toIso8601String(),
        'arrivalTime': arrivalTime.toIso8601String(),
        'price': price,
      },
    );
    final data = res['trip'] ?? res['data'] ?? res;
    return TripSummary.fromJson(data as Map<String, dynamic>);
  }

  Future<TripSummary> updateTrip({
    required int companyId,
    required int tripId,
    required int busId,
    required String startLocation,
    required String endLocation,
    required DateTime departureTime,
    required DateTime arrivalTime,
    required int price,
  }) async {
    final res = await ApiClient.instance.put(
      '/buscompany/$companyId/trips/$tripId',
      body: {
        'busId': busId,
        'startLocation': startLocation,
        'endLocation': endLocation,
        'departureTime': departureTime.toIso8601String(),
        'arrivalTime': arrivalTime.toIso8601String(),
        'price': price,
      },
    );
    final data = res['trip'] ?? res['data'] ?? res;
    return TripSummary.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteTrip({
    required int companyId,
    required int tripId,
  }) async {
    await ApiClient.instance.delete('/buscompany/$companyId/trips/$tripId');
  }

  Future<List<Map<String, dynamic>>> getBookings({int? tripId, int? companyId}) async {
    // If tripId is provided, get bookings for specific trip
    // Otherwise, get all bookings for the company
    if (tripId != null) {
      final res = await ApiClient.instance.get('/trip/$tripId/bookings');
      final list = res['data'] ?? res;
      return (list as List).cast<Map<String, dynamic>>();
    } else if (companyId != null) {
      final res = await ApiClient.instance.get('/buscompany/$companyId/bookings');
      final list = res['data'] ?? res;
      return (list as List).cast<Map<String, dynamic>>();
    } else {
      throw Exception('Either tripId or companyId must be provided');
    }
  }

  Future<void> checkInPassenger({required int tripId, required int ticketId}) async {
    await ApiClient.instance.put('/trip/$tripId/bookings/$ticketId/checkin');
  }

  Future<List<Map<String, dynamic>>> getSeats({required int tripId}) async {
    final res = await ApiClient.instance.get('/trip/$tripId/seats');
    final list = res['data'] ?? res;
    return (list as List).cast<Map<String, dynamic>>();
  }

  Future<void> releaseSeat({required int tripId, required String seatNumber}) async {
    await ApiClient.instance.delete('/buscompany/bus/seats/$seatNumber/release');
  }

  Future<List<Map<String, dynamic>>> getBusSeats({required int busId}) async {
    final res = await ApiClient.instance.get('/buscompany/bus/$busId/seats');
    final list = res['data'] ?? res;
    return (list as List).cast<Map<String, dynamic>>();
  }

  Future<void> updateBusSeat({
    required int busId,
    required int seatId,
    String? seatNumber,
    bool? isActive,
  }) async {
    final body = <String, dynamic>{};
    if (seatNumber != null) body['seatNumber'] = seatNumber;
    if (isActive != null) body['isActive'] = isActive;

    await ApiClient.instance.put(
      '/buscompany/bus/$busId/seats/$seatId',
      body: body,
    );
  }

  Future<PromotionInfo> createPromotion({
    required int companyId,
    required String code,
    required double discountPercent,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final res = await ApiClient.instance.post(
      '/buscompany/$companyId/promotions',
      body: {
        'code': code,
        'discountPercent': discountPercent,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      },
    );
    final data = res['data'] ?? res;
    return PromotionInfo.fromJson(data as Map<String, dynamic>);
  }

  Future<PromotionInfo> updatePromotion({
    required int companyId,
    required int promotionId,
    required String code,
    required double discountPercent,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final res = await ApiClient.instance.put(
      '/buscompany/$companyId/promotions/$promotionId',
      body: {
        'code': code,
        'discountPercent': discountPercent,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      },
    );
    final data = res['promotion'] ?? res['data'] ?? res;
    return PromotionInfo.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deletePromotion({
    required int companyId,
    required int promotionId,
  }) async {
    await ApiClient.instance.delete(
      '/buscompany/$companyId/promotions/$promotionId',
    );
  }
}
