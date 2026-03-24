import '../models/mock_data.dart';
import '../services/api_client.dart';

class ProfileRepository {
  ProfileRepository._();
  static final ProfileRepository instance = ProfileRepository._();

  Future<UserProfile> getProfile(int userId) async {
    final res = await ApiClient.instance.get('/user/$userId');
    final data = res['data'] ?? res;
    return UserProfile.fromJson(data as Map<String, dynamic>);
  }

  Future<UserProfile> updateProfile(UserProfile profile) async {
    final res = await ApiClient.instance.put('/user/${profile.id}/profile', body: {
      'fullName': profile.fullName,
      'phone': profile.phone,
      'role': profile.role,
    });
    final data = res['data'] ?? res;
    return UserProfile.fromJson(data as Map<String, dynamic>);
  }

  Future<List<PassengerProfile>> listPassengerProfiles(int userId) async {
    final res = await ApiClient.instance.get('/user/$userId/passenger-profiles');
    final list = res['data'] ?? res;
    return (list as List)
        .map((e) => PassengerProfile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PassengerProfile> createPassengerProfile({
    required int userId,
    required String fullName,
    required String phone,
    required String identityNumber,
    String? note,
  }) async {
    final res = await ApiClient.instance.post('/user/$userId/passenger-profiles', body: {
      'fullName': fullName,
      'phone': phone,
      'CCCD': identityNumber,
      if (note != null) 'note': note,
    });
    final data = res['data'] ?? res;
    return PassengerProfile.fromJson(data as Map<String, dynamic>);
  }

  Future<PassengerProfile> updatePassengerProfile(PassengerProfile profile) async {
    final res = await ApiClient.instance.put('/user/passenger-profile/${profile.id}', body: {
      'fullName': profile.fullName,
      'phone': profile.phone,
      'CCCD': profile.identityNumber,
      if (profile.note != null) 'note': profile.note,
    });
    final data = res['data'] ?? res;
    return PassengerProfile.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deletePassengerProfile(int id) async {
    await ApiClient.instance.delete('/user/passenger-profile/$id');
  }
}
