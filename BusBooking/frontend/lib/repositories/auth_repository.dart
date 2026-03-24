import '../models/mock_data.dart';
import '../models/company_model.dart';
import '../services/api_client.dart';

class AuthRepository {
  AuthRepository._();
  static final AuthRepository instance = AuthRepository._();

  UserProfile? currentUser;

  // Update company status without re-login
  void updateCompanyStatus(CompanyRegistrationStatus status) {
    if (currentUser != null) {
      currentUser = UserProfile(
        id: currentUser!.id,
        email: currentUser!.email,
        fullName: currentUser!.fullName,
        phone: currentUser!.phone,
        role: currentUser!.role,
        companyStatus: CompanyRegistrationStatusModel.fromStatus(status),
      );
    }
  }

  // Get current user's company ID (for Provider role only)
  int? get currentCompanyId {
    if (currentUser?.role != 'Provider') return null;
    return currentUser?.companyStatus?.company?.id;
  }

  Future<UserProfile> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    String role = 'User',
  }) async {
    final res = await ApiClient.instance.post('/auth/register', body: {
      'email': email,
      'password': password,
      'fullName': fullName,
      'phone': phone,
      'role': role,
    });
    final userJson = res['user'] as Map<String, dynamic>? ?? res;
    final token = res['token'] ?? res['accessToken'];
    if (token != null) {
      await ApiClient.instance.setToken(token as String);
    }
    currentUser = UserProfile.fromJson(userJson);
    return currentUser!;
  }

  Future<UserProfile> login({required String email, required String password}) async {
    final res = await ApiClient.instance.post('/auth/login', body: {
      'email': email,
      'password': password,
    });
    final token = res['token'] ?? res['accessToken'];
    if (token != null) {
      await ApiClient.instance.setToken(token as String);
    }
    final userJson = res['user'] as Map<String, dynamic>? ?? {};
    // Add companyStatus from root level to user object
    if (res['companyStatus'] != null) {
      userJson['companyStatus'] = res['companyStatus'];
    }
    currentUser = UserProfile.fromJson(userJson);
    return currentUser!;
  }

  Future<void> logout() async {
    try {
      await ApiClient.instance.post('/auth/logout');
    } catch (_) {
      // Ignore logout network errors.
    }
    currentUser = null;
    await ApiClient.instance.clearToken();
  }
}
