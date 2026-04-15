import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';

class ApiService {
  static const String baseUrl = "https://lancarekspedisi.satcloud.tech/api";

  // POST pesanan
  static Future<Map<String, dynamic>?> kirimPesanan(Map<String, dynamic> data) async {
    final token = await AuthService.getToken();
    print('DEBUG ORDER - Token: $token');
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/pesanan'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: jsonEncode(data),
      );

      print('DEBUG ORDER - Status: ${response.statusCode}');
      print('DEBUG ORDER - Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        print('DEBUG ORDER - Error: Sesi tidak valid / Belum login');
      }

      return null;
    } catch (e) {
      print('DEBUG ORDER - Exception: $e');
      return null;
    }
  }

  // GET list pesanan
  static Future<List<dynamic>> getPesanan() async {
    final token = await AuthService.getToken();
    print('DEBUG GET_PESANAN - Token: $token');
    
    final response = await http.get(
      Uri.parse('$baseUrl/pesanan'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    print('DEBUG GET_PESANAN - Status: ${response.statusCode}');
    print('DEBUG GET_PESANAN - Body: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load data: ${response.statusCode}');
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

  // POST batalkan pesanan (pelanggan)
  static Future<bool> batalkanPesanan(int orderId) async {
    final token = await AuthService.getToken();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/pesanan/$orderId/batal'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
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