import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  final http.Client _client = http.Client();
  String? _token;

  Future<void> loadPersistedToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  Map<String, String> _headers([Map<String, String>? extra]) {
    final base = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (_token != null && _token!.isNotEmpty) 'Authorization': 'Bearer $_token',
    };
    if (extra != null) base.addAll(extra);
    return base;
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final cleanPath = path.startsWith('http') ? path : '${AppConfig.baseUrl}${AppConfig.apiPrefix}$path';
    return Uri.parse(cleanPath).replace(queryParameters: query?.map((k, v) => MapEntry(k, v.toString())));
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) async {
    final res = await _client
        .get(_uri(path, query), headers: _headers())
        .timeout(AppConfig.requestTimeout);
    return _handle(res);
  }

  Future<Map<String, dynamic>> post(String path, {Object? body}) async {
    final res = await _client
        .post(_uri(path), headers: _headers(), body: body == null ? null : jsonEncode(body))
        .timeout(AppConfig.requestTimeout);
    return _handle(res);
  }

  Future<Map<String, dynamic>> put(String path, {Object? body}) async {
    final res = await _client
        .put(_uri(path), headers: _headers(), body: body == null ? null : jsonEncode(body))
        .timeout(AppConfig.requestTimeout);
    return _handle(res);
  }

  Future<Map<String, dynamic>> delete(String path, {Object? body}) async {
    final res = await _client
        .delete(_uri(path), headers: _headers(), body: body == null ? null : jsonEncode(body))
        .timeout(AppConfig.requestTimeout);
    return _handle(res);
  }

  Future<Map<String, dynamic>> uploadFile(String path, {required File file, String fieldName = 'file'}) async {
    final request = http.MultipartRequest('POST', _uri(path));
    // Add auth header but let Multipart set its own content-type
    final headers = _headers();
    headers.remove('Content-Type');
    request.headers.addAll(headers);

    request.files.add(await http.MultipartFile.fromPath(fieldName, file.path));

    final streamed = await request.send().timeout(AppConfig.requestTimeout);
    final res = await http.Response.fromStream(streamed);
    return _handle(res);
  }

  Map<String, dynamic> _handle(http.Response res) {
    final decoded = res.body.isNotEmpty ? jsonDecode(res.body) : {};
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return decoded is Map<String, dynamic> ? decoded : {'data': decoded};
    }
    throw ApiException(res.statusCode, decoded['message'] ?? 'Request failed');
  }
}

class ApiException implements Exception {
  ApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
