import '../models/mock_data.dart';
import '../services/api_client.dart';

class TripRepository {
  TripRepository._();
  static final TripRepository instance = TripRepository._();

  Future<List<TripSummary>> searchTrips({
    required String startLocation,
    required String endLocation,
    required DateTime departureDate,
    double? minPrice,
    double? maxPrice,
    String? busType,
    int? departureHourStart,
    int? departureHourEnd,
  }) async {
    final res = await ApiClient.instance.post('/trip/search', body: {
      'startLocation': startLocation,
      'endLocation': endLocation,
      'departureDate': departureDate.toIso8601String().split('T').first,
      if (minPrice != null) 'minPrice': minPrice,
      if (maxPrice != null) 'maxPrice': maxPrice,
      if (busType != null) 'busType': busType,
      if (departureHourStart != null) 'departureHourStart': departureHourStart,
      if (departureHourEnd != null) 'departureHourEnd': departureHourEnd,
    });
    final list = res['data'] ?? res;
    return (list as List)
        .map((e) => TripSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TripSummary> getTripDetail(int id) async {
    final res = await ApiClient.instance.get('/trip/$id');
    final data = res['data'] ?? res;
    return TripSummary.fromJson(data as Map<String, dynamic>);
  }

  Future<List<HotRoute>> getHotRoutes() async {
    // Return list of popular routes for users to explore
    return [
      HotRoute(startLocation: 'Hà Nội', endLocation: 'TP Hồ Chí Minh'),
      HotRoute(startLocation: 'TP Hồ Chí Minh', endLocation: 'Đà Nẵng'),
      HotRoute(startLocation: 'Hà Nội', endLocation: 'Thừa Thiên Huế'),
      HotRoute(startLocation: 'TP Hồ Chí Minh', endLocation: 'Lâm Đồng'),
      HotRoute(startLocation: 'Đà Nẵng', endLocation: 'Hồ Chí Minh'),
    ];
  }
}
