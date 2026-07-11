// ── API Service ────────────────────────────────────────────────
// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

class ApiService {
  static String get baseUrl => AppConfig.baseUrl;
  static bool useMockData = false;

  // ── Token & Session ─────────────────────────────────────────
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_name');
  }

  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_email');
  }

  static Future<void> saveToken(String token,
      {String role = 'user', String? name, String? email}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('role', role);
    if (name != null) await prefs.setString('user_name', name);
    if (email != null) await prefs.setString('user_email', email);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('role');
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
    } catch (_) {}
  }

  static Future<Map<String, String>> _headers({bool auth = false}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (auth) {
      final token = await getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // ── Auth ─────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/login'),
            headers: await _headers(),
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(AppConfig.connectTimeout);
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  static Future<Map<String, dynamic>> loginWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId:
            '439907351995-9a38oj99i8rnbambgvh1k65tcseso3kq.apps.googleusercontent.com',
        scopes: ['email'],
      );

      // Selalu sign out dan disconnect terlebih dahulu sebelum melakukan sign in agar dialog pemilihan akun Google muncul
      try {
        await googleSignIn.signOut();
        await googleSignIn.disconnect();
      } catch (e) {
        debugPrint('Google Sign Out/Disconnect error sebelum sign in: $e');
      }

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return {'success': false, 'message': 'Login Google dibatalkan.'};
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        return {'success': false, 'message': 'Gagal mendapatkan token Google.'};
      }

      final res = await http
          .post(
            Uri.parse('$baseUrl/login/google'),
            headers: await _headers(),
            body: jsonEncode({'id_token': idToken}),
          )
          .timeout(AppConfig.connectTimeout);

      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Kesalahan saat login Google: $e'};
    }
  }

  static Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
    String passwordConfirmation, {
    String role = 'user',
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/register'),
            headers: await _headers(),
            body: jsonEncode({
              'name': name,
              'email': email,
              'password': password,
              'password_confirmation': passwordConfirmation,
              'role': role,
            }),
          )
          .timeout(AppConfig.connectTimeout);
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  static Future<Map<String, dynamic>> logout() async {
    try {
      try {
        final GoogleSignIn googleSignIn = GoogleSignIn();
        await googleSignIn.signOut();
      } catch (_) {}

      final res = await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: await _headers(auth: true),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': '$e'};
    }
  }

  /// Validasi token ke server — digunakan saat auto-login di splash/landing
  static Future<Map<String, dynamic>> validateToken() async {
    final token = await getToken();
    if (token != null && token.startsWith('demo_token')) {
      useMockData = true;
      return {'success': true, 'role': token == 'demo_token_coach' ? 'coach' : 'user'};
    }
    try {
      final res = await http
          .get(
            Uri.parse('$baseUrl/user'),
            headers: await _headers(auth: true),
          )
          .timeout(AppConfig.connectTimeout);
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return {'success': false, 'message': 'Token tidak valid (Status: ${res.statusCode})'};
    } catch (e) {
      return {'success': false, 'message': '$e'};
    }
  }

  // ── Dashboard ────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getDashboard() async {
    if (useMockData) {
      return _getMockDashboard();
    }
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/dashboard'),
        headers: await _headers(auth: true),
      ).timeout(AppConfig.connectTimeout);
      
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        return _getMockDashboard();
      }
    } catch (e) {
      debugPrint('ApiService: Menggunakan mock dashboard karena gagal terhubung: $e');
      return _getMockDashboard();
    }
  }

  // ── Foods ────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getFoods(
      {String? search, String? kategori}) async {
    if (useMockData) {
      return _getMockFoods();
    }
    try {
      final params = <String, String>{};
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (kategori != null && kategori.isNotEmpty) params['kategori'] = kategori;
      final uri = Uri.parse('$baseUrl/foods')
          .replace(queryParameters: params.isEmpty ? null : params);
      final res = await http.get(uri, headers: await _headers()).timeout(AppConfig.connectTimeout);
      
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        return _getMockFoods();
      }
    } catch (e) {
      debugPrint('ApiService: Menggunakan mock foods karena gagal terhubung: $e');
      return _getMockFoods();
    }
  }

  static Future<Map<String, dynamic>> getMealPlan() async {
    if (useMockData) {
      return _getMockMealPlan();
    }
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/foods/meal-plan'),
        headers: await _headers(auth: true),
      ).timeout(AppConfig.connectTimeout);
      
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        return _getMockMealPlan();
      }
    } catch (e) {
      debugPrint('ApiService: Menggunakan mock meal plan karena gagal terhubung: $e');
      return _getMockMealPlan();
    }
  }

  // ── Insight ──────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getInsight() async {
    if (useMockData) {
      return _getMockInsight();
    }
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/insight'),
        headers: await _headers(auth: true),
      ).timeout(AppConfig.connectTimeout);
      
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        return _getMockInsight();
      }
    } catch (e) {
      debugPrint('ApiService: Menggunakan mock insight karena gagal terhubung: $e');
      return _getMockInsight();
    }
  }

  // ── Log Food ─────────────────────────────────────────────────
  static Future<Map<String, dynamic>> logFood(int foodId, String waktu,
      {double porsi = 100}) async {
    if (useMockData) {
      return {'success': true, 'message': 'Log makanan tersimpan (Demo Mode)'};
    }
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/food/log'),
        headers: await _headers(auth: true),
        body: jsonEncode(
            {'food_id': foodId, 'waktu_makan': waktu, 'porsi_gram': porsi}),
      ).timeout(AppConfig.connectTimeout);
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  // ── Log Activity ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> logActivity(
      String name, double met, int duration) async {
    if (useMockData) {
      return {'success': true, 'message': 'Log aktivitas tersimpan (Demo Mode)'};
    }
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/activity-log'),
        headers: await _headers(auth: true),
        body: jsonEncode({
          'activity_name': name,
          'met': met,
          'duration_minutes': duration,
        }),
      ).timeout(AppConfig.connectTimeout);
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  // ── BMI ──────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> updateBmi({
    required double tinggi,
    required double berat,
    required int usia,
    required String gender,
    required String aktivitas,
  }) async {
    if (useMockData) {
      return {'success': true, 'message': 'Data BMI tersimpan (Demo Mode)'};
    }
    try {
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
      ).timeout(AppConfig.connectTimeout);
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  static Future<Map<String, dynamic>> getLatestBmi() async {
    if (useMockData) {
      return _getMockLatestBmi();
    }
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/bmi/latest'),
        headers: await _headers(auth: true),
      ).timeout(AppConfig.connectTimeout);
      
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        return _getMockLatestBmi();
      }
    } catch (e) {
      debugPrint('ApiService: Menggunakan mock latest BMI karena gagal terhubung: $e');
      return _getMockLatestBmi();
    }
  }

  // ── Delete Food Log ──────────────────────────────────────────
  static Future<Map<String, dynamic>> deleteFoodLog(int logId) async {
    if (useMockData) {
      return {'success': true, 'message': 'Log makanan dihapus (Demo Mode)'};
    }
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/food/log/$logId'),
        headers: await _headers(auth: true),
      ).timeout(AppConfig.connectTimeout);
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  // ── Food History ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> getFoodHistory(
      {int days = 7, String? date}) async {
    if (useMockData) {
      final dashboard = _getMockDashboard();
      return {
        'success': true,
        'data': dashboard['data']['today_logs']
      };
    }
    try {
      final params = <String, String>{};
      if (date != null) {
        params['date'] = date;
      } else {
        params['days'] = days.toString();
      }
      final uri = Uri.parse('$baseUrl/food-history')
          .replace(queryParameters: params);
      final res = await http.get(uri, headers: await _headers(auth: true)).timeout(AppConfig.connectTimeout);
      
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        final dashboard = _getMockDashboard();
        return {
          'success': true,
          'data': dashboard['data']['today_logs']
        };
      }
    } catch (e) {
      debugPrint('ApiService: Menggunakan mock history karena gagal terhubung: $e');
      final dashboard = _getMockDashboard();
      return {
        'success': true,
        'data': dashboard['data']['today_logs']
      };
    }
  }

  // ── Coach Endpoints ──────────────────────────────────────────
  /// Ambil daftar semua atlet (untuk pelatih)
  static Future<Map<String, dynamic>> getCoachAthletes() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/coach/athletes'),
        headers: await _headers(auth: true),
      ).timeout(AppConfig.connectTimeout);
      
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        return {'success': false, 'message': 'Gagal mengambil daftar atlet dari server (Status: ${res.statusCode})'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Kesalahan koneksi: $e'};
    }
  }

  /// Ambil detail satu atlet berdasarkan ID (untuk pelatih)
  static Future<Map<String, dynamic>> getCoachAthleteDetail(int id) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/coach/athletes/$id'),
        headers: await _headers(auth: true),
      ).timeout(AppConfig.connectTimeout);

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        return {'success': false, 'message': 'Gagal mengambil detail atlet dari server (Status: ${res.statusCode})'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Kesalahan koneksi: $e'};
    }
  }

  /// Ambil profil pelatih
  static Future<Map<String, dynamic>> getCoachProfile() async {
    if (useMockData) {
      return _getMockCoachProfile();
    }
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/coach/profile'),
        headers: await _headers(auth: true),
      ).timeout(AppConfig.connectTimeout);

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        return {'success': false, 'message': 'Status code: ${res.statusCode}'};
      }
    } catch (e) {
      debugPrint('ApiService: Gagal mengambil profil pelatih: $e');
      return {'success': false, 'message': e.toString()};
    }
  }



  static Map<String, dynamic> _getMockDashboard() {
    return {
      'success': true,
      'data': {
        'today': 'Selasa, 07 Juli 2026',
        'user': {
          'name': 'Budi Santoso',
          'email': 'budi.santoso@email.com'
        },
        'consumed_kalori': 1850.0,
        'burned_calories': 300.0,
        'current_slot': 'sarapan',
        'today_logs': [
          {'id': 1, 'food_name': 'Nasi Goreng + Telur Ceplok', 'waktu_makan': 'sarapan', 'kalori': 450.0, 'porsi_gram': 250.0},
          {'id': 2, 'food_name': 'Ayam Goreng Dada + Nasi Putih', 'waktu_makan': 'makan_siang', 'kalori': 600.0, 'porsi_gram': 300.0},
          {'id': 3, 'food_name': 'Sate Ayam (10 tusuk) + Lontong', 'waktu_makan': 'makan_malam', 'kalori': 710.0, 'porsi_gram': 350.0},
          {'id': 4, 'food_name': 'Pisang Ambon', 'waktu_makan': 'selingan', 'kalori': 90.0, 'porsi_gram': 100.0}
        ],
        'result': {
          'bmi': 22.4,
          'category': 'Normal',
          'calories': 2200.0,
          'bmi_data': {
            'berat_ideal': 65.5
          }
        }
      }
    };
  }

  static Map<String, dynamic> _getMockInsight() {
    return {
      'success': true,
      'data': {
        'bmi': 22.4,
        'status': 'Normal',
        'tinggi_badan': 175.0,
        'berat_badan': 68.6,
        'berat_ideal': 65.5,
        'target_kalori': 2200.0,
        'consumed_kalori': 1850.0,
        'pct_kalori': 84.0,
        'consumed_protein': 65.0,
        'target_protein': 75.0,
        'consumed_karbo': 220.0,
        'target_karbo': 275.0,
        'consumed_lemak': 50.0,
        'target_lemak': 60.0,
        'weekly_summary': [
          {'date': '2026-07-01', 'day': 'Rab', 'kalori': 1900.0, 'target': 2200.0},
          {'date': '2026-07-02', 'day': 'Kam', 'kalori': 2100.0, 'target': 2200.0},
          {'date': '2026-07-03', 'day': 'Jum', 'kalori': 2300.0, 'target': 2200.0},
          {'date': '2026-07-04', 'day': 'Sab', 'kalori': 1800.0, 'target': 2200.0},
          {'date': '2026-07-05', 'day': 'Min', 'kalori': 2050.0, 'target': 2200.0},
          {'date': '2026-07-06', 'day': 'Sen', 'kalori': 2250.0, 'target': 2200.0},
          {'date': '2026-07-07', 'day': 'Sel', 'kalori': 1850.0, 'target': 2200.0}
        ]
      }
    };
  }

  static Map<String, dynamic> _getMockFoods() {
    return {
      'success': true,
      'data': [
        {'id': 1, 'nama_makanan': 'Nasi Goreng + Telur Ceplok', 'kategori': 'Makanan Utama', 'kalori': 450.0, 'porsi_gram': 250.0, 'protein': 15.0, 'karbohidrat': 50.0, 'lemak': 18.0},
        {'id': 2, 'nama_makanan': 'Ayam Goreng Dada + Nasi Putih', 'kategori': 'Makanan Utama', 'kalori': 600.0, 'porsi_gram': 300.0, 'protein': 35.0, 'karbohidrat': 60.0, 'lemak': 12.0},
        {'id': 3, 'nama_makanan': 'Sate Ayam (10 tusuk) + Lontong', 'kategori': 'Makanan Utama', 'kalori': 710.0, 'porsi_gram': 350.0, 'protein': 28.0, 'karbohidrat': 70.0, 'lemak': 25.0},
        {'id': 4, 'nama_makanan': 'Pisang Ambon', 'kategori': 'Selingan', 'kalori': 90.0, 'porsi_gram': 100.0, 'protein': 1.2, 'karbohidrat': 23.0, 'lemak': 0.3},
        {'id': 5, 'nama_makanan': 'Bubur Ayam Cirebon', 'kategori': 'Makanan Utama', 'kalori': 320.0, 'porsi_gram': 200.0, 'protein': 10.0, 'karbohidrat': 40.0, 'lemak': 8.0},
        {'id': 6, 'nama_makanan': 'Gado-Gado Betawi', 'kategori': 'Makanan Utama', 'kalori': 380.0, 'porsi_gram': 250.0, 'protein': 12.0, 'karbohidrat': 45.0, 'lemak': 15.0},
        {'id': 7, 'nama_makanan': 'Susu Full Cream UHT', 'kategori': 'Selingan', 'kalori': 150.0, 'porsi_gram': 200.0, 'protein': 8.0, 'karbohidrat': 12.0, 'lemak': 8.0},
        {'id': 8, 'nama_makanan': 'Roti Bakar Keju Cokelat', 'kategori': 'Selingan', 'kalori': 420.0, 'porsi_gram': 150.0, 'protein': 9.0, 'karbohidrat': 55.0, 'lemak': 16.0},
        {'id': 9, 'nama_makanan': 'Nasi Padang Rendang', 'kategori': 'Makanan Utama', 'kalori': 850.0, 'porsi_gram': 400.0, 'protein': 30.0, 'karbohidrat': 95.0, 'lemak': 38.0},
        {'id': 10, 'nama_makanan': 'Kopi Susu Gula Aren', 'kategori': 'Minuman', 'kalori': 230.0, 'porsi_gram': 200.0, 'protein': 3.0, 'karbohidrat': 32.0, 'lemak': 6.0}
      ]
    };
  }

  static Map<String, dynamic> _getMockMealPlan() {
    return {
      'success': true,
      'data': {
        'sarapan': {'id': 1, 'nama_makanan': 'Nasi Goreng + Telur Ceplok', 'kalori': 450.0},
        'makan_siang': {'id': 2, 'nama_makanan': 'Ayam Goreng Dada + Nasi Putih', 'kalori': 600.0},
        'makan_malam': {'id': 3, 'nama_makanan': 'Sate Ayam (10 tusuk) + Lontong', 'kalori': 710.0},
        'selingan': {'id': 4, 'nama_makanan': 'Pisang Ambon', 'kalori': 90.0}
      }
    };
  }

  static Map<String, dynamic> _getMockLatestBmi() {
    return {
      'success': true,
      'data': {
        'tinggi_badan': 175.0,
        'berat_badan': 68.6,
        'usia': 22,
        'jenis_kelamin': 'Laki-laki',
        'aktivitas': 'Sedang',
        'skor': 22.4,
        'category': 'Normal',
        'kalori_target': 2200.0
      }
    };
  }

  static Map<String, dynamic> _getMockCoachProfile() {
    return {
      'success': true,
      'data': {
        'name': 'Coach John Doe',
        'email': 'john.doe@coach.giziapp.com',
        'role': 'coach',
        'total_athletes': 5,
        'joined_at': '01 Juni 2026',
      }
    };
  }
}