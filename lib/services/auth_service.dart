import 'dart:convert';
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
      await prefs.setString('token', data['token']); // ✅ INI YANG BENAR

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

  static Future<Map<String, dynamic>> register(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      print("DEBUG REGISTER - Status: ${response.statusCode}");
      print("DEBUG REGISTER - Body: ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        return {'success': true, 'message': data['message'] ?? 'Berhasil'};
      } else {
        // Ambil pesan error dari Laravel (biasanya ada di data['message'] atau data['errors'])
        String errorMsg = data['message'] ?? 'Registrasi gagal';
        if (data['errors'] != null && data['errors'] is Map) {
          final errors = data['errors'] as Map;
          errorMsg = errors.values.first[0].toString(); // Ambil error pertama
        }
        return {'success': false, 'message': errorMsg};
      }
    } catch (e) {
      print("DEBUG REGISTER - Error Catch: $e");
      return {'success': false, 'message': 'Terjadi kesalahan koneksi: $e'};
    }
  }

  static Future<bool> updateProfile(String name, String email) async {
    final token = await getToken();
    if (token == null) return false;

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/user/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}