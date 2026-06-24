// ── API Service ────────────────────────────────────────────────
// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';

class ApiService {
  // Gunakan IP WiFi laptop agar HP bisa konek dalam jaringan yang sama
  static const String baseUrl = 'http://192.168.1.14/gizi-app/public/api';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user_name');
  }

  static Future<Map<String, String>> _headers({bool auth = false}) async {
    final headers = {'Content-Type': 'application/json', 'Accept': 'application/json'};
    if (auth) {
      final token = await getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // Auth
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: await _headers(),
      body: jsonEncode({'email': email, 'password': password}),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> loginWithGoogle() async {
    try {
      // Hasil Revisi: Instansiasi objek GoogleSignIn disesuaikan agar dikenali compiler Dart
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: [
          'email',
          'https://www.googleapis.com/auth/contacts.readonly',
        ],
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        return {'success': false, 'message': 'Login Google dibatalkan.'};
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        return {'success': false, 'message': 'Gagal mendapatkan token Google.'};
      }

      // Send token to backend API
      final res = await http.post(
        Uri.parse('$baseUrl/login/google'),
        headers: await _headers(),
        body: jsonEncode({'id_token': idToken}),
      );

      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Kesalahan saat login Google: $e'};
    }
  }

  static Future<Map<String, dynamic>> register(String name, String email, String password, String passwordConfirmation) async {
    final res = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: await _headers(),
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      }),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> logout() async {
    final res = await http.post(
      Uri.parse('$baseUrl/logout'),
      headers: await _headers(auth: true),
    );
    return jsonDecode(res.body);
  }

  // Dashboard
  static Future<Map<String, dynamic>> getDashboard() async {
    final res = await http.get(
      Uri.parse('$baseUrl/dashboard'),
      headers: await _headers(auth: true),
    );
    return jsonDecode(res.body);
  }

  // Foods list (with optional search & category filter)
  static Future<Map<String, dynamic>> getFoods({String? search, String? kategori}) async {
    final params = <String, String>{};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (kategori != null && kategori.isNotEmpty) params['kategori'] = kategori;
    final uri = Uri.parse('$baseUrl/foods').replace(queryParameters: params.isEmpty ? null : params);
    final res = await http.get(uri, headers: await _headers());
    return jsonDecode(res.body);
  }

  // Meal plan mingguan (perlu auth)
  static Future<Map<String, dynamic>> getMealPlan() async {
    final res = await http.get(
      Uri.parse('$baseUrl/foods/meal-plan'),
      headers: await _headers(auth: true),
    );
    return jsonDecode(res.body);
  }

  // Insight
  static Future<Map<String, dynamic>> getInsight() async {
    final res = await http.get(
      Uri.parse('$baseUrl/insight'),
      headers: await _headers(auth: true),
    );
    return jsonDecode(res.body);
  }

  // Log food
  static Future<Map<String, dynamic>> logFood(int foodId, String waktu, {double porsi = 100}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/food/log'),
      headers: await _headers(auth: true),
      body: jsonEncode({'food_id': foodId, 'waktu_makan': waktu, 'porsi_gram': porsi}),
    );
    return jsonDecode(res.body);
  }

  // Log Activity
  static Future<Map<String, dynamic>> logActivity(String name, double met, int duration) async {
    final res = await http.post(
      Uri.parse('$baseUrl/activity-log'),
      headers: await _headers(auth: true),
      body: jsonEncode({
        'activity_name': name,
        'met': met,
        'duration_minutes': duration,
      }),
    );
    return jsonDecode(res.body);
  }

  // BMI Update
  static Future<Map<String, dynamic>> updateBmi({
    required double tinggi,
    required double berat,
    required int usia,
    required String gender,
    required String aktivitas,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/bmi'),
      headers: await _headers(auth: true),
      body: jsonEncode({
        'tinggi_badan': tinggi,
        'berat_badan': berat,
        'usia': usia,
        'jenis_kelamin': gender,
        'aktivitas': aktivitas,
      }),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getLatestBmi() async {
    final res = await http.get(
      Uri.parse('$baseUrl/bmi/latest'),
      headers: await _headers(auth: true),
    );
    return jsonDecode(res.body);
  }

  // Delete Food Log
  static Future<Map<String, dynamic>> deleteFoodLog(int logId) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/food/log/$logId'),
      headers: await _headers(auth: true),
    );
    return jsonDecode(res.body);
  }

  // Food History
  static Future<Map<String, dynamic>> getFoodHistory({int days = 7, String? date}) async {
    final params = <String, String>{};
    if (date != null) {
      params['date'] = date;
    } else {
      params['days'] = days.toString();
    }
    final uri = Uri.parse('$baseUrl/food-history').replace(queryParameters: params);
    final res = await http.get(uri, headers: await _headers(auth: true));
    return jsonDecode(res.body);
  }
}