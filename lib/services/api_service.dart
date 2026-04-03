import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.0.112:8000/api';

  // POST pesanan
  static Future<Map<String, dynamic>?> kirimPesanan(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/pesanan'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: jsonEncode(data),
      );

      print('STATUS: ${response.statusCode}');
      print('BODY: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }

      return null;
    } catch (e) {
      print('ERROR API: $e');
      return null;
    }
  }

  // GET list pesanan
  static Future<List<dynamic>> getPesanan() async {
    final token = await AuthService.getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/pesanan'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load data');
    }
  }

  // POST selesaikan pesanan (pelanggan)
  static Future<bool> selesaikanPesanan(int orderId) async {
    final token = await AuthService.getToken();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/pesanan/$orderId/selesaikan'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('ERROR SELESAIKAN: $e');
      return false;
    }
  }

  // GET dashboard statistik
  static Future<Map<String, dynamic>> getDashboard() async {
    final response = await http.get(
      Uri.parse('$baseUrl/dashboard'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Gagal load dashboard');
    }
  }

  // GET tracking resi
  static Future<Map<String, dynamic>?> trackingResi(String resi) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tracking/$resi'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return null;
    } catch (e) {
      print('ERROR TRACKING: $e');
      return null;
    }
  }
}