class AppConfig {
  AppConfig._();


  static const String baseUrl = 'http://localhost:5242';
  static const String apiPrefix = '/api';

  static const Duration requestTimeout = Duration(seconds: 12);
}
