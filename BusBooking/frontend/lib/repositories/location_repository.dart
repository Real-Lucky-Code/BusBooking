import '../services/api_client.dart';

class LocationRepository {
  LocationRepository._();
  static final LocationRepository instance = LocationRepository._();

  Future<List<String>> getProvinces() async {
    final res = await ApiClient.instance.get('/location');
    final list = res['data'] ?? res;
    return (list as List).map((e) => e.toString()).toList();
  }
}
