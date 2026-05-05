import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = "https://lancarekspedisi.satcloud.tech/api";

  static Future<bool> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    print("Status: ${response.statusCode}");
    print("Body: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token']);

      return true;
    } else {
      return false;
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<Map<String, dynamic>?> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return null;

    final response = await http.get(
      Uri.parse('$baseUrl/user'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return null;
    }
  }

  static Future<Map<String, dynamic>> register(String name, String email, String password, {File? image}) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/register'));
      request.headers.addAll({
        'Accept': 'application/json',
      });

      request.fields['name'] = name;
      request.fields['email'] = email;
      request.fields['password'] = password;

      if (image != null) {
        request.files.add(await http.MultipartFile.fromPath('foto', image.path));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print("DEBUG REGISTER - Status: ${response.statusCode}");
      print("DEBUG REGISTER - Body: ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        return {'success': true, 'message': data['message'] ?? 'Berhasil'};
      } else {
        String errorMsg = data['message'] ?? 'Registrasi gagal';
        if (data['errors'] != null && data['errors'] is Map) {
          final errors = data['errors'] as Map;
          errorMsg = errors.values.first[0].toString();
        }
        return {'success': false, 'message': errorMsg};
      }
    } catch (e) {
      print("DEBUG REGISTER - Error Catch: $e");
      return {'success': false, 'message': 'Terjadi kesalahan koneksi: $e'};
    }
  }

  static Future<bool> updateProfile(String name, String email, {File? image}) async {
    final token = await getToken();
    if (token == null) return false;

    try {
      // Laravel requires POST with _method=PUT for multipart PUT requests
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/user/profile'));
      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      request.fields['name'] = name;
      request.fields['email'] = email;
      request.fields['_method'] = 'PUT'; // Method spoofing for Laravel

      if (image != null) {
        request.files.add(await http.MultipartFile.fromPath('foto', image.path));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/forgot-password'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email}),
      );

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'Terjadi kesalahan'
      };
    } catch (e) {
      return {'success': false, 'message': 'Kesalahan koneksi: $e'};
    }
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reset-password'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'otp': otp,
          'password': password,
          'password_confirmation': confirmPassword,
        }),
      );

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'Terjadi kesalahan'
      };
    } catch (e) {
      return {'success': false, 'message': 'Kesalahan koneksi: $e'};
    }
  }
}